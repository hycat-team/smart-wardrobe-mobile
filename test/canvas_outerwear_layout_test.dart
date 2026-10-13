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

  void expectNoHorizontalOverlap(CanvasItem base, CanvasItem outw, double w, double h) {
    final baseRight = base.positionX + widthOf(base) / 2;
    final outLeft = outw.positionX - widthOf(outw) / 2;
    expect(
      outLeft,
      greaterThanOrEqualTo(baseRight - tolerance),
      reason: 'outerwear chồng lớp nền trên ${w.toInt()}x${h.toInt()} '
          '(outLeft=$outLeft, baseRight=$baseRight)',
    );
    expect(outw.layerOrder, greaterThan(base.layerOrder));
  }

  group('layoutOuterwearBesideBase (US2)', () {
    for (final size in canvasSizes) {
      test('(a) top + outerwear không chồng ngang trên ${size.w.toInt()}x${size.h.toInt()}', () {
        final items = [
          roleItem('top', CanvasRole.top, positionY: -140),
          roleItem('outerwear', CanvasRole.outerwear, positionY: -145),
        ];

        final result = layoutOuterwearBesideBase(
          items,
          canvasWidth: size.w,
          canvasHeight: size.h,
        );

        final base = baseOf(result);
        final outw = outerwearOf(result);
        expectNoHorizontalOverlap(base, outw, size.w, size.h);
        expectInside(base, size.w, size.h, 'top');
        expectInside(outw, size.w, size.h, 'outerwear');
      });

      test('(b) fullbody + outerwear không chồng ngang trên ${size.w.toInt()}x${size.h.toInt()}', () {
        final items = [
          roleItem('dress', CanvasRole.fullbody, positionY: -15),
          roleItem('outerwear', CanvasRole.outerwear, positionY: -145),
        ];

        final result = layoutOuterwearBesideBase(
          items,
          canvasWidth: size.w,
          canvasHeight: size.h,
        );

        final base = baseOf(result);
        final outw = outerwearOf(result);
        expectNoHorizontalOverlap(base, outw, size.w, size.h);
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

      final result = layoutOuterwearBesideBase(
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

  group('Studio addItemToCanvas outerwear layout (US2)', () {
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

    test('(d) thêm áo rồi áo khoác → hai món không chồng ngang, trong khung', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(outfitStudioProvider.notifier);
      notifier.setCanvasSize(canvasW, canvasH);

      notifier.addItemToCanvas(fixture('top1', 'Áo thun', 'ao'));
      notifier.addItemToCanvas(fixture('coat1', 'Áo khoác dạ', 'ao-khoac'));

      final items = container.read(outfitStudioProvider).canvasItems;
      expect(items.length, 2);

      final base = baseOf(items);
      final outw = outerwearOf(items);
      expectNoHorizontalOverlap(base, outw, canvasW, canvasH);
      expectInside(base, canvasW, canvasH, 'top');
      expectInside(outw, canvasW, canvasH, 'outerwear');
    });

    test('(e) thêm giày/phụ kiện sau áo không reset vị trí áo (không gọi layout)', () {
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
  });
}
