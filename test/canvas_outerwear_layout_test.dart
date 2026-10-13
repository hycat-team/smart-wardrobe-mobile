import 'dart:math' as math;

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
    expect(it.positionX - itemW / 2, greaterThanOrEqualTo(-w / 2 + margin - tolerance),
        reason: '$label tràn trái trên ${w.toInt()}x${h.toInt()}');
    expect(it.positionX + itemW / 2, lessThanOrEqualTo(w / 2 - margin + tolerance),
        reason: '$label tràn phải trên ${w.toInt()}x${h.toInt()}');
    expect(it.positionY - itemH / 2, greaterThanOrEqualTo(-h / 2 + margin - tolerance),
        reason: '$label tràn trên trên ${w.toInt()}x${h.toInt()}');
    expect(it.positionY + itemH / 2, lessThanOrEqualTo(h / 2 - margin + tolerance),
        reason: '$label tràn dưới trên ${w.toInt()}x${h.toInt()}');
  }

  /// Áo khoác chồng lên lớp nền đúng ~20% bề rộng nền; nền không dời.
  void expectTwentyPercentOverlap(CanvasItem base, CanvasItem outw, double w, double h) {
    final baseW = widthOf(base);
    final baseL = base.positionX - baseW / 2;
    final baseR = base.positionX + baseW / 2;
    final outL = outw.positionX - widthOf(outw) / 2;
    final outR = outw.positionX + widthOf(outw) / 2;
    final overlap = (math.min(baseR, outR) - math.max(baseL, outL)).clamp(0.0, double.infinity);
    expect(overlap, closeTo(0.20 * baseW, 1.5),
        reason: 'chồng không ~20% nền trên ${w.toInt()}x${h.toInt()} (overlap=$overlap)');
    expect(outw.layerOrder, greaterThan(base.layerOrder));
  }

  group('layoutOuterwearOverBase', () {
    for (final size in canvasSizes) {
      test('(a) top + outerwear chồng ~20%, nền không dời trên ${size.w.toInt()}x${size.h.toInt()}', () {
        final items = [
          roleItem('top', CanvasRole.top, positionY: -140),
          roleItem('outerwear', CanvasRole.outerwear, positionY: -145),
        ];
        final topBefore = items[0];

        final result = layoutOuterwearOverBase(items, canvasWidth: size.w, canvasHeight: size.h);
        final base = baseOf(result);
        final outw = outerwearOf(result);

        expect(base.positionX, closeTo(topBefore.positionX, tolerance));
        expect(base.positionY, closeTo(topBefore.positionY, tolerance));
        expect(base.scale, closeTo(topBefore.scale, tolerance));

        expectTwentyPercentOverlap(base, outw, size.w, size.h);
        expectInside(base, size.w, size.h, 'top');
        expectInside(outw, size.w, size.h, 'outerwear');
      });

      test('(b) fullbody + outerwear chồng ~20%, nền không dời trên ${size.w.toInt()}x${size.h.toInt()}', () {
        final items = [
          roleItem('dress', CanvasRole.fullbody, positionY: -15),
          roleItem('outerwear', CanvasRole.outerwear, positionY: -145),
        ];
        final dressBefore = items[0];

        final result = layoutOuterwearOverBase(items, canvasWidth: size.w, canvasHeight: size.h);
        final base = baseOf(result);
        final outw = outerwearOf(result);

        expect(base.positionX, closeTo(dressBefore.positionX, tolerance));
        expect(base.positionY, closeTo(dressBefore.positionY, tolerance));
        expect(base.scale, closeTo(dressBefore.scale, tolerance));

        expectTwentyPercentOverlap(base, outw, size.w, size.h);
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

      final result = layoutOuterwearOverBase(items, canvasWidth: 390, canvasHeight: 700);

      expect(identical(result, items), isTrue);
      for (var i = 0; i < result.length; i++) {
        expect(result[i].positionX, beforeX[i]);
        expect(result[i].positionY, beforeY[i]);
        expect(result[i].scale, beforeScale[i]);
      }
    });
  });

  group('Studio addItemToCanvas', () {
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

    test('(d) thêm áo rồi áo khoác → chồng ~20%, áo không bị dời, trong khung', () {
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

      expect(base.positionX, closeTo(topBefore.positionX, tolerance));
      expect(base.positionY, closeTo(topBefore.positionY, tolerance));
      expectTwentyPercentOverlap(base, outw, canvasW, canvasH);
      expectInside(outw, canvasW, canvasH, 'outerwear');
    });

    test('(e) thêm giày/phụ kiện sau áo không reset vị trí áo', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(outfitStudioProvider.notifier);
      notifier.setCanvasSize(canvasW, canvasH);

      notifier.addItemToCanvas(fixture('top1', 'Áo thun', 'ao'));
      final before = container.read(outfitStudioProvider).canvasItems.first;

      notifier.addItemToCanvas(fixture('shoe1', 'Giày sneaker', 'giay'));

      final after = container.read(outfitStudioProvider).canvasItems.first;
      expect(after.positionX, before.positionX);
      expect(after.positionY, before.positionY);
      expect(after.scale, before.scale);
    });

    test('(f) thêm quần SAU áo+khoác không dời áo (món khác loại)', () {
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

    test('(g) thay giày cùng loại → giữ đúng vị trí + kích thước món cũ', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(outfitStudioProvider.notifier);
      notifier.setCanvasSize(canvasW, canvasH);

      notifier.addItemToCanvas(fixture('shoe1', 'Giày A', 'giay'));
      notifier.updateItemPosition(0, 30, -40);
      notifier.updateItemScale(0, 1.2);

      final before = container.read(outfitStudioProvider).canvasItems.single;

      notifier.addItemToCanvas(fixture('shoe2', 'Giày B', 'giay'));

      final after = container.read(outfitStudioProvider).canvasItems.single;
      expect(after.id, isNot(before.id));
      expect(after.fashionItemId, 'fashion-shoe2');
      expect(after.positionX, closeTo(before.positionX, tolerance));
      expect(after.positionY, closeTo(before.positionY, tolerance));
      expect(after.scale, closeTo(before.scale, tolerance));
    });
  });
}
