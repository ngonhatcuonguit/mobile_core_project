import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/data/data_sources/remote/level_up_api_service.dart';
import 'package:flutter_core_project/data/models/level_up/level_up_models.dart';

enum LevelUpFilterStep { factory, line, machine, level }

Future<LevelUpFilter?> showLevelUpFilterFlow({
  required BuildContext context,
  required LevelUpApiService api,
  required String email,
  required LevelUpFilter initialFilter,
  required LevelUpFilterStep startStep,
}) async {
  var filter = initialFilter;

  if (startStep.index <= LevelUpFilterStep.factory.index) {
    final factories = await api.getFactories(email: email);
    if (!context.mounted) return null;
    final selected = await _showLevelUpOptionPicker<LevelUpFactory>(
      context: context,
      title: 'Chọn nhà máy',
      options: factories,
      selectedId: filter.factoryId,
      idOf: (item) => item.id,
      labelOf: (item) => item.name,
      subtitleOf: (item) => item.code,
    );
    if (selected == null || !context.mounted) return null;
    if (selected.id != filter.factoryId) {
      filter = LevelUpFilter(
        factoryId: selected.id,
        factoryName: selected.name,
      );
    }
  }

  final factoryId = filter.factoryId;
  if (factoryId == null) return null;
  if (startStep.index <= LevelUpFilterStep.line.index) {
    final lines = await api.getLines(factoryId: factoryId);
    if (!context.mounted) return null;
    final selected = await _showLevelUpOptionPicker<LevelUpLine>(
      context: context,
      title: 'Chọn line',
      options: lines,
      selectedId: filter.lineId,
      idOf: (item) => item.id,
      labelOf: (item) => item.name,
      subtitleOf: (item) => item.code,
    );
    if (selected == null || !context.mounted) return null;
    if (selected.id != filter.lineId) {
      filter = filter.copyWith(
        lineId: selected.id,
        lineName: selected.name,
        clearMachine: true,
        clearLevel: true,
      );
    }
  }

  final lineId = filter.lineId;
  if (lineId == null) return null;
  if (startStep.index <= LevelUpFilterStep.machine.index) {
    final machines = await api.getMachines(lineId: lineId);
    if (!context.mounted) return null;
    final selected = await _showLevelUpOptionPicker<LevelUpMachine>(
      context: context,
      title: 'Chọn máy',
      options: machines,
      selectedId: filter.machineId,
      idOf: (item) => item.id,
      labelOf: (item) => item.name,
      subtitleOf: (item) => item.code,
    );
    if (selected == null || !context.mounted) return null;
    if (selected.id != filter.machineId) {
      filter = filter.copyWith(
        machineId: selected.id,
        machineName: selected.name,
        clearLevel: true,
      );
    }
  }

  if (filter.machineId == null) return null;
  final levels = await api.getLevels();
  if (!context.mounted) return null;
  final selected = await _showLevelUpOptionPicker<LevelUpLevel>(
    context: context,
    title: 'Chọn cấp bậc',
    options: levels,
    selectedId: filter.levelId,
    idOf: (item) => item.id,
    labelOf: (item) => item.name,
    subtitleOf: (item) => item.description ?? item.code,
  );
  if (selected == null) return null;
  filter = filter.copyWith(
    levelId: selected.id,
    levelCode: selected.code,
    levelName: selected.name,
  );
  return filter.canLoadExams ? filter : null;
}

Future<T?> _showLevelUpOptionPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required int? selectedId,
  required int Function(T) idOf,
  required String Function(T) labelOf,
  required String Function(T) subtitleOf,
}) {
  if (options.isEmpty) {
    throw LevelUpApiException('$title: không có dữ liệu để lựa chọn.');
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _OptionPickerSheet<T>(
      title: title,
      options: options,
      selectedId: selectedId,
      idOf: idOf,
      labelOf: labelOf,
      subtitleOf: subtitleOf,
    ),
  );
}

