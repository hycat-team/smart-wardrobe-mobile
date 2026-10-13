import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/outfit_studio/layout/canvas_layout.dart';
import 'package:smart_wardrobe/features/outfit_studio/models/outfit_models.dart';
import 'package:smart_wardrobe/features/outfit_studio/providers/outfit_studio_provider.dart';
import 'package:smart_wardrobe/features/wardrobe/models/wardrobe_models.dart';

void main() {
  const multiplier = 1.25;
  const margin = 8.0;
  const tolerance = 0.01;

  const canvasSizes = <({double w, double h})>[
    (w: 360.0, h: 640.0),
    (w: 430.0, h: 932.0),
  ];

  double widthOf(CanvasItem it) => it.baseScale * it.boxRatioW * it.scale * multiplier;
  double heightOf(CanvasItem it) => it.baseScale * it.boxRatioH * it.scale * multiplier;

  CanvasItem roleItem(String id, CanvasRole role, {required double positionY}) {
    final placement =
        roleCoordinatesSeparate[role] ?? roleCoordinatesSeparate[CanvasRole.other]!;
    final box = roleBoundingBoxRatios[role] ?? roleBoundingBoxRatios[CanvasRole.unknown]!;
    return CanvasItem(
      id: id,
      fashionItemId: 'fashion-$id',
      imageUrl: 'https://example.com/$id.png',
      name: id,
      role: role.name,
      positionX: placement.x,
      positionY: positionY,
      scale: 1.0,
      layerOrder: placement.zIndex,
      baseScale: placement.scale,
      boxRatioW: box.widthRatio,
      boxRatioH: box.heightRatio,
    );
  }

  CanvasItem baseOf(List<CanvasItem> items) =>
      items.firstWhere((i) => i.role == CanvasRole.top.name || i.role == CanvasRole.fullbody.name);
  CanvasItem outerwearOf(List<CanvasItem> items) =>
      items.firstWhere((i) => i.role == CanvasRole.outerwear.name);

  void expectInside(CanvasItem it, double w, double h, String label) {
    final itemW = widthOf(it);
    final itemH = heightOf(it);
    expect(
      it.positionX - itemW / 2,
      greaterThanOrEqualTo(-w / 2 + margin - tolerance),
      reason: '$label tràn trái trên ${w.toInt()}x${h.toInt()}',
    );
    expect(
      it.positionX + itemW / 2,
      lessThanOrEqualTo(w / 2 - margin + tolerance),
      reason: '$label tràn phải trên ${w.toInt()}x${h.toInt()}',
    );
    expect(
      it.positionY - itemH / 2,
      greaterThanOrEqualTo(-h / 2 + margin - tolerance),
      reason: '$label tràn trên trên ${w.toInt()}x${h.toInt()}',
    );
    expect(
      it.positionY + itemH / 2,
      lessThanOrEqualTo(h / 2 - margin + tolerance),
      reason: '$label tràn dưới trên ${w.toInt()}x${h.toInt()}',
    );
  }

  /// Chồng nhẹ kiểu layer: hai món vẫn phủ lên nhau (không tách rời hoàn toàn),
  /// nhưng lớp nền lộ ra một phần; áo khoác ở lớp trên và đã dịch khỏi tâm nền.
  void expectLayerOverlap(CanvasItem base, CanvasItem outw, double w, double h) {
    final baseL = base.positionX - widthOf(base) / 2;
    final baseR = base.positionX + widthOf(base) / 2;
    final outL = outw.positionX - widthOf(outw) / 2;
    final outR = outw.positionX + widthOf(outw) / 2;

    // Có chồng ngang (không né hoàn toàn).
    expect(outL, lessThan(baseR), reason: 'outerwear né hoàn toàn nền trên ${w.toInt()}x${h.toInt()}');
    expect(outR, greaterThan(baseL), reason: 'outerwear né hoàn toàn nền trên ${w.toInt()}x${h.toInt()}');

    // Nền lộ ra một phần (nhô ra ngoài áo khoác ở ít nhất một phía).
    expect(
      baseL < outL || baseR > outR,
      isTrue,
      reason: 'áo khoác che kín nền (không lộ) trên ${w.toInt()}x${h.toInt()}',
    );

    // Áo khoác dịch khỏi tâm nền (đúng đặc trưng layer).
    expect(outw.positionX, isNot(closeTo(base.positionX, 0.5)));
    expect(outw.layerOrder, greaterThan(base.layerOrder));
  }

  group('layoutOuterwearOverBase', () {
    for (final size in canvasSizes) {
      test('(a) top + outerwear chồng nhẹ & nền không dời trên ${size.w.toInt()}x${size.h.toInt()}', () {
        final items = [
          roleItem('top', CanvasRole.top, positionY: -140),
          roleItem('outerwear', CanvasRole.outerwear, positionY: -145),
        ];
        final topBefore = items[0];

        final result = layoutOuterwearOverBase(
          items,
          canvasWidth: size.w,
          canvasHeight: size.h,
        );

        final base = baseOf(result);
        final outw = outerwearOf(result);

        // Lớp nền giữ nguyên vị trí & tỉ lệ (không bị dời).
        expect(base.positionX, closeTo(topBefore.positionX, tolerance));
        expect(base.positionY, closeTo(topBefore.positionY, tolerance));
        expect(base.scale, closeTo(topBefore.scale, tolerance));

        expectLayerOverlap(base, outw, size.w, size.h);
        expectInside(base, size.w, size.h, 'top');
        expectInside(outw, size.w, size.h, 'outerwear');
      });

      test('(b) fullbody + outerwear chồng nhẹ & nền không dời trên ${size.w.toInt()}x${size.h.toInt()}', () {
        final items = [
          roleItem('dress', CanvasRole.fullbody, positionY: -15),
          roleItem('outerwear', CanvasRole.outerwear, positionY: -145),
        ];
        final dressBefore = items[0];

        final result = layoutOuterwearOverBase(
          items,
          canvasWidth: size.w,
          canvasHeight: size.h,
        );

        final base = baseOf(result);
        final outw = outerwearOf(result);

        expect(base.positionX, closeTo(dressBefore.positionX, tolerance));
        expect(base.positionY, closeTo(dressBefore.positionY, tolerance));
        expect(base.scale, closeTo(dressBefore.scale, tolerance));

        expectLayerOverlap(base, outw, size.w, size.h);
        expectInside(base, size.w, size.h, 'fullbody');
        expectInside(outw, size.w, size.h, 'outerwear');
      });
    }

    test('(c) chỉ outerwear (không lớp nền) → không dịch chuyển', () {
      final items = [
        roleItem('outerwear', CanvasRole.outerwear, positionY: -145),
        roleItem('acc', CanvasRole.accessory, positionY: 40),
      ];
      final beforeX = items.map((i) => i.positionX).toList();
      final beforeY = items.map((i) => i.positionY).toList();
      final beforeScale = items.map((i) => i.scale).toList();

      final result = layoutOuterwearOverBase(
        items,
        canvasWidth: 390,
        canvasHeight: 700,
      );

      expect(identical(result, items), isTrue);
      for (var i = 0; i < result.length; i++) {
        expect(result[i].positionX, beforeX[i]);
        expect(result[i].positionY, beforeY[i]);
        expect(result[i].scale, beforeScale[i]);
      }
    });
  });

  group('Studio addItemToCanvas outerwear layout', () {
    const canvasW = 390.0;
    const canvasH = 700.0;

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

    test('(d) thêm áo rồi áo khoác → chồng nhẹ, áo không bị dời, trong khung', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(outfitStudioProvider.notifier);
      notifier.setCanvasSize(canvasW, canvasH);

      notifier.addItemToCanvas(fixture('top1', 'Áo thun', 'ao'));
      final topBefore = container.read(outfitStudioProvider).canvasItems.first;

      notifier.addItemToCanvas(fixture('coat1', 'Áo khoác dạ', 'ao-khoac'));

      final items = container.read(outfitStudioProvider).canvasItems;
      expect(items.length, 2);

      final base = baseOf(items);
      final outw = outerwearOf(items);

      // Áo thường giữ nguyên vị trí (không bị dời khi thêm áo khoác).
      expect(base.positionX, closeTo(topBefore.positionX, tolerance));
      expect(base.positionY, closeTo(topBefore.positionY, tolerance));

      expectLayerOverlap(base, outw, canvasW, canvasH);
      expectInside(outw, canvasW, canvasH, 'outerwear');
    });

    test('(e) thêm giày/phụ kiện sau áo không reset vị trí áo', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(outfitStudioProvider.notifier);
      notifier.setCanvasSize(canvasW, canvasH);

      notifier.addItemToCanvas(fixture('top1', 'Áo thun', 'ao'));
      final before = container.read(outfitStudioProvider).canvasItems.first;
      final posX = before.positionX;
      final posY = before.positionY;
      final scale = before.scale;

      notifier.addItemToCanvas(fixture('shoe1', 'Giày sneaker', 'giay'));

      final after = container.read(outfitStudioProvider).canvasItems.first;
      expect(after.positionX, posX);
      expect(after.positionY, posY);
      expect(after.scale, scale);
    });

    test('(f) thêm quần SAU áo+khoác không chồng/dời áo (món khác loại)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(outfitStudioProvider.notifier);
      notifier.setCanvasSize(canvasW, canvasH);

      notifier.addItemToCanvas(fixture('top1', 'Áo thun', 'ao'));
      notifier.addItemToCanvas(fixture('coat1', 'Áo khoác dạ', 'ao-khoac'));
      final topBefore = baseOf(container.read(outfitStudioProvider).canvasItems);

      notifier.addItemToCanvas(fixture('bot1', 'Quần jean', 'quan'));

      final topAfter = baseOf(container.read(outfitStudioProvider).canvasItems);
      expect(topAfter.positionX, closeTo(topBefore.positionX, tolerance));
      expect(topAfter.positionY, closeTo(topBefore.positionY, tolerance));
      expect(topAfter.scale, closeTo(topBefore.scale, tolerance));
    });
  });
}
