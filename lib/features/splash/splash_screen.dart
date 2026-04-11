import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/memory_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ── Entrance animation ───────────────────────────────────────────────────────
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;

  // ── Heartbeat loop ───────────────────────────────────────────────────────────
  late final AnimationController _heartCtrl;
  late final Animation<double> _heartbeat;
  late final Animation<double> _glowPulse;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // ── Entrance ─────────────────────────────────────────────────────────────
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
      ),
    );

    // ── Heartbeat (lub-dub pattern) ──────────────────────────────────────────
    // Duration: 900ms per beat — lub(fast) dub(fast) pause
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Scale: 1.0 → 1.14 → 0.97 → 1.1 → 1.0 → hold
    _heartbeat = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.14)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.14, end: 0.97)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.97, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      // Pause between beats
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 58,
      ),
    ]).animate(_heartCtrl);

    // Glow: pulses with the beat (0.0 → 1.0 → 0.0 over first half)
    _glowPulse = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 58,
      ),
    ]).animate(_heartCtrl);

    // Start entrance, then kick off heartbeat loop
    _ctrl.forward().then((_) {
      if (mounted) _heartCtrl.repeat();
    });

    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted && !_navigated) {
        _navigated = true;
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _heartCtrl.dispose();
    super.dispose();
  }

  void _precachePhotos(List memories) {
    for (final m in memories.take(10)) {
      final url = m.photoUrl as String?;
      if (url != null && url.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(url), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(memoriesProvider);
    memoriesAsync.whenData(_precachePhotos);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_ctrl, _heartCtrl]),
          builder: (_, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: ScaleTransition(
                    scale: _heartbeat,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.5 * _glowPulse.value),
                            blurRadius: 32 * _glowPulse.value,
                            spreadRadius: 4 * _glowPulse.value,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/logo/app_logo.jpg',
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Opacity(
                opacity: _textFade.value,
                child: Column(
                  children: [
                    Text(
                      'harmony',
                      style: AppTextStyles.appTitle.copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'every moment, together',
                      style: AppTextStyles.muted.copyWith(
                        fontSize: 13,
                        color: AppColors.primary.withValues(alpha: 0.6),
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
