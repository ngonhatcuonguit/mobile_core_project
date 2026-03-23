import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/assets/app_vectors.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_bloc.dart';
import 'package:flutter_core_project/presentation/pages/home/home_page.dart';
import 'package:flutter_core_project/presentation/pages/leave_request/leave_request_page.dart';
import 'package:flutter_core_project/presentation/pages/timesheet/timesheet_page.dart';
import 'package:flutter_core_project/presentation/pages/profile/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      BlocProvider<RemoteTimesheetBloc>.value(
        value: sl<RemoteTimesheetBloc>(),
        child: const TimesheetPage(),
      ),
      const LeaveRequestPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1C1C1C) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor:
                isDarkMode ? const Color(0xFF1C1C1C) : Colors.white,
            selectedItemColor: const Color(0xFF42C83C),
            unselectedItemColor:
                isDarkMode ? Colors.grey[600] : Colors.grey[400],
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Satoshi',
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontFamily: 'Satoshi',
            ),
            elevation: 0,
            items: [
              _buildNavItem(
                activeIcon: AppVectors.icHomeActive,
                inactiveIcon: AppVectors.icHome,
                label: 'Trang chủ',
                isActive: _currentIndex == 0,
                isDark: isDarkMode,
              ),
              _buildNavItem(
                activeIcon: AppVectors.icDelivery,
                inactiveIcon: AppVectors.icDelivery,
                label: 'Bảng công',
                isActive: _currentIndex == 1,
                isDark: isDarkMode,
              ),
              _buildNavItem(
                activeIcon: 'assets/vectors/ic_edit_document.svg',
                inactiveIcon: 'assets/vectors/ic_edit_document.svg',
                label: 'Đơn từ',
                isActive: _currentIndex == 2,
                isDark: isDarkMode,
              ),
              _buildNavItem(
                activeIcon: AppVectors.icProfileActive,
                inactiveIcon: AppVectors.icProfile,
                label: 'Cá nhân',
                isActive: _currentIndex == 3,
                isDark: isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required String activeIcon,
    required String inactiveIcon,
    required String label,
    required bool isActive,
    required bool isDark,
  }) {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        isActive ? activeIcon : inactiveIcon,
        width: 26,
        height: 26,
        // ignore: deprecated_member_use
        color: isActive
            ? const Color(0xFF42C83C)
            : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
      ),
      label: label,
    );
  }
}
