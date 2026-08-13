import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../providers/home_banner_provider.dart';
import '../../routes/route_names.dart';

class PromoSlide {
  const PromoSlide({
    required this.title,
    required this.quote,
    required this.cta,
    required this.route,
    required this.gradient,
    required this.icon,
    this.imageUrl,
  });

  final String title;
  final String quote;
  final String cta;
  final String route;
  final List<Color> gradient;
  final IconData icon;
  final String? imageUrl;
}

/// Fallback when API is empty/offline — matches previous hardcoded slides.
const fallbackPromoSlides = <PromoSlide>[
  PromoSlide(
    title: 'Explore hospitals',
    quote: 'Care finds you when you need it most.',
    cta: 'Explore Now →',
    route: RouteNames.hospitals,
    gradient: [Color(0xFF002855), Color(0xFF1565C0), Color(0xFF7DD3FC)],
    icon: Icons.local_hospital_outlined,
  ),
  PromoSlide(
    title: 'Pharmacy',
    quote: 'The right medicine, right when you need it.',
    cta: 'Shop Now →',
    route: RouteNames.pharmacy,
    gradient: [Color(0xFF0F766E), Color(0xFF009F93), Color(0xFF99F6E4)],
    icon: Icons.local_pharmacy_outlined,
  ),
  PromoSlide(
    title: 'Find doctors',
    quote: 'Good health begins with the right doctor.',
    cta: 'Browse Doctors →',
    route: RouteNames.doctors,
    gradient: [Color(0xFF0D9488), Color(0xFF14B8A6), Color(0xFF57D2E8)],
    icon: Icons.medical_services_outlined,
  ),
  PromoSlide(
    title: 'Health Protection',
    quote: 'Protect today. Peace of mind tomorrow.',
    cta: 'Protect Now →',
    route: RouteNames.healthProtection,
    gradient: [Color(0xFF1E3A5F), Color(0xFF3B82A8), Color(0xFFA5B4FC)],
    icon: Icons.health_and_safety_outlined,
  ),
];

/// Full-bleed home promo carousel: remote slides + 3s auto-advance.
class HomePromoCarousel extends ConsumerStatefulWidget {
  const HomePromoCarousel({super.key});

  @override
  ConsumerState<HomePromoCarousel> createState() => _HomePromoCarouselState();
}

class _HomePromoCarouselState extends ConsumerState<HomePromoCarousel> {
  final _pageController = PageController();
  Timer? _autoTimer;
  int _index = 0;
  bool _userDragging = false;
  List<PromoSlide> _slides = fallbackPromoSlides;

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
      if (_slides.isEmpty) return;
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
    ref.listen<AsyncValue<List<PromoSlide>>>(homeBannersProvider, (prev, next) {
      next.whenData((remote) {
        if (!mounted || remote.isEmpty) return;
        setState(() {
          _slides = remote;
          if (_index >= _slides.length) _index = 0;
        });
      });
    });
    ref.watch(homeBannersProvider);
    final slides = _slides.isEmpty ? fallbackPromoSlides : _slides;

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
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _PromoCard(slide: slides[i]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(slides.length, (i) {
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

  final PromoSlide slide;

  @override
  Widget build(BuildContext context) {
    final hasImage = (slide.imageUrl ?? '').isNotEmpty;
    return GestureDetector(
      onTap: () => context.push(slide.route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
          gradient: hasImage
              ? null
              : LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: slide.gradient,
                ),
          image: hasImage
              ? DecorationImage(
                  image: CachedNetworkImageProvider(slide.imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Container(
          decoration: hasImage
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                )
              : null,
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
              if (!hasImage)
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
      ),
    );
  }
}
