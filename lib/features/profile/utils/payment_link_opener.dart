import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mở link PayOS bằng browser ngoài.
///
/// Không bao giờ fail im lặng:
/// - link rỗng / sai định dạng → SnackBar báo rõ + trả về false.
/// - không mở được browser (máy thiếu browser, scheme lạ, exception) →
///   tự sao chép link vào clipboard để user dán tay vào trình duyệt.
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
