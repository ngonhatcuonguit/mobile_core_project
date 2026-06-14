import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/core/configs/assets/app_vectors.dart';
import 'package:flutter_core_project/presentation/choose_mode/bloc/locale_cubit.dart';
import 'package:flutter_core_project/presentation/choose_mode/bloc/theme_cubit.dart';
import 'package:flutter_core_project/presentation/intro/pages/get_started.dart';
import 'package:flutter_core_project/presentation/pages/notification/notification_page.dart';
import 'package:flutter_core_project/presentation/pages/profile/user_info_page.dart';
import 'package:flutter_core_project/presentation/pages/profile/terms_of_service_page.dart';
import 'package:flutter_core_project/presentation/pages/request_history/request_history_page.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

final Uri _androidStoreUrl = Uri.parse(
  'https://play.google.com/store/apps/details?id=com.digital.thp.my_thp&pli=1',
);
final Uri _iosStoreUrl = Uri.parse(
  'https://apps.apple.com/us/app/my-thp/id6761755105',
);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await AuthService.getUserName();
    final email = await AuthService.getUserEmail();
    final displayName = await AuthService.getDisplayName();
    setState(() {
      _userName = displayName ?? name; // Ưu tiên hiển thị displayname từ API
      _userEmail = email;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // leading: IconButton(
        //   icon: Icon(
        //     Icons.arrow_back_ios,
        //     color: isDark ? Colors.white : Colors.black,
        //   ),
        //   onPressed: () => Navigator.pop(context),
        // ),
        title: Text(
          context.tr('profile_title'),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Avatar & Info
            _buildProfileHeader(isDark),
            const SizedBox(height: 32),
            // Menu Items
            _buildMenuItem(
              context,
              icon: AppVectors.icSettings,
              title: context.tr('profile_settings'),
              iconColor: const Color(0xFFB1B1B1),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
              isDark: isDark,
            ),
            _buildMenuItem(
              context,
              icon: AppVectors.icNotification,
              title: context.tr('profile_notification'),
              iconColor: const Color(0xFF1B94A1),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationPage(),
                  ),
                );
              },
              isDark: isDark,
            ),
            // _buildMenuItem(
            //   context,
            //   icon: AppVectors.icOrderHistory,
            //   title: context.tr('profile_account'),
            //   iconColor: const Color(0xFF6366F1),
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (_) => const UserInfoPage(),
            //       ),
            //     );
            //   },
            //   isDark: isDark,
            // ),
            _buildMenuItem(
              context,
              icon: AppVectors.icOrderHistory,
              title: context.tr('profile_order_history'),
              iconColor: const Color(0xFFFD9F12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RequestHistoryPage(),
                  ),
                );
              },
              isDark: isDark,
            ),
            _buildMenuItem(
              context,
              icon: AppVectors.icUpdate,
              title: context.tr('profile_update'),
              iconColor: const Color(0xFF42C83C),
              onTap: _openStoreUpdate,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr('profile_account'),
                  style: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            _buildMenuItem(
              context,
              icon: AppVectors.icTerms,
              title: context.tr('profile_account'),
              iconColor: const Color(0xFF6366F1),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserInfoPage(),
                  ),
                );
              },
              isDark: isDark,
            ),
            _buildMenuItem(
              context,
              icon: AppVectors.icPrivacy,
              title: context.tr('profile_terms'),
              iconColor: const Color(0xFF008BD9),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermsOfServicePage(),
                  ),
                );
              },
              isDark: isDark,
            ),
            _buildMenuItem(
              context,
              icon: AppVectors.icLogout,
              title: context.tr('profile_logout'),
              iconColor: const Color(0xFFF44545),
              onTap: () => _handleLogout(context),
              isDark: isDark,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Column(
      children: [
        // Avatar with decorative elements
        Stack(
          alignment: Alignment.center,
          children: [
            // Decorative green dots
            Positioned(
              top: 0,
              left: 120,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF42C83C),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 100,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF42C83C),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF42C83C),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  width: 4,
                ),
              ),
              child: const Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            // Decorative black dots
            Positioned(
              bottom: 10,
              left: 90,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 110,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Email
        Text(
          _userEmail ?? 'user@email.com',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        // Username
        Text(
          _userName ?? 'Username',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SvgPicture.asset(
                  icon,
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStoreUpdate() async {
    final uri = defaultTargetPlatform == TargetPlatform.iOS
        ? _iosStoreUrl
        : _androidStoreUrl;

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('profile_update_open_failed'))),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('profile_logout_title')),
        content: Text(context.tr('profile_logout_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('profile_logout_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF44545),
            ),
            child: Text(context.tr('profile_logout')),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await AuthService.logout();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const GetStartedPage()),
        (route) => false,
      );
    }
  }
}

// Settings Page
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('settings_title'),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Mode Section
              Text(
                context.tr('settings_appearance'),
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _buildThemeSelector(isDark),
              const SizedBox(height: 32),

              // Language Section
              Text(
                context.tr('settings_app_language'),
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _buildLanguageSelector(isDark),
              const SizedBox(height: 32),

              Text(
                context.tr('profile_update'),
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _buildUpdateOption(isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('settings_theme_mode'),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  icon: Icons.light_mode,
                  title: context.tr('settings_light'),
                  isSelected: !isDark,
                  onTap: () {
                    context.read<ThemeCubit>().updateTheme(ThemeMode.light);
                  },
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildThemeOption(
                  icon: Icons.dark_mode,
                  title: context.tr('settings_dark'),
                  isSelected: isDark,
                  onTap: () {
                    context.read<ThemeCubit>().updateTheme(ThemeMode.dark);
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF42C83C).withOpacity(0.1)
              : (isDark ? const Color(0xFF1C1C1C) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF42C83C)
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF42C83C)
                  : (isDark ? Colors.grey[600] : Colors.grey[500]),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF42C83C)
                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateOption(bool isDark) {
    return GestureDetector(
      onTap: _openStoreUpdate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF42C83C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SvgPicture.asset(
                  AppVectors.icUpdate,
                  width: 22,
                  height: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr('profile_update'),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStoreUpdate() async {
    final uri = defaultTargetPlatform == TargetPlatform.iOS
        ? _iosStoreUrl
        : _androidStoreUrl;

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('profile_update_open_failed'))),
      );
    }
  }

  Widget _buildLanguageSelector(bool isDark) {
    final currentLocale = context.read<LocaleCubit>().state.languageCode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('settings_app_language'),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildLanguageOption(
            title: context.tr('english'),
            code: 'EN',
            isSelected: currentLocale == 'en',
            onTap: () {
              context.read<LocaleCubit>().changeLocale('en');
              setState(() {});
            },
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildLanguageOption(
            title: context.tr('vietnamese'),
            code: 'VI',
            isSelected: currentLocale == 'vi',
            onTap: () {
              context.read<LocaleCubit>().changeLocale('vi');
              setState(() {});
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String code,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF42C83C).withOpacity(0.1)
              : (isDark ? const Color(0xFF1C1C1C) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF42C83C)
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF42C83C)
                    : (isDark ? Colors.grey[800] : Colors.grey[300]),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  code,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey[400] : Colors.grey[700]),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF42C83C)
                      : (isDark ? Colors.white : Colors.black),
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF42C83C),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
