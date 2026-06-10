import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../brand/medclues_palette.dart';
import '../../config/app_config.dart';
import '../../helpers/storage_helper.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/brand/medclues_logo_image.dart';
import '../../features/emergency/widgets/emergency_help_button.dart';
import '../../widgets/splash/fullscreen_splash_video.dart';

/// Full-screen splash animation (1080×1920 portrait, cover) → login handoff.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  VideoPlayerController? _video;
  bool _handoffStarted = false;
  bool _videoFinished = false;
  bool _useLogoFallback = false;
  bool _needsTapToPlay = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initOpeningVideo();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    super.dispose();
  }

  Future<void> _initOpeningVideo() async {
    final controller = VideoPlayerController.asset(
      AppConfig.splashVideoAsset,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      controller.setLooping(false);
      controller.addListener(_onVideoTick);
      setState(() => _video = controller);
      await _startPlayback(controller);

      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted || _videoFinished) return;
      if (!controller.value.isPlaying) {
        setState(() => _needsTapToPlay = true);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Splash video failed: $e');
        debugPrint('$st');
      }
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _useLogoFallback = true;
      });
      Future.delayed(const Duration(milliseconds: 1800), _tryHandoff);
    }
  }

  Future<void> _startPlayback(VideoPlayerController controller) async {
    await controller.setVolume(0);
    await controller.play();
    if (!controller.value.isPlaying) {
      await controller.play();
    }
  }

  Future<void> _onTapPlay() async {
    final c = _video;
    if (c == null) return;
    setState(() => _needsTapToPlay = false);
    await c.setVolume(0);
    await c.play();
  }

  void _onVideoTick() {
    final c = _video;
    if (c == null || !c.value.isInitialized || _videoFinished) return;

    if (c.value.isPlaying) _needsTapToPlay = false;

    final dur = c.value.duration;
    final pos = c.value.position;

    if (dur > Duration.zero && pos >= dur - const Duration(milliseconds: 400)) {
      _onVideoComplete();
      return;
    }

    if (dur == Duration.zero &&
        !c.value.isPlaying &&
        pos > const Duration(milliseconds: 500)) {
      _onVideoComplete();
    }
  }

  void _onVideoComplete() {
    if (_videoFinished) return;
    _videoFinished = true;
    _video?.pause();
    setState(() {});
    Future.delayed(const Duration(milliseconds: 350), _tryHandoff);
  }

  bool get _isStillOnSplash {
    if (!mounted) return false;
    return ModalRoute.of(context)?.isCurrent ?? false;
  }

  void _tryHandoff() {
    if (!mounted || _handoffStarted || !_isStillOnSplash) return;
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.loading) return;

    _handoffStarted = true;
    _video?.pause();
    final dest = auth.status == AuthStatus.authenticated
        ? RouteNames.dashboard
        : RouteNames.login;
    context.go(dest);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status != AuthStatus.loading && _videoFinished) {
        _tryHandoff();
      }
    });

    final fadingOut = _videoFinished;

    return Scaffold(
      backgroundColor: MedcluesPalette.splashCanvas,
      body: AnimatedOpacity(
        opacity: fadingOut ? 0 : 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_useLogoFallback) {
      return Stack(
        children: [
          ColoredBox(
            color: MedcluesPalette.pureWhite,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MedcluesLogoImage(size: MedcluesLogoSize.auth, useHero: true),
              if (_loadError != null && kDebugMode) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Video error: $_loadError',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: MedcluesPalette.softSlate),
                  ),
                ),
              ],
                ],
              ),
            ),
          ),
          const EmergencyHelpButton(
            style: EmergencyHelpButtonStyle.floating,
            replaceRoute: true,
          ),
        ],
      );
    }

    final c = _video;
    if (c == null || !c.value.isInitialized) {
      return const ColoredBox(
        color: MedcluesPalette.splashCanvas,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: MedcluesPalette.medicalTeal,
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FullscreenSplashVideo(controller: c),
        const EmergencyHelpButton(
          style: EmergencyHelpButtonStyle.floating,
          replaceRoute: true,
        ),
        if (_needsTapToPlay)
          Positioned.fill(
            child: GestureDetector(
              onTap: _onTapPlay,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: MedcluesPalette.deepNavy.withValues(alpha: 0.12),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: MedcluesPalette.deepNavy.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Tap to continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
