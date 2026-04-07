import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../home/widgets/heart_line_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textFade = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Çizim bittikten sonra yazı fade-in, ardından home'a geç
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animasyonlu logo
            const HeartLineLogo(
              size: 120,
              color: AppColors.primary,
              strokeWidth: 5.0,
              duration: Duration(milliseconds: 1800),
            ),
            const SizedBox(height: 32),
            // Yazı — logo bittikten sonra fade in
            FadeTransition(
              opacity: _textFade,
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
    );
  }
}
