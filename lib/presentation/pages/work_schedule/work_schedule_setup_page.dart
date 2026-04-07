import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/data/models/work_schedule/work_schedule_model.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:flutter_core_project/services/work_schedule_notification_service.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kGreen  = Color(0xFF42C83C);
const _kBlue   = Color(0xFF3B82F6);
const _kAmber  = Color(0xFFF59E0B);
const _kRed    = Color(0xFFEF4444);
const _kViolet = Color(0xFF8B5CF6);
const _kGray   = Color(0xFF9CA3AF);

enum _SaveStatus { saved, pending, saving }

// ─── Page ─────────────────────────────────────────────────────────────────────
class WorkScheduleSetupPage extends StatefulWidget {
  const WorkScheduleSetupPage({super.key});
  @override
  State<WorkScheduleSetupPage> createState() => _WorkScheduleSetupPageState();
}

class _WorkScheduleSetupPageState extends State<WorkScheduleSetupPage> {
  List<WorkShiftEntry> _shifts = [];
  WorkScheduleReminder _reminder = const WorkScheduleReminder();
  int _shiftIdCounter = 0;

  // Auto-save state
  _SaveStatus _saveStatus = _SaveStatus.saved;
  Timer? _saveTimer;

  // User data
  String? _employeeId;
  String? _displayName;
  String? _department;

  @override
  void initState() {
    super.initState();
    _loadSaved();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final employeeId = await AuthService.getEmployeeId();
    final displayName = await AuthService.getDisplayName();
    final department = await AuthService.getDepartment();
    setState(() {
      _employeeId = employeeId;
      _displayName = displayName;
      _department = department;
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  // ── Persistence ──────────────────────────────────────────────────────────────
  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kWorkScheduleKey);
    if (raw == null) return;
    try {
      final m = WorkScheduleModel.fromJsonString(raw);
      setState(() {
        _shifts = List.from(m.shifts);
        _reminder = m.reminder;
        _shiftIdCounter = _shifts.length;
      });
    } catch (_) {}
  }

  /// Called after every user action. Debounces 700 ms then persists.
  void _scheduleAutoSave() {
    _saveTimer?.cancel();
    setState(() => _saveStatus = _SaveStatus.pending);
    _saveTimer = Timer(const Duration(milliseconds: 700), _autoSave);
  }

  Future<void> _autoSave() async {
    if (!mounted) return;
    setState(() => _saveStatus = _SaveStatus.saving);

    final now = DateTime.now();
    final model = WorkScheduleModel(
      employeeId:   _employeeId ?? 'EMP001',
      employeeName: _displayName ?? 'User',
      department:   _department ?? 'Department',
      scheduleId:   'SCH_${now.millisecondsSinceEpoch}',
      scheduleName: 'Lịch làm việc',
      shifts:       _shifts,
      reminder:     _reminder,
      createdAt:    now,
      updatedAt:    now,
    );
    final json = model.toJsonString();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kWorkScheduleKey, json);

    // Schedule notifications
    await WorkScheduleNotificationService.instance.scheduleFromWorkSchedule(model);

    // TODO: when API is ready → call PATCH /api/v1/work-schedules

    if (mounted) {
      setState(() => _saveStatus = _SaveStatus.saved);
    }
  }

  bool get _hasPendingChanges => _saveStatus != _SaveStatus.saved;

  // ── Back guard ────────────────────────────────────────────────────────────────
  Future<bool> _onWillPop() async {
    if (!_hasPendingChanges) return true;

    // Flush immediately, then leave
    _saveTimer?.cancel();
    await _autoSave();
    return true;
  }

