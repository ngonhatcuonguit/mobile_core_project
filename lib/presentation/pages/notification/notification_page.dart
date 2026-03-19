import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
enum NotificationType {
  timesheet,    // Bảng công
  leaveRequest, // Đơn nghỉ phép
  payroll,      // Lương
  announcement, // Thông báo chung
  warning,      // Cảnh báo
  system,       // Hệ thống
  birthday,     // Sinh nhật
}

class NotificationItem {
  final String id;
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

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        type: type,
        title: title,
        content: content,
        time: time,
        isRead: isRead ?? this.isRead,
      );
}

// ─── Mock Data (public — dùng chung với HomePage badge count) ────────────────
final DateTime _now = DateTime.now();

final List<NotificationItem> mockNotifications = [
  NotificationItem(
    id: '1',
    type: NotificationType.timesheet,
    title: 'Bảng công tháng 3/2026 đã được duyệt',
    content: 'Bảng công tháng 3 năm 2026 của bạn đã được HR xác nhận và duyệt thành công. Vui lòng kiểm tra lại thông tin.',
    time: _now.subtract(const Duration(minutes: 5)),
    isRead: false,
  ),
  NotificationItem(
    id: '2',
    type: NotificationType.leaveRequest,
    title: 'Đơn xin nghỉ phép đã được phê duyệt',
    content: 'Đơn xin nghỉ phép từ ngày 20/03/2026 đến 22/03/2026 của bạn đã được quản lý phê duyệt.',
    time: _now.subtract(const Duration(hours: 1)),
    isRead: false,
  ),
  NotificationItem(
    id: '3',
    type: NotificationType.payroll,
    title: 'Phiếu lương tháng 2/2026 đã sẵn sàng',
    content: 'Phiếu lương tháng 2 năm 2026 đã được tải lên hệ thống. Bạn có thể xem chi tiết trong mục tài chính.',
    time: _now.subtract(const Duration(hours: 3)),
    isRead: false,
  ),
  NotificationItem(
    id: '4',
    type: NotificationType.warning,
    title: 'Cảnh báo: Quét vân tay không thành công ngày 17/03',
    content: 'Hệ thống ghi nhận bạn chưa quét vân tay vào ngày 17/03/2026. Vui lòng liên hệ HR để điều chỉnh.',
    time: _now.subtract(const Duration(hours: 6)),
    isRead: false,
  ),
  NotificationItem(
    id: '5',
    type: NotificationType.announcement,
    title: 'Thông báo nghỉ lễ Giỗ Tổ Hùng Vương 2026',
    content: 'Công ty thông báo nghỉ lễ Giỗ Tổ Hùng Vương vào ngày 18/04/2026 (âm lịch 10/3). Toàn thể nhân viên được nghỉ.',
    time: _now.subtract(const Duration(days: 1)),
    isRead: true,
  ),
  NotificationItem(
    id: '6',
    type: NotificationType.birthday,
    title: 'Chúc mừng sinh nhật đồng nghiệp!',
    content: 'Hôm nay là sinh nhật của Trần Thị Mai - Phòng Kế toán. Hãy gửi lời chúc đến đồng nghiệp nhé!',
    time: _now.subtract(const Duration(days: 1, hours: 2)),
    isRead: true,
  ),
  NotificationItem(
    id: '7',
    type: NotificationType.leaveRequest,
    title: 'Đơn xin nghỉ phép yêu cầu bổ sung thông tin',
    content: 'Đơn xin nghỉ phép ngày 25/03/2026 của bạn cần bổ sung lý do cụ thể hơn. Vui lòng cập nhật và gửi lại.',
    time: _now.subtract(const Duration(days: 2)),
    isRead: true,
  ),
  NotificationItem(
    id: '8',
    type: NotificationType.system,
    title: 'Hệ thống bảo trì định kỳ',
    content: 'Hệ thống sẽ bảo trì từ 22:00 đến 24:00 ngày 20/03/2026. Trong thời gian này một số chức năng có thể bị gián đoạn.',
    time: _now.subtract(const Duration(days: 3)),
    isRead: true,
  ),
  NotificationItem(
    id: '9',
    type: NotificationType.timesheet,
    title: 'Nhắc nhở: Xác nhận bảng công tháng 2/2026',
    content: 'Bạn chưa xác nhận bảng công tháng 2 năm 2026. Hạn chót xác nhận là ngày 05/03/2026.',
    time: _now.subtract(const Duration(days: 5)),
    isRead: true,
  ),
  NotificationItem(
    id: '10',
    type: NotificationType.payroll,
    title: 'Thưởng Tết Nguyên Đán 2026 đã được chuyển',
    content: 'Thưởng Tết Nguyên Đán 2026 đã được chuyển vào tài khoản của bạn. Vui lòng kiểm tra tài khoản ngân hàng.',
    time: _now.subtract(const Duration(days: 7)),
    isRead: true,
  ),
  NotificationItem(
    id: '11',
    type: NotificationType.announcement,
    title: 'Cập nhật chính sách phúc lợi nhân viên năm 2026',
    content: 'Công ty đã cập nhật chính sách phúc lợi cho năm 2026 bao gồm tăng mức phép năm và bổ sung bảo hiểm sức khỏe.',
    time: _now.subtract(const Duration(days: 10)),
    isRead: true,
  ),
  NotificationItem(
    id: '12',
    type: NotificationType.warning,
    title: 'Cảnh báo: Số ngày phép còn lại sắp hết',
    content: 'Bạn chỉ còn 1.14 ngày phép cho năm 2026. Vui lòng cân nhắc khi đăng ký nghỉ phép trong thời gian tới.',
    time: _now.subtract(const Duration(days: 12)),
    isRead: true,
  ),
  NotificationItem(
    id: '13',
    type: NotificationType.system,
    title: 'Tính năng mới: Báo cáo điều chỉnh bảng công',
    content: 'Ứng dụng đã cập nhật tính năng báo cáo điều chỉnh bảng công. Bạn có thể gửi yêu cầu điều chỉnh trực tiếp từ ứng dụng.',
    time: _now.subtract(const Duration(days: 14)),
    isRead: true,
  ),
  NotificationItem(
    id: '14',
    type: NotificationType.birthday,
    title: 'Chúc mừng sinh nhật Nguyễn Văn An!',
    content: 'Hôm nay là sinh nhật của Nguyễn Văn An - Trưởng phòng IT. Hãy gửi lời chúc tốt đẹp nhé!',
    time: _now.subtract(const Duration(days: 15)),
    isRead: true,
  ),
  NotificationItem(
    id: '15',
    type: NotificationType.leaveRequest,
    title: 'Đơn xin nghỉ phép tháng 1 đã bị từ chối',
    content: 'Đơn xin nghỉ phép từ ngày 15/01/2026 đến 16/01/2026 đã bị từ chối do trùng với thời gian cao điểm công việc.',
    time: _now.subtract(const Duration(days: 18)),
    isRead: true,
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const int _pageSize = 6;

  late List<NotificationItem> _allItems;
  final List<NotificationItem> _displayedItems = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // Filter: null = all, true = unread, false = read
  bool? _filterRead;

  @override
  void initState() {
    super.initState();
    _allItems = List.from(mockNotifications);
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Filtered source ───────────────────────────────────────────────────────
  List<NotificationItem> get _filtered {
    if (_filterRead == null) return _allItems;
    return _allItems.where((e) => e.isRead == _filterRead).toList();
  }

  // ── Load more ─────────────────────────────────────────────────────────────
  void _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final source = _filtered;
    final start = _displayedItems.length;
    final end = (start + _pageSize).clamp(0, source.length);

    setState(() {
      _displayedItems.addAll(source.sublist(start, end));
      _hasMore = end < source.length;
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      _loadMore();
    }
  }

  // ── Apply filter ──────────────────────────────────────────────────────────
  void _applyFilter(bool? value) {
    setState(() {
      _filterRead = value;
      _displayedItems.clear();
      _hasMore = true;
    });
    _loadMore();
  }

  // ── Mark all read ─────────────────────────────────────────────────────────
  void _markAllRead() {
    setState(() {
      _allItems = _allItems.map((e) => e.copyWith(isRead: true)).toList();
      _displayedItems.clear();
      _hasMore = true;
    });
    _loadMore();
  }

  // ── Mark single read ──────────────────────────────────────────────────────
  void _markRead(String id) {
    final idx = _allItems.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    setState(() {
      _allItems[idx] = _allItems[idx].copyWith(isRead: true);
      final di = _displayedItems.indexWhere((e) => e.id == id);
      if (di != -1) {
        _displayedItems[di] = _displayedItems[di].copyWith(isRead: true);
      }
    });
  }

  int get _unreadCount => _allItems.where((e) => !e.isRead).length;

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF5F5F5);
    final appBarBg = isDark ? const Color(0xFF242424) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);

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
              child: _displayedItems.isEmpty && !_isLoadingMore
                  ? _buildEmpty(isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount:
                          _displayedItems.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i == _displayedItems.length) {
                          return _buildLoadingIndicator();
                        }
                        return _NotificationItemWidget(
                          item: _displayedItems[i],
                          isDark: isDark,
                          onTap: () => _markRead(_displayedItems[i].id),
                        );
                      },
                    ),
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
                if (_unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_unreadCount',
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
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all_rounded,
                  size: 15, color: Color(0xFF42C83C)),
              label: const Text(
                'Đọc tất cả',
                style: TextStyle(
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
  Widget _buildFilterRow(
      bool isDark, Color appBarBg, Color borderColor) {
    return Container(
      color: appBarBg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          _FilterChip(
            label: 'Tất cả',
            count: _allItems.length,
            isSelected: _filterRead == null,
            isDark: isDark,
            onTap: () => _applyFilter(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Chưa đọc',
            count: _allItems.where((e) => !e.isRead).length,
            isSelected: _filterRead == false,
            isDark: isDark,
            onTap: () => _applyFilter(false),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Đã đọc',
            count: _allItems.where((e) => e.isRead).length,
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
            'Không có thông báo',
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

  // ── Loading indicator ──────────────────────────────────────────────────────
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
        return _IconConfig(
          icon: Icons.calendar_month_rounded,
          bg: const Color(0xFF42C83C),
        );
      case NotificationType.leaveRequest:
        return _IconConfig(
          icon: Icons.event_available_rounded,
          bg: const Color(0xFF2196F3),
        );
      case NotificationType.payroll:
        return _IconConfig(
          icon: Icons.payments_rounded,
          bg: const Color(0xFF10B981),
        );
      case NotificationType.announcement:
        return _IconConfig(
          icon: Icons.campaign_rounded,
          bg: const Color(0xFFF59E0B),
        );
      case NotificationType.warning:
        return _IconConfig(
          icon: Icons.warning_amber_rounded,
          bg: const Color(0xFFEF4444),
        );
      case NotificationType.system:
        return _IconConfig(
          icon: Icons.settings_rounded,
          bg: const Color(0xFF8B5CF6),
        );
      case NotificationType.birthday:
        return _IconConfig(
          icon: Icons.cake_rounded,
          bg: const Color(0xFFEC4899),
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

    // Background colors
    final unreadBg = isDark
        ? const Color(0xFF1E2A1E)   // dark green tint for unread
        : const Color(0xFFF0FDF4);  // light green tint for unread
    final readBg = isDark
        ? const Color(0xFF242424)
        : Colors.white;

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
                child: Icon(
                  cfg.icon,
                  color: cfg.bg,
                  size: 22,
                ),
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
                          style: TextStyle(fontSize: 11, color: timeColor),
                        ),
                        const Spacer(),
                        // Type label badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cfg.bg.withOpacity(isDark ? 0.15 : 0.1),
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

