import 'package:flutter/material.dart';
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
import '../../features/identity/identity_screen.dart';

/// Updated when coupleId is known.
final routerCoupleNotifier = ValueNotifier<String?>(null);

/// True once _bootstrap() in main.dart finishes — prevents premature redirects.
final routerBootstrapNotifier = ValueNotifier<bool>(false);

/// True once the user has selected their identity (name).
final routerIdentityNotifier = ValueNotifier<bool>(false);

/// Global navigator key — used by NotificationService to navigate after tap.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  refreshListenable: Listenable.merge([
    routerCoupleNotifier,
    routerBootstrapNotifier,
    routerIdentityNotifier,
  ]),
  redirect: (context, state) {
    final bootstrapDone = routerBootstrapNotifier.value;
    final identitySet = routerIdentityNotifier.value;
    final loc = state.matchedLocation;

    if (loc == '/splash') return null;
    if (!bootstrapDone) return null;

    // Identity not set → always go to identity screen (handles date code + persona)
    if (!identitySet) {
      return loc == '/identity' ? null : '/identity';
    }

    // Fully set up → home
    if (loc == '/onboarding' || loc == '/identity') return '/';

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/identity',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const IdentityScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
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
