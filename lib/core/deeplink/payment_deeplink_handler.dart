import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Đón deep-link PayOS quay về app và điều hướng về trang thông báo.
///
/// - `smartwardrobe://subscription/success|cancel` → gói Premium.
/// - `smartwardrobe://wallet/topup/success|cancel` → nạp ví.
/// - Web: `/profile/payment/result?...` đã là route GoRouter, không cần xử lý.
///
/// Chỉ điều hướng; trạng thái thật do [PaymentResultScreen] verify lại qua BE.
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

  /// Map deep-link PayOS → route trang thông báo trong app.
  ///
  /// PayOS append thêm query của nó (`code`, `cancel`, `status`, `orderCode`)
  /// vào custom-scheme URL — giữ nguyên toàn bộ query để
  /// [PaymentResult.fromQuery] ưu tiên đọc param PayOS.
  static String? _mapToResultRoute(Uri uri) {
    // host: subscription | wallet ; path: /success | /cancel | /topup/success ...
    final host = uri.host.toLowerCase();
    final segments =
        uri.pathSegments.map((s) => s.toLowerCase()).toList();
    final last = segments.isNotEmpty ? segments.last : '';
    final isCancel = last == 'cancel' ||
        last == 'cancelled' ||
        last == 'canceled' ||
        last == 'fail' ||
        last == 'failed';

    final status = isCancel ? 'cancelled' : 'success';
    // Giữ lại query PayOS append (code/cancel/status/orderCode) để
    // PaymentResult.fromQuery đọc đúng; chỉ thêm kind còn thiếu.
    final merged = Map<String, String>.from(uri.queryParameters);
    merged.putIfAbsent('result', () => status);
    final kind = host == 'subscription' ? 'purchase' : 'topup';
    merged.putIfAbsent('kind', () => kind);
    final qs = merged.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    if (host == 'subscription' || host == 'wallet') {
      return '/profile/payment/result?$qs';
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
