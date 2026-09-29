import 'package:web/web.dart' as web;

/// Dọn sạch toàn bộ storage và cookie trong trình duyệt Web khi người dùng đăng xuất.
void clearWebBrowserStorage() {
  try {
    web.window.localStorage.clear();
  } catch (_) {}

  try {
    web.window.sessionStorage.clear();
  } catch (_) {}

  try {
    final cookieStr = web.document.cookie;
    if (cookieStr.isNotEmpty) {
      final cookies = cookieStr.split(';');
      for (final c in cookies) {
        final eqPos = c.indexOf('=');
        final name = (eqPos > -1 ? c.substring(0, eqPos) : c).trim();
        if (name.isNotEmpty) {
          web.document.cookie = '$name=; Max-Age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/;';
          try {
            final host = web.window.location.hostname;
            if (host.isNotEmpty && host != 'localhost') {
              web.document.cookie = '$name=; Max-Age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/; domain=$host;';
            }
          } catch (_) {}
        }
      }
    }
  } catch (_) {}
}
