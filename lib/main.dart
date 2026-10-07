import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/router/url_strategy.dart';
import 'core/session/session_provider.dart';
import 'core/deeplink/payment_deeplink_handler.dart';
import 'features/auth/presentation/widgets/google_sign_in_bootstrap.dart';
import 'features/auth/presentation/widgets/splash_screen.dart';
import 'features/auth/providers/auth_provider.dart';

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
  // Dùng bootstrap singleton để không bị initialize() lần hai ở widget.
  await GoogleSignInBootstrap.ensureInitialized(AppConstants.googleClientId);

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
    final authState = ref.watch(authStateProvider);

    return PaymentDeepLinkObserver(
      router: router,
      child: MaterialApp.router(
        title: 'Closy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) {
          // Spec 015 — FR-003: màn hình khởi động đặt TRÊN router, nên router
          // vẫn tính đích đến bình thường và không phát sinh route mới.
          //
          // Ba nhánh, theo đúng FR-001/FR-005:
          // ① Lỗi tạm thời → giữ splash **vô hạn** kèm "Thử lại". Ngưỡng 1 giây
          //    KHÔNG áp dụng ở nhánh này (spec 128): nếu áp, người dùng sẽ bị đẩy
          //    ra màn đăng nhập dù token vẫn còn.
          // ② Splash lúc khởi động → hiện ở mọi lần mở app, tự ẩn khi kiểm tra
          //    xong HOẶC tối đa 1 giây (FR-005). Cờ `AuthStartup` giữ nó ở mức
          //    "một lần mỗi tiến trình" nên đổi tài khoản không nháy lại.
          // ③ Còn lại → ứng dụng bình thường.
          final hasFailed = authState.authCheckFailed;
          final app = child ?? const SizedBox.shrink();

          if (hasFailed) {
            return SplashScreen(
              errorMessage: authState.errorMessage,
              onRetry: () =>
                  ref.read(authStateProvider.notifier).checkAuthStatus(),
            );
          }

          if (AuthStartup.isBootSplashPending) {
            return _SplashGate(app: app, isChecking: authState.isCheckingAuth);
          }

          return app;
        },
      ),
    );
  }
}

/// Giữ [SplashScreen] rồi trả về [app].
///
/// FR-005: ẩn sớm nếu kiểm tra phiên xong sớm (không thêm độ trễ cảm nhận được),
/// nhưng **tối đa 1 giây** kể từ lúc splash xuất hiện. Đếm ngược chạy song song với
/// việc kiểm tra, ai xong trước thì dùng.
///
/// Cờ `_painted` bảo đảm splash **đã kịp vẽ ra một frame** trước khi ẩn — nếu
/// không, lần mở app mà token đã hợp lệ sẽ không hề thấy splash, vi phạm FR-003.
class _SplashGate extends StatefulWidget {
  final Widget app;

  /// Còn đang kiểm tra phiên hay không.
  final bool isChecking;

  const _SplashGate({required this.app, required this.isChecking});

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  /// Ngân sách hiển thị tối đa 1 giây (FR-005, SC-002).
  static const Duration maxVisible = Duration(seconds: 1);

  Timer? _timer;
  bool _painted = false;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _painted = true);
    });
    _timer = Timer(maxVisible, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settled = !widget.isChecking;
    if (_timedOut || (_painted && settled)) {
      // Đánh dấu ngay khi hiển thị xong để lần recreate ProviderScope sau này
      // (đổi tài khoản) không hiện splash lần nữa.
      AuthStartup.markBootSplashDone();
      return widget.app;
    }
    return const SplashScreen();
  }
}
