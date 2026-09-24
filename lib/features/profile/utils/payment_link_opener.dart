import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// @Deprecated: Luồng thanh toán đã chuyển lên website
/// (009-web-payment-redirect). Mobile không tạo và không mở bất kỳ
/// link thanh toán nào — hàm này không còn được gọi từ UI.
/// Giữ lại để tránh vỡ các màn hình cũ chưa xóa; KHÔNG dùng cho code mới.
@Deprecated('Thanh toán chuyển lên website — không mở checkout trong app')
Future<bool> openPaymentLink(
  BuildContext context, {
  required String paymentUrl,
  required int orderCode,
}) async {
  final url = paymentUrl.trim();
  if (url.isEmpty) {
    _notify(context,
        'Không tìm thấy link thanh toán (mã #$orderCode). Vui lòng tạo mã mới.');
    return false;
  }

  late final Uri uri;
  try {
    uri = Uri.parse(url);
  } catch (_) {
    _notify(context, 'Link thanh toán không hợp lệ (mã #$orderCode).');
    return false;
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    _notify(context, 'Link thanh toán không hợp lệ (mã #$orderCode).');
    return false;
  }

  try {
    debugPrint('[PayOS] Opening $url (order #$orderCode)');
    final canOpen = await canLaunchUrl(uri);
    debugPrint('[PayOS] canLaunchUrl=$canOpen');
    if (canOpen) {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('[PayOS] launchUrl=$opened');
      if (opened) return true;
    }
  } catch (e) {
    debugPrint('[PayOS] open failed: $e');
  }

  // Fallback: copy link để user tự mở thay vì treo ở màn hình chờ.
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return false;
  _notify(
    context,
    'Không mở được trình duyệt tự động. Đã sao chép link (mã #$orderCode) — hãy dán vào trình duyệt để thanh toán.',
  );
  return false;
}

void _notify(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
  );
}
