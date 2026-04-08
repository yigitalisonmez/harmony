import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart'
    show appRouter, routerCoupleNotifier, routerBootstrapNotifier;
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'data/repositories/couple_provider.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/bucket_list_repository.dart';
import 'data/repositories/places_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  // Init Hive for settings/bucket/places (still local)
  await Hive.initFlutter();
  await SettingsRepository.init();
  await BucketListRepository.init();
  await PlacesRepository.init();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const ProviderScope(child: HarmonyApp()));
}

class HarmonyApp extends ConsumerStatefulWidget {
  const HarmonyApp({super.key});

  @override
  ConsumerState<HarmonyApp> createState() => _HarmonyAppState();
}

class _HarmonyAppState extends ConsumerState<HarmonyApp> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Sign in anonymously if needed
    if (AuthService.currentUser == null) {
      await AuthService.signInAnonymously();
    }

    // Load coupleId if already paired
    final coupleId = await AuthService.getCoupleId();
    if (mounted && coupleId != null) {
      ref.read(coupleIdProvider.notifier).state = coupleId;
      routerCoupleNotifier.value = coupleId;
    }

    // Bootstrap done — router can now make redirect decisions
    routerBootstrapNotifier.value = true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'harmony',
      theme: appTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
