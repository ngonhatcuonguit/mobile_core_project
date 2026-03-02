import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/assets/app_vectors.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_bloc.dart';
import 'package:flutter_core_project/presentation/pages/home/home_page.dart';
import 'package:flutter_core_project/presentation/pages/news/daily_news.dart';
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
      const DailyNews(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _pages[_currentIndex],
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
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor:
                isDarkMode ? const Color(0xFF1C1C1C) : Colors.white,
            selectedItemColor: const Color(0xFF42C83C),
            unselectedItemColor:
                isDarkMode ? Colors.grey[600] : Colors.grey[400],
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: 0,
            items: [
              _buildNavItem(
                activeIcon: AppVectors.icHomeActive,
                inactiveIcon: AppVectors.icHome,
                isActive: _currentIndex == 0,
              ),
              _buildNavItem(
                activeIcon: AppVectors.icDelivery,
                inactiveIcon: AppVectors.icDelivery,
                isActive: _currentIndex == 1,
              ),
              _buildNavItem(
                activeIcon: AppVectors.icDelivery,
                inactiveIcon: AppVectors.icDelivery,
                isActive: _currentIndex == 2,
              ),
              _buildNavItem(
                activeIcon: AppVectors.icProfileActive,
                inactiveIcon: AppVectors.icProfile,
                isActive: _currentIndex == 3,
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
    required bool isActive,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BottomNavigationBarItem(
      icon: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF42C83C) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(
            isActive ? activeIcon : inactiveIcon,
            width: 24,
            height: 24,
            color: isActive
                ? Colors.white
                : (isDarkMode ? Colors.grey[600]! : Colors.grey[400]!),
          ),
        ),
      ),
      label: '',
    );
  }
}
