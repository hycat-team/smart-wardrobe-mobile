import 'package:flutter_web_plugins/url_strategy.dart';

/// Web: dùng URL dạng path (`/auth/callback`) thay vì hash (`/#/auth/callback`)
/// để khớp `redirectUrl` mà BE chuyển hướng về sau luồng Google redirect.
void configureUrlStrategy() {
  usePathUrlStrategy();
}
