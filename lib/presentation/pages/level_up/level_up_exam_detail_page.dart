import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/core/configs/app_config.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/data/models/level_up/level_up_models.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_core_project/services/level_up_local_store.dart';

class LevelUpExamDetailPage extends StatefulWidget {
  final LevelUpPracticalExam exam;
  final String examinerEmail;
  final LevelUpLocalStore localStore;

  const LevelUpExamDetailPage({
    super.key,
    required this.exam,
    required this.examinerEmail,
    required this.localStore,
  });

  @override
  State<LevelUpExamDetailPage> createState() => _LevelUpExamDetailPageState();
}

class _LevelUpExamDetailPageState extends State<LevelUpExamDetailPage> {
  late final List<_EditableCriterion> _criteria;
  final TextEditingController _overallNoteController = TextEditingController();
  String? _token;
  bool _loadingDraft = true;
  bool _savingDraft = false;
  bool _isDirty = false;
  bool _discardDialogOpen = false;
  int _editRevision = 0;

  @override
  void initState() {
    super.initState();
    final source = widget.exam.criteria.isEmpty && widget.exam.maxScore != null
        ? [
            LevelUpScoreCriterion(
              id: 'overall',
              title: 'Điểm tổng bài thi',
              minScore: 0,
              maxScore: widget.exam.maxScore ?? 100,
              existingScore: widget.exam.score,
              imageUrls: const [],
              rawData: const {},
              description:
                  'Backend chưa trả danh sách tiêu chí; nhập điểm tổng theo thang điểm của bài thi.',
            ),
          ]
        : widget.exam.criteria;
    _criteria = [
      for (final criterion in source)
        _EditableCriterion(
          criterion,
          prefillExistingScore: widget.exam.isScored,
        ),
    ];
    for (final item in _criteria) {
      item.scoreController.addListener(_onFieldChanged);
      item.noteController.addListener(_onFieldChanged);
    }
    _overallNoteController.addListener(_onFieldChanged);
    _loadDraft();
  }

  @override
  void dispose() {
    for (final item in _criteria) {
      item.scoreController
        ..removeListener(_onFieldChanged)
        ..dispose();
      item.noteController
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    _overallNoteController
      ..removeListener(_onFieldChanged)
      ..dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!mounted || _loadingDraft) return;
    setState(() {
      _editRevision++;
      _isDirty = true;
    });
  }

