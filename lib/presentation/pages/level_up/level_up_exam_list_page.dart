import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/data/data_sources/remote/level_up_api_service.dart';
import 'package:flutter_core_project/data/models/level_up/level_up_models.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/presentation/pages/level_up/level_up_exam_detail_page.dart';
import 'package:flutter_core_project/presentation/pages/level_up/level_up_filter_page.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_core_project/services/level_up_local_store.dart';
import 'package:intl/intl.dart';

enum _ExamView { all, pending, scored }

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
  final TextEditingController _searchController = TextEditingController();

  String _email = '';
  LevelUpFilter _filter = const LevelUpFilter();
  List<LevelUpPracticalExam> _exams = const [];
  _ExamView _view = _ExamView.all;
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
    _searchController.addListener(_refreshSearch);
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  void _refreshSearch() {
    if (mounted) setState(() {});
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
      final compatibleMachines = machines
          .where((machine) => machine.appliesToLevelCode(level.code))
          .toList(growable: false);
      final machine =
          _byId(compatibleMachines, saved.machineId, (item) => item.id);
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

  Future<void> _editFilter() async {
    if (_openingFilter || _email.isEmpty) return;
    _openingFilter = true;
    final selected = await Navigator.of(context).push<LevelUpFilter>(
      MaterialPageRoute(
        builder: (_) => LevelUpFilterPage(
          api: _api,
          email: _email,
          initialFilter: _filter,
        ),
      ),
    );
    _openingFilter = false;
    if (!mounted || selected == null) return;

    var persisted = true;
    try {
      await _localStore.saveFilter(_email, selected);
    } catch (_) {
      persisted = false;
    }
    if (!mounted) return;
    setState(() {
      _filter = selected;
      _view = _ExamView.all;
      _searchController.clear();
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
      final exams = await _api.getPracticalExams(filter: requestedFilter);
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

  List<LevelUpPracticalExam> get _visibleExams {
    final query = _searchController.text.trim().toLowerCase();
    return _exams.where((exam) {
      final matchesView = switch (_view) {
        _ExamView.all => true,
        _ExamView.pending => !exam.isScored,
        _ExamView.scored => exam.isScored,
      };
      if (!matchesView) return false;
      if (query.isEmpty) return true;
      return '${exam.candidateName} ${exam.candidateCode} ${exam.title} ${exam.examCode ?? ''}'
          .toLowerCase()
          .contains(query);
    }).toList(growable: false);
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
            onPressed: _email.isEmpty ? null : _editFilter,
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
                  Expanded(child: _buildBody(isDark)),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterSummary(bool isDark) {
    final items = <({IconData icon, String label})>[
      (icon: Icons.factory_outlined, label: _filter.factoryName ?? ''),
      (icon: Icons.account_tree_outlined, label: _filter.lineName ?? ''),
      (
        icon: Icons.precision_manufacturing_outlined,
        label: _filter.machineName ?? '',
      ),
      (icon: Icons.military_tech_outlined, label: _filter.levelName ?? ''),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in items) ...[
              Container(
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
                        color:
                            isDark ? Colors.white70 : const Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
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
        onChangeFilter: _email.isEmpty ? null : _editFilter,
      );
    }
    if (!_filter.canLoadExams) {
      return _NoFilterState(onChoose: _email.isEmpty ? null : _editFilter);
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
              onChangeFilter: _editFilter,
            ),
          ],
        ),
      );
    }

    final exams = _visibleExams;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm thí sinh, mã nhân viên, bài thi...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: isDark ? const Color(0xFF222222) : Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              _ViewChip(
                label: 'Tất cả',
                count: _exams.length,
                selected: _view == _ExamView.all,
                onTap: () => setState(() => _view = _ExamView.all),
              ),
              const SizedBox(width: 8),
              _ViewChip(
                label: 'Chưa chấm',
                count: _exams.where((exam) => !exam.isScored).length,
                selected: _view == _ExamView.pending,
                onTap: () => setState(() => _view = _ExamView.pending),
              ),
              const SizedBox(width: 8),
              _ViewChip(
                label: 'Đã chấm',
                count: _exams.where((exam) => exam.isScored).length,
                selected: _view == _ExamView.scored,
                onTap: () => setState(() => _view = _ExamView.scored),
              ),
            ],
          ),
        ),
        Expanded(
          child: exams.isEmpty
              ? const Center(child: Text('Không có bài thi khớp tìm kiếm'))
              : RefreshIndicator(
                  onRefresh: _loadExams,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: exams.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ExamCard(
                      exam: exams[index],
                      onTap: () => _openExam(exams[index]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _openExam(LevelUpPracticalExam exam) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LevelUpExamDetailPage(
          exam: exam,
          examinerEmail: _email,
          localStore: _localStore,
        ),
      ),
    );
  }
}

T? _byId<T>(List<T> items, int? id, int Function(T) idOf) {
  if (id == null) return null;
  for (final item in items) {
    if (idOf(item) == id) return item;
  }
  return null;
}

class _ViewChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _ViewChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label, $count bài thi',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF166534)
                  : (context.isDarkMode
                      ? const Color(0xFF242424)
                      : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF166534)
                    : (context.isDarkMode ? Colors.white12 : Colors.black12),
              ),
            ),
            child: Text(
              '$label ($count)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final LevelUpPracticalExam exam;
  final VoidCallback onTap;

  const _ExamCard({required this.exam, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final parsedDate = DateTime.tryParse(exam.examDate ?? '');
    final scoreLabel = !exam.isScored || exam.score == null
        ? null
        : '${_number(exam.score!)}${exam.maxScore == null ? '' : '/${_number(exam.maxScore!)}'}';
    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF15803D), Color(0xFF42C83C)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _initials(exam.candidateName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.candidateName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (exam.candidateCode.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            'MSNV: ${exam.candidateCode}',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF6B7280),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _StatusBadge(isScored: exam.isScored, label: exam.status),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                exam.title,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (exam.examCode?.isNotEmpty == true)
                    _Meta(icon: Icons.tag_rounded, text: exam.examCode!),
                  if (parsedDate != null)
                    _Meta(
                      icon: Icons.event_outlined,
                      text:
                          DateFormat('dd/MM/yyyy').format(parsedDate.toLocal()),
                    ),
                  if (exam.criteria.isNotEmpty)
                    _Meta(
                      icon: Icons.checklist_rounded,
                      text: '${exam.criteria.length} tiêu chí',
                    ),
                  if (exam.imageUrls.isNotEmpty)
                    _Meta(
                      icon: Icons.photo_library_outlined,
                      text: '${exam.imageUrls.length} ảnh',
                    ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  if (scoreLabel != null)
                    Text(
                      'Điểm: $scoreLabel',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFF15803D),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    Text(
                      'Mở bài thi để bắt đầu chấm',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                    size: 20,
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

class _StatusBadge extends StatelessWidget {
  final bool isScored;
  final String label;

  const _StatusBadge({required this.isScored, required this.label});

  @override
  Widget build(BuildContext context) {
    final background =
        isScored ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED);
    final foreground =
        isScored ? const Color(0xFF166534) : const Color(0xFFC2410C);
    return Container(
      constraints: const BoxConstraints(maxWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final color =
        context.isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 10, color: color),
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

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
