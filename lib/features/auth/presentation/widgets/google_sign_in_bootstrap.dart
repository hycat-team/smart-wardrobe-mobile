import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Khởi tạo Google Sign-In **đúng một lần** cho toàn app.
///
/// Vì sao cần lớp này: `main.dart` khởi tạo SDK lúc startup, các widget
/// (nút đăng nhập) cũng khởi tạo lại lúc mount. Với `google_sign_in` 7.x,
/// gọi `GoogleSignIn.instance.initialize()` lần thứ hai có thể ném lỗi và
/// làm luồng đăng nhập hỏng trên bản release — trong khi ở debug/web thường
/// không thấy vì lỗi bị `catch` nuốt.
class GoogleSignInBootstrap {
  GoogleSignInBootstrap._();

  static bool _initialized = false;
  static bool _initializing = false;
  static Future<void>? _pending;

  /// Đã khởi tạo xong chưa (dùng cho UI chờ).
  static bool get isInitialized => _initialized;

  /// Đảm bảo SDK đã sẵn sàng. Các lời gọi song song sẽ chung một Future.
  static Future<void> ensureInitialized(String clientId) async {
    if (_initialized) return;
    // Đang khởi tạo → chờ hết lần trước thay vì gọi chồng.
    if (_initializing) return _pending;

    _initializing = true;
    final completer = Completer<void>();
    _pending = completer.future;

    try {
      if (clientId.isNotEmpty) {
        await GoogleSignIn.instance.initialize(
          clientId: kIsWeb ? clientId : null,
          serverClientId: kIsWeb ? null : clientId,
        );
      }
      _initialized = true;
    } catch (e, st) {
      // Không ném ra: app vẫn chạy được các luồng đăng nhập khác
      // (email/mật khẩu). Chỉ ghi log để điều tra.
      debugPrint('Google Sign-In initialization failed: $e\n$st');
      // Vẫn đánh dấu đã thử để không gọi lại vô tận mỗi lần rebuild.
      _initialized = true;
    } finally {
      _initializing = false;
      if (!completer.isCompleted) completer.complete();
    }
  }

  /// Chỉ dùng cho test — đặt lại trạng thái singleton.
  @visibleForTesting
  static void debugReset() {
    _initialized = false;
    _initializing = false;
    _pending = null;
  }
}
