import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/closy_network_image.dart';
import '../models/product_model.dart';
import '../providers/marketplace_provider.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final List<String> _categories = ['All', 'Outerwear', 'Knitwear', 'Tailoring', 'Footwear'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketState = ref.watch(marketplaceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Search Bar & Filter Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  ref.read(marketplaceProvider.notifier).setSearchQuery(val);
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Search curate pieces, brands...',
                                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: const Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),

            // Categories Row
            SliverToBoxAdapter(
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = marketState.selectedCategory == cat;

                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(cat),
                      selectedColor: AppColors.accentSand,
                      backgroundColor: AppColors.surfaceSubtle,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: AppColors.primary,
                      ),
                      shape: const StadiumBorder(side: BorderSide(color: AppColors.border, width: 0.5)),
                      onSelected: (_) {
                        ref.read(marketplaceProvider.notifier).setCategory(cat);
                      },
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Product Grid
            if (marketState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (marketState.errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(marketState.errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(marketplaceProvider.notifier).loadProducts(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (marketState.products.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text('No curated items found.', style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 18,
                    childAspectRatio: 0.64,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = marketState.products[index];
                      return MarketplaceProductCard(
                        product: product,
                        onToggleFavorite: () {
                          ref.read(marketplaceProvider.notifier).toggleFavorite(product.id);
                        },
                      );
                    },
                    childCount: marketState.products.length,
                    addAutomaticKeepAlives: true,
                    addRepaintBoundaries: true,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class MarketplaceProductCard extends StatefulWidget {
  final MarketProductModel product;
  final VoidCallback onToggleFavorite;

  const MarketplaceProductCard({
    super.key,
    required this.product,
    required this.onToggleFavorite,
  });

  @override
  State<MarketplaceProductCard> createState() => _MarketplaceProductCardState();
}

class _MarketplaceProductCardState extends State<MarketplaceProductCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final product = widget.product;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0ECE6),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClosyNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 400,
                  memCacheHeight: 400,
                  errorWidget: const Center(
                    child: Icon(Icons.shopping_bag_outlined, size: 40, color: AppColors.accentSandDark),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: InkWell(
                    onTap: widget.onToggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        product.isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 16,
                        color: product.isFavorited ? Colors.redAccent : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.brand.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${product.price.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
      ],
    );
  }
}