  // ── Shift CRUD ────────────────────────────────────────────────────────────────
  Future<void> _openShiftSheet({WorkShiftEntry? existing}) async {
    final result = await showModalBottomSheet<WorkShiftEntry?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShiftEditorSheet(
        isDark: context.isDarkMode,
        existing: existing,
      ),
    );
    if (result == null) return;
    setState(() {
      if (existing != null) {
        final idx = _shifts.indexWhere((s) => s.id == existing.id);
        if (idx != -1) _shifts[idx] = result.copyWith(id: existing.id);
      } else {
        _shiftIdCounter++;
        _shifts.add(result.copyWith(id: 'shift_$_shiftIdCounter'));
      }
    });
    _scheduleAutoSave();
  }

  void _deleteShift(String id) {
    setState(() => _shifts.removeWhere((s) => s.id == id));
    _scheduleAutoSave();
  }

  void _toggleShiftActive(String id) {
    setState(() {
      final idx = _shifts.indexWhere((s) => s.id == id);
      if (idx != -1) {
        _shifts[idx] = _shifts[idx].copyWith(isActive: !_shifts[idx].isActive);
      }
    });
    _scheduleAutoSave();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark  = context.isDarkMode;
    final bg      = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final card    = isDark ? const Color(0xFF242424) : Colors.white;
    final border  = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final txt     = isDark ? Colors.white             : const Color(0xFF111827);
    final sub     = isDark ? const Color(0xFF9CA3AF)  : const Color(0xFF6B7280);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final canLeave = await _onWillPop();
        if (canLeave) nav.pop();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────
              _buildTopBar(isDark, txt, sub),

              // ── Scrollable body (employee card scrolls too) ─────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EmployeeCard(
                        isDark: isDark,
                        sub: sub,
                        employeeName: _displayName,
                        department: _department,
                      ),
                      const SizedBox(height: 16),
                      _buildShiftList(isDark, card, border, txt, sub),
                      const SizedBox(height: 16),
                      if (_shifts.isNotEmpty) ...[
                        _buildWeeklySummary(isDark, card, border, txt, sub),
                        const SizedBox(height: 16),
                      ],
                      _buildReminderSection(isDark, card, border, txt, sub),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isDark, Color txt, Color sub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _CircleBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            isDark: isDark,
            txt: txt,
            onTap: () async {
              final nav = Navigator.of(context);
              final canLeave = await _onWillPop();
              if (canLeave) nav.pop();
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('ws_title'),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: txt),
            ),
          ),
          // Auto-save status indicator
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (_saveStatus) {
              _SaveStatus.saving => const SizedBox(
                  key: ValueKey('saving'),
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kGreen),
                ),
              _SaveStatus.pending => const Icon(
                  key: ValueKey('pending'),
                  Icons.circle, size: 8,
                  color: _kAmber,
                ),
              _SaveStatus.saved => Row(
                  key: const ValueKey('saved'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: _kGreen),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('ws_autosaved'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
            },
          ),
          // Debug: Test notification button (only in debug mode)
          if (kDebugMode) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await WorkScheduleNotificationService.instance.showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.notifications_active, size: 16, color: _kAmber),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Shift list section ─────────────────────────────────────────────────────
  Widget _buildShiftList(bool isDark, Color card, Color border, Color txt, Color sub) {
    final headerBtn = GestureDetector(
      onTap: _openShiftSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(context.tr('ws_add_shift'),
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );

    final inlineAddBtn = GestureDetector(
      onTap: _openShiftSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _kGreen.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kGreen.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(color: _kGreen.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.add, color: _kGreen, size: 15),
            ),
            const SizedBox(width: 8),
            Text(context.tr('ws_add_another_shift'),
                style: const TextStyle(color: _kGreen, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );

    return _SectionCard(
      isDark: isDark, card: card, border: border,
      icon: Icons.access_time_rounded,
      title: context.tr('ws_shifts_section'),
      action: headerBtn,
      child: _shifts.isEmpty
          ? _EmptyShiftPlaceholder(sub: sub, onAdd: _openShiftSheet, ctx: context)
          : Column(
              children: [
                ..._shifts.map((s) => _ShiftEntryCard(
                      entry: s,
                      isDark: isDark, border: border, txt: txt, sub: sub,
                      dayLabels: _dayLabels(context),
                      onEdit:   () => _openShiftSheet(existing: s),
                      onDelete: () => _deleteShift(s.id),
                      onToggleActive: () => _toggleShiftActive(s.id),
                    )),
                const SizedBox(height: 4),
                inlineAddBtn,
              ],
            ),
    );
  }

  // ── Weekly summary ─────────────────────────────────────────────────────────
  Widget _buildWeeklySummary(bool isDark, Color card, Color border, Color txt, Color sub) {
    final days = _dayLabels(context);
    return _SectionCard(
      isDark: isDark, card: card, border: border,
      icon: Icons.calendar_view_week_rounded,
      title: context.tr('ws_weekly_summary'),
      child: Column(
        children: List.generate(7, (i) {
          final day = i + 1;
          final isWeekend = day >= 6;
          // Only show ACTIVE shifts in summary
          final dayShifts = _shifts
              .where((s) =>
                  s.isActive &&
                  (s.repeatType == 'daily' || s.appliedDays.contains(day)))
              .toList()
            ..sort((a, b) => a.checkInTime.compareTo(b.checkInTime));

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(days[i],
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: isWeekend ? _kRed : txt)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: dayShifts.isEmpty
                      ? Text(context.tr('ws_no_shift_day'),
                          style: TextStyle(color: sub, fontSize: 12))
                      : Wrap(
                          spacing: 6, runSpacing: 6,
                          children: dayShifts
                              .map((s) => _ShiftPill(entry: s, isDark: isDark))
                              .toList(),
                        ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Reminder section ───────────────────────────────────────────────────────
  Widget _buildReminderSection(bool isDark, Color card, Color border, Color txt, Color sub) {
    return _SectionCard(
      isDark: isDark, card: card, border: border,
      icon: Icons.notifications_outlined,
      title: context.tr('ws_reminder_section'),
      child: Column(children: [
        _ReminderRow(
          isDark: isDark, border: border, txt: txt, sub: sub,
          label: context.tr('ws_reminder_checkin'),
          icon: Icons.login_rounded, iconColor: _kBlue,
          enabled: _reminder.checkInEnabled,
          minutes: _reminder.checkInMinutesBefore,
          onToggle: (v) { setState(() => _reminder = _reminder.copyWith(checkInEnabled: v)); _scheduleAutoSave(); },
          onMin: (v) { setState(() => _reminder = _reminder.copyWith(checkInMinutesBefore: v)); _scheduleAutoSave(); },
        ),
        const SizedBox(height: 8),
        _ReminderRow(
          isDark: isDark, border: border, txt: txt, sub: sub,
          label: context.tr('ws_reminder_checkout'),
          icon: Icons.logout_rounded, iconColor: _kAmber,
          enabled: _reminder.checkOutEnabled,
          minutes: _reminder.checkOutMinutesBefore,
          onToggle: (v) { setState(() => _reminder = _reminder.copyWith(checkOutEnabled: v)); _scheduleAutoSave(); },
          onMin: (v) { setState(() => _reminder = _reminder.copyWith(checkOutMinutesBefore: v)); _scheduleAutoSave(); },
        ),
        const SizedBox(height: 8),
        _SwitchRow(
          isDark: isDark, border: border, txt: txt,
          label: context.tr('ws_alert_late'),
          icon: Icons.warning_amber_rounded, iconColor: _kRed,
          value: _reminder.lateAlertEnabled,
          onToggle: (v) { setState(() => _reminder = _reminder.copyWith(lateAlertEnabled: v)); _scheduleAutoSave(); },
        ),
        const SizedBox(height: 8),
        _SwitchRow(
          isDark: isDark, border: border, txt: txt,
          label: context.tr('ws_alert_overtime'),
          icon: Icons.timer_outlined, iconColor: _kViolet,
          value: _reminder.overtimeAlertEnabled,
          onToggle: (v) { setState(() => _reminder = _reminder.copyWith(overtimeAlertEnabled: v)); _scheduleAutoSave(); },
        ),
      ]),
    );
  }

  // ── Util ───────────────────────────────────────────────────────────────────
  static List<String> _dayLabels(BuildContext ctx) => [
    ctx.tr('ws_day_mon'), ctx.tr('ws_day_tue'), ctx.tr('ws_day_wed'),
    ctx.tr('ws_day_thu'), ctx.tr('ws_day_fri'), ctx.tr('ws_day_sat'), ctx.tr('ws_day_sun'),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── Sub-widgets ───────────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final Color card, border;
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? action;
  const _SectionCard({
    required this.isDark, required this.card, required this.border,
    required this.icon, required this.title, required this.child, this.action,
  });
  @override
  Widget build(BuildContext context) {
    final txt = isDark ? Colors.white : const Color(0xFF111827);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: _kGreen, size: 18),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: txt, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            if (action != null) ...[const Spacer(), action!],
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final Color txt;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.isDark, required this.txt, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Icon(icon, size: 16, color: txt),
    ),
  );
}

class _EmployeeCard extends StatelessWidget {
  final bool isDark;
  final Color sub;
  final String? employeeName;
  final String? department;

  const _EmployeeCard({
    required this.isDark,
    required this.sub,
    this.employeeName,
    this.department,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: isDark
          ? const LinearGradient(colors: [Color(0xFF1A3A1A), Color(0xFF0D2010)], begin: Alignment.topLeft, end: Alignment.bottomRight)
          : const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.person_outline, color: Colors.white, size: 24),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            employeeName ?? 'User',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            department ?? 'Department',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Text(context.tr('ws_employee_badge'),
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    ]),
  );
}

class _EmptyShiftPlaceholder extends StatelessWidget {
  final Color sub;
  final VoidCallback onAdd;
  final BuildContext ctx;
  const _EmptyShiftPlaceholder({required this.sub, required this.onAdd, required this.ctx});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onAdd,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        border: Border.all(color: _kGreen.withOpacity(0.35), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: _kGreen.withOpacity(0.04),
      ),
      child: Column(children: [
        Icon(Icons.add_circle_outline_rounded, size: 36, color: _kGreen.withOpacity(0.6)),
        const SizedBox(height: 8),
        Text(ctx.tr('ws_no_shifts'), textAlign: TextAlign.center,
            style: TextStyle(color: sub, fontSize: 13)),
      ]),
    ),
  );
}

// ─── Shift Entry Card ─────────────────────────────────────────────────────────
class _ShiftEntryCard extends StatelessWidget {
  final WorkShiftEntry entry;
  final bool isDark;
  final Color border, txt, sub;
  final List<String> dayLabels;
  final VoidCallback onEdit, onDelete, onToggleActive;

  const _ShiftEntryCard({
    required this.entry, required this.isDark,
    required this.border, required this.txt, required this.sub,
    required this.dayLabels,
    required this.onEdit, required this.onDelete, required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = entry.isActive;
    final isDaily = entry.repeatType == 'daily';
    final rowBg = isActive
        ? (isDark ? const Color(0xFF1E3A1E).withOpacity(0.5) : const Color(0xFFECFDF5))
        : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6));
    final borderClr = isActive ? _kGreen.withOpacity(0.3) : border;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isActive ? 1.0 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: rowBg, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderClr),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 6),
              child: Row(children: [
                // Icon
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: (isActive ? _kGreen : _kGray).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.schedule, color: isActive ? _kGreen : _kGray, size: 20),
                ),
                const SizedBox(width: 10),
                // Name + times
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(
                        child: Text(entry.name,
                            style: TextStyle(color: txt, fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                      if (!isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kGray.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(context.tr('ws_shift_paused'),
                              style: const TextStyle(color: _kGray, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.login_rounded, size: 11, color: _kBlue),
                      const SizedBox(width: 3),
                      Text(entry.checkInTime,
                          style: const TextStyle(color: _kBlue, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      const Icon(Icons.logout_rounded, size: 11, color: _kAmber),
                      const SizedBox(width: 3),
                      Text(
                        entry.crossesMidnight ? '${entry.checkOutTime} (+1)' : entry.checkOutTime,
                        style: const TextStyle(color: _kAmber, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      if (entry.crossesMidnight) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _kViolet.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                          child: const Text('Ca đêm', style: TextStyle(color: _kViolet, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ]),
                  ]),
                ),
                // Active toggle
                GestureDetector(
                  onTap: onToggleActive,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36, height: 20,
                    decoration: BoxDecoration(
                      color: isActive ? _kGreen : _kGray.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 16, height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Edit
                _IconBtn(icon: Icons.edit_outlined, color: sub, bg: isDark ? const Color(0xFF2C2C2C) : Colors.white, border: border, onTap: onEdit),
                const SizedBox(width: 6),
                // Delete
                _IconBtn(icon: Icons.delete_outline, color: _kRed, bg: _kRed.withOpacity(0.08), border: _kRed.withOpacity(0.25), onTap: onDelete),
              ]),
            ),

            Divider(height: 1, color: (isActive ? _kGreen : _kGray).withOpacity(0.2)),

            // ── Days + frequency ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(children: [
                if (isDaily)
                  _FreqBadge(label: context.tr('ws_freq_daily'), color: _kGreen)
                else
                  Expanded(
                    child: Wrap(
                      spacing: 4, runSpacing: 4,
                      children: List.generate(7, (i) {
                        final day = i + 1;
                        final active = entry.appliedDays.contains(day);
                        final isWe = day >= 6;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: active
                                ? (isWe ? _kRed : _kGreen)
                                : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F4F6)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: active ? Colors.transparent : border),
                          ),
                          child: Text(dayLabels[i],
                              style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600,
                                color: active ? Colors.white : (isWe ? _kRed.withOpacity(0.6) : sub),
                              )),
                        );
                      }),
                    ),
                  ),
                const SizedBox(width: 8),
                if (!isDaily)
                  _FreqBadge(
                    label: entry.repeatType == 'weekly' ? context.tr('ws_freq_weekly') : context.tr('ws_freq_custom'),
                    color: _kBlue,
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreqBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _FreqBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bg, border;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.bg, required this.border, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
      child: Icon(icon, size: 15, color: color),
    ),
  );
}

