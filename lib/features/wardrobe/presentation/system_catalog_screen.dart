import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/closy_network_image.dart';
import '../models/wardrobe_models.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/system_catalog_provider.dart';

/// Màn hình tủ đồ hệ thống (US3).
/// Mirror FE `/wardrobe/explore`: duyệt + lọc danh mục + tìm kiếm +
/// tick chọn nhiều + thêm vào tủ cá nhân qua `POST /wardrobe-items/catalog-init`.
class SystemCatalogScreen extends ConsumerStatefulWidget {
  const SystemCatalogScreen({super.key});

  @override
  ConsumerState<SystemCatalogScreen> createState() =>
      _SystemCatalogScreenState();
}

class _SystemCatalogScreenState extends ConsumerState<SystemCatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    final notifier = ref.read(systemCatalogProvider.notifier);
    final count = ref.read(systemCatalogProvider).selectedCount;
    try {
      final added = await notifier.initSelected();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm $added món từ tủ hệ thống vào tủ đồ của bạn.'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
      // Về lại Wardrobe (tủ cá nhân đã được refresh trong provider).
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      final message = ref.read(systemCatalogProvider).errorMessage ??
          'Không thể thêm đồ từ tủ hệ thống. Vui lòng thử lại (đã giữ nguyên $count lựa chọn).';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(systemCatalogProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Tủ đồ hệ thống',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref
                .read(systemCatalogProvider.notifier)
                .loadCatalog(refresh: true),
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thêm nhanh các trang phục từ hệ thống vào tủ đồ của bạn.',
                          style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        // Search (debounce 500ms trong provider, giống FE)
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm trang phục...',
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: AppColors.textSecondary),
                            suffixIcon:
                                _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded,
                                            size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          ref
                                              .read(systemCatalogProvider
                                                  .notifier)
                                              .setQueryDebounced('');
                                        },
                                      )
                                    : null,
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onChanged: (v) {
                            setState(() {});
                            ref
                                .read(systemCatalogProvider.notifier)
                                .setQueryDebounced(v);
                          },
                        ),
                        const SizedBox(height: 12),
                        // Category chips (reuse GET /categories)
                        categoriesAsync.when(
                          data: (categories) => SizedBox(
                            height: 44,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _CategoryChip(
                                  label: 'Tất cả',
                                  selected:
                                      catalogState.categorySlug == null,
                                  onSelected: () => ref
                                      .read(systemCatalogProvider.notifier)
                                      .selectCategory(null),
                                ),
                                ...categories.map(
                                  (cat) => _CategoryChip(
                                    label: cat.name,
                                    selected: catalogState.categorySlug ==
                                        cat.slug,
                                    onSelected: () => ref
                                        .read(systemCatalogProvider.notifier)
                                        .selectCategory(cat.slug),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          loading: () => const SizedBox(height: 44),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 8),
                        if (catalogState.total > 0)
                          Text(
                            '${catalogState.total} mẫu có sẵn',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                _buildGridSliver(catalogState),
                // Load-more indicator
                if (catalogState.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),

          // Bottom action bar (giống FE floating bar)
          if (catalogState.selectedCount > 0)
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Đã chọn ${catalogState.selectedCount} mẫu',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: catalogState.isAdding ? null : _handleAdd,
                        icon: catalogState.isAdding
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.add_rounded, size: 18),
                        label: Text(catalogState.isAdding
                            ? 'Đang thêm...'
                            : 'Thêm vào tủ đồ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentSand,
                          foregroundColor: AppColors.primary,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridSliver(SystemCatalogState catalogState) {
    if (catalogState.isLoading && catalogState.items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (catalogState.errorMessage != null && catalogState.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined,
                    size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(catalogState.errorMessage!,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .read(systemCatalogProvider.notifier)
                      .loadCatalog(refresh: true),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (catalogState.items.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Không có trang phục nào trong catalog.',
              style:
                  TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Load-more khi chạm gần cuối (giữ lại 4 item dự phòng).
            if (index >= catalogState.items.length - 4 &&
                catalogState.hasMore &&
                !catalogState.isLoadingMore) {
              Future.microtask(() => ref
                  .read(systemCatalogProvider.notifier)
                  .loadCatalog());
            }
            final item = catalogState.items[index];
            final isSelected =
                catalogState.selectedIds.contains(item.id);
            final alreadyOwned = ref
                .watch(systemCatalogProvider.notifier)
                .isInMyWardrobe(item.id);
            return _CatalogCard(
              item: item,
              selected: isSelected,
              alreadyOwned: alreadyOwned,
              onTap: () => ref
                  .read(systemCatalogProvider.notifier)
                  .toggleSelect(item.id),
            );
          },
          childCount: catalogState.items.length,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: AppColors.primary,
        // Tick trắng cùng màu chữ khi chọn (US 007).
        checkmarkColor: selected ? Colors.white : AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Card catalog: KHÔNG dùng Hero (tránh đụng flight với tag `item_*`
/// của list/detail khi push route). Tap = tick chọn (luôn ở select-mode, giống FE).
class _CatalogCard extends StatelessWidget {
  final WardrobeItemModel item;
  final bool selected;
  final bool alreadyOwned;
  final VoidCallback onTap;

  const _CatalogCard({
    required this.item,
    required this.selected,
    required this.alreadyOwned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2.0 : 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: alreadyOwned ? null : onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: const Color(0xFFF2EFE9),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClosyNetworkImage(
                          imageUrl: item.displayImageUrl,
                          fit: BoxFit.contain,
                          memCacheWidth: 400,
                        ),
                      ),
                      if (selected)
                        Container(color: AppColors.primary.withOpacity(0.12)),
                      if (selected)
                        const Positioned(
                          top: 8,
                          left: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.check_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      if (alreadyOwned)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Đã có trong tủ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayCategoryName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
