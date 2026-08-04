import 'dart:convert';

import 'package:flutter_core_project/data/models/level_up/level_up_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef PreferencesFactory = Future<SharedPreferences> Function();

class LevelUpLocalStore {
  static const int _draftVersion = 1;

  final PreferencesFactory _preferencesFactory;

  LevelUpLocalStore({PreferencesFactory? preferencesFactory})
      : _preferencesFactory =
            preferencesFactory ?? SharedPreferences.getInstance;

  String _filterKey(String email) =>
      'level_up_filter_v1::${email.trim().toLowerCase()}';

  String _draftKey(String email, String examId) =>
      'level_up_score_draft_v1::${email.trim().toLowerCase()}::$examId';

  Future<LevelUpFilter?> loadFilter(String email) async {
    if (email.trim().isEmpty) return null;
    final prefs = await _preferencesFactory();
    final raw = prefs.getString(_filterKey(email));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException('Expected map');
      final json = Map<String, dynamic>.from(decoded);
      if (json['version'] != LevelUpFilter.currentVersion) return null;
      return LevelUpFilter.fromJson(json);
    } catch (_) {
      await prefs.remove(_filterKey(email));
      return null;
    }
  }

  Future<void> saveFilter(String email, LevelUpFilter filter) async {
    if (email.trim().isEmpty) return;
    final prefs = await _preferencesFactory();
    final didSave = await prefs.setString(
      _filterKey(email),
      jsonEncode(filter.copyWith(savedAt: DateTime.now()).toJson()),
    );
    if (!didSave) {
      throw StateError('Không thể lưu bộ lọc LevelUp.');
    }
  }

  Future<void> deleteFilter(String email) async {
    if (email.trim().isEmpty) return;
    final prefs = await _preferencesFactory();
    await prefs.remove(_filterKey(email));
  }

  Future<LevelUpScoreSubmission?> loadDraft(
    String email,
    String examId,
  ) async {
    if (email.trim().isEmpty || examId.isEmpty) return null;
    final prefs = await _preferencesFactory();
    final raw = prefs.getString(_draftKey(email, examId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException('Expected map');
      final stored = Map<String, dynamic>.from(decoded);
      if (stored['version'] != _draftVersion || stored['draft'] is! Map) {
        throw const FormatException('Unsupported draft version');
      }
      final draft = LevelUpScoreSubmission.fromJson(
        Map<String, dynamic>.from(stored['draft'] as Map),
      );
      if (draft.examId != examId ||
          draft.examinerEmail.trim().toLowerCase() !=
              email.trim().toLowerCase()) {
        throw const FormatException('Draft identity mismatch');
      }
      return draft;
    } catch (_) {
      await prefs.remove(_draftKey(email, examId));
      return null;
    }
  }

  Future<void> saveDraft(LevelUpScoreSubmission draft) async {
    if (draft.examinerEmail.trim().isEmpty || draft.examId.isEmpty) return;
    final prefs = await _preferencesFactory();
    final didSave = await prefs.setString(
      _draftKey(draft.examinerEmail, draft.examId),
      jsonEncode({
        'version': _draftVersion,
        'draft': draft.toJson(),
      }),
    );
    if (!didSave) {
      throw StateError('Không thể lưu bản nháp LevelUp.');
    }
  }

  Future<void> deleteDraft(String email, String examId) async {
    if (email.trim().isEmpty || examId.isEmpty) return;
    final prefs = await _preferencesFactory();
    await prefs.remove(_draftKey(email, examId));
  }
}