  Future<void> _loadDraft() async {
    try {
      final storedData = await Future.wait<Object?>([
        AuthService.getToken(),
        _hasStableDraftIdentity
            ? widget.localStore.loadDraft(
                widget.examinerEmail,
                widget.exam.id,
              )
            : Future<LevelUpScoreSubmission?>.value(),
      ]);
      final token = storedData[0] as String?;
      final draft = storedData[1] as LevelUpScoreSubmission?;
      if (!mounted) return;

      if (draft != null) {
        for (final saved in draft.items) {
          for (final editable in _criteria) {
            if (editable.criterion.id == saved.criterionId) {
              editable.scoreController.text = _formatNumber(saved.score);
              editable.noteController.text = saved.note ?? '';
              break;
            }
          }
        }
        _overallNoteController.text = draft.overallNote ?? '';
      }
      setState(() {
        _token = token;
        _loadingDraft = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDraft = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không đọc được bản nháp đã lưu. Bạn vẫn có thể chấm bài mới.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }
  }

  double? _scoreOf(_EditableCriterion editable) {
    final raw = editable.scoreController.text.trim().replaceAll(',', '.');
    return raw.isEmpty ? null : double.tryParse(raw);
  }

  double get _totalScore => _criteria.fold<double>(
        0,
        (sum, item) => sum + (_scoreOf(item) ?? 0),
      );

  double? get _criteriaMaxTotal {
    if (_criteria.isEmpty ||
        _criteria.any((item) => !_hasValidScoreRange(item.criterion))) {
      return null;
    }
    return _criteria.fold<double>(
      0,
      (sum, item) => sum + item.criterion.maxScore!,
    );
  }

  bool get _hasConsistentScoreTotal {
    final criteriaTotal = _criteriaMaxTotal;
    final examTotal = widget.exam.maxScore;
    if (criteriaTotal == null || examTotal == null) return false;
    return (criteriaTotal - examTotal).abs() <= 0.000001;
  }

  bool get _hasScorableCriteria => _hasConsistentScoreTotal;

  bool get _hasStableDraftIdentity {
    if (!widget.exam.hasStableId ||
        _criteria.isEmpty ||
        _criteria.any((item) => !item.criterion.hasStableId)) {
      return false;
    }
    final ids = _criteria.map((item) => item.criterion.id).toList();
    return ids.toSet().length == ids.length;
  }

  bool get _canSaveDraft => _hasStableDraftIdentity && _hasScorableCriteria;

  double? get _maxScore {
    return _hasScorableCriteria ? widget.exam.maxScore : null;
  }

  String? _validateScores() {
    for (var index = 0; index < _criteria.length; index++) {
      final editable = _criteria[index];
      final raw = editable.scoreController.text.trim();
      if (raw.isEmpty) {
        if (editable.noteController.text.trim().isNotEmpty) {
          return 'Vui lòng nhập điểm tiêu chí ${index + 1} trước khi lưu ghi chú.';
        }
        continue;
      }
      final maxScore = editable.criterion.maxScore;
      if (maxScore == null) {
        return 'Tiêu chí ${index + 1} chưa được cấu hình thang điểm.';
      }
      final score = _scoreOf(editable);
      if (score == null) return 'Điểm tiêu chí ${index + 1} không hợp lệ.';
      if (score < editable.criterion.minScore || score > maxScore) {
        return 'Điểm tiêu chí ${index + 1} phải từ '
            '${_formatNumber(editable.criterion.minScore)} đến '
            '${_formatNumber(maxScore)}.';
      }
    }
    return null;
  }

  LevelUpScoreSubmission _buildSubmission() {
    final items = <LevelUpScoreItem>[];
    for (final editable in _criteria) {
      final score = _scoreOf(editable);
      final maxScore = editable.criterion.maxScore;
      if (score == null || maxScore == null) continue;
      final note = editable.noteController.text.trim();
      items.add(
        LevelUpScoreItem(
          criterionId: editable.criterion.id,
          criterionName: editable.criterion.title,
          score: score,
          maxScore: maxScore,
          note: note.isEmpty ? null : note,
        ),
      );
    }
    final overallNote = _overallNoteController.text.trim();
    return LevelUpScoreSubmission(
      examId: widget.exam.id,
      candidateId: widget.exam.candidateId,
      examinerEmail: widget.examinerEmail,
      items: items,
      totalScore: _totalScore,
      overallNote: overallNote.isEmpty ? null : overallNote,
      gradedAt: DateTime.now(),
    );
  }

  Future<void> _saveDraft() async {
    FocusScope.of(context).unfocus();
    final validation = _validateScores();
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _savingDraft = true);
    final savedRevision = _editRevision;
    final submission = _buildSubmission();
    try {
      await widget.localStore.saveDraft(submission);
      if (!mounted) return;
      final hasNewerChanges = _editRevision != savedRevision;
      if (!hasNewerChanges) setState(() => _isDirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasNewerChanges
                ? 'Đã lưu bản nháp. Các thay đổi mới hơn chưa được lưu.'
                : 'Đã lưu bản nháp chấm điểm trên thiết bị.',
          ),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không lưu được bản nháp. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final background =
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F7F6);
    return PopScope(
      canPop: !_isDirty && !_savingDraft,
      onPopInvoked: (didPop) {
        if (!didPop && !_savingDraft) _confirmDiscardChanges();
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Chi tiết bài thi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        body: _loadingDraft
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        children: [
                          _buildCandidateHeader(isDark),
                          const SizedBox(height: 14),
                          _buildExamInformation(isDark),
                          if (widget.exam.imageUrls.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _SectionCard(
                              title: 'Ảnh bài thi',
                              icon: Icons.photo_library_outlined,
                              child: _ImageStrip(
                                urls: widget.exam.imageUrls,
                                headers: _imageHeaders,
                                cacheScope: _imageCacheScope,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Nội dung chấm điểm',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                _criteria.isEmpty
                                    ? 'Chưa có thang điểm'
                                    : '${_criteria.length} tiêu chí',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFD1D5DB)
                                      : const Color(0xFF6B7280),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (!_hasStableDraftIdentity &&
                              _criteria.isNotEmpty) ...[
                            _buildDraftIdentityMissing(isDark),
                            const SizedBox(height: 12),
                          ],
                          if (_maxScore == null) ...[
                            _buildScoreConfigurationMissing(isDark),
                            const SizedBox(height: 12),
                          ],
                          for (var index = 0;
                              index < _criteria.length;
                              index++) ...[
                            _CriterionCard(
                              index: index,
                              editable: _criteria[index],
                              headers: _imageHeaders,
                              cacheScope: _imageCacheScope,
                              allowScoring: _canSaveDraft,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _buildOverallNote(isDark),
                          const SizedBox(height: 12),
                          _buildBackendNotice(isDark),
                        ],
                      ),
                    ),
                    _buildBottomBar(isDark),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _confirmDiscardChanges() async {
    if (_discardDialogOpen || !mounted) return;
    _discardDialogOpen = true;
    try {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Bỏ thay đổi chưa lưu?'),
          content: const Text(
            'Điểm hoặc nhận xét bạn vừa nhập sẽ bị mất.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Tiếp tục chấm'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
              child: const Text('Bỏ thay đổi'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
      setState(() => _isDirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    } finally {
      _discardDialogOpen = false;
    }
  }

  Map<String, String>? get _imageHeaders {
    final token = _token;
    if (token == null || token.isEmpty) return null;
    return {'Authorization': 'Bearer $token'};
  }

  String get _imageCacheScope => widget.examinerEmail
      .trim()
      .toLowerCase()
      .hashCode
      .toUnsigned(32)
      .toRadixString(16);

  Widget _buildCandidateHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14532D), Color(0xFF22A447)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Text(
                  _initials(widget.exam.candidateName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THÍ SINH',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.exam.candidateName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.exam.candidateCode.isNotEmpty)
                      Text(
                        'MSNV: ${widget.exam.candidateCode}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 96),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.exam.status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.exam.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamInformation(bool isDark) {
    final rows = <({IconData icon, String label, String value})>[
      if (widget.exam.examCode?.isNotEmpty == true)
        (
          icon: Icons.tag_rounded,
          label: 'Mã bài thi',
          value: widget.exam.examCode!,
        ),
      if (widget.exam.factoryName?.isNotEmpty == true)
        (
          icon: Icons.factory_outlined,
          label: 'Nhà máy',
          value: widget.exam.factoryName!,
        ),
      if (widget.exam.lineName?.isNotEmpty == true)
        (
          icon: Icons.account_tree_outlined,
          label: 'Line',
          value: widget.exam.lineName!,
        ),
      if (widget.exam.machineName?.isNotEmpty == true)
        (
          icon: Icons.precision_manufacturing_outlined,
          label: 'Máy',
          value: widget.exam.machineName!,
        ),
      if (widget.exam.levelName?.isNotEmpty == true)
        (
          icon: Icons.military_tech_outlined,
          label: 'Cấp bậc',
          value: widget.exam.levelName!,
        ),
      if (widget.exam.examDate?.isNotEmpty == true)
        (
          icon: Icons.event_outlined,
          label: 'Ngày thi',
          value: widget.exam.examDate!,
        ),
    ];
    return _SectionCard(
      title: 'Thông tin bài thi',
      icon: Icons.assignment_outlined,
      child: rows.isEmpty
          ? const Text(
              'Backend chưa cung cấp thêm thông tin cho bài thi này.',
              style: TextStyle(fontSize: 12),
            )
          : Column(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  Row(
                    children: [
                      Icon(
                        rows[index].icon,
                        size: 17,
                        color: isDark
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 9),
                      SizedBox(
                        width: 76,
                        child: Text(
                          rows[index].label,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFD1D5DB)
                                : const Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          rows[index].value,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (index != rows.length - 1)
                    Divider(
                      height: 20,
                      color: isDark ? Colors.white10 : const Color(0xFFF0F0F0),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _buildOverallNote(bool isDark) {
    return _SectionCard(
      title: 'Nhận xét chung',
      icon: Icons.notes_rounded,
      child: TextField(
        controller: _overallNoteController,
        enabled: _canSaveDraft,
        maxLines: 4,
        minLines: 3,
        maxLength: 1000,
        decoration: _inputDecoration(
          isDark,
          hint: 'Nhập nhận xét tổng quan về bài thi...',
        ),
      ),
    );
  }

  Widget _buildScoreConfigurationMissing(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF302A1E) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.rule_folder_outlined, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _criteriaMaxTotal != null && widget.exam.maxScore != null
                  ? 'Tổng thang điểm bài thi không khớp tổng các tiêu chí. '
                      'Chức năng nhập điểm được khóa để tránh chấm sai dữ liệu.'
                  : 'Bài thi chưa có tiêu chí hoặc thang điểm từ backend. '
                      'Chức năng nhập điểm được khóa để tránh chấm sai dữ liệu.',
              style: const TextStyle(fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftIdentityMissing(bool isDark) {
    final message = widget.exam.hasStableId
        ? 'Backend chưa cung cấp mã ổn định và duy nhất cho tất cả tiêu chí. '
            'Nhập điểm được khóa để tránh gán nhầm bản nháp.'
        : 'Backend chưa cung cấp mã bài thi ổn định. Nhập điểm '
            'được khóa để tránh gán nhầm bản nháp.';
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF302A1E) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.key_off_outlined, color: Color(0xFFD97706)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackendNotice(bool isDark) {
    final message = !widget.exam.hasStableId
        ? 'Backend chưa cung cấp mã bài thi ổn định, nên bản nháp '
            'không được lưu để tránh gán nhầm điểm sang bài khác.'
        : !_hasStableDraftIdentity
            ? 'Backend chưa cung cấp mã ổn định và duy nhất cho tất cả tiêu chí, '
                'nên bản nháp được khóa để tránh gán nhầm điểm.'
            : !_hasScorableCriteria
                ? 'Backend chưa cung cấp đủ thang điểm. Chức năng lưu '
                    'bản nháp được khóa cho tới khi dữ liệu hợp lệ.'
                : 'Điểm hiện được lưu nháp trên thiết bị. Nút gửi hệ thống '
                    'sẽ được bật khi backend cung cấp API POST chính thức.';
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF302A1E) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final maxScore = _maxScore;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TỔNG ĐIỂM ĐÃ NHẬP',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF6B7280),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _formatNumber(_totalScore),
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFF15803D),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' / ${maxScore == null ? '—' : _formatNumber(maxScore)}',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              key: const ValueKey('levelup_save_draft'),
              onPressed: _savingDraft || !_canSaveDraft ? null : _saveDraft,
              icon: _savingDraft
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Lưu bản nháp'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableCriterion {
  final LevelUpScoreCriterion criterion;
  final TextEditingController scoreController;
  final TextEditingController noteController;

  _EditableCriterion(
    this.criterion, {
    required bool prefillExistingScore,
  })  : scoreController = TextEditingController(
          text: !prefillExistingScore || criterion.existingScore == null
              ? ''
              : _formatNumber(criterion.existingScore!),
        ),
        noteController = TextEditingController();
}

class _CriterionCard extends StatelessWidget {
  final int index;
  final _EditableCriterion editable;
  final Map<String, String>? headers;
  final String cacheScope;
  final bool allowScoring;

  const _CriterionCard({
    required this.index,
    required this.editable,
    required this.headers,
    required this.cacheScope,
    required this.allowScoring,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final criterion = editable.criterion;
    final maxScore = criterion.maxScore;
    final rangeConfigured = _hasValidScoreRange(criterion);
    final scoreEnabled = allowScoring && rangeConfigured;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8EC),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      criterion.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    if (criterion.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 5),
                      Text(
                        criterion.description!,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF6B7280),
                          fontSize: 11,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  !rangeConfigured
                      ? 'Chưa có thang điểm'
                      : 'Tối đa ${_formatNumber(maxScore!)}',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF6B7280),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (criterion.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 13),
            _ImageStrip(
              urls: criterion.imageUrls,
              headers: headers,
              cacheScope: cacheScope,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                textField: true,
                enabled: scoreEnabled,
                label: !allowScoring
                    ? '${criterion.title}, đang khóa do dữ liệu bài thi chưa hợp lệ'
                    : !rangeConfigured
                        ? '${criterion.title}, chưa có thang điểm'
                        : 'Điểm ${criterion.title}, tối đa ${_formatNumber(maxScore!)}',
                child: SizedBox(
                  width: 112,
                  child: TextField(
                    key: ValueKey('levelup_score_${criterion.id}'),
                    controller: editable.scoreController,
                    enabled: scoreEnabled,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [_DecimalScoreFormatter()],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFF15803D),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: _inputDecoration(
                      isDark,
                      hint: !allowScoring
                          ? 'Đã khóa'
                          : !rangeConfigured
                              ? 'Chưa cấu hình'
                              : 'Điểm',
                      suffixText: !rangeConfigured
                          ? null
                          : '/${_formatNumber(maxScore!)}',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: ValueKey('levelup_note_${criterion.id}'),
                  controller: editable.noteController,
                  enabled: scoreEnabled,
                  maxLines: 2,
                  minLines: 1,
                  maxLength: 500,
                  decoration: _inputDecoration(
                    isDark,
                    hint: 'Ghi chú tiêu chí (không bắt buộc)',
                  ).copyWith(counterText: ''),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 19,
                color:
                    isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  final List<String> urls;
  final Map<String, String>? headers;
  final String cacheScope;

  const _ImageStrip({
    required this.urls,
    required this.headers,
    required this.cacheScope,
  });

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final thumbnailCacheWidth = (112 * pixelRatio).round();
    final thumbnailCacheHeight = (94 * pixelRatio).round();
    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final url = _absoluteImageUrl(urls[index]);
          return Semantics(
            button: true,
            label:
                'Ảnh bài thi ${index + 1} trên ${urls.length}. Chạm để xem và phóng to.',
            child: InkWell(
              key: ValueKey('levelup_image_$index'),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => _FullScreenImageViewer(
                    urls: urls,
                    initialIndex: index,
                    headers: headers,
                    cacheScope: cacheScope,
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 112,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: url,
                        cacheKey: _scopedImageCacheKey(cacheScope, url),
                        httpHeaders: _trustedImageHeaders(url, headers),
                        memCacheWidth: thumbnailCacheWidth,
                        memCacheHeight: thumbnailCacheHeight,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFFF3F4F6),
                          alignment: Alignment.center,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFF3F4F6),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 5,
                        bottom: 5,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final Map<String, String>? headers;
  final String cacheScope;

  const _FullScreenImageViewer({
    required this.urls,
    required this.initialIndex,
    required this.headers,
    required this.cacheScope,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_index + 1}/${widget.urls.length}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (index) => setState(() => _index = index),
        itemCount: widget.urls.length,
        itemBuilder: (context, index) {
          final imageUrl = _absoluteImageUrl(widget.urls[index]);
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 5,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                cacheKey: _scopedImageCacheKey(
                  widget.cacheScope,
                  imageUrl,
                ),
                httpHeaders: _trustedImageHeaders(imageUrl, widget.headers),
                fit: BoxFit.contain,
                placeholder: (_, __) => const CircularProgressIndicator(
                  color: Colors.white,
                ),
                errorWidget: (_, __, ___) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image_outlined,
                        color: Colors.white54, size: 52),
                    SizedBox(height: 10),
                    Text('Không tải được ảnh',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

InputDecoration _inputDecoration(
  bool isDark, {
  required String hint,
  String? suffixText,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: isDark ? Colors.white12 : const Color(0xFFD1D5DB),
    ),
  );
  return InputDecoration(
    hintText: hint,
    suffixText: suffixText,
    filled: true,
    fillColor: isDark ? const Color(0xFF292929) : const Color(0xFFF9FAFB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
    ),
  );
}

String _absoluteImageUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final base = AppConfig.baseUrl.replaceFirst(RegExp(r'/$'), '');
  return '$base/${trimmed.replaceFirst(RegExp(r'^/'), '')}';
}

String _scopedImageCacheKey(String scope, String url) => 'levelup-$scope::$url';

Map<String, String>? _trustedImageHeaders(
  String imageUrl,
  Map<String, String>? headers,
) {
  if (headers == null || headers.isEmpty) return null;
  final imageUri = Uri.tryParse(imageUrl);
  final baseUri = Uri.tryParse(AppConfig.baseUrl);
  if (imageUri == null || baseUri == null) return null;

  int effectivePort(Uri uri) {
    if (uri.hasPort) return uri.port;
    return uri.scheme.toLowerCase() == 'https' ? 443 : 80;
  }

  final trusted = imageUri.scheme.toLowerCase() == 'https' &&
      baseUri.scheme.toLowerCase() == 'https' &&
      imageUri.host.toLowerCase() == baseUri.host.toLowerCase() &&
      effectivePort(imageUri) == effectivePort(baseUri);
  return trusted ? headers : null;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'TS';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');

bool _hasValidScoreRange(LevelUpScoreCriterion criterion) {
  final maxScore = criterion.maxScore;
  return maxScore != null &&
      criterion.minScore >= 0 &&
      criterion.minScore <= maxScore;
}

class _DecimalScoreFormatter extends TextInputFormatter {
  const _DecimalScoreFormatter();

  static final RegExp _pattern = RegExp(r'^\d*(?:[.,]\d*)?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
