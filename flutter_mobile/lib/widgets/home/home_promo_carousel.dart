import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../routes/route_names.dart';

class _PromoSlide {
  const _PromoSlide({
    required this.title,
    required this.quote,
    required this.cta,
    required this.route,
    required this.gradient,
    required this.icon,
  });

  final String title;
  final String quote;
  final String cta;
  final String route;
  final List<Color> gradient;
  final IconData icon;
}

/// Full-bleed home promo carousel: swipe + 3s auto-advance.
class HomePromoCarousel extends StatefulWidget {
  const HomePromoCarousel({super.key});

  @override
  State<HomePromoCarousel> createState() => _HomePromoCarouselState();
}

class _HomePromoCarouselState extends State<HomePromoCarousel> {
  static const _slides = <_PromoSlide>[
    _PromoSlide(
      title: 'Explore hospitals',
      quote: 'Care finds you when you need it most.',
      cta: 'Explore Now →',
      route: RouteNames.hospitals,
      gradient: [
        Color(0xFF002855),
        Color(0xFF1565C0),
        Color(0xFF7DD3FC),
      ],
      icon: Icons.local_hospital_outlined,
    ),
    _PromoSlide(
      title: 'Pharmacy',
      quote: 'The right medicine, right when you need it.',
      cta: 'Shop Now →',
      route: RouteNames.pharmacy,
      gradient: [
        Color(0xFF0F766E),
        Color(0xFF009F93),
        Color(0xFF99F6E4),
      ],
      icon: Icons.local_pharmacy_outlined,
    ),
    _PromoSlide(
      title: 'Find doctors',
      quote: 'Good health begins with the right doctor.',
      cta: 'Browse Doctors →',
      route: RouteNames.doctors,
      gradient: [
        Color(0xFF0D9488),
        Color(0xFF14B8A6),
        Color(0xFF57D2E8),
      ],
      icon: Icons.medical_services_outlined,
    ),
    _PromoSlide(
      title: 'Health Protection',
      quote: 'Protect today. Peace of mind tomorrow.',
      cta: 'Protect Now →',
      route: RouteNames.healthProtection,
      gradient: [
        Color(0xFF1E3A5F),
        Color(0xFF3B82A8),
        Color(0xFFA5B4FC),
      ],
      icon: Icons.health_and_safety_outlined,
    ),
  ];

  final _pageController = PageController();
  Timer? _autoTimer;
  int _index = 0;
  bool _userDragging = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAutoTimer();
  }

  void _syncAutoTimer() {
    final disable = MediaQuery.disableAnimationsOf(context);
    if (disable) {
      _autoTimer?.cancel();
      _autoTimer = null;
      return;
    }
    _autoTimer ??= Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _userDragging || !_pageController.hasClients) return;
      final next = (_index + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 232,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollStartNotification && n.dragDetails != null) {
                  _userDragging = true;
                } else if (n is ScrollEndNotification) {
                  _userDragging = false;
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _PromoCard(slide: _slides[i]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: active
                      ? AppColors.primaryBlue
                      : AppColors.textHint.withValues(alpha: 0.45),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.slide});

  final _PromoSlide slide;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(slide.route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: slide.gradient,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 65,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 10, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      slide.title,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      slide.quote,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1.5),
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: Text(
                        slide.cta,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 35,
              child: Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  child: Icon(
                    slide.icon,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
