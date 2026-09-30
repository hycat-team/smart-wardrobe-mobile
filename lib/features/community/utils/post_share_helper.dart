import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/widgets/closy_toast.dart';

/// Tên miền web dùng để dựng link chia sẻ công khai cho bài viết cộng đồng.
const String kCommunityWebHost = 'closy.hycat.online';

/// Dựng URL tuyệt đối từ `sharePath` (đường dẫn tương đối do BE trả về).
///
/// BE trả `sharePath` dạng `/community/posts/<publicId>`. Người dùng cần một
/// URL đầy đủ để dán vào nơi khác (Zalo, Facebook, email…), nên ta ghép thêm
/// scheme `https` và host web.
String buildPostShareUrl(String sharePath) {
  var path = sharePath.trim();
  if (path.isEmpty) return 'https://$kCommunityWebHost/community';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  if (!path.startsWith('/')) path = '/$path';
  return 'https://$kCommunityWebHost$path';
}

/// Sao chép liên kết bài viết vào clipboard của hệ thống.
///
/// Trước đây chỉ hiện toast "Đã sao chép liên kết" mà **không** gọi
/// `Clipboard.setData`, nên trên Android bấm nút không copy được gì cả.
Future<void> copyPostLink(BuildContext context, String sharePath) async {
  final url = buildPostShareUrl(sharePath);
  try {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ClosyToast.success(context, 'Đã sao chép liên kết bài viết.');
    }
  } catch (e) {
    if (context.mounted) {
      ClosyToast.error(context, 'Không sao chép được. Link: $url');
    }
  }
}
