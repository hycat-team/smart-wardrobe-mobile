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

  // Pre-initialize Google Sign-In SDK: Web (GIS) dùng clientId; Android dùng
  // serverClientId. Giúp GIS sẵn sàng ngay khi màn login render.
  try {
    final clientId = AppConstants.googleClientId;
    if (clientId.isNotEmpty) {
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb ? clientId : null,
        serverClientId: !kIsWeb ? clientId : null,
      );
    }
  } catch (e) {
    debugPrint('Google Sign-In pre-initialization notice: $e');
  }

  runApp(
    const SmartWardrobeRoot(),
  );
}

class SmartWardrobeRoot extends StatefulWidget {
  const SmartWardrobeRoot({super.key});

  @override
  State<SmartWardrobeRoot> createState() => _SmartWardrobeRootState();
}

class _SmartWardrobeRootState extends State<SmartWardrobeRoot> {
  int _session = 0;

  @override
  void initState() {
    super.initState();
    appSessionNotifier.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    appSessionNotifier.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) {
      setState(() {
        _session = appSessionNotifier.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ProviderScope ở gốc ứng dụng được gán key theo _session.
    // Khi đăng xuất hoặc chuyển tài khoản, _session tăng khiến toàn bộ
    // ProviderContainer gốc bị dispose sạch: mọi state trong RAM (tủ đồ,
    // stylist, hạn mức, profile...) bị hủy triệt để và khởi tạo mới.
    return ProviderScope(
      key: ValueKey<int>(_session),
      child: const SmartWardrobeApp(),
    );
  }
}

class SmartWardrobeApp extends ConsumerWidget {
  const SmartWardrobeApp({super.key});

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
