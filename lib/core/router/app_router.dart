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

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
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
