import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/session/session_provider.dart';
import 'core/deeplink/payment_deeplink_handler.dart';

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
    // Mỗi khi session đổi (đăng xuất), ProviderScope lồng bên trong bị
    // dispose toàn bộ: mọi state của tài khoản cũ biến mất, tài khoản
    // mới đăng nhập vào container sạch.
    final session = ref.watch(sessionProvider);

    return ProviderScope(
      key: ValueKey<int>(session),
      child: const _SessionShell(),
    );
  }
}

class _SessionShell extends ConsumerWidget {
  const _SessionShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return PaymentDeepLinkObserver(
      router: router,
      child: MaterialApp.router(
        title: 'Smart Wardrobe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }
}
