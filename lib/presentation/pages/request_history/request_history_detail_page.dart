import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/data/models/request_history/request_history_model.dart';
import 'package:intl/intl.dart';

// ─── Helpers (reuse from list page by keeping consistent) ───────────────────
IconData _iconForType(String code) {
  switch (code.toUpperCase()) {
    case 'NOT_YET':        return Icons.fingerprint;
    case 'FORGOTEN':       return Icons.do_not_touch_outlined;
    case 'MCC_ERROR':      return Icons.error_outline_rounded;
    case 'SHIFT_SWAPPING': return Icons.swap_horiz_rounded;
    case 'NIGHT_SHIFT':    return Icons.nightlight_round;
    case 'DAY_BUSINESS':   return Icons.work_outline_rounded;
    default:               return Icons.edit_note_rounded;
  }
}

Color _colorForType(String code) {
  switch (code.toUpperCase()) {
    case 'NOT_YET':        return const Color(0xFFEF4444);
    case 'FORGOTEN':       return const Color(0xFFF59E0B);
    case 'MCC_ERROR':      return const Color(0xFFEC4899);
    case 'SHIFT_SWAPPING': return const Color(0xFF8B5CF6);
    case 'NIGHT_SHIFT':    return const Color(0xFF6366F1);
    case 'DAY_BUSINESS':   return const Color(0xFF10B981);
    default:               return const Color(0xFF64748B);
  }
}

Color _statusColor(RequestStatus s) {
  switch (s) {
    case RequestStatus.approved: return const Color(0xFF10B981);
    case RequestStatus.pending:  return const Color(0xFFF59E0B);
  }
}

IconData _statusIcon(RequestStatus s) {
  switch (s) {
    case RequestStatus.approved: return Icons.check_circle_outline_rounded;
    case RequestStatus.pending:  return Icons.pending_outlined;
  }
}

// ─── Detail Page ─────────────────────────────────────────────────────────────
class RequestHistoryDetailPage extends StatelessWidget {
  final RequestHistoryItem item;
  final bool isVi;

  const RequestHistoryDetailPage({
    super.key,
    required this.item,
    required this.isVi,
  });

  static final _dateFmt     = DateFormat('dd/MM/yyyy');
  static final _timeFmt     = DateFormat('HH:mm');
  static final _datetimeFmt = DateFormat('dd/MM/yyyy HH:mm');

