import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/outfit_studio/providers/outfit_studio_provider.dart';
import 'package:smart_wardrobe/features/wardrobe/models/wardrobe_models.dart';

void main() {
  group('Studio Wardrobe Integration & Replacement Tests', () {
    test('replaceItemOnCanvas updates item on canvas while preserving position and layer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(outfitStudioProvider.notifier);

      // Add item 1: Áo thun
      const item1 = WardrobeItemModel(
        id: 'wardrobe-1',
        fashionItem: FashionItemModel(
          id: 'fashion-1',
          imageUrl: 'https://example.com/shirt1.png',
          style: 'Casual',
          color: 'Trắng',
          category: CategoryModel(id: 'cat-top', name: 'Áo', slug: 'top'),
        ),
      );
      notifier.addItemToCanvas(item1);

      expect(container.read(outfitStudioProvider).canvasItems.length, 1);
      final initialCanvasItem = container.read(outfitStudioProvider).canvasItems.first;
      expect(initialCanvasItem.name, contains('Áo'));
      final origPosX = initialCanvasItem.positionX;
      final origPosY = initialCanvasItem.positionY;
      final origLayer = initialCanvasItem.layerOrder;

      // Replace with item 2: Sơ mi
      const item2 = WardrobeItemModel(
        id: 'wardrobe-2',
        fashionItem: FashionItemModel(
          id: 'fashion-2',
          imageUrl: 'https://example.com/shirt2.png',
          style: 'Formal',
          color: 'Xanh',
          category: CategoryModel(id: 'cat-top', name: 'Áo', slug: 'top'),
        ),
      );
      notifier.replaceItemOnCanvas(0, item2);

      final replacedCanvasItem = container.read(outfitStudioProvider).canvasItems.first;
      expect(replacedCanvasItem.fashionItemId, 'fashion-2');
      expect(replacedCanvasItem.imageUrl, 'https://example.com/shirt2.png');
      expect(replacedCanvasItem.positionX, origPosX);
      expect(replacedCanvasItem.positionY, origPosY);
      expect(replacedCanvasItem.layerOrder, origLayer);
    });
  });
}
