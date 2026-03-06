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
      title: 'Lại gần Sơn Tùng cùng',
      highlight: 'TRÀ XANH KHÔNG ĐỘ',
      subtitle:
          'Đi khắp 15 tỉnh thành cùng Sơn Tùng và\nTrà Xanh Không Độ. Bạn đã sẵn sàng?',
      gradientStart: Color(0xFF2E7D32),
      gradientEnd: Color(0xFF66BB6A),
    ),
    _BannerItem(
      title: 'Khám phá sản phẩm mới',
      highlight: 'THP GROUP 2026',
      subtitle: 'Những sản phẩm mới nhất từ THP Group\nĐặt hàng ngay hôm nay!',
      gradientStart: Color(0xFF1B5E20),
      gradientEnd: Color(0xFF43A047),
    ),
    _BannerItem(
      title: 'Chương trình ưu đãi đặc biệt',
      highlight: 'DÀNH CHO NHÂN VIÊN',
      subtitle: 'Ưu đãi độc quyền cho nhân viên THP\nÁp dụng từ tháng 3/2026',
      gradientStart: Color(0xFF388E3C),
      gradientEnd: Color(0xFF81C784),
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
            itemBuilder: (_, i) => _BannerCard(item: _banners[i]),
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
  const _BannerCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Decorative leaf/pattern overlay
          Positioned(
            right: -10,
            bottom: -10,
            child: Opacity(
              opacity: 0.18,
              child: Icon(
                Icons.eco,
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
                Icons.spa,
                size: 100,
                color: Colors.white,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
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
                    fontFamily: 'Satoshi',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.highlight,
                  style: const TextStyle(
                    color: Color(0xFFFFEB3B),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Satoshi',
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Satoshi',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                      fontFamily: 'Satoshi',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  const _BannerItem({
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

