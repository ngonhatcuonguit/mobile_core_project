import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/data/data_sources/remote/level_up_api_service.dart';
import 'package:flutter_core_project/data/models/level_up/level_up_models.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/presentation/pages/level_up/level_up_filter_page.dart';
import 'package:flutter_core_project/presentation/pages/level_up/level_up_practical_detail_page.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_core_project/services/level_up_local_store.dart';

class LevelUpExamListPage extends StatefulWidget {
  final LevelUpApiService? api;
  final LevelUpLocalStore? localStore;

  const LevelUpExamListPage({
    super.key,
    this.api,
    this.localStore,
  });

  @override
  State<LevelUpExamListPage> createState() => _LevelUpExamListPageState();
}

class _LevelUpExamListPageState extends State<LevelUpExamListPage> {
  late final LevelUpApiService _api;
  late final LevelUpLocalStore _localStore;

  String _email = '';
  LevelUpFilter _filter = const LevelUpFilter();
  List<LevelUpPracticalExam> _exams = const [];
  LevelUpExamStatus _status = LevelUpExamStatus.registered;
  bool _isBootstrapping = true;
  bool _isLoadingExams = false;
  bool _openingFilter = false;
  String? _error;
  int _examRequest = 0;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? sl<LevelUpApiService>();
    _localStore = widget.localStore ?? LevelUpLocalStore();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() {
        _isBootstrapping = true;
        _error = null;
      });
    }
    try {
      final email = (await AuthService.getUserEmail())?.trim() ?? '';
      if (!mounted) return;
      if (email.isEmpty) {
        setState(() {
          _isBootstrapping = false;
          _error =
              'Tài khoản đăng nhập chưa có email để kiểm tra quyền chấm thi.';
        });
        return;
      }
      setState(() => _email = email);

      final saved = await _localStore.loadFilter(email);
      final validated =
          saved == null ? null : await _validateSavedFilter(email, saved);
      if (saved != null && validated == null) {
        await _localStore.deleteFilter(email);
      }
      if (!mounted) return;
      setState(() {
        _filter = validated ?? const LevelUpFilter();
        _isBootstrapping = false;
      });

      if (validated != null) {
        await _loadExams();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _editFilter();
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isBootstrapping = false;
        _error = error.toString();
      });
    }
  }

  Future<LevelUpFilter?> _validateSavedFilter(
    String email,
    LevelUpFilter saved,
  ) async {
    if (!saved.canLoadExams) return null;
    try {
      final metadata = await Future.wait<Object>([
        _api.getFactories(email: email),
        _api.getLevels(),
      ]);
      final factories = metadata[0] as List<LevelUpFactory>;
      final levels = metadata[1] as List<LevelUpLevel>;
      final factory = _byId(factories, saved.factoryId, (item) => item.id);
      final level = _byId(levels, saved.levelId, (item) => item.id);
      if (factory == null || level == null) return null;

      final lines = await _api.getLines(factoryId: factory.id);
      final line = _byId(lines, saved.lineId, (item) => item.id);
      if (line == null) return null;

      final machines = await _api.getMachines(lineId: line.id);
      final machine = _byId(machines, saved.machineId, (item) => item.id);
      if (machine == null) return null;

      return LevelUpFilter(
        factoryId: factory.id,
        factoryName: factory.name,
        levelId: level.id,
        levelCode: level.code,
        levelName: level.name,
        lineId: line.id,
        lineName: line.name,
        machineId: machine.id,
        machineName: machine.name,
        savedAt: saved.savedAt,
      );
    } on LevelUpApiException catch (error) {
      final message = error.message.toLowerCase();
      if (error.statusCode == 401) {
        rethrow;
      }
      if (const {400, 403, 404, 410, 422}.contains(error.statusCode) ||
          message.contains('phân quyền') ||
          message.contains('phan quyen') ||
          message.contains('không có quyền') ||
          message.contains('khong co quyen') ||
          message.contains('forbidden') ||
          message.contains('permission denied')) {
        return null;
      }
      // Giữ snapshot local nhưng dừng tại lỗi đầu tiên để tránh chờ thêm một
      // request bài thi khi metadata đang mất kết nối.
      rethrow;
    }
  }

  Future<void> _editFilter({LevelUpFilterStep? startStep}) async {
    if (_openingFilter || _email.isEmpty) return;
    _openingFilter = true;
    LevelUpFilter? selected;
    try {
      selected = startStep == null
          ? await Navigator.of(context).push<LevelUpFilter>(
              MaterialPageRoute(
                builder: (_) => LevelUpFilterPage(
                  api: _api,
                  email: _email,
                  initialFilter: _filter,
                ),
              ),
            )
          : await showLevelUpFilterFlow(
              context: context,
              api: _api,
              email: _email,
              initialFilter: _filter,
              startStep: startStep,
            );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      _openingFilter = false;
    }
    if (!mounted || selected == null) return;
    final appliedFilter = selected;

    var persisted = true;
    try {
      await _localStore.saveFilter(_email, appliedFilter);
    } catch (_) {
      persisted = false;
    }
    if (!mounted) return;
    setState(() {
      _filter = appliedFilter;
      _exams = const [];
      _error = null;
    });
    if (!persisted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bộ lọc đã được áp dụng nhưng chưa thể ghi nhớ trên thiết bị.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
    await _loadExams();
  }

  Future<void> _loadExams() async {
    if (!_filter.canLoadExams) return;
    final request = ++_examRequest;
    final requestedFilter = _filter;
    setState(() {
      _isLoadingExams = true;
      _error = null;
    });
    try {
      final exams = await _api.getPracticalExams(
        filter: requestedFilter,
        status: _status,
      );
      if (!mounted || request != _examRequest) return;
      setState(() {
        _exams = exams;
        _isLoadingExams = false;
      });
    } catch (error) {
      if (!mounted || request != _examRequest) return;
      setState(() {
        _isLoadingExams = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _changeStatus(LevelUpExamStatus status) async {
    if (status == _status) return;
    setState(() {
      _status = status;
      _exams = const [];
      _error = null;
    });
    await _loadExams();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final background =
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F7F6);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chấm điểm LevelUp',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Bài thi thực hành được phân quyền',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đổi bộ lọc',
            onPressed: _email.isEmpty ? null : () => _editFilter(),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: _isBootstrapping
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: Column(
                children: [
                  if (_filter.canLoadExams) _buildFilterSummary(isDark),
                  if (_filter.canLoadExams) _buildStatusTabs(isDark),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterSummary(bool isDark) {
    final items = <({IconData icon, String label, LevelUpFilterStep step})>[
      (
        icon: Icons.factory_outlined,
        label: _filter.factoryName ?? '',
        step: LevelUpFilterStep.factory,
      ),
      (
        icon: Icons.account_tree_outlined,
        label: _filter.lineName ?? '',
        step: LevelUpFilterStep.line,
      ),
      (
        icon: Icons.precision_manufacturing_outlined,
        label: _filter.machineName ?? '',
        step: LevelUpFilterStep.machine,
      ),
      (
        icon: Icons.military_tech_outlined,
        label: _filter.levelName ?? '',
        step: LevelUpFilterStep.level,
      ),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in items) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('levelup_filter_tag_${item.step.name}'),
                  onTap: _openingFilter
                      ? null
                      : () => _editFilter(startStep: item.step),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF202D22)
                          : const Color(0xFFEAF8EC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFF15803D),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFF15803D),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTabs(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          for (final status in LevelUpExamStatus.values) ...[
            Expanded(
              child: _ExamStatusTab(
                status: status,
                selected: status == _status,
                isDark: isDark,
                onTap: () => _changeStatus(status),
              ),
            ),
            if (status != LevelUpExamStatus.values.last)
              const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingExams) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Đang tải bài thi được phân quyền...'),
          ],
        ),
      );
    }
    if (_error != null) {
      return _ExamErrorState(
        message: _error!,
        onRetry: _filter.canLoadExams ? _loadExams : _bootstrap,
        onChangeFilter: _email.isEmpty ? null : () => _editFilter(),
      );
    }
    if (!_filter.canLoadExams) {
      return _NoFilterState(
        onChoose: _email.isEmpty ? null : () => _editFilter(),
      );
    }
    if (_exams.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadExams,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _EmptyExamState(
              onRefresh: _loadExams,
              onChangeFilter: () => _editFilter(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExams,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _exams.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _ExamCard(
          exam: _exams[index],
          showTotalScore: _status == LevelUpExamStatus.submitted,
          onTap: () => _openExam(_exams[index]),
        ),
      ),
    );
  }

  Future<void> _openExam(LevelUpPracticalExam exam) async {
    final practicalId = int.tryParse(exam.id);
    if (practicalId == null || practicalId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID bài thi không hợp lệ.')),
      );
      return;
    }
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LevelUpPracticalDetailPage(
          api: _api,
          practicalId: practicalId,
          summary: exam,
        ),
      ),
    );
    if (submitted == true && mounted) await _loadExams();
  }
}

