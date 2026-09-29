import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier toàn cục để restart toàn bộ root [ProviderScope] khi đăng xuất hoặc đổi tài khoản.
final appSessionNotifier = ValueNotifier<int>(0);

void bumpAppSession() {
  appSessionNotifier.value++;
}

/// Đếm thế hệ phiên đăng nhập.
///
/// Tăng giá trị này khi đăng xuất hoặc chuyển tài khoản để toàn bộ
/// [ProviderScope] gốc bị dispose toàn bộ: mọi provider chứa dữ liệu
/// user (profile, wardrobe, subscription, wallet, stylist, outfit...)
/// được giải phóng hoàn toàn và tạo mới tinh khiết từ đầu.
final sessionProvider = StateProvider<int>((ref) {
  ref.listenSelf((previous, next) {
    if (next != appSessionNotifier.value) {
      bumpAppSession();
    }
  });
  return appSessionNotifier.value;
});
