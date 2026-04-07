import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/memory_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/bucket_list_repository.dart';
import 'data/repositories/places_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  // Hive init
  await Hive.initFlutter();
  await MemoryRepository.init();
  await SettingsRepository.init();
  await BucketListRepository.init();
  await PlacesRepository.init();

  runApp(const ProviderScope(child: HarmonyApp()));
}

class HarmonyApp extends StatelessWidget {
  const HarmonyApp({super.key});

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
