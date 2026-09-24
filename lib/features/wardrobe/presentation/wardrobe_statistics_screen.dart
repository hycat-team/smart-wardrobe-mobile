import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/stats_bar_chart.dart';
import '../models/wardrobe_stats_models.dart';
import '../providers/wardrobe_stats_provider.dart';

/// Màn Thống kê chi tiết (spec 009).
/// Màn RIÊNG, bổ sung cho `/wardrobe/insights` hiện có (không thay thế).
/// Gồm 4 nhóm: (a) mức độ sử dụng, (b) giá trị & cost-per-wear,
/// (c) outfit, (d) xu hướng 6 tháng. Các chỉ số thiếu dữ liệu máy chủ
/// (cost-per-wear, xu hướng) được ẩn kèm ghi chú rõ ràng (FR-014).
class WardrobeStatisticsScreen extends ConsumerWidget {
  const WardrobeStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(wardrobeStatisticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Thống kê chi tiết',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Làm mới',
            onPressed: () => ref.invalidate(wardrobeStatisticsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(wardrobeStatisticsProvider);
        },
        color: AppColors.primary,
        child: statsAsync.when(
          data: (stats) => _buildBody(context, stats),
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => _buildError(context, ref, '$err'),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_outlined,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Không thể tải số liệu thống kê: $err',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(wardrobeStatisticsProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, StatsBundle stats) {
    if (!stats.hasData) {
      return _buildEmpty(context);
    }
    final u = stats.utilization;
    final v = stats.value;
    final catTotal =
        v.byCategory.fold<int>(0, (sum, c) => sum + c.itemCount);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // 1. Tổng quan.
        _buildHeroCard(
          title: 'TỔNG QUAN TỦ ĐỒ',
          bigValue: '${u.totalItems}',
          bigUnit: 'món',
          note:
              'Tỷ lệ sử dụng ${u.formattedRate} (dựa trên số món mặc trong 30 ngày gần nhất).',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.history_rounded,
                title: '>30 ngày',
                value: '${u.unused30}',
                unit: 'món',
                accentColor: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.history_toggle_off_rounded,
                title: '>60 ngày',
                value: '${u.unused60}',
                unit: 'món',
                accentColor: const Color(0xFFB45309),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.hourglass_bottom_rounded,
                title: '>90 ngày',
                value: '${u.unused90}',
                unit: 'món',
                accentColor: const Color(0xFF92400E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // 2. Giá trị.
        const _SectionTitle('GIÁ TRỊ TỦ ĐỒ'),
        const SizedBox(height: 12),
        _buildHeroCard(
          title: 'TỔNG GIÁ TRỊ ƯỚC TÍNH',
          bigValue: v.formattedTotalValue,
          bigUnit: null,
          note: 'Dựa trên giá mua các món đã nhập.'
              '${v.missingPriceCount > 0 ? ' Còn ${v.missingPriceCount} món chưa nhập giá nên chưa được tính.' : ''}',
        ),
        const SizedBox(height: 16),
        if (v.byCategory.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.6),
            ),
            child: Column(
              children: v.byCategory.map((c) {
                final pct = catTotal > 0
                    ? (c.itemCount / catTotal).clamp(0.0, 1.0)
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              c.categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${c.itemCount} món (${(pct * 100).toStringAsFixed(1)}%)',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceSubtle,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.accentSandDark),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 28),
        ],

        // 3. Cost-per-wear (fallback khi chưa có dữ liệu mặc).
        const _SectionTitle('CHI PHÍ MỖI LẦN MẶC'),
        const SizedBox(height: 12),
        if (stats.wearDataAvailable && stats.costPerWearItems.isNotEmpty)
          ...stats.costPerWearItems
              .take(10)
              .map((c) => _buildCostPerWearRow(c))
        else
          const _FallbackNotice(
            message:
                'Chưa có dữ liệu số lần mặc từ máy chủ nên chưa tính được chi phí mỗi lần mặc. '
                'Số liệu sẽ hiển thị khi tính năng theo dõi lượt mặc được bật.',
          ),
        const SizedBox(height: 28),

        // 4. Outfit.
        const _SectionTitle('OUTFIT'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.checkroom_rounded,
                title: 'Outfit đã lưu',
                value: '${stats.outfits.totalOutfits}',
                unit: 'bộ',
                accentColor: AppColors.primary,
              ),
            ),
            if (stats.outfits.usedOutfits != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Outfit đã dùng',
                  value: '${stats.outfits.usedOutfits}',
                  unit: 'bộ',
                  accentColor: AppColors.accentSandDark,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 28),

        // 5. Xu hướng 6 tháng.
        const _SectionTitle('XU HƯỚNG 6 THÁNG'),
        const SizedBox(height: 12),
        if (stats.hasTrendData)
          StatsBarChart(points: stats.trend)
        else
          const _FallbackNotice(
            message:
                'Chưa đủ dữ liệu lịch sử mặc để vẽ xu hướng. '
                'Biểu đồ sẽ hiển thị khi có số liệu tối thiểu 2 tháng.',
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart_outlined,
                size: 48, color: AppColors.accentSandDark),
            const SizedBox(height: 12),
            Text(
              'Tủ đồ của bạn chưa có món nào',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thêm món đồ đầu tiên để xem thống kê sử dụng, giá trị và xu hướng.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/wardrobe'),
              child: const Text('Thêm món đồ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required String title,
    required String bigValue,
    required String? bigUnit,
    required String note,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF111111)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.accentSand,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  bigValue,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (bigUnit != null) ...[
                const SizedBox(width: 8),
                Text(
                  bigUnit,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style:
                const TextStyle(fontSize: 12, color: Colors.white60, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostPerWearRow(CostPerWear c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              c.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            c.formattedCostPerWear,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _FallbackNotice extends StatelessWidget {
  final String message;

  const _FallbackNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.accentSandDark, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
