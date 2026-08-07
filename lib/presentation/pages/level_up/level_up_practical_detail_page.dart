import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/core/configs/app_config.dart';
import 'package:flutter_core_project/data/data_sources/remote/level_up_api_service.dart';
import 'package:flutter_core_project/data/models/level_up/level_up_models.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_html/flutter_html.dart';

class LevelUpPracticalDetailPage extends StatefulWidget {
  final LevelUpApiService api;
  final int practicalId;
  final LevelUpPracticalExam summary;

  const LevelUpPracticalDetailPage({
    super.key,
    required this.api,
    required this.practicalId,
    required this.summary,
  });

  @override
  State<LevelUpPracticalDetailPage> createState() =>
      _LevelUpPracticalDetailPageState();
}

class _LevelUpPracticalDetailPageState
    extends State<LevelUpPracticalDetailPage> {
  final ScrollController _scrollController = ScrollController();
  LevelUpPracticalDetail? _detail;
  List<_QuestionScoreEditor> _editors = const [];
  List<GlobalKey> _questionKeys = const [];
  String? _token;
  String? _error;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isDirty = false;
  int? _expandedQuestionIndex = 0;
  int _questionToggleRequest = 0;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _disposeEditors();
    _scrollController.dispose();
    super.dispose();
  }

  void _disposeEditors() {
    for (final editor in _editors) {
      editor.controller
        ..removeListener(_onScoreChanged)
        ..dispose();
    }
  }

  Future<void> _loadDetail() async {
    _questionToggleRequest++;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await Future.wait<Object?>([
        widget.api.getPracticalDetail(practicalId: widget.practicalId),
        AuthService.getToken(),
      ]);
      final detail = result[0] as LevelUpPracticalDetail;
      final token = result[1] as String?;
      if (!mounted) return;
      _disposeEditors();
      final editors = [
        for (final question in detail.questions) _QuestionScoreEditor(question),
      ];
      for (final editor in editors) {
        editor.controller.addListener(_onScoreChanged);
      }
      setState(() {
        _detail = detail;
        _editors = editors;
        _questionKeys = [for (final _ in editors) GlobalKey()];
        _token = token;
        _isLoading = false;
        _isDirty = false;
        _expandedQuestionIndex = editors.isEmpty ? null : 0;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  void _onScoreChanged() {
    if (!mounted || _isLoading) return;
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _toggleQuestion(int index) async {
    FocusScope.of(context).unfocus();
    final requestId = ++_questionToggleRequest;
    final willOpen = _expandedQuestionIndex != index;
    setState(() {
      _expandedQuestionIndex = willOpen ? index : null;
    });
    if (!willOpen) return;

    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted || requestId != _questionToggleRequest) return;
    final targetContext = _questionKeys[index].currentContext;
    if (targetContext == null || !targetContext.mounted) return;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  double? _scoreOf(_QuestionScoreEditor editor) {
    final text = editor.controller.text.trim().replaceAll(',', '.');
    return text.isEmpty ? null : double.tryParse(text);
  }

  double get _totalScore => _editors.fold<double>(
        0,
        (sum, editor) => sum + (_scoreOf(editor) ?? 0),
      );

  double get _maximumScore => _editors.fold<double>(
        0,
        (sum, editor) => sum + editor.question.scoreLimit,
      );

  String? _validateScores() {
    if (_editors.isEmpty) return 'Bài thi chưa có câu hỏi để chấm điểm.';
    for (var index = 0; index < _editors.length; index++) {
      final editor = _editors[index];
      final raw = editor.controller.text.trim();
      if (raw.isEmpty) continue;
      final score = _scoreOf(editor);
      if (score == null || !score.isFinite) {
        return 'Điểm câu ${index + 1} không hợp lệ.';
      }
      if (score < 0 || score > editor.question.scoreLimit) {
        return 'Điểm câu ${index + 1} phải từ 0 đến '
            '${_formatScore(editor.question.scoreLimit)}.';
      }
    }
    return null;
  }

  Future<void> _completeGrading() async {
    if (_isSubmitting) return;
    final validation = _validateScores();
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation), backgroundColor: Colors.red),
      );
      return;
    }

    final zeroCount = _editors.where((editor) {
      final score = _scoreOf(editor);
      return score == null || score == 0;
    }).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          zeroCount > 0
              ? Icons.warning_amber_rounded
              : Icons.fact_check_outlined,
          color:
              zeroCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF15803D),
          size: 38,
        ),
        title: Text(
          zeroCount > 0
              ? '$zeroCount câu có điểm 0'
              : 'Xác nhận hoàn thành chấm bài',
          textAlign: TextAlign.center,
        ),
        content: Text(
          zeroCount > 0
              ? 'Có $zeroCount/${_editors.length} câu đang bỏ trống hoặc có điểm 0. Các câu bỏ trống sẽ tự động được gửi với 0 điểm. Bạn có chắc muốn hoàn thành?'
              : 'Tất cả câu hỏi đã được nhập điểm. Bạn có chắc muốn gửi kết quả chấm bài?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kiểm tra lại'),
          ),
          FilledButton(
            key: const ValueKey('levelup_confirm_submit'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận gửi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final detail = _detail!;
    final payloads = [
      for (final editor in _editors)
        LevelUpPracticalScoreRequest(
          examPracticalId: detail.examPracticalId,
          fixedExamPracticalId: editor.question.practicalId,
          fixedExamPracticalQuestionId: editor.question.id,
          score: _scoreOf(editor) ?? 0,
        ),
    ];
    setState(() => _isSubmitting = true);
    try {
      await widget.api.submitPracticalScores(scores: payloads);
      if (!mounted) return;
      setState(() {
        _isDirty = false;
        _isSubmitting = false;
      });
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 44,
          ),
          title: const Text('Đã hoàn thành chấm bài'),
          content: const Text(
            'Điểm bài thi đã được gửi thành công.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleBack() async {
    if (_isSubmitting) return;
    if (!_isDirty) {
      Navigator.pop(context);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bỏ thay đổi chưa gửi?'),
        content: const Text('Các điểm vừa chỉnh sửa sẽ không được lưu.'),
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
            child: const Text('Rời trang'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final background =
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F7F6);
    return PopScope(
      canPop: !_isDirty && !_isSubmitting,
      onPopInvoked: (didPop) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          leading: BackButton(onPressed: _isSubmitting ? null : _handleBack),
          title: const Text(
            'Chi tiết bài thi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: _buildBody(isDark)),
            if (_isSubmitting)
              const Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Colors.black45,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 14),
                              Text('Đang gửi điểm bài thi...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Đang tải chi tiết bài thi...'),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 52, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadDetail,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final detail = _detail!;
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              key: const PageStorageKey('levelup_practical_detail_scroll'),
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _buildHeader(detail, isDark),
                if (detail.descriptionHtml?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _HtmlSection(
                    title: 'Mô tả bài thi',
                    html: detail.descriptionHtml!,
                    token: _token,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Câu hỏi và bài làm',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${detail.questions.length} câu',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_editors.isEmpty)
                  const _EmptyQuestions()
                else
                  for (var index = 0; index < _editors.length; index++) ...[
                    _QuestionCard(
                      cardKey: _questionKeys[index],
                      index: index,
                      editor: _editors[index],
                      token: _token,
                      expanded: _expandedQuestionIndex == index,
                      onToggle: () => _toggleQuestion(index),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
          _buildBottomBar(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(LevelUpPracticalDetail detail, bool isDark) {
    final exam = detail.exam;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14532D), Color(0xFF22A447)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BÀI THI #${exam.examNumber ?? exam.examCode ?? '--'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail.examTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            exam.candidateName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _HeaderTag(text: exam.factoryName ?? '--'),
              _HeaderTag(text: exam.lineName ?? '--'),
              _HeaderTag(text: exam.machineName ?? '--'),
              _HeaderTag(text: exam.levelName ?? '--'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tổng điểm', style: TextStyle(fontSize: 10)),
                AnimatedBuilder(
                  animation: Listenable.merge([
                    for (final editor in _editors) editor.controller,
                  ]),
                  builder: (_, __) => Text(
                    '${_formatScore(_totalScore)} / ${_formatScore(_maximumScore)}',
                    key: const ValueKey('levelup_detail_total_score'),
                    style: const TextStyle(
                      color: Color(0xFF15803D),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              key: const ValueKey('levelup_complete_grading'),
              onPressed:
                  _isSubmitting || _editors.isEmpty ? null : _completeGrading,
              icon: const Icon(Icons.task_alt_rounded),
              label: const Text('Hoàn thành chấm bài'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionScoreEditor {
  final LevelUpPracticalQuestion question;
  final TextEditingController controller;

  _QuestionScoreEditor(this.question)
      : controller = TextEditingController(
          text: question.score == null ? '' : _formatScore(question.score!),
        );
}

class _QuestionCard extends StatelessWidget {
  final Key cardKey;
  final int index;
  final _QuestionScoreEditor editor;
  final String? token;
  final bool expanded;
  final VoidCallback onToggle;

  const _QuestionCard({
    required this.cardKey,
    required this.index,
    required this.editor,
    required this.token,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final question = editor.question;
    return Container(
      key: cardKey,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expanded
              ? const Color(0xFF22A447).withOpacity(0.55)
              : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('levelup_question_toggle_${question.id}'),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: expanded
                            ? const Color(0xFF166534)
                            : const Color(0xFFEAF8EC),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color:
                              expanded ? Colors.white : const Color(0xFF15803D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: editor.controller,
                        builder: (_, value, __) {
                          final raw = value.text.trim().replaceAll(',', '.');
                          final score = double.tryParse(raw);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Câu ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                score == null
                                    ? 'Chưa nhập điểm • Tối đa ${_formatScore(question.scoreLimit)}'
                                    : '${_formatScore(score)} / ${_formatScore(question.scoreLimit)} điểm',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: score == null
                                      ? (isDark
                                          ? Colors.white54
                                          : const Color(0xFF6B7280))
                                      : const Color(0xFF15803D),
                                  fontWeight: score == null
                                      ? FontWeight.w400
                                      : FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            reverseDuration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    key: ValueKey('levelup_question_body_${question.id}'),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                          height: 1,
                          color:
                              isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                        ),
                        const SizedBox(height: 12),
                        const _QuestionSectionLabel(
                          icon: Icons.help_outline_rounded,
                          text: 'Nội dung câu hỏi',
                        ),
                        const SizedBox(height: 4),
                        _ExamHtml(
                          html: question.questionContentHtml,
                          token: token,
                          emptyText: 'Không có nội dung câu hỏi.',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2115)
                                : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withOpacity(0.28),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _QuestionSectionLabel(
                                icon: Icons.lightbulb_outline_rounded,
                                text: 'Đáp án gợi ý',
                                emphasized: true,
                              ),
                              const SizedBox(height: 3),
                              _ExamHtml(
                                html: question.questionAnswerHtml,
                                token: token,
                                emptyText: 'Chưa có đáp án gợi ý.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF17251B)
                                : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF22A447).withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Điểm chấm',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Bỏ trống sẽ tính 0 điểm',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 118,
                                height: 42,
                                child: TextField(
                                  key: ValueKey(
                                    'levelup_remote_score_${question.id}',
                                  ),
                                  controller: editor.controller,
                                  textAlign: TextAlign.center,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: const [
                                    _ScoreInputFormatter()
                                  ],
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: '0',
                                    suffixText:
                                        '/ ${_formatScore(question.scoreLimit)}',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 10,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF292929)
                                        : Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _QuestionSectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool emphasized;

  const _QuestionSectionLabel({
    required this.icon,
    required this.text,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = emphasized
        ? (context.isDarkMode
            ? const Color(0xFFFBBF24)
            : const Color(0xFFB45309))
        : const Color(0xFF15803D);
    return Row(
      children: [
        Icon(icon, size: emphasized ? 20 : 15, color: color),
        SizedBox(width: emphasized ? 7 : 5),
        Text(
          text,
          style: TextStyle(
            fontSize: emphasized ? 15 : 12,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _HtmlSection extends StatelessWidget {
  final String title;
  final String html;
  final String? token;

  const _HtmlSection({
    required this.title,
    required this.html,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          _ExamHtml(html: html, token: token, emptyText: ''),
        ],
      ),
    );
  }
}

class _ExamHtml extends StatelessWidget {
  final String html;
  final String? token;
  final String emptyText;

  const _ExamHtml({
    required this.html,
    required this.token,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (html.trim().isEmpty) {
      return Text(emptyText, style: const TextStyle(fontSize: 12));
    }
    final textColor =
        context.isDarkMode ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    return ClipRect(
      child: Html(
        data: html,
        shrinkWrap: true,
        style: {
          'body': Style(
            color: textColor,
            fontSize: FontSize(14),
            lineHeight: LineHeight.number(1.45),
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
          'p': Style(
            margin: Margins.only(bottom: 8),
          ),
        },
        extensions: [
          ImageExtension(
            handleAssetImages: false,
            networkSchemas: const {'http', 'https', ''},
            builder: (extensionContext) => _SafeHtmlImage(
              rawSource: extensionContext.attributes['src'] ?? '',
              token: token,
            ),
          ),
        ],
      ),
    );
  }
}

class _HtmlImageViewer extends StatelessWidget {
  final String source;
  final String? token;

  const _HtmlImageViewer({required this.source, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Xem hình ảnh'),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 6,
                boundaryMargin: const EdgeInsets.all(60),
                child: SizedBox.expand(
                  child: _SafeHtmlImage(
                    rawSource: source,
                    token: token,
                    fullscreen: true,
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: IgnorePointer(
                child: Text(
                  'Chụm hai ngón tay để phóng to hoặc thu nhỏ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafeHtmlImage extends StatefulWidget {
  final String rawSource;
  final String? token;
  final bool fullscreen;

  const _SafeHtmlImage({
    required this.rawSource,
    required this.token,
    this.fullscreen = false,
  });

  @override
  State<_SafeHtmlImage> createState() => _SafeHtmlImageState();
}

class _SafeHtmlImageState extends State<_SafeHtmlImage> {
  static const int _maximumDataUriLength = 24 * 1024 * 1024;

  String? _source;
  Future<Uint8List?>? _dataBytes;

  @override
  void initState() {
    super.initState();
    _prepareSource();
  }

  @override
  void didUpdateWidget(covariant _SafeHtmlImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawSource != widget.rawSource) _prepareSource();
  }

  void _prepareSource() {
    _source = _resolveHtmlImageSource(widget.rawSource);
    final source = _source;
    _dataBytes = source != null && _isDataImage(source)
        ? source.length <= _maximumDataUriLength
            ? compute(_decodeDataImage, source)
            : Future<Uint8List?>.value(null)
        : null;
  }

  Future<void> _openViewer(String source) async {
    final position = Scrollable.maybeOf(context)?.position;
    final savedOffset = position?.pixels;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _HtmlImageViewer(
          source: source,
          token: widget.token,
        ),
      ),
    );
    if (!mounted || position == null || savedOffset == null) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !position.hasContentDimensions) return;
    final restoredOffset = savedOffset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((position.pixels - restoredOffset).abs() > 0.5) {
      position.jumpTo(restoredOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    if (source == null) return const _HtmlImageError();

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final fallbackWidth = math.max(120.0, mediaSize.width - 64);
        final availableWidth = constraints.hasBoundedWidth &&
                constraints.maxWidth.isFinite &&
                constraints.maxWidth > 0
            ? constraints.maxWidth
            : fallbackWidth;
        final maxWidth = widget.fullscreen
            ? availableWidth
            : math.min(availableWidth, fallbackWidth);
        final availableHeight = constraints.hasBoundedHeight &&
                constraints.maxHeight.isFinite &&
                constraints.maxHeight > 0
            ? constraints.maxHeight
            : mediaSize.height;
        final maxHeight = widget.fullscreen
            ? availableHeight
            : math.min(480.0, maxWidth * 1.25);
        final pixelRatio = MediaQuery.devicePixelRatioOf(context);
        final cacheWidth =
            (maxWidth * pixelRatio * (widget.fullscreen ? 2.0 : 1.0))
                .round()
                .clamp(1, 3072);
        final cacheHeight =
            (maxHeight * pixelRatio * (widget.fullscreen ? 2.0 : 1.0))
                .round()
                .clamp(1, 3072);

        final image = _buildImage(
          source: source,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
        );
        if (widget.fullscreen) {
          return Center(child: image);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Semantics(
            button: true,
            label: 'Mở ảnh để phóng to',
            child: Material(
              color: context.isDarkMode
                  ? const Color(0xFF111827)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('levelup_html_image_${identityHashCode(this)}'),
                onTap: () => _openViewer(source),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    image,
                    Container(
                      margin: const EdgeInsets.all(7),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.62),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImage({
    required String source,
    required double maxWidth,
    required double maxHeight,
    required int cacheWidth,
    required int cacheHeight,
  }) {
    if (_isDataImage(source)) {
      return FutureBuilder<Uint8List?>(
        future: _dataBytes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _HtmlImageLoading(
              width: maxWidth,
              fullscreen: widget.fullscreen,
            );
          }
          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) {
            return const _HtmlImageError();
          }
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              cacheWidth: cacheWidth,
              cacheHeight: cacheHeight,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => const _HtmlImageError(),
            ),
          );
        },
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: Image.network(
        source,
        fit: BoxFit.contain,
        headers: _trustedImageHeaders(source, widget.token),
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : _HtmlImageLoading(
                width: maxWidth,
                fullscreen: widget.fullscreen,
              ),
        errorBuilder: (_, __, ___) => const _HtmlImageError(),
      ),
    );
  }
}

class _HtmlImageLoading extends StatelessWidget {
  final double width;
  final bool fullscreen;

  const _HtmlImageLoading({required this.width, required this.fullscreen});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: fullscreen ? 180 : 130,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, color: Colors.grey, size: 30),
            SizedBox(height: 5),
            Text('Đang tải ảnh...', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _HtmlImageError extends StatelessWidget {
  const _HtmlImageError();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 110,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.grey, size: 34),
            SizedBox(height: 5),
            Text('Không tải được ảnh', style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _HeaderTag extends StatelessWidget {
  final String text;

  const _HeaderTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}

class _EmptyQuestions extends StatelessWidget {
  const _EmptyQuestions();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.quiz_outlined, size: 46, color: Colors.grey),
          SizedBox(height: 10),
          Text('Bài thi chưa có câu hỏi để chấm điểm.'),
        ],
      ),
    );
  }
}

class _ScoreInputFormatter extends TextInputFormatter {
  const _ScoreInputFormatter();

  static final RegExp _pattern = RegExp(r'^\d*(?:[.,]\d*)?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}

String? _resolveHtmlImageSource(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (_isDataImage(trimmed)) return trimmed;

  final baseUri = Uri.tryParse(AppConfig.baseUrl);
  if (baseUri == null) return null;
  if (trimmed.startsWith('//')) {
    return '${baseUri.scheme}:$trimmed';
  }

  final parsed = Uri.tryParse(trimmed.replaceAll('\\', '/'));
  if (parsed == null) return null;
  if (parsed.hasScheme) {
    if (parsed.scheme != 'http' && parsed.scheme != 'https') return null;
    return parsed.toString();
  }
  return baseUri.resolveUri(parsed).toString();
}

bool _isDataImage(String value) =>
    value.toLowerCase().startsWith('data:image/');

Uint8List? _decodeDataImage(String source) {
  try {
    final comma = source.indexOf(',');
    if (comma <= 0) return null;
    final metadata = source.substring(0, comma).toLowerCase();
    if (!metadata.contains(';base64')) return null;
    final payload = source.substring(comma + 1).replaceAll(RegExp(r'\s'), '');
    return base64Decode(payload);
  } on FormatException {
    return null;
  }
}

Map<String, String>? _trustedImageHeaders(String imageUrl, String? token) {
  if (token == null || token.isEmpty) return null;
  final imageUri = Uri.tryParse(imageUrl);
  final baseUri = Uri.tryParse(AppConfig.baseUrl);
  if (imageUri == null || baseUri == null) return null;
  final trusted = imageUri.scheme == 'https' &&
      baseUri.scheme == 'https' &&
      imageUri.host.toLowerCase() == baseUri.host.toLowerCase();
  return trusted ? {'Authorization': 'Bearer $token'} : null;
}

String _formatScore(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
