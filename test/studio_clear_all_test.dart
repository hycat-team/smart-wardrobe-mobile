import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/outfit_studio/providers/outfit_studio_provider.dart';
import 'package:smart_wardrobe/features/wardrobe/models/wardrobe_models.dart';

void main() {
  const item1 = WardrobeItemModel(
    id: 'wardrobe-1',
    fashionItem: FashionItemModel(
      id: 'fashion-1',
      imageUrl: 'https://example.com/shirt.png',
      style: 'Casual',
      color: 'Trắng',
      category: CategoryModel(id: 'cat-top', name: 'Áo', slug: 'top'),
    ),
  );
  const item2 = WardrobeItemModel(
    id: 'wardrobe-2',
    fashionItem: FashionItemModel(
      id: 'fashion-2',
      imageUrl: 'https://example.com/jeans.png',
      style: 'Casual',
      color: 'Xanh',
      category: CategoryModel(id: 'cat-bottom', name: 'Quần', slug: 'quan'),
    ),
  );

  group('Studio clear canvas — Xóa tất cả (US3)', () {
    test('clearCanvas() removes every canvas item and clears the selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(outfitStudioProvider.notifier);

      notifier.addItemToCanvas(item1);
      notifier.addItemToCanvas(item2);

      expect(container.read(outfitStudioProvider).canvasItems.length, 2);

      notifier.selectItem(0);
      expect(container.read(outfitStudioProvider).selectedIndex, 0);

      notifier.clearCanvas();

      final state = container.read(outfitStudioProvider);
      expect(state.canvasItems, isEmpty);
      expect(state.selectedIndex, isNull);
    });
  });
}
