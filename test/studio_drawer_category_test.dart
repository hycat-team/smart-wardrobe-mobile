import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/outfit_studio/providers/outfit_studio_provider.dart';
import 'package:smart_wardrobe/features/wardrobe/models/wardrobe_models.dart';

void main() {
  const outerwear = WardrobeItemModel(
    id: 'w-outer',
    fashionItem: FashionItemModel(
      id: 'f-outer',
      imageUrl: 'https://example.com/coat.png',
      style: 'Elegant',
      color: 'Be',
      category: CategoryModel(id: 'cat-outer', name: 'Áo khoác', slug: 'ao-khoac'),
    ),
  );
  const top = WardrobeItemModel(
    id: 'w-top',
    fashionItem: FashionItemModel(
      id: 'f-top',
      imageUrl: 'https://example.com/shirt.png',
      style: 'Casual',
      color: 'Trắng',
      category: CategoryModel(id: 'cat-top', name: 'Áo', slug: 'ao'),
    ),
  );
  const bottom = WardrobeItemModel(
    id: 'w-bottom',
    fashionItem: FashionItemModel(
      id: 'f-bottom',
      imageUrl: 'https://example.com/jeans.png',
      style: 'Casual',
      color: 'Xanh',
      category: CategoryModel(id: 'cat-bottom', name: 'Quần', slug: 'quan'),
    ),
  );
  const shoe = WardrobeItemModel(
    id: 'w-shoe',
    fashionItem: FashionItemModel(
      id: 'f-shoe',
      imageUrl: 'https://example.com/shoes.png',
      style: 'Casual',
      color: 'Đen',
      category: CategoryModel(id: 'cat-shoe', name: 'Giày', slug: 'giay'),
    ),
  );

  const allItems = [outerwear, top, bottom, shoe];

  group('Studio drawer category chip — "Áo khoác" / "Áo" (US2)', () {
    test('chip "Áo khoác" returns ONLY outerwear items', () {
      const state = OutfitStudioState(
        wardrobeItems: allItems,
        selectedDrawerCategory: 'Áo khoác',
      );

      final result = state.filteredWardrobeItems;

      expect(result.length, 1);
      expect(result.single.id, 'w-outer');
    });

    test('chip "Áo" excludes outerwear and includes the top', () {
      const state = OutfitStudioState(
        wardrobeItems: allItems,
        selectedDrawerCategory: 'Áo',
      );

      final result = state.filteredWardrobeItems;
      final ids = result.map((e) => e.id).toList();

      expect(ids, contains('w-top'));
      expect(ids, isNot(contains('w-outer')));
      expect(result.length, 1);
    });

    test('chip "All" returns every item', () {
      const state = OutfitStudioState(wardrobeItems: allItems);

      expect(state.filteredWardrobeItems.length, allItems.length);
    });
  });
}