enum _FilterLoadStage { initial, lines, machines }

class LevelUpFilterPage extends StatefulWidget {
  final LevelUpApiService api;
  final String email;
  final LevelUpFilter initialFilter;

  const LevelUpFilterPage({
    super.key,
    required this.api,
    required this.email,
    required this.initialFilter,
  });

  @override
  State<LevelUpFilterPage> createState() => _LevelUpFilterPageState();
}

class _LevelUpFilterPageState extends State<LevelUpFilterPage> {
  List<LevelUpFactory> _factories = const [];
  List<LevelUpLevel> _levels = const [];
  List<LevelUpLine> _lines = const [];
  List<LevelUpMachine> _machines = const [];

  late LevelUpFilter _filter;
  bool _isLoading = true;
  bool _isLoadingLines = false;
  bool _isLoadingMachines = false;
  String? _error;
  _FilterLoadStage _failedStage = _FilterLoadStage.initial;
  int _lineRequest = 0;
  int _machineRequest = 0;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _failedStage = _FilterLoadStage.initial;
    });
    try {
      final metadata = await Future.wait<Object>([
        widget.api.getFactories(email: widget.email),
        widget.api.getLevels(),
      ]);
      final factories = metadata[0] as List<LevelUpFactory>;
      final levels = metadata[1] as List<LevelUpLevel>;
      if (!mounted) return;

      final selectedFactory = _findById(
        factories,
        _filter.factoryId,
        (item) => item.id,
      );
      final selectedLevel = _findById(
        levels,
        _filter.levelId,
        (item) => item.id,
      );

      _filter = LevelUpFilter(
        factoryId: selectedFactory?.id,
        factoryName: selectedFactory?.name,
        levelId: selectedLevel?.id,
        levelCode: selectedLevel?.code,
        levelName: selectedLevel?.name,
      );
      setState(() {
        _factories = factories;
        _levels = levels;
        _isLoading = false;
      });

      if (selectedFactory != null) {
        await _loadLines(
          selectedFactory.id,
          preferredLineId: widget.initialFilter.lineId,
          preferredMachineId: widget.initialFilter.machineId,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
        _failedStage = _FilterLoadStage.initial;
      });
    }
  }

  Future<void> _loadLines(
    int factoryId, {
    int? preferredLineId,
    int? preferredMachineId,
  }) async {
    final request = ++_lineRequest;
    _machineRequest++;
    setState(() {
      _isLoadingLines = true;
      _isLoadingMachines = false;
      _lines = const [];
      _machines = const [];
      _error = null;
    });
    try {
      final lines = await widget.api.getLines(factoryId: factoryId);
      if (!mounted ||
          request != _lineRequest ||
          _filter.factoryId != factoryId) {
        return;
      }
      final selected = _findById(lines, preferredLineId, (item) => item.id);
      setState(() {
        _lines = lines;
        _isLoadingLines = false;
        _filter = _filter.copyWith(
          lineId: selected?.id,
          lineName: selected?.name,
          clearLine: selected == null,
          clearMachine: true,
        );
      });
      if (selected != null) {
        await _loadMachines(
          selected.id,
          preferredMachineId: preferredMachineId,
        );
      }
    } catch (error) {
      if (!mounted || request != _lineRequest) return;
      setState(() {
        _isLoadingLines = false;
        _error = error.toString();
        _failedStage = _FilterLoadStage.lines;
      });
    }
  }

  Future<void> _loadMachines(
    int lineId, {
    int? preferredMachineId,
  }) async {
    final request = ++_machineRequest;
    setState(() {
      _isLoadingMachines = true;
      _machines = const [];
      _error = null;
    });
    try {
      final machines = await widget.api.getMachines(lineId: lineId);
      if (!mounted || request != _machineRequest || _filter.lineId != lineId) {
        return;
      }
      final selected = _findById(
        machines,
        preferredMachineId,
        (item) => item.id,
      );
      setState(() {
        _machines = machines;
        _isLoadingMachines = false;
        _filter = _filter.copyWith(
          machineId: selected?.id,
          machineName: selected?.name,
          clearMachine: selected == null,
        );
      });
    } catch (error) {
      if (!mounted || request != _machineRequest) return;
      setState(() {
        _isLoadingMachines = false;
        _error = error.toString();
        _failedStage = _FilterLoadStage.machines;
      });
    }
  }

  void _retryFailedLoad() {
    switch (_failedStage) {
      case _FilterLoadStage.initial:
        _initialize();
        return;
      case _FilterLoadStage.lines:
        final factoryId = _filter.factoryId;
        if (factoryId == null) {
          _initialize();
          return;
        }
        final isRestoring = factoryId == widget.initialFilter.factoryId;
        _loadLines(
          factoryId,
          preferredLineId: isRestoring ? widget.initialFilter.lineId : null,
          preferredMachineId:
              isRestoring ? widget.initialFilter.machineId : null,
        );
        return;
      case _FilterLoadStage.machines:
        final lineId = _filter.lineId;
        if (lineId == null) {
          final factoryId = _filter.factoryId;
          if (factoryId == null) {
            _initialize();
          } else {
            _loadLines(factoryId);
          }
          return;
        }
        _loadMachines(
          lineId,
          preferredMachineId: lineId == widget.initialFilter.lineId
              ? widget.initialFilter.machineId
              : null,
        );
        return;
    }
  }

  Future<void> _selectFactory() async {
    final selected = await _showOptionPicker<LevelUpFactory>(
      title: 'Chọn nhà máy',
      options: _factories,
      selectedId: _filter.factoryId,
      idOf: (item) => item.id,
      labelOf: (item) => item.name,
      subtitleOf: (item) => [
        if (item.code.isNotEmpty) item.code,
        if (item.rolePermission?.isNotEmpty == true) item.rolePermission!,
      ].join(' • '),
    );
    if (!mounted || selected == null) return;
    if (selected.id != _filter.factoryId) {
      setState(() {
        _error = null;
        _filter = LevelUpFilter(
          factoryId: selected.id,
          factoryName: selected.name,
        );
      });
      await _loadLines(selected.id);
    }
    if (mounted && _lines.isNotEmpty) await _selectLine();
  }

  Future<void> _selectLevel() async {
    final selected = await _showOptionPicker<LevelUpLevel>(
      title: 'Chọn cấp bậc',
      options: _levels,
      selectedId: _filter.levelId,
      idOf: (item) => item.id,
      labelOf: (item) => item.name,
      subtitleOf: (item) => item.description ?? item.code,
    );
    if (!mounted || selected == null) return;
    setState(() {
      _filter = _filter.copyWith(
        levelId: selected.id,
        levelCode: selected.code,
        levelName: selected.name,
      );
    });
    if (_filter.canLoadExams && Navigator.of(context).canPop()) {
      Navigator.pop(context, _filter);
    }
  }

  Future<void> _selectLine() async {
    final selected = await _showOptionPicker<LevelUpLine>(
      title: 'Chọn line',
      options: _lines,
      selectedId: _filter.lineId,
      idOf: (item) => item.id,
      labelOf: (item) => item.name,
      subtitleOf: (item) => item.code,
    );
    if (!mounted || selected == null) return;
    if (selected.id != _filter.lineId) {
      setState(() {
        _error = null;
        _filter = _filter.copyWith(
          lineId: selected.id,
          lineName: selected.name,
          clearMachine: true,
          clearLevel: true,
        );
      });
      await _loadMachines(selected.id);
    }
    if (mounted && _machines.isNotEmpty) await _selectMachine();
  }

  Future<void> _selectMachine() async {
    final selected = await _showOptionPicker<LevelUpMachine>(
      title: 'Chọn máy',
      options: _machines,
      selectedId: _filter.machineId,
      idOf: (item) => item.id,
      labelOf: (item) => item.name,
      subtitleOf: (item) => item.code,
    );
    if (!mounted || selected == null) return;
    setState(() {
      _filter = _filter.copyWith(
        machineId: selected.id,
        machineName: selected.name,
        clearLevel: selected.id != _filter.machineId,
      );
    });
    if (mounted && _levels.isNotEmpty) await _selectLevel();
  }

  Future<T?> _showOptionPicker<T>({
    required String title,
    required List<T> options,
    required int? selectedId,
    required int Function(T) idOf,
    required String Function(T) labelOf,
    required String Function(T) subtitleOf,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OptionPickerSheet<T>(
        title: title,
        options: options,
        selectedId: selectedId,
        idOf: idOf,
        labelOf: labelOf,
        subtitleOf: subtitleOf,
      ),
    );
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
        title: const Text(
          'Bộ lọc bài thi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _factories.isEmpty
              ? _InitialError(message: _error!, onRetry: _initialize)
              : SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            _buildIntro(isDark),
                            if (_factories.isEmpty) ...[
                              const SizedBox(height: 12),
                              const _SelectionNotice(
                                message:
                                    'Tài khoản chưa được phân quyền nhà máy để chấm thi.',
                              ),
                            ],
                            if (_levels.isEmpty) ...[
                              const SizedBox(height: 12),
                              const _SelectionNotice(
                                message:
                                    'Hệ thống chưa cấu hình danh sách cấp bậc.',
                              ),
                            ],
                            const SizedBox(height: 16),
                            _FilterField(
                              step: 1,
                              icon: Icons.factory_outlined,
                              label: 'Nhà máy',
                              value: _filter.factoryName,
                              placeholder: 'Chọn nhà máy được phân quyền',
                              onTap: _factories.isEmpty ? null : _selectFactory,
                            ),
                            const SizedBox(height: 12),
                            _FilterField(
                              step: 2,
                              icon: Icons.account_tree_outlined,
                              label: 'Line',
                              value: _filter.lineName,
                              placeholder: _filter.factoryId == null
                                  ? 'Chọn nhà máy trước'
                                  : 'Chọn line sản xuất',
                              isLoading: _isLoadingLines,
                              onTap: _filter.factoryId != null &&
                                      !_isLoadingLines &&
                                      _lines.isNotEmpty
                                  ? _selectLine
                                  : null,
                            ),
                            if (_filter.factoryId != null &&
                                !_isLoadingLines &&
                                _error == null &&
                                _lines.isEmpty) ...[
                              const SizedBox(height: 8),
                              const _SelectionNotice(
                                message:
                                    'Nhà máy này chưa có line được cấu hình.',
                              ),
                            ],
                            const SizedBox(height: 12),
                            _FilterField(
                              step: 3,
                              icon: Icons.precision_manufacturing_outlined,
                              label: 'Máy',
                              value: _filter.machineName,
                              placeholder: _filter.lineId == null
                                  ? 'Chọn line trước'
                                  : 'Chọn máy',
                              isLoading: _isLoadingMachines,
                              onTap: _filter.lineId != null &&
                                      !_isLoadingMachines &&
                                      _machines.isNotEmpty
                                  ? _selectMachine
                                  : null,
                            ),
                            if (_filter.lineId != null &&
                                !_isLoadingMachines &&
                                _error == null &&
                                _machines.isEmpty) ...[
                              const SizedBox(height: 8),
                              const _SelectionNotice(
                                message: 'Line này chưa có máy được cấu hình.',
                              ),
                            ],
                            const SizedBox(height: 12),
                            _FilterField(
                              step: 4,
                              icon: Icons.military_tech_outlined,
                              label: 'Cấp bậc',
                              value: _filter.levelName,
                              placeholder: _filter.machineId == null
                                  ? 'Chọn máy trước'
                                  : 'Chọn cấp bậc cần chấm',
                              onTap: _filter.machineId != null &&
                                      _levels.isNotEmpty
                                  ? _selectLevel
                                  : null,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              _InlineError(
                                message: _error!,
                                onRetry: _retryFailedLoad,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1C1C1C) : Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            key: const ValueKey('levelup_apply_filter'),
                            onPressed: _filter.canLoadExams
                                ? () => Navigator.pop(context, _filter)
                                : null,
                            icon: const Icon(Icons.search_rounded),
                            label: const Text(
                              'Xem bài thi cần chấm',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF166534),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  isDark ? Colors.white12 : Colors.black12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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

  Widget _buildIntro(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF42C83C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fact_check_outlined, color: Colors.white, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chấm điểm LevelUp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Chọn Nhà máy → Line → Máy → Cấp bậc. Mỗi bước sẽ tự mở ngay sau khi hoàn tất bước trước.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

T? _findById<T>(List<T> items, int? id, int Function(T) idOf) {
  if (id == null) return null;
  for (final item in items) {
    if (idOf(item) == id) return item;
  }
  return null;
}

class _FilterField extends StatelessWidget {
  final int step;
  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;
  final bool isLoading;

  const _FilterField({
    required this.step,
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Bước $step, $label, ${value ?? placeholder}',
      child: Material(
        key: ValueKey('levelup_filter_$step'),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: value != null
                    ? AppColors.primary.withOpacity(0.45)
                    : (isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            AppColors.primary.withOpacity(isDark ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 23),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        width: 19,
                        height: 19,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF166534),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$step',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color:
                              isDark ? Colors.white60 : const Color(0xFF6B7280),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value ?? placeholder,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: value != null
                              ? (isDark
                                  ? Colors.white
                                  : const Color(0xFF111827))
                              : (isDark
                                  ? Colors.white38
                                  : const Color(0xFF9CA3AF)),
                          fontSize: 14,
                          fontWeight:
                              value == null ? FontWeight.w400 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: enabled
                        ? (isDark ? Colors.white54 : const Color(0xFF6B7280))
                        : (isDark ? Colors.white12 : Colors.black12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionPickerSheet<T> extends StatefulWidget {
  final String title;
  final List<T> options;
  final int? selectedId;
  final int Function(T) idOf;
  final String Function(T) labelOf;
  final String Function(T) subtitleOf;

  const _OptionPickerSheet({
    required this.title,
    required this.options,
    required this.selectedId,
    required this.idOf,
    required this.labelOf,
    required this.subtitleOf,
  });

  @override
  State<_OptionPickerSheet<T>> createState() => _OptionPickerSheetState<T>();
}

class _OptionPickerSheetState<T> extends State<_OptionPickerSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final normalized = _query.trim().toLowerCase();
    final filtered = normalized.isEmpty
        ? widget.options
        : widget.options.where((item) {
            return '${widget.labelOf(item)} ${widget.subtitleOf(item)}'
                .toLowerCase()
                .contains(normalized);
          }).toList(growable: false);

    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: widget.options.length > 8,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF292929)
                      : const Color(0xFFF3F4F6),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Không tìm thấy kết quả'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color:
                            isDark ? Colors.white10 : const Color(0xFFF0F0F0),
                      ),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final selected = widget.idOf(item) == widget.selectedId;
                        final subtitle = widget.subtitleOf(item).trim();
                        return ListTile(
                          onTap: () => Navigator.pop(context, item),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF166534)
                                  : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              selected
                                  ? Icons.check_rounded
                                  : Icons.factory_outlined,
                              color:
                                  selected ? Colors.white : AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            widget.labelOf(item),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: subtitle.isEmpty
                              ? null
                              : Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InitialError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 54, color: Colors.orange),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionNotice extends StatelessWidget {
  final String message;

  const _SelectionNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF302A1E) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF6B5522) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD97706),
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF92400E),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