class _ShiftPill extends StatelessWidget {
  final WorkShiftEntry entry;
  final bool isDark;
  const _ShiftPill({required this.entry, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _kGreen.withOpacity(isDark ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _kGreen.withOpacity(0.35)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.schedule, size: 10, color: _kGreen),
      const SizedBox(width: 4),
      Text('${entry.name}  ${entry.checkInTime}–${entry.checkOutTime}',
          style: const TextStyle(fontSize: 11, color: _kGreen, fontWeight: FontWeight.w600)),
      if (entry.crossesMidnight) ...[
        const SizedBox(width: 3),
        const Text('+1', style: TextStyle(fontSize: 9, color: _kViolet, fontWeight: FontWeight.w700)),
      ],
    ]),
  );
}

// ─── Reminder Row ──────────────────────────────────────────────────────────────
class _ReminderRow extends StatelessWidget {
  final bool isDark;
  final Color border, txt, sub;
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool enabled;
  final int minutes;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onMin;
  const _ReminderRow({
    required this.isDark, required this.border, required this.txt, required this.sub,
    required this.label, required this.icon, required this.iconColor,
    required this.enabled, required this.minutes,
    required this.onToggle, required this.onMin,
  });
  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9FAFB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(children: [
        Row(children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: txt, fontSize: 13, fontWeight: FontWeight.w500))),
          Switch(value: enabled, onChanged: onToggle, activeColor: _kGreen, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ]),
        if (enabled) ...[
          const SizedBox(height: 8),
          Row(children: [
            Text(context.tr('ws_reminder_before'), style: TextStyle(color: sub, fontSize: 12)),
            const Spacer(),
            _MinuteStepper(value: minutes, isDark: isDark, onChanged: onMin),
          ]),
        ],
      ]),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final bool isDark;
  final Color border, txt;
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onToggle;
  const _SwitchRow({
    required this.isDark, required this.border, required this.txt,
    required this.label, required this.icon, required this.iconColor,
    required this.value, required this.onToggle,
  });
  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9FAFB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(children: [
        Icon(icon, size: 17, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(color: txt, fontSize: 13, fontWeight: FontWeight.w500))),
        Switch(value: value, onChanged: onToggle, activeColor: _kGreen, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ]),
    );
  }
}

