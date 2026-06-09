import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/domain/entities/timesheet/timesheet_entity.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_bloc.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_event.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_state.dart';
import 'package:flutter_core_project/presentation/pages/timesheet/adjustment_report_page.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class TimesheetPageController {
  _TimesheetPageState? _state;

  void hideTooltip() => _state?._removeTooltip();

  void _attach(_TimesheetPageState state) {
    _state = state;
  }

  void _detach(_TimesheetPageState state) {
    if (_state == state) _state = null;
  }
}

class TimesheetPage extends StatefulWidget {
  final bool showBackButton;
  final TimesheetPageController? controller;

  const TimesheetPage({
    super.key,
    this.showBackButton = false,
    this.controller,
  });

  @override
  State<TimesheetPage> createState() => _TimesheetPageState();
}

class _TimesheetPageState extends State<TimesheetPage> {
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _currentDate = DateTime.now();
    _restoreAndLoad();
  }

  @override
  void didUpdateWidget(covariant TimesheetPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _removeTooltip();
    super.dispose();
  }

  Future<void> _restoreAndLoad() async {
    final bloc = context.read<RemoteTimesheetBloc>();

    // Nếu Bloc đang có data (navigate đi rồi quay lại) → giữ nguyên _currentDate
    // theo state hiện tại, không làm gì thêm.
    // Nếu Bloc chưa có data (app restart) → reset UI về tháng hiện tại.
    if (bloc.state is! TimesheetLoaded) {
      // App restart: luôn hiển thị tháng hiện tại
      if (mounted) {
        setState(() => _currentDate = DateTime.now());
      }
    }

    if (!mounted) return;
    bloc.add(const RestoreTimesheetFromCache());
  }

  void _loadTimesheet() {
    context.read<RemoteTimesheetBloc>().add(
          GetTimesheet(year: _currentDate.year, month: _currentDate.month),
        );
  }

  void _changeMonth(int delta) {
    final next = DateTime(_currentDate.year, _currentDate.month + delta);
    setState(() => _currentDate = next);
    context.read<RemoteTimesheetBloc>().add(
          ChangeMonth(year: _currentDate.year, month: _currentDate.month),
        );
  }

  // ── Shimmer skeleton khi đang loading ────────────────────────────────────
  Widget _buildShimmerSkeleton(bool isDark) {
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlight = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;


    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlight,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Summary cards row
            Row(children: [
              Expanded(child: _skCard(cardColor, h: 64)),
              const SizedBox(width: 8),
              Expanded(child: _skCard(cardColor, h: 64)),
              const SizedBox(width: 8),
              Expanded(child: _skCard(cardColor, h: 64)),
            ]),
            const SizedBox(height: 12),
            // Month selector
            _skCard(cardColor, h: 40),
            const SizedBox(height: 12),
            // Calendar grid placeholder
            _skCard(cardColor, h: 260, r: 12),
            const SizedBox(height: 12),
            // Action button
            _skCard(cardColor, h: 48, r: 10),
          ],
        ),
      ),
    );
  }

  Widget _skCard(Color color, {double h = 80, double r = 10}) => Container(
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.showBackButton) _buildBackHeader(isDark),
            Expanded(
              child: BlocConsumer<RemoteTimesheetBloc, TimesheetState>(
                // Sync _currentDate khi Bloc load xong (trường hợp restore từ cache)
                listener: (context, state) {
                  if (state is TimesheetLoaded && state.timesheet != null) {
                    final ts = state.timesheet!;
                    if (ts.year > 0 && ts.month > 0) {
                      final loaded = DateTime(ts.year, ts.month);
                      if (loaded != DateTime(_currentDate.year, _currentDate.month)) {
                        setState(() => _currentDate = loaded);
                      }
                    }
                  }
                },
                builder: (context, state) {
                  // ── Lần đầu chưa có data → shimmer toàn màn hình ──────────────
                  if (state is TimesheetLoading) {
                    return _buildShimmerSkeleton(isDark);
                  }

                  // ── Đang refresh nhưng vẫn có data cũ → giữ UI + overlay ──────
                  if (state is TimesheetRefreshing) {
                    return Stack(
                      children: [
                        // Nội dung cũ vẫn hiển thị
                        _buildTimesheetContent(
                          TimesheetLoaded(
                            timesheet: state.timesheet!,
                            selectedDate: state.selectedDate,
                          ),
                        ),
                        // Overlay trong suốt khoá tương tác (trừ bottom nav bên ngoài)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: false,
                            child: Container(
                              color: Colors.black.withOpacity(0.18),
                            ),
                          ),
                        ),
                        // Popup loading nhỏ gọn ở giữa
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 22),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 24,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Color(0xFF42C83C),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Đang tải bảng công...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (state is TimesheetError) {
                    final err = state.error;
                    final errMsg = err?.message?.isNotEmpty == true
                        ? err!.message!
                        : err?.error?.toString() ?? 'Unknown error';
                    final statusCode = err?.response?.statusCode;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text(
                              'Không tải được bảng công',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              statusCode != null ? 'HTTP $statusCode – $errMsg' : errMsg,
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadTimesheet,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (state is TimesheetLoaded) {
                    return _buildTimesheetContent(state);
                  }
                  return _buildShimmerSkeleton(isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackHeader(bool isDark) {
    final bgColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final iconColor = isDark ? Colors.white : const Color(0xFF111827);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
      child: Row(
        children: [
          Material(
            color: bgColor,
            shape: const CircleBorder(),
            elevation: isDark ? 0 : 1,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: iconColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            context.tr('nav_timesheet'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Nội dung chính của màn hình timesheet — dùng cho cả Loaded và Refreshing
  Widget _buildTimesheetContent(TimesheetLoaded state) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _removeTooltip(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildSummaryCards(state),
            const SizedBox(height: 8),
            _buildMonthSelector(),
            _buildCalendar(state),
            if (state.selectedDate != null) _buildDayDetails(state),
            _buildActionButtons(selectedDate: state.selectedDate),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final year = _currentDate.year;
    final month = _currentDate.month;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isFuture = DateTime(year, month)
        .isAfter(DateTime(DateTime.now().year, DateTime.now().month));

    final bgColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
    final iconColor = isDarkMode ? Colors.grey[400]! : const Color(0xFF42C83C);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          // ← prev month button
          _monthNavBtn(
            icon: Icons.chevron_left,
            color: iconColor,
            bg: bgColor,
            onTap: () => _changeMonth(-1),
          ),
          const SizedBox(width: 8),
          // Center pill — clickable, clearly styled
          Expanded(
            child: GestureDetector(
              onTap: _showMonthYearPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        size: 15, color: const Color(0xFF42C83C)),
                    const SizedBox(width: 6),
                    Text(
                      'Tháng $month / $year',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isFuture ? Colors.grey : textColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.expand_more_rounded,
                        size: 16, color: const Color(0xFF42C83C)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // → next month button
          _monthNavBtn(
            icon: Icons.chevron_right,
            color: iconColor,
            bg: bgColor,
            onTap: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _monthNavBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }

  // Show month/year picker dialog
  void _showMonthYearPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn Tháng và Năm'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Year Picker
              const Text(
                'Năm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: ListWheelScrollView(
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    // Year selection handled in OK button
                  },
                  children: List.generate(
                    20,
                    (index) {
                      final year = _currentDate.year - 10 + index;
                      return Center(
                        child: Text(
                          year.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: _currentDate.year == year
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _currentDate.year == year
                                ? const Color(0xFF42C83C)
                                : Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Month Picker
              const Text(
                'Tháng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  12,
                  (index) {
                    final month = index + 1;
                    final isSelected = _currentDate.month == month;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentDate = DateTime(
                            _currentDate.year,
                            month,
                          );
                        });
                        context.read<RemoteTimesheetBloc>().add(
                              ChangeMonth(
                                year: _currentDate.year,
                                month: _currentDate.month,
                              ),
                            );
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF42C83C)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF42C83C)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            month.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Đóng')),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(TimesheetLoaded state) {
    final workingDays = state.timesheet?.timeSheetData.fold(
          0.0,
          (sum, day) => sum + day.wd,
        ) ??
        0.0;
    final leaveDays = state.timesheet?.timeSheetData
            .where((day) => (day.p ?? 0) > 0)
            .length ?? 0;
    final overtimeHours = state.timesheet?.timeSheetData
            .fold(0.0, (sum, day) => sum + (day.numHourExtra ?? 0.0)) ?? 0.0;
    final overtimeStr = overtimeHours == 0
        ? '0h'
        : '${overtimeHours.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}h';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Ngày công',
              workingDays.toStringAsFixed(2),
              const Color(0xFF42C83C),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Ngày có sd phép',
              leaveDays.toString(),
              const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Tăng ca',
              overtimeStr,
              const Color(0xFFFF9800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 2,
            width: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(TimesheetLoaded state) {
    final timesheet = state.timesheet!;
    final daysInMonth = timesheet.sumDayOfMonth;
    final firstDayOfMonth = DateTime(timesheet.year, timesheet.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildWeekdayHeaders(),
          const SizedBox(height: 4),
          _buildCalendarGrid(
            state,
            daysInMonth,
            firstWeekday,
            timesheet,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: day == 'CN'
                    ? Colors.red
                    : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(
    TimesheetLoaded state,
    int daysInMonth,
    int firstWeekday,
    timesheet,
  ) {
    final List<Widget> dayWidgets = [];

    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(timesheet.year, timesheet.month, day);
      TimeSheetDataEntity? dayData;
      try {
        // Match by year + month + day to avoid cross-month mismatch
        dayData = timesheet.timeSheetData.firstWhere(
          (d) =>
              d.dateWorking.year == timesheet.year &&
              d.dateWorking.month == timesheet.month &&
              d.dateWorking.day == day,
        );
      } catch (e) {
        dayData = null;
      }

      dayWidgets.add(_buildDayCell(date, dayData, state.selectedDate));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1,
      children: dayWidgets,
    );
  }


  // ─── Helper: safe CheckingPoint ──────────────────────────────────────────
  // Tránh .reduce() gây lỗi type mismatch (CheckingPointEntity vs CheckingPointModel)
  CheckingPointEntity? _bestCheckingPoint(TimeSheetDataEntity d) {
    if (d.checkingPoints.isEmpty) return null;
    // Ưu tiên: CP có TIME_IN thực (không phải midnight)
    // Nếu nhiều CP có TIME_IN thực → lấy cái có WD cao nhất
    CheckingPointEntity? best;
    for (final cp in d.checkingPoints) {
      if (best == null) {
        best = cp;
      } else if (_isRealTime(cp.timeIn) && !_isRealTime(best.timeIn)) {
        // cp có giờ thực, best chưa có → chọn cp
        best = cp;
      } else if (_isRealTime(cp.timeIn) && cp.wd >= best.wd) {
        best = cp;
      }
    }
    return best;
  }

  bool _isRealTime(DateTime? t) =>
      t != null && !(t.hour == 0 && t.minute == 0 && t.second == 0);

  String _fmt(DateTime? t) =>
      (t != null) ? DateFormat('HH:mm').format(t) : '--:--';

  // ─── Overlay tooltip state ────────────────────────────────────────────────
  OverlayEntry? _tooltipOverlay;

  void _removeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  // ─── Show floating tooltip anchored to the tapped cell ───────────────────
  void _showCellTooltip(
    BuildContext cellContext,
    DateTime date,
    TimeSheetDataEntity d,
  ) {
    _removeTooltip();

    // ── Suppress tooltip for HT / NL days and truly empty days ──────
    final bool isHT = d.hT != null && d.hT! > 0;
    final bool isNL = d.nL != null && d.nL! > 0 && d.wd == 0;
    if (isHT || isNL) return;

    final cp      = _bestCheckingPoint(d);
    final hasIn   = _isRealTime(cp?.timeIn);
    final hasOut  = cp?.timeOut != null;

    // Build chips first so we can decide whether to show tooltip
    final List<_TipChip> chips = [];
    void addChip(double? v, String label, Color color) {
      if (v == null || v <= 0) return;
      final s = v == 1.0
          ? label
          : '${v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}$label';
      chips.add(_TipChip(text: s, color: color));
    }
    if (d.wd > 0) {
      final h = d.wd * 8.0;
      final s = h.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      chips.add(_TipChip(text: '${s}h', color: const Color(0xFF42C83C)));
    }
    addChip(d.p,   'P',    const Color(0xFF2196F3));
    addChip(d.bL,  'BL',   const Color(0xFF1976D2));
    addChip(d.b,   'B',    Colors.purple);
    addChip(d.ro,  'Ro',   Colors.grey);
    addChip(d.o,   'K',    Colors.orange);
    addChip(d.pr,  'Pr',   Colors.teal);
    addChip(d.n,   'N',    const Color(0xFF795548));
    addChip(d.tN,  'TN',   Colors.red[700]!);
    addChip(d.ca3, 'Ca3',  Colors.indigo);
    addChip(d.tS,  'TS',   Colors.pink);
    addChip(d.ngG,  'NgG',  const Color(0xFFFF9800));
    addChip(d.ngG2, 'NgG2', const Color(0xFFFF5722));

    // Suppress if no check-in/out AND no meaningful chips
    if (!hasIn && !hasOut && chips.isEmpty) return;

    final RenderBox? box = cellContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlay    = Overlay.of(cellContext);
    final screenSize = MediaQuery.of(cellContext).size;
    final isDark     = Theme.of(cellContext).brightness == Brightness.dark;

    // Cell position
    final cellOffset  = box.localToGlobal(Offset.zero);
    final cellSize    = box.size;
    final cellCenterX = cellOffset.dx + cellSize.width / 2;

    final timeIn  = hasIn   ? _fmt(cp!.timeIn)  : '--:--';
    final timeOut = hasOut  ? _fmt(cp!.timeOut) : '--:--';

    // ── Colours ──────────────────────────────────────────────────────
    final bgColor     = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final borderColor = const Color(0xFF42C83C).withOpacity(isDark ? 0.45 : 0.55);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);

    // ── Sizing ─────────────────────────────────────────────────────
    const double caretH    = 7.0;
    // Max width caps the bubble so it never goes edge-to-edge
    final double maxWidth  = (screenSize.width * 0.3).clamp(150.0, 220.0);

    // Position: above cell if enough space (> 140 from top), else below
    final showAbove = cellOffset.dy > 140;

    // Centre over cell; clamp so it never overflows screen edges
    // We use maxWidth as the anchor width for clamping, actual bubble may be smaller
    double tipLeft = cellCenterX - maxWidth / 2;
    tipLeft = tipLeft.clamp(8.0, screenSize.width - maxWidth - 8);

    final double tipTop = cellOffset.dy + cellSize.height + caretH;

    // Caret X relative to tipLeft
    final double arrowOffsetX =
        (cellCenterX - tipLeft).clamp(14.0, maxWidth - 14.0);

    // ── Build chip widgets ──────────────────────────────────────────
    List<Widget> chipWidgets(bool dark) => chips
        .map((c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: c.color.withOpacity(dark ? 0.22 : 0.10),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: c.color.withOpacity(0.45), width: 0.8),
              ),
              child: Text(
                c.text,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: dark ? c.color.withOpacity(0.92) : c.color,
                ),
              ),
            ))
        .toList();

    _tooltipOverlay = OverlayEntry(
      builder: (_) => Positioned(
        left: tipLeft,
        // NO width: — let the Row inside shrink to content
        top:    showAbove ? null : tipTop,
        bottom: showAbove
            ? screenSize.height - cellOffset.dy + caretH
            : null,
        child: IgnorePointer(
          ignoring: true,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              // Hard cap so it never goes full-screen
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // stretch = caret spans same width as card
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Caret DOWN (bubble above cell) ─────────
                  if (showAbove)
                    _buildCaret(
                      arrowOffsetX: arrowOffsetX,
                      caretH: caretH,
                      color: bgColor,
                      borderColor: borderColor,
                      pointUp: false,
                    ),
                  // ── Card — intrinsic width from Row child ──
                  IntrinsicWidth(
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(isDark ? 0.45 : 0.13),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Check-in / out ─────────────────
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 13, color: Color(0xFF42C83C)),
                              const SizedBox(width: 5),
                              Text(
                                '$timeIn  →  $timeOut',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: (!hasIn && !hasOut)
                                      ? Colors.grey
                                      : textPrimary,
                                ),
                              ),
                            ],
                          ),
                          // ── Chips ──────────────────────────
                          if (chips.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: chipWidgets(isDark),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // ── Caret UP (bubble below cell) ────────────
                  if (!showAbove)
                    _buildCaret(
                      arrowOffsetX: arrowOffsetX,
                      caretH: caretH,
                      color: bgColor,
                      borderColor: borderColor,
                      pointUp: true,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_tooltipOverlay!);
  }
  /// Builds the triangle caret pointing toward the tapped cell.
  Widget _buildCaret({
    required double arrowOffsetX,
    required double caretH,
    required Color color,
    required Color borderColor,
    required bool pointUp,
  }) {
    return SizedBox(
      height: caretH,
      // Width stretches to match Column's crossAxisAlignment.stretch
      child: LayoutBuilder(
        builder: (_, box) => CustomPaint(
          size: Size(box.maxWidth, caretH),
          painter: _CaretPainter(
            offsetX: arrowOffsetX.clamp(10.0, box.maxWidth - 10.0),
            color: color,
            borderColor: borderColor,
            pointUp: pointUp,
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime date, TimeSheetDataEntity? dayData, DateTime? selectedDate) {
    return _DayCell(
      date: date,
      dayData: dayData,
      selectedDate: selectedDate,
      onTap: (ctx, d) {
        _removeTooltip();
        context.read<RemoteTimesheetBloc>().add(SelectDay(selectedDate: date));
        if (d != null) {
          // ctx is the cell's own BuildContext — RenderBox is always valid here
          _showCellTooltip(ctx, date, d);
        }
      },
    );
  }

  Widget _buildDayDetails(TimesheetLoaded state) {
    final selectedDate = state.selectedDate!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Safe find
    TimeSheetDataEntity? dayData;
    try {
      dayData = state.timesheet?.timeSheetData.firstWhere(
        (d) =>
            d.dateWorking.year  == selectedDate.year  &&
            d.dateWorking.month == selectedDate.month &&
            d.dateWorking.day   == selectedDate.day,
      );
    } catch (_) {
      dayData = null;
    }

    if (dayData == null) return const SizedBox();

    // Safe CheckingPoint — pick best, skip midnight placeholders
    final cp = _bestCheckingPoint(dayData);
    final hasCP = cp != null;
    final checkInTime  = hasCP && _isRealTime(cp.timeIn)   ? _fmt(cp.timeIn)  : '--:--';
    final checkOutTime = hasCP && cp.timeOut != null        ? _fmt(cp.timeOut) : '--:--';

    // Status badge
    String statusLabel; Color statusColor;
    if (dayData.wd >= 1.0) {
      statusLabel = context.tr('timesheet_status_full');   statusColor = const Color(0xFF42C83C);
    } else if (dayData.wd > 0) {
      statusLabel = context.tr('timesheet_status_half');  statusColor = const Color(0xFFFF9800);
    } else {
      statusLabel = context.tr('timesheet_status_off');      statusColor = Colors.grey;
    }

    // Helper: format value (skip 0.0)
    String fmtVal(double? v) {
      if (v == null) return '0';
      return v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }

    final cardBg   = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final labelClr = isDarkMode ? Colors.grey[400]!       : Colors.grey[600]!;
    final valClr   = isDarkMode ? Colors.white            : Colors.black;


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF42C83C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.calendar_today, color: Color(0xFF42C83C), size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Chi tiết: ${DateFormat('dd-MM-yyyy').format(selectedDate)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valClr),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── giờ vào / ra ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF333333) : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: hasCP
                ? Row(
                    children: [
                      const Icon(Icons.login, size: 14, color: Color(0xFF42C83C)),
                      const SizedBox(width: 6),
                      Text('${context.tr('timesheet_check_in')}: ', style: TextStyle(fontSize: 11, color: labelClr)),
                      Text(checkInTime,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                              color: checkInTime == '--:--' ? Colors.orange : valClr)),
                      const Spacer(),
                      const Icon(Icons.logout, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Text('${context.tr('timesheet_check_out')}: ', style: TextStyle(fontSize: 11, color: labelClr)),
                      Text(checkOutTime,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                              color: checkOutTime == '--:--' ? Colors.orange : valClr)),
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text(context.tr('timesheet_no_fingerprint'),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500],
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          // ── CheckingPoint list (nếu nhiều hơn 1) ──────────────────────
          if (dayData.checkingPoints.length > 1) ...[
            Text('${context.tr('timesheet_all_scans')} (${dayData.checkingPoints.length}):',
                style: TextStyle(fontSize: 10, color: labelClr, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...dayData.checkingPoints.map((cp2) {
              final tin  = _isRealTime(cp2.timeIn)  ? _fmt(cp2.timeIn)  : '--:--';
              final tout = cp2.timeOut != null        ? _fmt(cp2.timeOut) : '--:--';
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    const Icon(Icons.radio_button_checked, size: 8, color: Color(0xFF42C83C)),
                    const SizedBox(width: 4),
                    Text('$tin → $tout',
                        style: TextStyle(fontSize: 11, color: valClr)),
                    const SizedBox(width: 8),
                    Text('WD:${fmtVal(cp2.wd)}',
                        style: TextStyle(fontSize: 10, color: labelClr)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
          ],
          const Divider(height: 14, thickness: 0.5),
          // ── Chỉ hiển thị các trường có giá trị > 0 ──────────────────────
          ..._buildVisibleDetailRows(dayData, fmtVal),
        ],
      ),
    );
  }

  /// Trả về list widget chỉ gồm những item có giá trị > 0
  List<Widget> _buildVisibleDetailRows(
      TimeSheetDataEntity dayData, String Function(double?) fmtVal) {
    // Map: label → value (chỉ lấy những cái > 0)
    final fields = <MapEntry<String, String>>[];
    void add(String label, double? v) {
      if (v != null && v > 0) fields.add(MapEntry(label, fmtVal(v)));
    }

    add('Ngày làm việc (Wd)', dayData.wd);
    add('Phép năm (P)', dayData.p);
    add('Nghỉ việc riêng có hưởng lương (Pr)', dayData.pr);
    add('Ngoài giờ (NgG)', dayData.ngG);
    add('Nghỉ lễ (NL)', dayData.nL);
    add('Tăng giờ (NgG_2)', dayData.ngG2);
    add('Tai nạn (TN)', dayData.tN);
    add('Nghỉ bù (B)', dayData.b);
    add('Nghỉ phép không lương (Ro)', dayData.ro);
    add('Nghỉ ngưng việc (N)', dayData.n);
    add('Khác / Không phép (K)', dayData.o);
    add('Ca3', dayData.ca3);
    add('Bù lễ (BL)', dayData.bL);
    add('Thai sản (TS)', dayData.tS);

    if (fields.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(context.tr('timesheet_no_data'),
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ];
    }

    // Ghép thành từng cặp để dùng row2
    final rows = <Widget>[];
    for (int i = 0; i < fields.length; i += 2) {
      if (i + 1 < fields.length) {
        rows.add(Row(children: [
          Expanded(child: _buildDetailItem(fields[i].key, fields[i].value)),
          const SizedBox(width: 10),
          Expanded(child: _buildDetailItem(fields[i + 1].key, fields[i + 1].value)),
        ]));
      } else {
        // Item lẻ cuối
        rows.add(Row(children: [
          Expanded(child: _buildDetailItem(fields[i].key, fields[i].value)),
          const SizedBox(width: 10),
          const Expanded(child: SizedBox()),
        ]));
      }
      if (i + 2 < fields.length) rows.add(const SizedBox(height: 6));
    }
    return rows;
  }

  Widget _buildDetailItem(String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF4A4A4A) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons({DateTime? selectedDate}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: _buildActionButton(
          context.tr('timesheet_adjustment_report'),
          const Color(0xFF2196F3),
          Icons.edit_document,
          () {
            _removeTooltip();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdjustmentReportPage(
                  initialDate: selectedDate ?? DateTime.now(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDarkMode ? 0.3 : 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Standalone cell widget — owns stable key so RenderBox is always valid ───
class _DayCell extends StatefulWidget {
  final DateTime date;
  final TimeSheetDataEntity? dayData;
  final DateTime? selectedDate;
  final void Function(BuildContext ctx, TimeSheetDataEntity? d) onTap;

  const _DayCell({
    required this.date,
    required this.dayData,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  // stable key lives in State — survives parent rebuilds
  final _containerKey = GlobalKey();

  // ── cell label helper (copy of _buildCellLabel) ──────────────────────────
  String _label(TimeSheetDataEntity d) {
    final parts = <String>[];
    if (d.wd > 0) {
      final h = d.wd * 8.0;
      parts.add(h.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), ''));
    }
    void addLeave(double? v, String code) {
      if (v == null || v <= 0) return;
      if (v == 1.0) {
        parts.add(code);
      } else {
        parts.add('${v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}$code');
      }
    }
    addLeave(d.p,        'P');
    addLeave(d.nL,       'NL');
    addLeave(d.bL,       'BL');
    addLeave(d.b,        'B');
    addLeave(d.ro,       'Ro');
    addLeave(d.o,        'O');
    addLeave(d.pr,       'Pr');
    addLeave(d.n,        'N');
    addLeave(d.tN,       'TN');
    addLeave(d.ca3,      'Ca3');
    addLeave(d.tS,       'TS');
    addLeave(d.sickLeave,'SK');
    if (d.ngG != null && d.ngG! > 0) {
      parts.add('(${d.ngG!.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')})');
    }
    if (d.ngG2 != null && d.ngG2! > 0) {
      parts.add('(${d.ngG2!.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')})');
    }
    if (d.hT != null && d.hT! > 0 && parts.isEmpty) parts.add('HT');
    return parts.join(',');
  }

  @override
  Widget build(BuildContext context) {
    final dayData    = widget.dayData;
    final date       = widget.date;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day   == DateTime.now().day;

    final isSelected = widget.selectedDate != null &&
        date.year  == widget.selectedDate!.year &&
        date.month == widget.selectedDate!.month &&
        date.day   == widget.selectedDate!.day;

    Color? backgroundColor;
    Color dayNumberColor  = isDarkMode ? const Color(0xFFBEBEBE) : const Color(0xFF111827);
    Color statusTextColor = Colors.black87;
    String cellLabel = '';
    bool isWorking = false;

    if (dayData != null) {
      final bool isNoData = dayData.hT == null &&
          dayData.nL == null && dayData.bL == null &&
          dayData.b  == null && dayData.p  == null &&
          dayData.pr == null && dayData.ro == null &&
          dayData.o  == null && dayData.n  == null &&
          dayData.wd == 0.0  && dayData.numHour == null;

      if (!isNoData) {
        cellLabel = _label(dayData);

        if (dayData.hT != null && dayData.hT! > 0 && dayData.wd == 0.0) {
          backgroundColor = Colors.red.withOpacity(0.08);
          statusTextColor = Colors.red;
        } else if (dayData.nL != null && dayData.nL! > 0) {
          backgroundColor = Colors.red.withOpacity(0.08);
          statusTextColor = Colors.red;
        } else if (dayData.bL != null && dayData.bL! > 0) {
          backgroundColor = Colors.blue.withOpacity(0.08);
          statusTextColor = const Color(0xFF2196F3);
        } else if (dayData.b != null && dayData.b! > 0 && dayData.wd == 0.0) {
          backgroundColor = Colors.purple.withOpacity(0.08);
          statusTextColor = Colors.purple;
        } else if (dayData.o != null && dayData.o! > 0 && dayData.wd == 0.0) {
          backgroundColor = Colors.orange.withOpacity(0.08);
          statusTextColor = Colors.orange[800]!;
        } else if (dayData.p != null && dayData.p! > 0 && dayData.wd == 0.0) {
          backgroundColor = Colors.amber.withOpacity(0.1);
          statusTextColor = Colors.orange[700]!;
        } else if (dayData.ro != null && dayData.ro! > 0 && dayData.wd == 0.0) {
          backgroundColor = Colors.grey.withOpacity(0.1);
          statusTextColor = Colors.grey[700]!;
        } else if (dayData.wd > 0) {
          final displayHours = dayData.wd * 8.0;
          backgroundColor = displayHours >= 8
              ? const Color(0xFF42C83C).withOpacity(0.1)
              : Colors.orange.withOpacity(0.1);
          statusTextColor = displayHours >= 8
              ? const Color(0xFF42C83C)
              : const Color(0xFFFF9800);
          isWorking = true;
        }
      }
    }

    if (isSelected) {
      backgroundColor = const Color(0xFF42C83C);
      dayNumberColor  = Colors.white;
      statusTextColor = Colors.white;
    }

    return GestureDetector(
      onTap: () {
        // Pass the container's own BuildContext — RenderBox is always available
        // because _containerKey lives in State and is never recreated.
        final ctx = _containerKey.currentContext;
        widget.onTap(ctx ?? context, dayData);
      },
      child: Container(
        key: _containerKey,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: isToday
              ? Border.all(color: const Color(0xFF42C83C), width: 2)
              : null,
        ),
        padding: const EdgeInsets.all(1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.normal,
                color: dayNumberColor,
              ),
            ),
            if (cellLabel.isNotEmpty) ...[
              const SizedBox(height: 1),
              Flexible(
                child: Text(
                  cellLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isWorking ? 11 : 9,
                    color: isSelected ? Colors.white : statusTextColor,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Chip model for tooltip ──────────────────────────────────────────────────
class _TipChip {
  final String text;
  final Color color;
  const _TipChip({required this.text, required this.color});
}

// ─── Triangle caret painter ──────────────────────────────────────────────────
class _CaretPainter extends CustomPainter {
  final double offsetX; // horizontal center of triangle
  final Color color;
  final Color borderColor;
  final bool pointUp; // true = triangle tip points up (below bubble), false = down (above bubble)

  const _CaretPainter({
    required this.offsetX,
    required this.color,
    required this.borderColor,
    required this.pointUp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final half = 8.0;

    final path = Path();
    if (pointUp) {
      // Triangle pointing up → arrow below bubble pointing toward cell above
      path.moveTo(offsetX, 0);
      path.lineTo(offsetX - half, h);
      path.lineTo(offsetX + half, h);
    } else {
      // Triangle pointing down → arrow above bubble pointing toward cell below
      path.moveTo(offsetX - half, 0);
      path.lineTo(offsetX + half, 0);
      path.lineTo(offsetX, h);
    }
    path.close();

    // Border (slightly larger)
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, borderPaint);

    // Fill
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    // Inset slightly for border effect
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(_CaretPainter old) =>
      old.offsetX != offsetX ||
      old.color != color ||
      old.pointUp != pointUp;
}
