import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/data/models/notification/notification_model.dart';
import 'package:flutter_core_project/domain/repository/notification/notification_repository.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_bloc.dart';
import 'package:flutter_core_project/presentation/pages/timesheet/timesheet_page.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:intl/intl.dart';

// ─── Notification Type từ MessageType string ──────────────────────────────────
enum NotificationType {
  timesheet,    // TIMESHEET
  leaveRequest, // LEAVE
  payroll,      // PAYROLL
  announcement, // ANNOUNCEMENT
  warning,      // WARNING
  system,       // SYSTEM
  birthday,     // BIRTHDAY
}

NotificationType _typeFromString(String raw) {
  switch (raw.toUpperCase()) {
    case 'TIMESHEET':    return NotificationType.timesheet;
    case 'LEAVE':        return NotificationType.leaveRequest;
    case 'PAYROLL':      return NotificationType.payroll;
    case 'ANNOUNCEMENT': return NotificationType.announcement;
    case 'WARNING':      return NotificationType.warning;
    case 'SYSTEM':       return NotificationType.system;
    case 'BIRTHDAY':     return NotificationType.birthday;
    default:             return NotificationType.system;
  }
}

// ─── View-model dùng trong UI, map từ NotificationModel ──────────────────────
class NotificationItem {
  final int id;        // API Id
  final NotificationType type;
  final String title;
  final String content;
  final DateTime time;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.time,
    required this.isRead,
  });

  factory NotificationItem.fromModel(NotificationModel m) => NotificationItem(
        id: m.id,
        type: _typeFromString(m.messageType),
        title: m.messageTitle,
        content: m.message,
        time: m.created,
        isRead: m.isRead,
      );

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        type: type,
        title: title,
        content: content,
        time: time,
        isRead: isRead ?? this.isRead,
      );
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const int _pageSize = 10;

  final NotificationRepository _repo = sl<NotificationRepository>();

  final List<NotificationItem> _items = [];

  bool _isLoadingMore = false;
  bool _isFirstLoad = true;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalFromApi = 0;

  // Số lượng unread thật từ API /UnreadCount
  int _unreadCountFromApi = 0;

  final ScrollController _scrollController = ScrollController();

  // Filter: null = ALL, false = UNREAD, true = READ
  bool? _filterRead;

  String get _apiMode {
    if (_filterRead == null) return 'ALL';
    return _filterRead! ? 'READ' : 'UNREAD';
  }

  @override
  void initState() {
    super.initState();
    _fetchPage(reset: true);
    _fetchUnreadCount();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Fetch unread count from dedicated API ────────────────────────────────
  Future<void> _fetchUnreadCount() async {
    final count = await _repo.getUnreadCount();
    if (!mounted) return;
    setState(() => _unreadCountFromApi = count);
  }

  // ── Fetch from API ────────────────────────────────────────────────────────
  Future<void> _fetchPage({bool reset = false}) async {
    if (_isLoadingMore) return;
    if (!reset && !_hasMore) {
      _showNoMoreToast();
      return;
    }

    setState(() => _isLoadingMore = true);

    final page = reset ? 1 : _currentPage;

    final result = await _repo.getMessages(
      mode: _apiMode,
      page: page,
      pageSize: _pageSize,
    );

    if (!mounted) return;

    final newItems = result.items.map(NotificationItem.fromModel).toList();

    setState(() {
      if (reset) {
        _items
          ..clear()
          ..addAll(newItems);
        _currentPage = 2;
      } else {
        _items.addAll(newItems);
        _currentPage = page + 1;
      }
      _totalFromApi = result.total;
      // Dừng load more khi số item trả về < pageSize (trang cuối)
      _hasMore = newItems.length >= _pageSize;
      _isLoadingMore = false;
      _isFirstLoad = false;
    });
  }

  void _showNoMoreToast() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_none_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              context.tr('notification_no_more'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF374151),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      if (!_hasMore && !_isFirstLoad && !_isLoadingMore && _items.isNotEmpty) {
        _showNoMoreToast();
      } else {
        _fetchPage();
      }
    }
  }

  // ── Apply filter ──────────────────────────────────────────────────────────
  void _applyFilter(bool? value) {
    if (_filterRead == value) return;
    setState(() {
      _filterRead = value;
      _isFirstLoad = true;
    });
    _fetchPage(reset: true);
  }

  // ── Mark all read (optimistic UI + API) ──────────────────────────────────
  Future<void> _markAllRead() async {
    final unreadIds = _items
        .where((e) => !e.isRead)
        .map((e) => e.id)
        .toList();

    // Optimistic update
    setState(() {
      for (int i = 0; i < _items.length; i++) {
        if (!_items[i].isRead) {
          _items[i] = _items[i].copyWith(isRead: true);
        }
      }
      _unreadCountFromApi = 0;
    });

    // Fire API calls concurrently
    await Future.wait(unreadIds.map((id) => _repo.markAsRead(id: id)));

    // Sync real count from server
    _fetchUnreadCount();
  }

  // ── Mark single read ──────────────────────────────────────────────────────
  Future<void> _markRead(NotificationItem item) async {
    if (item.isRead) return;

    // Optimistic update
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      setState(() {
        _items[idx] = _items[idx].copyWith(isRead: true);
        if (_unreadCountFromApi > 0) _unreadCountFromApi--;
      });
    }

    // API call then re-sync
    await _repo.markAsRead(id: item.id);
    _fetchUnreadCount();
  }

  Future<void> _openTimesheetFromNotification(NotificationItem item) async {
    await _markRead(item);
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<RemoteTimesheetBloc>.value(
          value: sl<RemoteTimesheetBloc>(),
          child: const TimesheetPage(showBackButton: true),
        ),
      ),
    );
  }

  // Badge count: dùng số từ API /UnreadCount (chính xác hơn)
  int get _unreadBadge => _unreadCountFromApi;
  // Đếm local để cập nhật optimistic trong filter chips
  int get _unreadCountLocal => _items.where((e) => !e.isRead).length;
  int get _readCount        => _items.where((e) => e.isRead).length;

  // ── Total counts for filter chips ────────────────────────────────────────
  int get _totalCount => _totalFromApi;

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF5F5F5);
    final appBarBg = isDark ? const Color(0xFF242424) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ──────────────────────────────────────────────────
            _buildAppBar(isDark, appBarBg, titleColor, borderColor),

            // ── Filter tabs ─────────────────────────────────────────────
            _buildFilterRow(isDark, appBarBg, borderColor),

            // ── List ────────────────────────────────────────────────────
            Expanded(
              child: _isFirstLoad
                  ? _buildLoadingFull()
                  : (_items.isEmpty && !_isLoadingMore
                      ? _buildEmpty(isDark)
                      : RefreshIndicator(
                          color: const Color(0xFF42C83C),
                          onRefresh: () async {
                            await _fetchPage(reset: true);
                            _fetchUnreadCount();
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            itemCount: _items.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i == _items.length) {
                                return _buildLoadingIndicator();
                              }
                              return _NotificationItemWidget(
                                item: _items[i],
                                isDark: isDark,
                                onTap: () => _openTimesheetFromNotification(_items[i]),
                              );
                            },
                          ),
                        )),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar(
    bool isDark,
    Color appBarBg,
    Color titleColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      decoration: BoxDecoration(
        color: appBarBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: titleColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  'Thông báo',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                if (_unreadBadge > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_unreadBadge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Mark all read button
          if (_unreadBadge > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all_rounded,
                  size: 15, color: Color(0xFF42C83C)),
              label: Text(
                context.tr('notification_mark_all_read'),
                style: const TextStyle(
                  color: Color(0xFF42C83C),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  // ── Filter row ─────────────────────────────────────────────────────────────
  Widget _buildFilterRow(bool isDark, Color appBarBg, Color borderColor) {
    return Container(
      color: appBarBg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          _FilterChip(
            label: 'Tất cả',
            count: _totalFromApi,
            isSelected: _filterRead == null,
            isDark: isDark,
            onTap: () => _applyFilter(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Chưa đọc',
            count: _unreadBadge,
            isSelected: _filterRead == false,
            isDark: isDark,
            onTap: () => _applyFilter(false),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Đã đọc',
            count: _readCount,
            isSelected: _filterRead == true,
            isDark: isDark,
            onTap: () => _applyFilter(true),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 60,
              color: isDark ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            context.tr('notification_empty'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  // ── Full-screen loading (lần đầu) ─────────────────────────────────────────
  Widget _buildLoadingFull() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: Color(0xFF42C83C),
      ),
    );
  }

  // ── Loading indicator (pagination) ────────────────────────────────────────
  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFF42C83C),
          ),
        ),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF42C83C);
    final bg = isSelected
        ? primary.withOpacity(isDark ? 0.2 : 0.1)
        : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6));
    final borderC = isSelected
        ? primary.withOpacity(0.6)
        : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB));
    final textC = isSelected
        ? primary
        : (isDark ? Colors.grey[400]! : const Color(0xFF6B7280));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderC, width: isSelected ? 1.2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textC,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withOpacity(0.15)
                    : (isDark
                        ? const Color(0xFF3A3A3A)
                        : Colors.grey[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? primary : textC,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notification Item Widget ─────────────────────────────────────────────────
class _NotificationItemWidget extends StatelessWidget {
  final NotificationItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationItemWidget({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  // ── Icon config per type ──────────────────────────────────────────────────
  static _IconConfig _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.timesheet:
        return const _IconConfig(
          icon: Icons.calendar_month_rounded,
          bg: Color(0xFF42C83C),
        );
      case NotificationType.leaveRequest:
        return const _IconConfig(
          icon: Icons.event_available_rounded,
          bg: Color(0xFF2196F3),
        );
      case NotificationType.payroll:
        return const _IconConfig(
          icon: Icons.payments_rounded,
          bg: Color(0xFF10B981),
        );
      case NotificationType.announcement:
        return const _IconConfig(
          icon: Icons.campaign_rounded,
          bg: Color(0xFFF59E0B),
        );
      case NotificationType.warning:
        return const _IconConfig(
          icon: Icons.warning_amber_rounded,
          bg: Color(0xFFEF4444),
        );
      case NotificationType.system:
        return const _IconConfig(
          icon: Icons.settings_rounded,
          bg: Color(0xFF8B5CF6),
        );
      case NotificationType.birthday:
        return const _IconConfig(
          icon:  Icons.cake_rounded,
          bg: Color(0xFFEC4899),
        );
    }
  }

  // ── Time format ───────────────────────────────────────────────────────────
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _iconFor(item.type);

    final unreadBg = isDark
        ? const Color(0xFF1E2A1E)
        : const Color(0xFFF0FDF4);
    final readBg = isDark ? const Color(0xFF242424) : Colors.white;
    final bg = item.isRead ? readBg : unreadBg;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final contentColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final timeColor =
        isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead
                ? borderColor
                : const Color(0xFF42C83C).withOpacity(0.25),
            width: item.isRead ? 1 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ──────────────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cfg.bg.withOpacity(isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cfg.icon, color: cfg.bg, size: 22),
              ),
              const SizedBox(width: 12),

              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row + unread dot
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: titleColor,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Unread dot
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.isRead
                                  ? (isDark
                                      ? const Color(0xFF3A3A3A)
                                      : const Color(0xFFE5E7EB))
                                  : const Color(0xFF42C83C),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Content
                    Text(
                      item.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: contentColor,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Time + Type badge
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 11, color: timeColor),
                        const SizedBox(width: 3),
                        Text(
                          _formatTime(item.time),
                          style:
                              TextStyle(fontSize: 11, color: timeColor),
                        ),
                        const Spacer(),
                        // Type label badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                cfg.bg.withOpacity(isDark ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _typeLabel(item.type),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: cfg.bg,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.timesheet:    return 'Bảng công';
      case NotificationType.leaveRequest: return 'Nghỉ phép';
      case NotificationType.payroll:      return 'Lương';
      case NotificationType.announcement: return 'Thông báo';
      case NotificationType.warning:      return 'Cảnh báo';
      case NotificationType.system:       return 'Hệ thống';
      case NotificationType.birthday:     return 'Sinh nhật';
    }
  }
}

// ─── Icon config helper ────────────────────────────────────────────────────────
class _IconConfig {
  final IconData icon;
  final Color bg;
  const _IconConfig({required this.icon, required this.bg});
}
