import 'dart:async';
import 'package:flutter/material.dart';

class HomeBannerWidget extends StatefulWidget {
  const HomeBannerWidget({super.key});

  @override
  State<HomeBannerWidget> createState() => _HomeBannerWidgetState();
}

class _HomeBannerWidgetState extends State<HomeBannerWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<_BannerItem> _banners = const [
    _BannerItem(
      title: 'Trà xanh không độ',
      highlight: 'KHÔNG ĐỘ - KHÔNG STRESS',
      subtitle:
          'Thanh mát mỗi ngày, tỉnh táo mỗi ca làm.\nSảng khoái cùng Trà xanh không độ.',
      gradientStart: Color(0xFF1B8C3E),
      gradientEnd: Color(0xFF56C271),
      accentColor: Color(0xFFFFEB3B),
      decorIcon1: Icons.eco,
      decorIcon2: Icons.spa,
    ),
    _BannerItem(
      title: 'Khám phá sản phẩm mới',
      highlight: 'My THP 2026',
      subtitle: 'Những sản phẩm mới nhất từ My THP\nĐặt hàng ngay hôm nay!',
      gradientStart: Color(0xFF4A1FB8),
      gradientEnd: Color(0xFF8B5CF6),
      accentColor: Color(0xFFFDE68A),
      decorIcon1: Icons.star_outline_rounded,
      decorIcon2: Icons.auto_awesome,
    ),
    _BannerItem(
      title: 'Chương trình ưu đãi đặc biệt',
      highlight: 'DÀNH CHO NHÂN VIÊN',
      subtitle: 'Ưu đãi độc quyền cho nhân viên My THP\nÁp dụng từ tháng 3/2026',
      gradientStart: Color(0xFFB83232),
      gradientEnd: Color(0xFFFF7043),
      accentColor: Color(0xFFFFF9C4),
      decorIcon1: Icons.card_giftcard_outlined,
      decorIcon2: Icons.local_offer_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
          SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _banners.length,
              itemBuilder: (_, i) => _BannerCard(
                item: _banners[i],
                onTap: null,
              ),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == i ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == i
                    ? const Color(0xFF42C83C)
                    : Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final _BannerItem item;
  final VoidCallback? onTap;
  const _BannerCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [item.gradientStart, item.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative overlay
            Positioned(
              right: -10,
              bottom: -10,
              child: Opacity(
                opacity: 0.18,
                child: Icon(
                  item.decorIcon1,
                  size: 130,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              right: 40,
              top: -20,
              child: Opacity(
                opacity: 0.12,
                child: Icon(
                  item.decorIcon2,
                  size: 100,
                  color: Colors.white,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.highlight,
                    style: TextStyle(
                      color: item.accentColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white38, width: 1),
                    ),
                    child: const Text(
                      'Xem thêm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerItem {
  final String title;
  final String highlight;
  final String subtitle;
  final Color gradientStart;
  final Color gradientEnd;
  final Color accentColor;
  final IconData decorIcon1;
  final IconData decorIcon2;

  const _BannerItem({
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accentColor,
    required this.decorIcon1,
    required this.decorIcon2,
  });
}