class _MinuteStepper extends StatelessWidget {
  final int value;
  final bool isDark;
  final ValueChanged<int> onChanged;
  static const _steps = [5, 10, 15, 20, 30, 45, 60];
  const _MinuteStepper({required this.value, required this.isDark, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final bd = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB);
    int idx = _steps.indexOf(value);
    if (idx < 0) idx = 2;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _StepBtn(icon: Icons.remove, isDark: isDark, active: idx > 0, bg: bg, bd: bd,
          onTap: idx > 0 ? () => onChanged(_steps[idx - 1]) : null),
      const SizedBox(width: 8),
      Text('$value ${context.tr('ws_minutes')}',
          style: const TextStyle(color: _kGreen, fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(width: 8),
      _StepBtn(icon: Icons.add, isDark: isDark, active: idx < _steps.length - 1, bg: bg, bd: bd,
          onTap: idx < _steps.length - 1 ? () => onChanged(_steps[idx + 1]) : null),
    ]);
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark, active;
  final Color bg, bd;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, required this.isDark, required this.active,
      required this.bg, required this.bd, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7), border: Border.all(color: bd)),
      child: Icon(icon, size: 14,
          color: active ? _kGreen : (isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB))),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── Shift Editor Bottom Sheet ─────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════
class _ShiftEditorSheet extends StatefulWidget {
  final bool isDark;
  final WorkShiftEntry? existing;
  const _ShiftEditorSheet({required this.isDark, this.existing});
  @override
  State<_ShiftEditorSheet> createState() => _ShiftEditorSheetState();
}

