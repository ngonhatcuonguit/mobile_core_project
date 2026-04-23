import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/data/models/work_schedule/work_schedule_model.dart';
import 'package:flutter_core_project/presentation/pages/work_schedule/work_schedule_setup_page.dart';
import 'package:flutter_core_project/services/localization_service.dart';

class HomeWorkScheduleWidget extends StatefulWidget {
  const HomeWorkScheduleWidget({super.key});

  @override
  State<HomeWorkScheduleWidget> createState() => _HomeWorkScheduleWidgetState();
}

class _HomeWorkScheduleWidgetState extends State<HomeWorkScheduleWidget> {
  WorkScheduleModel? _schedule;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(kWorkScheduleKey);
      if (raw != null) {
        final model = WorkScheduleModel.fromJsonString(raw);
        setState(() {
          _schedule = model;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final txt = isDark ? Colors.white : const Color(0xFF111827);
    final subTxt = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final accentColor = const Color(0xFF42C83C);

    if (_isLoading || _schedule == null) {
      return const SizedBox.shrink();
    }

    final days = _dayLabels(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and action
            Row(
              children: [
                Icon(Icons.calendar_view_week_rounded,
                    color: accentColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Lịch làm việc',
                  style: TextStyle(
                    color: txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WorkScheduleSetupPage(),
                    ),
                  ),
                  child: Text(
                    'chỉnh sửa lịch',
                    style: const TextStyle(
                      color: Color(0xFF42C83C),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Schedule summary
            Column(
              children: List.generate(7, (i) {
                final day = i + 1;
                final isWeekend = day >= 6;
                // Get shifts for this day
                final dayShiftsForDay = _schedule!.shifts
                    .where((s) =>
                        s.isActive &&
                        (s.repeatType == 'daily' || s.appliedDays.contains(day)))
                    .toList()
                  ..sort((a, b) => a.checkInTime.compareTo(b.checkInTime));

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          days[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isWeekend ? const Color(0xFFEF4444) : txt,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: dayShiftsForDay.isEmpty
                            ? Text(
                                'Không có ca',
                                style:
                                    TextStyle(color: subTxt, fontSize: 12),
                              )
                            : Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: dayShiftsForDay
                                    .map((s) => _ShiftPill(
                                          entry: s,
                                          isDark: isDark,
                                        ))
                                    .toList(),
                              ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  static List<String> _dayLabels(BuildContext ctx) => [
        ctx.tr('ws_day_mon'),
        ctx.tr('ws_day_tue'),
        ctx.tr('ws_day_wed'),
        ctx.tr('ws_day_thu'),
        ctx.tr('ws_day_fri'),
        ctx.tr('ws_day_sat'),
        ctx.tr('ws_day_sun'),
      ];
}

class _ShiftPill extends StatelessWidget {
  final dynamic entry;
  final bool isDark;

  const _ShiftPill({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final startTime = entry.checkInTime.toString();
    final endTime = entry.checkOutTime.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF42C83C).withOpacity(isDark ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: const Color(0xFF42C83C).withOpacity(0.3), width: 1),
      ),
      child: Text(
        '$startTime - $endTime',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF42C83C),
        ),
      ),
    );
  }
}

