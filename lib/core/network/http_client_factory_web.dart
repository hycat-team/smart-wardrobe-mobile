import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// Web: client gửi kèm credentials (cookie HttpOnly) cho phiên đăng nhập web
/// — cần cho SSE (`/wardrobe-items/tasks/:id/sse`) và chat stream khi web
/// dùng luồng redirect (phiên cookie thay vì Bearer).
http.Client createHttpClient() {
  final client = BrowserClient();
  client.withCredentials = true;
  return client;
}
