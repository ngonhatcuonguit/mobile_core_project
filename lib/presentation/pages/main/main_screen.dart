import 'package:flutter/material.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/presentation/pages/home/home_page.dart';
import 'package:flutter_core_project/presentation/pages/profile/profile_page.dart';
import 'package:flutter_core_project/services/localization_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const _pages = [
    HomePage(),
    _LocalToolPage(
      titleKey: 'materials_title',
      descriptionKey: 'materials_description',
      icon: Icons.inventory_2_outlined,
    ),
    _LocalToolPage(
      titleKey: 'quantity_title',
      descriptionKey: 'quantity_description',
      icon: Icons.calculate_outlined,
    ),
    ProfilePage(),
  ];

  void _selectPage(int index) => setState(() => _currentIndex = index);

  void _showComingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.tr('coming_soon'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: SizedBox(
          height: 106,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              _NavigationPanel(
                currentIndex: _currentIndex,
                onSelected: _selectPage,
              ),
              Positioned(
                top: 0,
                child: _AddProjectButton(onPressed: _showComingSoon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? const Color(0xFF353141) : const Color(0xFFF0EDF5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.065),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavigationItem(
              key: const Key('homeNavigationButton'),
              icon: Icons.home_work_outlined,
              selectedIcon: Icons.home_work_rounded,
              label: context.tr('nav_home'),
              selected: currentIndex == 0,
              onPressed: () => onSelected(0),
            ),
          ),
          Expanded(
            child: _NavigationItem(
              key: const Key('materialsNavigationButton'),
              icon: Icons.inventory_2_outlined,
              selectedIcon: Icons.inventory_2_rounded,
              label: context.tr('nav_materials'),
              selected: currentIndex == 1,
              onPressed: () => onSelected(1),
            ),
          ),
          const SizedBox(width: 76),
          Expanded(
            child: _NavigationItem(
              key: const Key('quantityNavigationButton'),
              icon: Icons.calculate_outlined,
              selectedIcon: Icons.calculate_rounded,
              label: context.tr('nav_quantity'),
              selected: currentIndex == 2,
              onPressed: () => onSelected(2),
            ),
          ),
          Expanded(
            child: _NavigationItem(
              key: const Key('profileNavigationButton'),
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: context.tr('nav_profile'),
              selected: currentIndex == 3,
              onPressed: () => onSelected(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primary
        : Theme.of(context).textTheme.bodySmall?.color;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 23),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 9.5,
                    height: 1.15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProjectButton extends StatelessWidget {
  const _AddProjectButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr('nav_add_project'),
      child: Column(
        children: [
          Material(
            elevation: 10,
            shadowColor: AppColors.primary.withOpacity(0.42),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9B75FF), AppColors.primary],
                ),
              ),
              child: InkWell(
                key: const Key('addProjectButton'),
                onTap: onPressed,
                customBorder: const CircleBorder(),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 38),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('nav_add_project'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _LocalToolPage extends StatelessWidget {
  const _LocalToolPage({
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
  });

  final String titleKey;
  final String descriptionKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(titleKey),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.11),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 36),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.tr(titleKey),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      context.tr(descriptionKey),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                            height: 1.55,
                          ),
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
}
