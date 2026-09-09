import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure high-capacity image cache to avoid texture loss during fast scrolling
  PaintingBinding.instance.imageCache.maximumSizeBytes = 256 * 1024 * 1024; // 256 MB
  PaintingBinding.instance.imageCache.maximumSize = 1000;

  // Load .env variables safely
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Fallback constants used if .env is missing
  }

  runApp(
    const ProviderScope(
      child: SmartWardrobeApp(),
    ),
  );
}

class SmartWardrobeApp extends ConsumerWidget {
  const SmartWardrobeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Smart Wardrobe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
