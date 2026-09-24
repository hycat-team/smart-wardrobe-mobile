import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wardrobe_stats_models.dart';
import 'wardrobe_provider.dart';

/// Gói thống kê tổng hợp cho màn Thống kê (spec 009).
/// Tái dùng [wardrobeRepositoryProvider] sẵn có; làm mới bằng
/// `ref.invalidate(wardrobeStatisticsProvider)`.
final wardrobeStatisticsProvider =
    FutureProvider.autoDispose<StatsBundle>((ref) async {
  final repo = ref.watch(wardrobeRepositoryProvider);
  return await repo.getWardrobeStatistics();
});
