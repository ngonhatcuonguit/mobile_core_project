import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/data/models/request_history/request_history_model.dart';
import 'package:flutter_core_project/data/repositories/request_history/request_history_repository_impl.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/presentation/pages/request_history/request_history_detail_page.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:intl/intl.dart';

// ─── Type icon/color helper ────────────────────────────────────────────────
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

// ─── Status badge helper ───────────────────────────────────────────────────
Color _statusColor(RequestStatus s) {
  switch (s) {
    case RequestStatus.approved: return const Color(0xFF10B981);
    case RequestStatus.pending:  return const Color(0xFFF59E0B);
  }
}

String _statusLabel(RequestStatus s, bool isVi) {
  if (isVi) return s.labelVi;
  return s.labelEn;
}

// ─── Page ─────────────────────────────────────────────────────────────────
class RequestHistoryPage extends StatefulWidget {
  const RequestHistoryPage({super.key});

  @override
  State<RequestHistoryPage> createState() => _RequestHistoryPageState();
}

class _RequestHistoryPageState extends State<RequestHistoryPage> {
  static const _pageSize = 10;

  final _repo = sl<RequestHistoryRepository>();
  final _items = <RequestHistoryItem>[];
  final _scrollCtrl = ScrollController();

  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  // Filter: null = all
  RequestStatus? _filter;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 120 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
      _error = null;
    });
    try {
      final res = await _repo.getMyRequests(page: _page, pageSize: _pageSize);
      setState(() {
        _items.addAll(res.items);
        _page++;
        _hasMore = _items.length < res.total;
        _isFirstLoad = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isFirstLoad = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _page = 1;
      _hasMore = true;
      _isFirstLoad = true;
    });
    await _loadMore();
  }

  List<RequestHistoryItem> get _filtered {
    if (_filter == null) return _items;
    return _items.where((e) => e.status == _filter).toList();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white60 : const Color(0xFF6B7280);

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
          context.tr('rh_title'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: titleColor,
            fontFamily: 'Satoshi',
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Filter bar ───────────────────────────────────────────
          _FilterBar(
            selected: _filter,
            isDark: isDark,
            isVi: isVi,
            onSelect: (s) {
              setState(() => _filter = s);
            },
          ),

          // ── Content ──────────────────────────────────────────────
          Expanded(
            child: _isFirstLoad
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(
                        message: context.tr('rh_error'),
                        isDark: isDark,
                        onRetry: _refresh,
                        retryLabel: context.tr('rh_retry'),
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        color: const Color(0xFF2196F3),
                        child: _filtered.isEmpty
                            ? _EmptyView(
                                isDark: isDark,
                                message: context.tr('rh_empty'),
                              )
                            : ListView.builder(
                                controller: _scrollCtrl,
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                                itemCount:
                                    _filtered.length + (_isLoadingMore ? 1 : 0),
                                itemBuilder: (_, i) {
                                  if (i == _filtered.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                          child:
                                              CircularProgressIndicator(strokeWidth: 2)),
                                    );
                                  }
                                  return _RequestCard(
                                    item: _filtered[i],
                                    isDark: isDark,
                                    isVi: isVi,
                                    cardBg: cardBg,
                                    titleColor: titleColor,
                                    subColor: subColor,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RequestHistoryDetailPage(
                                          item: _filtered[i],
                                          isVi: isVi,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Full-width 3-segment tab bar ─────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final RequestStatus? selected;
  final bool isDark;
  final bool isVi;
  final ValueChanged<RequestStatus?> onSelect;

  const _FilterBar({
    required this.selected,
    required this.isDark,
    required this.isVi,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (null,                   isVi ? 'Tất cả'   : 'All'),
      (RequestStatus.pending,  isVi ? 'Đang chờ' : 'Pending'),
      (RequestStatus.approved, isVi ? 'Đã duyệt' : 'Approved'),
    ];

    final trackBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F1F3);

    return Container(
      color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: trackBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final t = tabs[i];
            final isActive = selected == t.$1;
            final activeColor = t.$1 == null
                ? const Color(0xFF2196F3)
                : _statusColor(t.$1!);

            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(t.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                  isDark ? 0.3 : 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      t.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive
                            ? activeColor
                            : (isDark
                                ? Colors.white38
                                : const Color(0xFF9CA3AF)),
                        fontFamily: 'Satoshi',
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Request card ─────────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final RequestHistoryItem item;
  final bool isDark;
  final bool isVi;
  final Color cardBg;
  final Color titleColor;
  final Color subColor;
  final VoidCallback onTap;

  const _RequestCard({
    required this.item,
    required this.isDark,
    required this.isVi,
    required this.cardBg,
    required this.titleColor,
    required this.subColor,
    required this.onTap,
  });

  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final typeCode  = item.typeCode;
    final typeColor = _colorForType(typeCode);
    final typeIcon  = _iconForType(typeCode);
    final typeLabel = isVi ? item.typeLabelVi : item.typeLabelEn;
    final statusColor = _statusColor(item.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Top stripe ─────────────────────────────────────────
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: type + status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(typeIcon, color: typeColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                                fontFamily: 'Satoshi',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${isVi ? 'Ngày công' : 'Work date'}: ${_dateFmt.format(item.dateWorking)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: subColor,
                                fontFamily: 'Satoshi',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _statusLabel(item.status, isVi),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                                fontFamily: 'Satoshi',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                    ),
                  ),

                  // Row 2: time in/out + reason
                  Row(
                    children: [
                      // Time in/out
                      Icon(Icons.access_time_rounded,
                          size: 14, color: subColor),
                      const SizedBox(width: 4),
                      Text(
                        item.timeIn != null
                            ? '${_timeFmt.format(item.timeIn!)} → ${item.timeOut != null ? _timeFmt.format(item.timeOut!) : '--:--'}'
                            : '--:-- → --:--',
                        style: TextStyle(
                          fontSize: 12,
                          color: subColor,
                          fontFamily: 'Satoshi',
                        ),
                      ),
                      const Spacer(),
                      // Request date
                      if (item.createAt != null)
                        Text(
                          _dateFmt.format(item.createAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: subColor,
                            fontFamily: 'Satoshi',
                          ),
                        ),
                    ],
                  ),

                  // Reason (if not empty)
                  if (item.reason.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.notes_rounded,
                            size: 13, color: subColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.reason,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: subColor,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Satoshi',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty / Error ─────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final bool isDark;
  final String message;
  const _EmptyView({required this.isDark, required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(Icons.inbox_rounded,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            fontFamily: 'Satoshi',
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final String retryLabel;
  final bool isDark;
  final VoidCallback onRetry;
  const _ErrorView({
    required this.message,
    required this.retryLabel,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 56,
              color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              fontFamily: 'Satoshi',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(retryLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

