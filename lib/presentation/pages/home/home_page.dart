import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/app_config.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_cubit.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_state.dart';
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
  int _projectCount = 3;

  static const _featuredProjects = [
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
      Icons.design_services_rounded,
      Color(0xFF2F80ED),
      Color(0xFFEAF3FF),
    ),
    _ServiceData(
      'service_construction',
      Icons.construction_rounded,
      Color(0xFFE58A19),
      Color(0xFFFFF4E3),
    ),
    _ServiceData(
      'service_estimate',
      Icons.request_quote_rounded,
      Color(0xFF249A68),
      Color(0xFFE8F7F0),
    ),
    _ServiceData(
      'service_library',
      Icons.holiday_village_rounded,
      Color(0xFFE55C4A),
      Color(0xFFFDEDEA),
    ),
    _ServiceData(
      'service_feng_shui',
      Icons.explore_rounded,
      Color(0xFF7A62C9),
      Color(0xFFF1EDFB),
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
      _currentProject = page % _projectCount;
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
    return BlocConsumer<ProjectCubit, ProjectState>(
      listenWhen: (previous, current) =>
          previous.projects.length != current.projects.length,
      listener: (context, state) {
        final count = state.projects.length + _featuredProjects.length;
        setState(() {
          _projectCount = count;
          _rawPage = _initialPage;
          _currentProject = 0;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_initialPage);
          }
        });
      },
      builder: (context, state) {
        final projects = [
          ...state.projects.map(_ProjectData.fromEntity),
          ..._featuredProjects,
        ];
        _projectCount = projects.length;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(
                  child: _buildProjectCarousel(context, projects),
                ),
                SliverToBoxAdapter(child: _buildPageIndicator(projects.length)),
                SliverToBoxAdapter(child: _buildServicesHeader(context)),
                SliverToBoxAdapter(child: _buildServices(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 148)),
              ],
            ),
          ),
        );
      },
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
                  color: Colors.black.withValues(alpha: 0.06),
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

  Widget _buildProjectCarousel(
    BuildContext context,
    List<_ProjectData> projects,
  ) {
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
                    project: projects[index % projects.length],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int projectCount) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(projectCount, (index) {
          final selected = index == _currentProject;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: selected ? 18 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : AppColors.lightGrey.withValues(alpha: 0.8),
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
      height: 84,
      child: ListView.separated(
        key: const Key('serviceList'),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
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
            color: AppColors.primary.withValues(alpha: isDark ? 0.13 : 0.10),
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
                if (project.imagePath == null || kIsWeb)
                  Image.asset(
                    project.assetPath,
                    fit: BoxFit.cover,
                    alignment: project.alignment,
                  ),
                if (project.imagePath != null && !kIsWeb)
                  Image.file(
                    File(project.imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      project.assetPath,
                      fit: BoxFit.cover,
                      alignment: project.alignment,
                    ),
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
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.tr(
                        project.isSavedProject
                            ? 'project_saved_status'
                            : 'project_status',
                      ),
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
                  project.titleKey == null
                      ? project.title
                      : context.tr(project.titleKey!),
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
                        project.locationKey == null
                            ? project.location
                            : context.tr(project.locationKey!),
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
        width: 176,
        height: 80,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? service.color.withValues(alpha: 0.13)
                : service.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: service.color.withValues(alpha: isDark ? 0.34 : 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: service.color.withValues(alpha: isDark ? 0.08 : 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: service.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(service.icon, color: Colors.white, size: 25),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr(service.titleKey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: service.color,
                      size: 20,
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
  const _ProjectData(
    this.titleKey,
    this.locationKey,
    this.alignment, {
    this.title = '',
    this.location = '',
    this.imagePath,
    this.isSavedProject = false,
  });

  factory _ProjectData.fromEntity(ConstructionProject project) {
    return _ProjectData(
      null,
      null,
      Alignment.center,
      title: project.name,
      location: project.location,
      imagePath: project.imagePath,
      isSavedProject: true,
    );
  }

  final String? titleKey;
  final String? locationKey;
  final Alignment alignment;
  final String title;
  final String location;
  final String? imagePath;
  String get assetPath => 'assets/images/projects/modern_townhouse.jpg';
  final bool isSavedProject;
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
