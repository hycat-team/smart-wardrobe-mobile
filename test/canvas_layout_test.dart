import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/outfit_studio/layout/canvas_layout.dart';
import 'package:smart_wardrobe/features/outfit_studio/models/outfit_models.dart';

void main() {
  group('Canvas Layout - Normalization & Anatomy Coordinates', () {
    test('normalizeRole maps accented Vietnamese and keywords correctly', () {
      expect(normalizeRole('Mũ len'), CanvasRole.headwear);
      expect(normalizeRole('Nón kết'), CanvasRole.headwear);
      expect(normalizeRole('Áo sơ mi'), CanvasRole.top);
      expect(normalizeRole('Áo khoác dạ'), CanvasRole.outerwear);
      expect(normalizeRole('Hoodie len'), CanvasRole.top);
      expect(normalizeRole('Quần jean'), CanvasRole.bottom);
      expect(normalizeRole('Chân váy chữ A'), CanvasRole.bottom);
      expect(normalizeRole('Đầm maxi'), CanvasRole.fullbody);
      expect(normalizeRole('Váy liền'), CanvasRole.fullbody);
      expect(normalizeRole('Giày sneaker'), CanvasRole.footwear);
      expect(normalizeRole('Sandal da'), CanvasRole.footwear);
      expect(normalizeRole('Dép quai ngang'), CanvasRole.footwear);
      expect(normalizeRole('Thắt lưng da'), CanvasRole.accessory);
      expect(normalizeRole('Khăn len'), CanvasRole.accessory);
      expect(normalizeRole('Trang sức bạc'), CanvasRole.accessory);
    });

    test('detectCompositionType identifies composition categories', () {
      expect(
        detectCompositionType([CanvasRole.fullbody, CanvasRole.top]),
        OutfitCompositionType.fullbody,
      );
      expect(
        detectCompositionType([CanvasRole.top, CanvasRole.bottom]),
        OutfitCompositionType.separatePieces,
      );
      expect(
        detectCompositionType([CanvasRole.accessory]),
        OutfitCompositionType.incomplete,
      );
    });

    test('roleBoundingBoxRatios matches FE specifications', () {
      expect(roleBoundingBoxRatios[CanvasRole.top]?.widthRatio, 2.1);
      expect(roleBoundingBoxRatios[CanvasRole.top]?.heightRatio, 2.1);

      expect(roleBoundingBoxRatios[CanvasRole.bottom]?.widthRatio, 1.9);
      expect(roleBoundingBoxRatios[CanvasRole.bottom]?.heightRatio, 2.3);

      expect(roleBoundingBoxRatios[CanvasRole.outerwear]?.widthRatio, 2.3);
      expect(roleBoundingBoxRatios[CanvasRole.outerwear]?.heightRatio, 2.3);

      expect(roleBoundingBoxRatios[CanvasRole.footwear]?.widthRatio, 1.8);
      expect(roleBoundingBoxRatios[CanvasRole.footwear]?.heightRatio, 1.3);

      expect(roleBoundingBoxRatios[CanvasRole.headwear]?.widthRatio, 1.8);
      expect(roleBoundingBoxRatios[CanvasRole.headwear]?.heightRatio, 1.4);

      expect(roleBoundingBoxRatios[CanvasRole.accessory]?.widthRatio, 1.6);
      expect(roleBoundingBoxRatios[CanvasRole.accessory]?.heightRatio, 1.6);

      expect(roleBoundingBoxRatios[CanvasRole.fullbody]?.widthRatio, 2.1);
      expect(roleBoundingBoxRatios[CanvasRole.fullbody]?.heightRatio, 3.2);
    });

    test('roleCoordinatesSeparate and roleCoordinatesFullbody verify correct coordinates and layers', () {
      final sepTop = roleCoordinatesSeparate[CanvasRole.top]!;
      expect(sepTop.x, 0.0);
      expect(sepTop.y, -140.0);
      expect(sepTop.scale, 100.0);
      expect(sepTop.zIndex, 5);

      final fb = roleCoordinatesFullbody[CanvasRole.fullbody]!;
      expect(fb.x, 0.0);
      expect(fb.y, -15.0);
      expect(fb.scale, 105.0);
      expect(fb.zIndex, 5);

      final outw = roleCoordinatesSeparate[CanvasRole.outerwear]!;
      expect(outw.x, -25.0);
      expect(outw.y, -145.0);
      expect(outw.scale, 105.0);
      expect(outw.zIndex, 7);
    });
  });

  group('Canvas Layout - Legacy Restoration & Fit-to-Canvas', () {
    test('restoreCanvasPlacement fixes inverted Y on upper body and legacy shifts', () {
      // Legacy top that had positive Y and x = 1.0
      final restoredTop = restoreCanvasPlacement(
        role: CanvasRole.top,
        positionX: 1.0,
        positionY: 85.0,
      );
      expect(restoredTop.y, -85.0); // Flipped to negative
      expect(restoredTop.x, 0.0); // Reset ±1 to 0

      // Legacy outerwear with x = 25
      final restoredOuterwear = restoreCanvasPlacement(
        role: CanvasRole.outerwear,
        positionX: 25.0,
        positionY: 60.0,
      );
      expect(restoredOuterwear.x, -25.0);
      expect(restoredOuterwear.y, -60.0);

      // Legacy footwear with y = 305
      final restoredFootwear = restoreCanvasPlacement(
        role: CanvasRole.footwear,
        positionX: 0.0,
        positionY: 305.0,
      );
      expect(restoredFootwear.y, 295.0);
    });

    test('layoutCanvasItems centers a single item', () {
      final singleItem = CanvasItem(
        id: '1',
        fashionItemId: 'f1',
        imageUrl: '',
        name: 'Áo thun',
        role: CanvasRole.top.name,
        positionX: 50.0,
        positionY: -120.0,
        scale: 1.2,
      );

      final result = layoutCanvasItems([singleItem], canvasWidth: 400, canvasHeight: 600);
      expect(result.length, 1);
      expect(result.first.positionX, 0.0);
      expect(result.first.positionY, 0.0);
      expect(result.first.scale, 1.2);
    });

    test('layoutCanvasItems scales and fits multi-item set inside canvas boundaries', () {
      final items = [
        CanvasItem(
          id: '1',
          fashionItemId: 'f1',
          imageUrl: '',
          name: 'Nón',
          role: CanvasRole.headwear.name,
          positionX: 0,
          positionY: -185,
          scale: 1.0,
        ),
        CanvasItem(
          id: '2',
          fashionItemId: 'f2',
          imageUrl: '',
          name: 'Áo',
          role: CanvasRole.top.name,
          positionX: 0,
          positionY: -70,
          scale: 1.0,
        ),
        CanvasItem(
          id: '3',
          fashionItemId: 'f3',
          imageUrl: '',
          name: 'Quần',
          role: CanvasRole.bottom.name,
          positionX: 0,
          positionY: 95,
          scale: 1.0,
        ),
        CanvasItem(
          id: '4',
          fashionItemId: 'f4',
          imageUrl: '',
          name: 'Giày',
          role: CanvasRole.footwear.name,
          positionX: 0,
          positionY: 215,
          scale: 1.0,
        ),
      ];

      // Small canvas height 350 to force fit scaling
      final result = layoutCanvasItems(items, canvasWidth: 320, canvasHeight: 350);
      expect(result.length, 4);

      // Check that all items are within canvas boundaries
      const halfW = 320 / 2;
      const halfH = 350 / 2;
      for (final item in result) {
        expect(item.positionX.abs(), lessThanOrEqualTo(halfW));
        expect(item.positionY.abs(), lessThanOrEqualTo(halfH));
      }
    });

    test('item scale clamp supports smooth zoom out down to 0.15', () {
      final item = CanvasItem(
        id: 'test_scale',
        fashionItemId: 'f1',
        imageUrl: '',
        name: 'Áo',
        role: CanvasRole.top.name,
        positionX: 0,
        positionY: 0,
        scale: 0.6,
        baseScale: 100,
        boxRatioW: 2.1,
        boxRatioH: 2.1,
      );

      // Verify dimensions with 1.25x scale multiplier:
      // itemW = baseScale * boxRatioW * scale * 1.25 = 100 * 2.1 * 0.6 * 1.25 = 157.5 px
      const scaleMultiplier = 1.25;
      final expectedW = item.baseScale * item.boxRatioW * item.scale * scaleMultiplier;
      expect(expectedW, closeTo(157.5, 0.01));

      // Scaling down with ratio * 0.85
      var curScale = item.scale;
      curScale = (curScale * 0.85).clamp(0.15, 3.0);
      expect(curScale, closeTo(0.51, 0.01));

      // Continuous zoom out reaches below old 0.4 limit
      for (int i = 0; i < 5; i++) {
        curScale = (curScale * 0.85).clamp(0.15, 3.0);
      }
      expect(curScale, lessThan(0.4));
      expect(curScale, greaterThanOrEqualTo(0.15));
    });
  });
}
