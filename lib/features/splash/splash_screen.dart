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
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
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
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted && !_navigated) {
        _navigated = true;
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
    // Watching memoriesProvider here starts the Firestore subscription early.
    // By the time HomeScreen mounts, data is already in Riverpod's cache.
    final memoriesAsync = ref.watch(memoriesProvider);
    memoriesAsync.whenData(_precachePhotos);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
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
