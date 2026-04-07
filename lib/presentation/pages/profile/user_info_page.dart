import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/services/auth_service.dart';

// ─── Data holder ─────────────────────────────────────────────────────────────
class _UserInfo {
  final String? employeeId;
  final String? displayName;
  final String? email;
  final String? position;
  final String? department;

  const _UserInfo({
    this.employeeId,
    this.displayName,
    this.email,
    this.position,
    this.department,
  });

  /// Initials for avatar (e.g. "NC" from "Ngô Nhật Cường")
  String get initials {
    if (displayName == null || displayName!.isEmpty) return '?';
    final parts = displayName!.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  _UserInfo _info = const _UserInfo();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final employeeId  = await AuthService.getEmployeeId();
    final displayName = await AuthService.getDisplayName();
    final email       = await AuthService.getUserEmail();
    final position    = await AuthService.getPosition();
    final department  = await AuthService.getDepartment();
    setState(() {
      _info = _UserInfo(
        employeeId:  employeeId,
        displayName: displayName,
        email:       email,
        position:    position,
        department:  department,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = context.isDarkMode;
    final isVi       = Localizations.localeOf(context).languageCode == 'vi';
    final bg         = isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: _buildHeader(isDark, isVi, titleColor),
                ),
              ],
              body: Column(
                children: [
                  // ── Tab bar ─────────────────────────────────────────
                  _buildTabBar(isDark, isVi),
                  // ── Tab views ───────────────────────────────────────
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _PersonalInfoTab(info: _info, isDark: isDark, isVi: isVi),
                        _FamilyInfoTab(isDark: isDark, isVi: isVi),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Header: appbar + avatar + achievements ────────────────────────────────
  Widget _buildHeader(bool isDark, bool isVi, Color titleColor) {
    final cardBg  = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final subColor = isDark ? Colors.white54 : const Color(0xFF6B7280);

    return Container(
      color: cardBg,
      child: Column(
        children: [
          // AppBar area
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: titleColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      isVi ? 'Thông tin cá nhân' : 'My Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        // fontFamily: 'Satoshi',
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance back button
                ],
              ),
            ),
          ),

          // Avatar + name + email + position
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                // Avatar circle with initials
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF42C83C), Color(0xFF2EA82A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF42C83C).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _info.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        // fontFamily: 'Satoshi',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name + email + position
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _info.displayName ?? '---',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                                // fontFamily: 'Satoshi',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              size: 16, color: Color(0xFF42C83C)),
                        ],
                      ),
                      if (_info.email != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.email_outlined,
                                size: 13, color: subColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _info.email!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subColor,
                                  fontFamily: 'Satoshi',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_info.position != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.badge_outlined,
                                size: 13, color: subColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _info.position!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subColor,
                                  fontFamily: 'Satoshi',
                                ),
                                overflow: TextOverflow.ellipsis,
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

          // Achievements strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: isDark ? Colors.white10 : const Color(0xFFF0F1F3)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AchievementChip(
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFEF4444),
                  label: 'Thank You Note',
                  value: '0',
                  isDark: isDark,
                ),
                _AchievementChip(
                  emoji: '🐻',
                  label: 'Con Gấu',
                  value: '0',
                  isDark: isDark,
                ),
                _AchievementChip(
                  icon: Icons.emoji_emotions_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  label: 'Step Up Card',
                  value: '0',
                  isDark: isDark,
                ),
                _AchievementChip(
                  icon: Icons.military_tech_rounded,
                  iconColor: const Color(0xFF10B981),
                  label: isVi ? 'Tổng điểm' : 'Total Score',
                  value: '0',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar(bool isDark, bool isVi) {
    return Container(
      color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF42C83C),
        unselectedLabelColor:
            isDark ? Colors.white38 : const Color(0xFF9CA3AF),
        indicatorColor: const Color(0xFF42C83C),
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          // fontFamily: 'Satoshi',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          // fontFamily: 'Satoshi',
        ),
        tabs: [
          Tab(text: isVi ? 'THÔNG TIN CÁ NHÂN' : 'PERSONAL INFO'),
          Tab(text: isVi ? 'THÔNG TIN THÂN NHÂN' : 'FAMILY INFO'),
        ],
      ),
    );
  }
}

