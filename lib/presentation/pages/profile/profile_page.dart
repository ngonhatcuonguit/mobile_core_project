import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/core/configs/assets/app_vectors.dart';
import 'package:flutter_core_project/presentation/choose_mode/bloc/locale_cubit.dart';
import 'package:flutter_core_project/presentation/choose_mode/bloc/theme_cubit.dart';
import 'package:flutter_core_project/presentation/intro/pages/get_started.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    setState(() {
      _userName = name;
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
          'Profile',
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
              title: 'Settings',
              iconColor: const Color(0xFFB1B1B1),
              onTap: () {
                // Navigate to Settings
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
              title: 'Notification',
              iconColor: const Color(0xFF1B94A1),
              onTap: () {
                // Navigate to Notification
              },
              isDark: isDark,
            ),
            _buildMenuItem(
              context,
              icon: AppVectors.icOrderHistory,
              title: 'Order History',
              iconColor: const Color(0xFFFD9F12),
              onTap: () {
                // Navigate to Order History
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Account',
                  style: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: AppVectors.icPrivacy,
              title: 'Privacy & Policy',
              iconColor: const Color(0xFF008BD9),
              onTap: () {
                // Navigate to Privacy & Policy
              },
              isDark: isDark,
            ),
            _buildMenuItem(
              context,
              icon: AppVectors.icTerms,
              title: 'Terms & Conditions',
              iconColor: const Color(0xFFFFCC47),
              onTap: () {
                // Navigate to Terms & Conditions
              },
              isDark: isDark,
            ),
            _buildMenuItem(
              context,
              icon: AppVectors.icLogout,
              title: 'Log Out',
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

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF44545),
            ),
            child: const Text('Logout'),
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
          'Settings',
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
                'Appearance',
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
                'Language',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _buildLanguageSelector(isDark),
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
            'Theme Mode',
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
                  title: 'Light',
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
                  title: 'Dark',
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
            'App Language',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildLanguageOption(
            title: 'English',
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
            title: 'Tiếng Việt',
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