T? _byId<T>(List<T> items, int? id, int Function(T) idOf) {
  if (id == null) return null;
  for (final item in items) {
    if (idOf(item) == id) return item;
  }
  return null;
}

class _ExamStatusTab extends StatelessWidget {
  final LevelUpExamStatus status;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ExamStatusTab({
    required this.status,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFF166534)
          : (isDark ? const Color(0xFF242424) : Colors.white),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        key: ValueKey('levelup_status_${status.apiValue}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? const Color(0xFF166534)
                  : (isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Text(
            status.label,
            style: TextStyle(
              color: selected ? Colors.white : null,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final LevelUpPracticalExam exam;
  final bool showTotalScore;
  final VoidCallback onTap;

  const _ExamCard({
    required this.exam,
    required this.showTotalScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final candidateId =
        exam.candidateCode.isNotEmpty ? exam.candidateCode : exam.candidateId;
    return Semantics(
      button: true,
      label: 'Bài thi ${exam.examNumber ?? ''}, ${exam.title}, '
          'thí sinh ${exam.candidateName}',
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF173D25)
                            : const Color(0xFFEAF8EC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Bài thi #${exam.examNumber ?? exam.examCode ?? '--'}',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFF166534),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  exam.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF15803D), Color(0xFF42C83C)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _initials(exam.candidateName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.candidateName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (candidateId?.isNotEmpty == true)
                            Text(
                              'Mã thí sinh: $candidateId',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF6B7280),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF252525)
                        : const Color(0xFFF8FAF9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _ExamInfoRow(
                        icon: Icons.factory_outlined,
                        label: 'Nhà máy',
                        value: exam.factoryName ?? '--',
                      ),
                      const SizedBox(height: 8),
                      _ExamInfoRow(
                        icon: Icons.account_tree_outlined,
                        label: 'Line',
                        value: exam.lineName ?? '--',
                      ),
                      const SizedBox(height: 8),
                      _ExamInfoRow(
                        icon: Icons.precision_manufacturing_outlined,
                        label: 'Máy',
                        value: exam.machineName ?? '--',
                      ),
                      const SizedBox(height: 8),
                      _ExamInfoRow(
                        icon: Icons.military_tech_outlined,
                        label: 'Cấp bậc',
                        value: exam.levelName ?? '--',
                      ),
                    ],
                  ),
                ),
                if (showTotalScore && exam.totalScorePractical != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_outlined,
                        color: Color(0xFF15803D),
                        size: 19,
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Tổng điểm',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        _formatScore(exam.totalScorePractical!),
                        key: const ValueKey('levelup_total_score'),
                        style: const TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ExamInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        context.isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280);
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 7),
        Text(
          '$label:',
          style: TextStyle(fontSize: 11, color: color),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _NoFilterState extends StatelessWidget {
  final VoidCallback? onChoose;

  const _NoFilterState({required this.onChoose});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF8EC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 42,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Chọn điều kiện chấm thi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hệ thống sẽ hiển thị đúng các bài thi thực hành mà bạn được phân quyền.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onChoose,
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: const Text('Chọn bộ lọc'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyExamState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final VoidCallback onChangeFilter;

  const _EmptyExamState({
    required this.onRefresh,
    required this.onChangeFilter,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.sizeOf(context).height * 0.52,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: Color(0xFF16A34A),
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Chưa có bài thi cần chấm',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Không có bài thi theo bộ lọc hiện tại. Kéo xuống để tải lại hoặc chọn điều kiện khác.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onChangeFilter,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Đổi bộ lọc'),
                  ),
                  FilledButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tải lại'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback? onChangeFilter;

  const _ExamErrorState({
    required this.message,
    required this.onRetry,
    required this.onChangeFilter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      color: Colors.orange, size: 54),
                  const SizedBox(height: 14),
                  const Text(
                    'Không tải được bài thi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    children: [
                      if (onChangeFilter != null)
                        OutlinedButton(
                          onPressed: onChangeFilter,
                          child: const Text('Đổi bộ lọc'),
                        ),
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'TS';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String _formatScore(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
