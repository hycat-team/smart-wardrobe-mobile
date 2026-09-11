import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Đếm thế hệ phiên đăng nhập, sống trong root [ProviderScope].
///
/// Tăng giá trị này khi đăng xuất để [ProviderScope] lồng bên trong
/// (key theo session) bị dispose toàn bộ: mọi provider chứa dữ liệu
/// user (profile, wardrobe, subscription, wallet, stylist, outfit...)
/// được tạo lại từ đầu cho lần đăng nhập kế tiếp.
///
/// Không có cơ chế này, state trong RAM của tài khoản A sẽ rò rỉ sang
/// tài khoản B vì các StateNotifierProvider không autoDispose.
final sessionProvider = StateProvider<int>((ref) => 0);
