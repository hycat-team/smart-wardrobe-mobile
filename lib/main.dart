import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/router/url_strategy.dart';
import 'core/session/session_provider.dart';
import 'core/deeplink/payment_deeplink_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web: URL dạng path (không hash) để khớp redirectUrl callback Google.
  configureUrlStrategy();

  // Configure high-capacity image cache to avoid texture loss during fast scrolling
  PaintingBinding.instance.imageCache.maximumSizeBytes = 256 * 1024 * 1024; // 256 MB
  PaintingBinding.instance.imageCache.maximumSize = 1000;

  // Load .env variables safely
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Fallback constants used if .env is missing
  }

  // Pre-initialize Google Sign-In SDK (chỉ Android/iOS). Web dùng luồng
  // redirect của BE (guide §1) nên KHÔNG cần Google Identity Services.
  if (!kIsWeb) {
    try {
      final clientId = AppConstants.googleClientId;
      if (clientId.isNotEmpty) {
        await GoogleSignIn.instance.initialize(
          clientId: null,
          serverClientId: clientId,
        );
      }
    } catch (e) {
      debugPrint('Google Sign-In pre-initialization notice: $e');
    }
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
