import 'package:flutter/foundation.dart';

/// Cờ release cho bản phát hành Google Play (spec 008).
///
/// - `ENABLE_PAID_FEATURES=false` (mặc định): ẩn mọi luồng thu tiền kỹ
///   thuật số (gói subscription, nạp ví PayOS) và deep-link thanh toán,
///   theo yêu cầu Google Play Billing cho hàng hóa số.
/// - Dev/local có thể bật bằng `--dart-define=ENABLE_PAID_FEATURES=true`
///   để kiểm thử luồng thanh toán.
class ReleaseFlags {
  static const bool enablePaidFeatures =
      bool.fromEnvironment('ENABLE_PAID_FEATURES', defaultValue: false);

  /// true khi chạy bản release thực tế (không phải debug/profile).
  static bool get isReleaseBuild => kReleaseMode;
}
