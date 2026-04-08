import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/add_memory/add_memory_screen.dart';
import '../../features/detail/memory_detail_screen.dart';
import '../../features/pixelmap_gallery/pixelmap_gallery_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/secret_letter/pin_screen.dart';
import '../../features/secret_letter/secret_letter_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/bucket_list/bucket_list_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../data/repositories/couple_provider.dart';

/// Updated when coupleId is known.
final routerCoupleNotifier = ValueNotifier<String?>(null);

/// True once _bootstrap() in main.dart finishes — prevents premature redirects.
final routerBootstrapNotifier = ValueNotifier<bool>(false);

final appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: Listenable.merge([
    routerCoupleNotifier,
    routerBootstrapNotifier,
  ]),
  redirect: (context, state) {
    final bootstrapDone = routerBootstrapNotifier.value;
    final coupleId = routerCoupleNotifier.value;
    final isOnboarding = state.matchedLocation == '/onboarding';
    final isSplash = state.matchedLocation == '/splash';

    // Always show splash; let it navigate when ready
    if (isSplash) return null;

    // Don't redirect until bootstrap completes — prevents onboarding flash
    if (!bootstrapDone) return null;

    if (coupleId == null && !isOnboarding) return '/onboarding';
    if (coupleId != null && isOnboarding) return '/';

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/add',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AddMemoryScreen(),
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
    GoRoute(
      path: '/memory/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: MemoryDetailScreen(memoryId: id),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        );
      },
    ),
    GoRoute(
      path: '/pixelmap-gallery',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PixelmapGalleryScreen(),
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
    GoRoute(
      path: '/explore',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ExploreScreen(),
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
    GoRoute(
      path: '/calendar',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CalendarScreen(),
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
    GoRoute(
      path: '/bucket-list',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const BucketListScreen(),
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
    GoRoute(
      path: '/secret-pin',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PinScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: '/secret-letter',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SecretLetterScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
  ],
);
