import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/outfit_studio/models/outfit_models.dart';
import 'package:smart_wardrobe/features/outfit_studio/providers/outfit_studio_provider.dart';
import 'package:smart_wardrobe/features/wardrobe/models/wardrobe_models.dart';

void main() {
  const canvasSizes = <({double w, double h})>[
    (w: 320.0, h: 520.0),
    (w: 390.0, h: 700.0),
    (w: 430.0, h: 932.0),
  ];

  const multiplier = 1.25;
  const margin = 8.0;

  WardrobeItemModel fixture(String id, String name, String slug) {
    return WardrobeItemModel(
      id: id,
      fashionItem: FashionItemModel(
        id: 'fashion-$id',
        imageUrl: 'https://example.com/$id.png',
        style: 'Casual',
        color: 'Đen',
        category: CategoryModel(id: 'cat-$id', name: name, slug: slug),
      ),
    );
  }

  void expectInsideCanvas(List<CanvasItem> items, double w, double h) {
    for (final item in items) {
      final itemW = item.baseScale * item.boxRatioW * item.scale * multiplier;
      final itemH = item.baseScale * item.boxRatioH * item.scale * multiplier;
      expect(
        item.positionX - itemW / 2,
        greaterThanOrEqualTo(-w / 2 + margin - 0.01),
        reason: '${item.name} tràn trái trên canvas ${w.toInt()}x${h.toInt()}',
      );
      expect(
        item.positionX + itemW / 2,
        lessThanOrEqualTo(w / 2 - margin + 0.01),
        reason: '${item.name} tràn phải trên canvas ${w.toInt()}x${h.toInt()}',
      );
      expect(
        item.positionY - itemH / 2,
        greaterThanOrEqualTo(-h / 2 + margin - 0.01),
        reason: '${item.name} tràn trên trên canvas ${w.toInt()}x${h.toInt()}',
      );
      expect(
        item.positionY + itemH / 2,
        lessThanOrEqualTo(h / 2 - margin + 0.01),
        reason: '${item.name} tràn dưới trên canvas ${w.toInt()}x${h.toInt()}',
      );
    }
  }

  group('Studio Canvas Placement - manual add clamp (US1)', () {
    for (final size in canvasSizes) {
      test(
        'accessory/footwear/other stay inside bounds on ${size.w.toInt()}x${size.h.toInt()}',
        () {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          final notifier = container.read(outfitStudioProvider.notifier);
          notifier.setCanvasSize(size.w, size.h);

          notifier.addItemToCanvas(fixture('acc', 'Túi xách', 'phu-kien'));
          notifier.addItemToCanvas(fixture('shoe', 'Giày sneaker', 'giay'));
          notifier.addItemToCanvas(fixture('misc', 'Khác', 'misc'));

          final items = container.read(outfitStudioProvider).canvasItems;
          expect(items.length, 3);
          expectInsideCanvas(items, size.w, size.h);
        },
      );
    }

    test('thêm món thứ hai → cả hai nằm trong khung (fit-to-canvas)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(outfitStudioProvider.notifier);
      notifier.setCanvasSize(320, 520);

      notifier.addItemToCanvas(fixture('top', 'Áo thun', 'ao'));
      notifier.addItemToCanvas(fixture('acc', 'Túi xách', 'phu-kien'));

      final items = container.read(outfitStudioProvider).canvasItems;
      expect(items.length, 2);
      expectInsideCanvas(items, 320, 520);
    });
  });
}