class _ShiftEditorSheetState extends State<_ShiftEditorSheet> {
  late TextEditingController _nameCtrl;
  late String _checkIn;
  late String _checkOut;
  late bool _crossesMidnight;
  late List<int> _days;
  late String _repeatType;

  // Inline validation state
  bool _nameError  = false;
  bool _daysError  = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _checkIn  = e?.checkInTime  ?? '08:00';
    _checkOut = e?.checkOutTime ?? '17:30';
    _crossesMidnight = e?.crossesMidnight ?? false;
    _days        = List.from(e?.appliedDays ?? [1, 2, 3, 4, 5]);
    _repeatType  = e?.repeatType  ?? 'weekly';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isIn) async {
    final parts = (isIn ? _checkIn : _checkOut).split(':');
    final init = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(
      context: context,
      initialTime: init,
      builder: (ctx, child) => Theme(
        data: widget.isDark
            ? ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _kGreen))
            : ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: _kGreen)),
        child: child!,
      ),
    );
    if (picked == null) return;
    final fmt = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => isIn ? _checkIn = fmt : _checkOut = fmt);
  }

  void _toggleDay(int day) {
    setState(() {
      if (_days.contains(day)) {
        _days.remove(day);
      } else {
        _days.add(day);
        _days.sort();
      }
      if (_days.isNotEmpty) _daysError = false;
    });
  }

  void _confirm() {
    // ── Validate ────────────────────────────────────────────
    final name = _nameCtrl.text.trim();
    final nameErr = name.isEmpty;
    final daysErr = _repeatType != 'daily' && _days.isEmpty;
    if (nameErr || daysErr) {
      setState(() { _nameError = nameErr; _daysError = daysErr; });
      return;
    }
    Navigator.of(context).pop(WorkShiftEntry(
      id: '',
      name: name,
      checkInTime: _checkIn,
      checkOutTime: _checkOut,
      crossesMidnight: _crossesMidnight,
      appliedDays: _repeatType == 'daily' ? [] : _days,
      repeatType: _repeatType,
      isActive: widget.existing?.isActive ?? true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = widget.isDark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F4F6);
    final border  = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB);
    final txt     = isDark ? Colors.white             : const Color(0xFF111827);
    final lbl     = isDark ? const Color(0xFF9CA3AF)  : const Color(0xFF6B7280);

    final dayLabels = [
      context.tr('ws_day_mon'), context.tr('ws_day_tue'), context.tr('ws_day_wed'),
      context.tr('ws_day_thu'), context.tr('ws_day_fri'), context.tr('ws_day_sat'), context.tr('ws_day_sun'),
    ];
    final freqOpts = [
      {'v': 'weekly', 'l': context.tr('ws_freq_weekly')},
      {'v': 'daily',  'l': context.tr('ws_freq_daily')},
      {'v': 'custom', 'l': context.tr('ws_freq_custom')},
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 14),

              // Title
              Text(
                widget.existing != null ? context.tr('ws_edit_shift_title') : context.tr('ws_add_shift_title'),
                style: TextStyle(color: txt, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),

              // ── Shift name ──────────────────────────────────────
              _SheetLabel(label: context.tr('ws_shift_name'), color: lbl),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                style: TextStyle(color: txt, fontSize: 14),
                inputFormatters: [LengthLimitingTextInputFormatter(30)],
                onChanged: (_) { if (_nameError) setState(() => _nameError = false); },
                decoration: InputDecoration(
                  hintText: context.tr('ws_shift_name_hint'),
                  hintStyle: TextStyle(color: lbl, fontSize: 13),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _nameError ? _kRed : border,
                      width: _nameError ? 1.5 : 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _nameError ? _kRed : border,
                      width: _nameError ? 1.5 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _nameError ? _kRed : border,
                      width: _nameError ? 1.5 : 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              if (_nameError) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.error_outline_rounded, size: 12, color: _kRed),
                  const SizedBox(width: 4),
                  Text(context.tr('ws_error_no_shift_name'),
                      style: const TextStyle(color: _kRed, fontSize: 11)),
                ]),
              ],
              const SizedBox(height: 14),

              // ── Time pickers ───────────────────────────────────
              Row(children: [
                Expanded(
                  child: _TimeTile(
                    label: context.tr('ws_checkin_time'), time: _checkIn,
                    icon: Icons.login_rounded, color: _kBlue,
                    inputBg: inputBg, border: _kBlue, lbl: lbl, onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeTile(
                    label: context.tr('ws_checkout_time'),
                    time: _crossesMidnight ? '$_checkOut +1' : _checkOut,
                    icon: Icons.logout_rounded, color: _kAmber,
                    inputBg: inputBg, border: _kAmber, lbl: lbl, onTap: () => _pickTime(false),
                  ),
                ),
              ]),
              const SizedBox(height: 10),

              // ── Crosses midnight ───────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _crossesMidnight = !_crossesMidnight),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: _crossesMidnight ? _kViolet : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: _crossesMidnight ? _kViolet : border, width: 1.5),
                    ),
                    child: _crossesMidnight ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 8),
                  Text(context.tr('ws_crosses_midnight'), style: TextStyle(color: txt, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 18),

              // ── Frequency ──────────────────────────────────────
              _SheetLabel(label: context.tr('ws_frequency_section'), color: lbl),
              const SizedBox(height: 8),
              Row(
                children: freqOpts.map((opt) {
                  final sel = _repeatType == opt['v'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _repeatType = opt['v']!;
                        if (_repeatType == 'daily') _daysError = false;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: sel ? _kGreen : inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? _kGreen : border),
                        ),
                        child: Text(opt['l']!, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : lbl)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ── Day picker (hidden when daily) ─────────────────
              if (_repeatType != 'daily') ...[
                _SheetLabel(
                  label: context.tr('ws_applied_days'),
                  color: _daysError ? _kRed : lbl,
                  trailing: GestureDetector(
                    onTap: () => setState(() {
                      _days = _days.length == 7 ? [] : [1, 2, 3, 4, 5, 6, 7];
                      if (_days.isNotEmpty) _daysError = false;
                    }),
                    child: Text(
                      _days.length == 7 ? context.tr('ws_deselect_all') : context.tr('ws_select_all'),
                      style: const TextStyle(color: _kGreen, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final sel = _days.contains(day);
                    final isWe = day >= 6;
                    return GestureDetector(
                      onTap: () => _toggleDay(day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 40, height: 52,
                        decoration: BoxDecoration(
                          color: sel ? (isWe ? _kRed : _kGreen) : inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _daysError
                                ? _kRed.withOpacity(0.6)
                                : (sel ? Colors.transparent : (isWe ? _kRed.withOpacity(0.3) : border)),
                            width: _daysError ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(dayLabels[i],
                                style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: sel ? Colors.white : (isWe ? _kRed.withOpacity(0.7) : lbl),
                                )),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 4, height: 4,
                              decoration: BoxDecoration(
                                color: sel ? Colors.white.withOpacity(0.7) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                if (_daysError) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.error_outline_rounded, size: 12, color: _kRed),
                    const SizedBox(width: 4),
                    Text(context.tr('ws_error_no_days'),
                        style: const TextStyle(color: _kRed, fontSize: 11)),
                  ]),
                ],
                const SizedBox(height: 16),
              ],

              // ── Confirm ────────────────────────────────────────
              GestureDetector(
                onTap: _confirm,
                child: Container(
                  width: double.infinity, height: 50,
                  decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Text(context.tr('ws_confirm'),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sheet helpers ─────────────────────────────────────────────────────────────
class _SheetLabel extends StatelessWidget {
  final String label;
  final Color color;
  final Widget? trailing;
  const _SheetLabel({required this.label, required this.color, this.trailing});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    if (trailing != null) ...[const Spacer(), trailing!],
  ]);
}

class _TimeTile extends StatelessWidget {
  final String label, time;
  final IconData icon;
  final Color color, inputBg, border, lbl;
  final VoidCallback onTap;
  const _TimeTile({required this.label, required this.time, required this.icon,
      required this.color, required this.inputBg, required this.border,
      required this.lbl, required this.onTap});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: lbl, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 5),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
              color: inputBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
          child: Row(children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(time, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    ],
  );
}