// ─── Achievement chip ─────────────────────────────────────────────────────────
class _AchievementChip extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final Color? iconColor;
  final String label;
  final String value;
  final bool isDark;

  const _AchievementChip({
    this.icon,
    this.emoji,
    this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final subColor = isDark ? Colors.white38 : const Color(0xFF9CA3AF);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (emoji != null)
          Text(emoji!, style: const TextStyle(fontSize: 22))
        else
          Icon(icon!, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827),
            // fontFamily: 'Satoshi',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: subColor,
            // fontFamily: 'Satoshi',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Personal Info Tab ────────────────────────────────────────────────────────
class _PersonalInfoTab extends StatelessWidget {
  final _UserInfo info;
  final bool isDark;
  final bool isVi;

  const _PersonalInfoTab({
    required this.info,
    required this.isDark,
    required this.isVi,
  });

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return ColoredBox(
      color: bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Thông tin cá nhân ────────────────────────────────────
          _InfoSection(
            icon: Icons.home_outlined,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF3B82F6),
            title: isVi ? 'Thông tin cá nhân' : 'Personal Information',
            isDark: isDark,
            cardBg: cardBg,
            rows: [
              _InfoRowData(
                label: isVi ? 'Mã số NV' : 'Employee ID',
                value: info.employeeId,
              ),
              _InfoRowData(
                label: isVi ? 'Họ và tên' : 'Full Name',
                value: info.displayName,
                highlight: true,
              ),
              _InfoRowData(
                label: isVi ? 'Ngày sinh' : 'Date of Birth',
                value: null,
              ),
              _InfoRowData(
                label: isVi ? 'CMND/CCCD' : 'National ID',
                value: null,
                masked: true,
              ),
              _InfoRowData(
                label: isVi ? 'Ngày cấp' : 'Issue Date',
                value: null,
              ),
              _InfoRowData(
                label: isVi ? 'Tình trạng hôn nhân' : 'Marital Status',
                value: null,
              ),
              _InfoRowData(
                label: isVi ? 'Dân tộc' : 'Ethnicity',
                value: null,
              ),
              _InfoRowData(
                label: isVi ? 'Quốc tịch' : 'Nationality',
                value: null,
              ),
              _InfoRowData(
                label: isVi ? 'Tôn giáo' : 'Religion',
                value: null,
              ),
              _InfoRowData(
                label: isVi ? 'Hộ chiếu' : 'Passport',
                value: null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Thông tin liên hệ ────────────────────────────────────
          _InfoSection(
            icon: Icons.phone_outlined,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            title: isVi ? 'Thông tin liên hệ' : 'Contact Information',
            isDark: isDark,
            cardBg: cardBg,
            rows: [
              _InfoRowData(
                label: isVi ? 'Điện thoại' : 'Phone',
                value: null,
                masked: true,
              ),
              _InfoRowData(
                label: isVi ? 'Địa chỉ tạm trú' : 'Current Address',
                value: null,
                multiline: true,
              ),
              _InfoRowData(
                label: isVi ? 'Địa chỉ thường trú' : 'Permanent Address',
                value: null,
                multiline: true,
              ),
              _InfoRowData(
                label: isVi ? 'Nguyên quán' : 'Hometown',
                value: null,
              ),
              _InfoRowData(
                label: isVi ? 'Email cá nhân' : 'Personal Email',
                value: null,
                masked: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Thông tin công việc ──────────────────────────────────
          _InfoSection(
            icon: Icons.work_outline_rounded,
            iconBg: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFF59E0B),
            title: isVi ? 'Thông tin công việc' : 'Work Information',
            isDark: isDark,
            cardBg: cardBg,
            rows: [
              _InfoRowData(
                label: isVi ? 'Ngày vào làm' : 'Join Date',
                value: null,
              ),
              _InfoRowData(
                label: isVi ? 'Phòng ban' : 'Department',
                value: info.department,
                highlight: true,
              ),
              _InfoRowData(
                label: isVi ? 'Chức vụ' : 'Position',
                value: info.position,
                highlight: true,
              ),
              _InfoRowData(
                label: isVi ? 'Số tài khoản' : 'Bank Account',
                value: null,
                masked: true,
              ),
              _InfoRowData(
                label: isVi ? 'Tên ngân hàng' : 'Bank Name',
                value: null,
              ),
              _InfoRowData(
                label: isVi ? 'Mã số thuế' : 'Tax Code',
                value: null,
                masked: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Family Info Tab ──────────────────────────────────────────────────────────
class _FamilyInfoTab extends StatelessWidget {
  final bool isDark;
  final bool isVi;

  const _FamilyInfoTab({required this.isDark, required this.isVi});

  @override
  Widget build(BuildContext context) {
    final subColor = isDark ? Colors.white38 : const Color(0xFF9CA3AF);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.family_restroom_rounded,
              size: 60,
              color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            isVi
                ? 'Thông tin thân nhân chưa khả dụng'
                : 'Family info not available yet',
            style: TextStyle(
              fontSize: 14,
              color: subColor,
              fontFamily: 'Satoshi',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section widget ───────────────────────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final bool isDark;
  final Color cardBg;
  final List<_InfoRowData> rows;

  const _InfoSection({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.isDark,
    required this.cardBg,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final divider = isDark ? Colors.white10 : const Color(0xFFF3F4F6);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    // fontFamily: 'Satoshi',
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: divider),

          // Rows
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return Column(
              children: [
                _InfoRowWidget(
                    data: e.value, isDark: isDark, isLast: isLast),
                if (!isLast) Divider(height: 1, color: divider),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Row data model ───────────────────────────────────────────────────────────
class _InfoRowData {
  final String label;
  final String? value;
  final bool highlight;
  final bool masked;
  final bool multiline;

  const _InfoRowData({
    required this.label,
    required this.value,
    this.highlight = false,
    this.masked = false,
    this.multiline = false,
  });
}

// ─── Row widget ───────────────────────────────────────────────────────────────
class _InfoRowWidget extends StatelessWidget {
  final _InfoRowData data;
  final bool isDark;
  final bool isLast;

  const _InfoRowWidget({
    required this.data,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final valueColor = data.highlight
        ? const Color(0xFF2563EB) // blue for highlight (like web)
        : (isDark ? Colors.white : const Color(0xFF111827));
    final emptyColor = isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFD1D5DB);

    final displayValue = data.value?.isNotEmpty == true
        ? (data.masked && data.value != null ? '••••••••' : data.value!)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: data.multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          // Label
          SizedBox(
            width: 130,
            child: Text(
              data.label,
              style: TextStyle(
                fontSize: 12,
                color: labelColor,
                // fontFamily: 'Satoshi',
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Value
          Expanded(
            child: displayValue != null
                ? Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                      // fontFamily: 'Satoshi',
                    ),
                    maxLines: data.multiline ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Container(
                    height: 2,
                    width: 24,
                    color: emptyColor,
                  ),
          ),
        ],
      ),
    );
  }
}

