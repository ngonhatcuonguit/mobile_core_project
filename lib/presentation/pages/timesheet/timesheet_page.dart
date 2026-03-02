import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/domain/entities/timesheet/timesheet_entity.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_bloc.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_event.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_state.dart';
import 'package:flutter_core_project/presentation/widgets/appbar/app_bar.dart';
import 'package:intl/intl.dart';

class TimesheetPage extends StatefulWidget {
  const TimesheetPage({super.key});

  @override
  State<TimesheetPage> createState() => _TimesheetPageState();
}

class _TimesheetPageState extends State<TimesheetPage> {
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTimesheet();
      }
    });
  }

  void _loadTimesheet() {
    context.read<RemoteTimesheetBloc>().add(
          GetTimesheet(
            year: _currentDate.year,
            month: _currentDate.month,
          ),
        );
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + delta);
    });
    context.read<RemoteTimesheetBloc>().add(
          ChangeMonth(
            year: _currentDate.year,
            month: _currentDate.month,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      appBar: const BasicAppBar(
        title: Text(
          'Bảng Công',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocBuilder<RemoteTimesheetBloc, TimesheetState>(
        builder: (context, state) {
          if (state is TimesheetLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TimesheetError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Có lỗi xảy ra: ${state.error?.message ?? "Unknown error"}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTimesheet,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          } else if (state is TimesheetLoaded) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildMonthSelector(),
                  _buildSummaryCards(state),
                  _buildCalendar(state),
                  if (state.selectedDate != null) _buildDayDetails(state),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
          return const Center(child: Text('No data'));
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    final year = _currentDate.year;
    final month = _currentDate.month;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left arrow - Previous month
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
          // Center - Month & Year with date picker
          Expanded(
            child: GestureDetector(
              onTap: _showMonthYearPicker,
              child: Column(
                children: [
                  Text(
                    'Tháng $month',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    year.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right arrow - Next month
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right),
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
        ],
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
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(TimesheetLoaded state) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final workingDays = state.timesheet?.timeSheetData
            .where((day) => day.wd > 0)
            .length
            .toDouble() ??
        0.0;
    final leaveDays = state.timesheet?.timeSheetData
            .where((day) => (day.p ?? 0) > 0)
            .length
            .toDouble() ??
        0.0;
    final totalHours = state.timesheet?.timeSheetData
            .where((day) => day.numHour != null)
            .fold(0.0, (sum, day) => sum + (day.numHour ?? 0.0)) ??
        0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng quan tháng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Chi tiết',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF42C83C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Ngày công',
                  workingDays.toString(),
                  const Color(0xFF42C83C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Phép năm',
                  leaveDays.toString(),
                  const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Tăng ca',
                  '${totalHours}h',
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 30,
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
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
        dayData = timesheet.timeSheetData.firstWhere(
          (d) => d.dateWorking.day == day,
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
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1,
      children: dayWidgets,
    );
  }

  Widget _buildDayCell(DateTime date, TimeSheetDataEntity? dayData, DateTime? selectedDate) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    final isSelected = selectedDate != null &&
        date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;

    Color? backgroundColor;
    Color dayNumberColor = isDarkMode ? const Color(0xFFBEBEBE) : const Color(0xFF111827);
    Color statusTextColor = Colors.black87;
    String? statusText;
    bool isLargeStatus = false;

    if (dayData != null) {
      // Check if it's a holiday (HT field indicates holiday)
      if (dayData.hT != null && dayData.hT! > 0) {
        backgroundColor = Colors.red.withOpacity(0.1);
        statusTextColor = Colors.red;
        statusText = 'HT';
      } else if (dayData.wd > 0) {
        // Working day
        backgroundColor = const Color(0xFF42C83C).withOpacity(0.1);
        final hours = dayData.numHour?.toInt() ?? 0;
        statusText = '$hours';
        // Color based on hours >= 8
        statusTextColor = hours >= 8 ? const Color(0xFF2563EB) : const Color(0xFF42C83C);
        isLargeStatus = true;
      } else if (dayData.p != null && dayData.p! > 0) {
        // Leave day
        backgroundColor = Colors.yellow[100];
        statusTextColor = Colors.orange[700]!;
        statusText = 'P';
      } else if (dayData.nL != null && dayData.nL! > 0) {
        // National holiday
        statusTextColor = Colors.red;
        statusText = 'NL';
      } else if (dayData.ro != null && dayData.ro! > 0) {
        // Unpaid leave
        statusTextColor = Colors.red;
        statusText = 'Ro';
      }
    }

    if (isSelected) {
      backgroundColor = const Color(0xFF42C83C);
      dayNumberColor = Colors.white;
      statusTextColor = Colors.white;
    }

    return GestureDetector(
      onTap: () {
        context.read<RemoteTimesheetBloc>().add(SelectDay(selectedDate: date));
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: isToday
              ? Border.all(color: const Color(0xFF42C83C), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: dayNumberColor,
              ),
            ),
            if (statusText != null) ...[
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: isLargeStatus ? 12 : 9,
                  color: isSelected ? Colors.white : statusTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetails(TimesheetLoaded state) {
    final selectedDate = state.selectedDate!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    TimeSheetDataEntity? dayData;
    try {
      dayData = state.timesheet?.timeSheetData.firstWhere(
        (d) =>
            d.dateWorking.year == selectedDate.year &&
            d.dateWorking.month == selectedDate.month &&
            d.dateWorking.day == selectedDate.day,
      );
    } catch (e) {
      dayData = null;
    }

    if (dayData == null) return const SizedBox();

    final hasCheckIn = dayData.checkingPoints.isNotEmpty &&
        dayData.checkingPoints.first.timeIn != null;
    final checkInTime = hasCheckIn
        ? DateFormat('HH:mm').format(dayData.checkingPoints.first.timeIn!)
        : '--:--';
    final checkOutTime = hasCheckIn &&
            dayData.checkingPoints.first.timeOut != null
        ? DateFormat('HH:mm').format(dayData.checkingPoints.first.timeOut!)
        : '--:--';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF42C83C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF42C83C),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Chi tiết: ${DateFormat('dd-MM-yyyy').format(selectedDate)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: dayData.wd > 0
                      ? const Color(0xFF42C83C).withOpacity(0.1)
                      : (isDarkMode ? Colors.grey[700] : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  dayData.wd > 0 ? 'Đủ công' : 'Vắng',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: dayData.wd > 0
                        ? const Color(0xFF42C83C)
                        : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Giờ vào (In)', checkInTime),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailItem('Giờ ra (Out)', checkOutTime),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Phép năm (P)', '${dayData.p ?? 0}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailItem('Nghỉ lễ (NL)', '${dayData.nL ?? 0}'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('TỔng ca (NgG_2)', '${dayData.ngG ?? 0}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailItem('Ngày làm việc (Wd)', '${dayData.wd}'),
              ),
            ],
          ),
        ],
      ),
    );
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Xin Phép Trễ/Sớm',
                  const Color(0xFF00BCD4),
                  Icons.settings,
                  () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  'Báo cáo điều chỉnh',
                  const Color(0xFF2196F3),
                  Icons.edit_document,
                  () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Xin Phép Dự Kiến',
                  const Color(0xFFF44336),
                  Icons.access_time,
                  () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  'Điểm Chỉnh Quét Nhầm',
                  const Color(0xFFFF9800),
                  Icons.fingerprint,
                  () {},
                ),
              ),
            ],
          ),
        ],
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