  String _weekdayLabel(DateTime dt) {
    const vi = ['', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
    const en = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return isVi ? vi[dt.weekday] : en[dt.weekday];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final sectionHeaderColor = isDark ? Colors.white38 : const Color(0xFF9CA3AF);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final dividerColor = isDark ? Colors.white10 : const Color(0xFFF3F4F6);

    final typeCode  = item.typeCode;
    final typeColor = _colorForType(typeCode);
    final typeIcon  = _iconForType(typeCode);
    final typeLabel = isVi ? item.typeLabelVi : item.typeLabelEn;
    final statusColor = _statusColor(item.status);
    final statusIcon  = _statusIcon(item.status);
    final statusLabel = isVi ? item.status.labelVi : item.status.labelEn;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : const Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isVi ? 'Chi tiết phản hồi' : 'Request Detail',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1,
              color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          children: [
            // ── Compact status banner ───────────────────────────────
            _StatusBanner(
              statusColor: statusColor,
              statusIcon: statusIcon,
              statusLabel: statusLabel,
              requestedAt: item.requestedAt,
              isDark: isDark,
              isVi: isVi,
              subColor: subColor,
            ),
            const SizedBox(height: 14),

            // ── Working Date & Time ─────────────────────────────────
            _InfoCard(
              isDark: isDark,
              cardBg: cardBg,
              dividerColor: dividerColor,
              sectionLabel: isVi ? 'THÔNG TIN NGÀY CÔNG' : 'ATTENDANCE INFO',
              sectionHeaderColor: sectionHeaderColor,
              children: [
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  iconColor: const Color(0xFF2196F3),
                  label: isVi ? 'Ngày công' : 'Work date',
                  value: '${_dateFmt.format(item.dateWorking)}  (${_weekdayLabel(item.dateWorking)})',
                  titleColor: titleColor,
                  subColor: subColor,
                ),
                Divider(height: 1, color: dividerColor),
                _InfoRow(
                  icon: Icons.login_rounded,
                  iconColor: const Color(0xFF10B981),
                  label: isVi ? 'Giờ vào' : 'Check-in',
                  value: item.timeIn != null
                      ? _timeFmt.format(item.timeIn!)
                      : '--:--',
                  titleColor: titleColor,
                  subColor: subColor,
                ),
                Divider(height: 1, color: dividerColor),
                _InfoRow(
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  label: isVi ? 'Giờ ra' : 'Check-out',
                  value: item.timeOut != null
                      ? _timeFmt.format(item.timeOut!)
                      : '--:--',
                  titleColor: titleColor,
                  subColor: subColor,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Request Type ────────────────────────────────────────
            _InfoCard(
              isDark: isDark,
              cardBg: cardBg,
              dividerColor: dividerColor,
              sectionLabel: isVi ? 'LOẠI YÊU CẦU' : 'REQUEST TYPE',
              sectionHeaderColor: sectionHeaderColor,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(typeIcon, color: typeColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Reason ─────────────────────────────────────────────
            _InfoCard(
              isDark: isDark,
              cardBg: cardBg,
              dividerColor: dividerColor,
              sectionLabel: isVi ? 'LÝ DO' : 'REASON',
              sectionHeaderColor: sectionHeaderColor,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    item.reason.isNotEmpty
                        ? item.reason
                        : (isVi ? 'Không có lý do' : 'No reason provided'),
                    style: TextStyle(
                      fontSize: 13,
                      color: item.reason.isNotEmpty ? titleColor : subColor,
                      height: 1.5,
                      fontStyle: item.reason.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── HR Note ────────────────────────────────────────────
            _InfoCard(
              isDark: isDark,
              cardBg: cardBg,
              dividerColor: dividerColor,
              sectionLabel: isVi ? 'GHI CHÚ TỪ HR' : 'HR NOTE',
              sectionHeaderColor: sectionHeaderColor,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.hrbpNote != null && item.hrbpNote!.isNotEmpty
                            ? Icons.comment_outlined
                            : Icons.hourglass_empty_rounded,
                        size: 18,
                        color: item.hrbpNote != null && item.hrbpNote!.isNotEmpty
                            ? const Color(0xFF2196F3)
                            : subColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.hrbpNote != null && item.hrbpNote!.isNotEmpty
                              ? item.hrbpNote!
                              : (isVi
                                  ? 'Chưa có ghi chú từ HR'
                                  : 'No HR note yet'),
                          style: TextStyle(
                            fontSize: 13,
                            color: item.hrbpNote != null &&
                                    item.hrbpNote!.isNotEmpty
                                ? titleColor
                                : subColor,
                            height: 1.5,
                            fontStyle:
                                item.hrbpNote == null || item.hrbpNote!.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Timeline ───────────────────────────────────────────
            _InfoCard(
              isDark: isDark,
              cardBg: cardBg,
              dividerColor: dividerColor,
              sectionLabel: isVi ? 'LỊCH SỬ' : 'TIMELINE',
              sectionHeaderColor: sectionHeaderColor,
              children: [
                _TimelineRow(
                  isDark: isDark,
                  label: isVi ? 'Ngày tạo' : 'Created',
                  dateTime: item.createAt,
                  formatter: _datetimeFmt,
                  subColor: subColor,
                  titleColor: titleColor,
                  dotColor: const Color(0xFF2196F3),
                  isLast: item.updateAt == null,
                ),
                if (item.updateAt != null)
                  _TimelineRow(
                    isDark: isDark,
                    label: isVi ? 'Cập nhật' : 'Updated',
                    dateTime: item.updateAt,
                    formatter: _datetimeFmt,
                    subColor: subColor,
                    titleColor: titleColor,
                    dotColor: statusColor,
                    isLast: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact status banner ────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;
  final Color subColor;
  final DateTime? requestedAt;
  final bool isDark;
  final bool isVi;

  const _StatusBanner({
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
    required this.subColor,
    required this.requestedAt,
    required this.isDark,
    required this.isVi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.22), width: 1),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 8),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
          if (requestedAt != null) ...[
            const SizedBox(width: 8),
            Text('·', style: TextStyle(color: subColor, fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${isVi ? 'Gửi lúc' : 'Sent at'} ${DateFormat('dd/MM/yyyy HH:mm').format(requestedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: subColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
  }
}

// ─── Info card container ──────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Color dividerColor;
  final String sectionLabel;
  final Color sectionHeaderColor;
  final List<Widget> children;

  const _InfoCard({
    required this.isDark,
    required this.cardBg,
    required this.dividerColor,
    required this.sectionLabel,
    required this.sectionHeaderColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            sectionLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: sectionHeaderColor,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

// ─── Row inside info card ─────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color titleColor;
  final Color subColor;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.titleColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: subColor,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline row ──────────────────────────────────────────────────────────
class _TimelineRow extends StatelessWidget {
  final bool isDark;
  final String label;
  final DateTime? dateTime;
  final DateFormat formatter;
  final Color subColor;
  final Color titleColor;
  final Color dotColor;
  final bool isLast;

  const _TimelineRow({
    required this.isDark,
    required this.label,
    required this.dateTime,
    required this.formatter,
    required this.subColor,
    required this.titleColor,
    required this.dotColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateTime != null ? formatter.format(dateTime!) : '--',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

