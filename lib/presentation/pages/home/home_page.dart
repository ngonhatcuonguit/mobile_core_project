import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_core_project/core/configs/app_config.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/services/localization_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _initialPage = 300;
  static const Duration _autoScrollDelay = Duration(seconds: 5);
  static const Duration _autoScrollDuration = Duration(milliseconds: 650);

  final PageController _pageController = PageController(
    viewportFraction: 0.76,
    initialPage: _initialPage,
  );
  Timer? _autoScrollTimer;
  int _rawPage = _initialPage;
  int _currentProject = 0;

  static const _projects = [
    _ProjectData('project_an_phu', 'project_an_phu_location', Alignment.center),
    _ProjectData(
      'project_green_villa',
      'project_green_villa_location',
      Alignment(-0.2, 0),
    ),
    _ProjectData(
      'project_city_house',
      'project_city_house_location',
      Alignment(0.2, 0),
    ),
  ];

  static const _services = [
    _ServiceData(
      'service_architecture',
      Icons.architecture_rounded,
      Color(0xFF8B6BFF),
      Color(0xFFF1ECFF),
    ),
    _ServiceData(
      'service_construction',
      Icons.engineering_rounded,
      Color(0xFFF4A62A),
      Color(0xFFFFF1D5),
    ),
    _ServiceData(
      'service_estimate',
      Icons.calculate_outlined,
      Color(0xFF8C67D9),
      Color(0xFFF0E8FF),
    ),
    _ServiceData(
      'service_library',
      Icons.home_work_outlined,
      Color(0xFFF06C45),
      Color(0xFFFFE9E1),
    ),
    _ServiceData(
      'service_feng_shui',
      Icons.blur_circular_rounded,
      Color(0xFF4C596A),
      Color(0xFFECEFF3),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleAutoScroll());
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _scheduleAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer(_autoScrollDelay, () {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.animateToPage(
        _rawPage + 1,
        duration: _autoScrollDuration,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onProjectChanged(int page) {
    setState(() {
      _rawPage = page;
      _currentProject = page % _projects.length;
    });
    _scheduleAutoScroll();
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.tr('coming_soon'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildProjectCarousel(context)),
            SliverToBoxAdapter(child: _buildPageIndicator()),
            SliverToBoxAdapter(child: _buildServicesHeader(context)),
            SliverToBoxAdapter(child: _buildServices(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 148)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset('assets/images/app_logo.png'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConfig.appTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  context.tr('home_subtitle'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 23),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCarousel(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SizedBox(
          height: 360,
          child: PageView.builder(
            key: const Key('projectCarousel'),
            controller: _pageController,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            onPageChanged: _onProjectChanged,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  var page = _rawPage.toDouble();
                  if (_pageController.hasClients &&
                      _pageController.position.hasContentDimensions) {
                    page = _pageController.page ?? page;
                  }
                  final distance =
                      (page - index).abs().clamp(0.0, 1.0).toDouble();
                  final scale = 1 - (distance * 0.09);
                  final opacity = 1 - (distance * 0.20);
                  return Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: Opacity(opacity: opacity, child: child),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  child: _ProjectCard(
                    project: _projects[index % _projects.length],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_projects.length, (index) {
          final selected = index == _currentProject;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: selected ? 18 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : AppColors.lightGrey.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildServicesHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 18, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr('services'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          TextButton(
            onPressed: _showComingSoon,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('see_all')),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServices(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        key: const Key('serviceList'),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) => _ServiceCard(
          service: _services[index],
          onPressed: _showComingSoon,
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final _ProjectData project;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isDark ? 0.13 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/projects/modern_townhouse.jpg',
                  fit: BoxFit.cover,
                  alignment: project.alignment,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x2A000000)],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.tr('project_status'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(project.titleKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.muted, size: 21),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.tr(project.locationKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.muted,
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
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onPressed,
  });

  final _ServiceData service;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SizedBox(
        key: Key('serviceCardSurface_${service.titleKey}'),
        width: 104,
        height: 104,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF353141) : const Color(0xFFF0EDF4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.075),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 7, 7, 6),
                child: Column(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: isDark
                            ? service.color.withOpacity(0.16)
                            : service.background,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(service.icon, color: service.color, size: 25),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Center(
                        child: Text(
                          context.tr(service.titleKey),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.18,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectData {
  const _ProjectData(this.titleKey, this.locationKey, this.alignment);

  final String titleKey;
  final String locationKey;
  final Alignment alignment;
}

class _ServiceData {
  const _ServiceData(
    this.titleKey,
    this.icon,
    this.color,
    this.background,
  );

  final String titleKey;
  final IconData icon;
  final Color color;
  final Color background;
}
