import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wardrobe/core/config/release_flags.dart';

/// Đón deep-link thanh toán cũ và chuyển về màn hình gói.
///
/// Luồng thanh toán đã chuyển lên website (009-web-payment-redirect):
/// app không còn màn hình chờ/kết quả checkout. Mọi deep-link PayOS cũ
/// (`smartwardrobe://subscription/...`, `smartwardrobe://wallet/...`)
/// đều được chuyển về màn hình gói (hiển thị hướng dẫn lên website),
/// không điều hướng tới trang thanh toán nào (FR-009).
class PaymentDeepLinkHandler {
  final GoRouter router;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  PaymentDeepLinkHandler({required this.router});

  Future<void> init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handle(initial);
      }
    } catch (_) {
      // Bỏ qua lỗi lấy initial link (cold-start không từ deep-link).
    }
    _sub = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (_) {},
    );
  }

  void _handle(Uri uri) {
    // Bỏ qua deep-link thanh toán ở bản phát hành Play (spec 008, FR-021).
    if (!ReleaseFlags.enablePaidFeatures) return;
    if (uri.scheme != 'smartwardrobe') return;
    final target = _mapToResultRoute(uri);
    if (target == null) return;
    // Dùng microtask để tránh điều hướng trong lúc router chưa sẵn sàng.
    Future.microtask(() {
      try {
        router.go(target);
      } catch (_) {}
    });
  }

  /// Map deep-link thanh toán cũ → màn hình gói trong app.
  ///
  /// Không còn map tới `/profile/payment/result` (route này giờ hiển thị
  /// thông báo hết hiệu lực). Màn hình gói hiển thị hướng dẫn lên website
  /// và tự tải lại trạng thái mới nhất khi mở.
  static String? _mapToResultRoute(Uri uri) {
    // host: subscription | wallet — mọi path đều về màn hình gói.
    final host = uri.host.toLowerCase();

    if (host == 'subscription' || host == 'wallet') {
      return '/profile/subscription';
    }
    return null;
  }

  /// Dùng trong test / debug mà không cần AppLinks.
  static String? mapForTest(Uri uri) => _mapToResultRoute(uri);

  void dispose() {
    _sub?.cancel();
  }
}

/// Widget bọc `MaterialApp.router` để kích hoạt handler một lần.
class PaymentDeepLinkObserver extends StatefulWidget {
  final GoRouter router;
  final Widget child;

  const PaymentDeepLinkObserver({
    super.key,
    required this.router,
    required this.child,
  });

  @override
  State<PaymentDeepLinkObserver> createState() =>
      _PaymentDeepLinkObserverState();
}

class _PaymentDeepLinkObserverState extends State<PaymentDeepLinkObserver> {
  PaymentDeepLinkHandler? _handler;

  @override
  void initState() {
    super.initState();
    _handler = PaymentDeepLinkHandler(router: widget.router);
    _handler!.init();
  }

  @override
  void dispose() {
    _handler?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
