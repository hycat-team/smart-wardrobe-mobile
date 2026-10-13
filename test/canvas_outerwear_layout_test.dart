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

  CanvasItem roleItem(String id, CanvasRole role, {double? positionY, double x = 0}) {
    final placement =
        roleCoordinatesSeparate[role] ?? roleCoordinatesSeparate[CanvasRole.other]!;
    final box = roleBoundingBoxRatios[role] ?? roleBoundingBoxRatios[CanvasRole.unknown]!;
    return CanvasItem(
      id: id,
      fashionItemId: 'fashion-$id',
      imageUrl: 'https://example.com/$id.png',
      name: id,
      role: role.name,
      positionX: x,
      positionY: positionY ?? placement.y,
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

  void expectOuterwearEqualAndOverlaps(CanvasItem base, CanvasItem outw, double w, double h) {
    final baseW = widthOf(base);
    final owW = widthOf(outw);
    expect(owW, closeTo(baseW, 1.5),
        reason: 'áo khoác không bằng kích thước áo trên ${w.toInt()}x${h.toInt()}');
    final baseL = base.positionX - baseW / 2;
    final baseR = base.positionX + baseW / 2;
    final outL = outw.positionX - owW / 2;
    final outR = outw.positionX + owW / 2;
    final overlap = (math.min(baseR, outR) - math.max(baseL, outL)).clamp(0.0, double.infinity);
    expect(overlap, lessThanOrEqualTo(0.40 * baseW + 1.5),
        reason: 'áo khoác chiếm > 40% áo trên ${w.toInt()}x${h.toInt()}');
    expect(overlap, greaterThan(0), reason: 'áo khoác không chồng áo');
    expect(outw.layerOrder, greaterThan(base.layerOrder));
  }

  group('decorateAndFitOutfit — outerwear', () {
    for (final size in canvasSizes) {
      test('(a) top + outerwear: bằng áo, chồng ≤40%, trong khung ${size.w.toInt()}x${size.h.toInt()}', () {
        final items = [
          roleItem('top', CanvasRole.top),
          roleItem('outerwear', CanvasRole.outerwear),
        ];
        final result = decorateAndFitOutfit(items, canvasWidth: size.w, canvasHeight: size.h);
        final base = baseOf(result);
        final outw = outerwearOf(result);
        expectOuterwearEqualAndOverlaps(base, outw, size.w, size.h);
        expectInside(base, size.w, size.h, 'top');
        expectInside(outw, size.w, size.h, 'outerwear');
      });

      test('(b) fullbody + outerwear: bằng áo, chồng ≤40%, trong khung ${size.w.toInt()}x${size.h.toInt()}', () {
        final items = [
          roleItem('dress', CanvasRole.fullbody),
          roleItem('outerwear', CanvasRole.outerwear),
        ];
        final result = decorateAndFitOutfit(items, canvasWidth: size.w, canvasHeight: size.h);
        final base = baseOf(result);
        final outw = outerwearOf(result);
        expectOuterwearEqualAndOverlaps(base, outw, size.w, size.h);
        expectInside(outw, size.w, size.h, 'outerwear');
      });
    }

    test('(c) chỉ outerwear (không lớp nền) → fit theo bố cục chuẩn, trong khung', () {
      final items = [roleItem('outerwear', CanvasRole.outerwear)];

      final result = decorateAndFitOutfit(items, canvasWidth: 360, canvasHeight: 640);

      expect(result.length, 1);
      expectInside(result.first, 360, 640, 'outerwear');
    });

    test('(h) phụ kiện bên trái → áo khoác sang phải (đối diện)', () {
      final items = [
        roleItem('top', CanvasRole.top),
        roleItem('outerwear', CanvasRole.outerwear),
        roleItem('acc', CanvasRole.accessory, x: -240),
      ];
      final result = layoutOuterwearOverBase(items, canvasWidth: 800, canvasHeight: 1000);
      expect(outerwearOf(result).positionX, greaterThan(baseOf(result).positionX));
    });

    test('(i) phụ kiện bên phải → áo khoác sang trái (đối diện)', () {
      final items = [
        roleItem('top', CanvasRole.top),
        roleItem('outerwear', CanvasRole.outerwear),
        roleItem('acc', CanvasRole.accessory, x: 240),
      ];
      final result = layoutOuterwearOverBase(items, canvasWidth: 800, canvasHeight: 1000);
      expect(outerwearOf(result).positionX, lessThan(baseOf(result).positionX));
    });
  });

  group('Studio addItemToCanvas', () {
    const canvasW = 390.0;
    const canvasH = 900.0;

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

    void expectAllInside(ProviderContainer c) {
      for (final it in c.read(outfitStudioProvider).canvasItems) {
        expectInside(it, canvasW, canvasH, it.name);
      }
    }

    test('(d) thêm áo rồi áo khoác → bằng áo, chồng ≤40%, trong khung', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(outfitStudioProvider.notifier);
      notifier.setCanvasSize(canvasW, canvasH);

      notifier.addItemToCanvas(fixture('top1', 'Áo thun', 'ao'));
      notifier.addItemToCanvas(fixture('coat1', 'Áo khoác dạ', 'ao-khoac'));

      final items = container.read(outfitStudioProvider).canvasItems;
      expect(items.length, 2);
      expectOuterwearEqualAndOverlaps(baseOf(items), outerwearOf(items), canvasW, canvasH);
      expectAllInside(container);
    });

    test('(e) thêm giày sau áo → áo còn, mọi món trong khung', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(outfitStudioProvider.notifier);
      notifier.setCanvasSize(canvasW, canvasH);

      notifier.addItemToCanvas(fixture('top1', 'Áo thun', 'ao'));
      notifier.addItemToCanvas(fixture('shoe1', 'Giày sneaker', 'giay'));

      final items = container.read(outfitStudioProvider).canvasItems;
      expect(items.any((i) => i.role == 'top'), isTrue);
      expect(items.any((i) => i.role == 'footwear'), isTrue);
      expectAllInside(container);
    });

    test('(f) thêm quần SAU áo+khoác → không gỡ món, trong khung', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(outfitStudioProvider.notifier);
      notifier.setCanvasSize(canvasW, canvasH);

      notifier.addItemToCanvas(fixture('top1', 'Áo thun', 'ao'));
      notifier.addItemToCanvas(fixture('coat1', 'Áo khoác dạ', 'ao-khoac'));
      notifier.addItemToCanvas(fixture('bot1', 'Quần jean', 'quan'));

      final items = container.read(outfitStudioProvider).canvasItems;
      expect(items.length, 3);
      expectAllInside(container);
    });

    test('(g) thay giày cùng loại → thay đúng món, còn 1 giày trong khung', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(outfitStudioProvider.notifier);
      notifier.setCanvasSize(canvasW, canvasH);

      notifier.addItemToCanvas(fixture('shoe1', 'Giày A', 'giay'));
      notifier.addItemToCanvas(fixture('shoe2', 'Giày B', 'giay'));

      final items = container.read(outfitStudioProvider).canvasItems;
      expect(items.length, 1);
      expect(items.single.fashionItemId, 'fashion-shoe2');
      expectAllInside(container);
    });
  });
}
