import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/outfit_studio/models/outfit_models.dart';
import 'package:smart_wardrobe/features/outfit_studio/providers/outfit_studio_provider.dart';
import 'package:smart_wardrobe/features/wardrobe/models/wardrobe_models.dart';

void main() {
  const canvasW = 390.0;
  const canvasH = 700.0;
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

  ({ProviderContainer container, OutfitStudioNotifier notifier}) setup() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(outfitStudioProvider.notifier);
    notifier.setCanvasSize(canvasW, canvasH);
    return (container: container, notifier: notifier);
  }

  List<CanvasItem> itemsOf(ProviderContainer c) =>
      c.read(outfitStudioProvider).canvasItems;

  void expectInsideCanvas(List<CanvasItem> items) {
    for (final item in items) {
      final itemW = item.baseScale * item.boxRatioW * item.scale * multiplier;
      final itemH = item.baseScale * item.boxRatioH * item.scale * multiplier;
      expect(
        item.positionX - itemW / 2,
        greaterThanOrEqualTo(-canvasW / 2 + margin - 0.01),
        reason: '${item.name} tràn trái',
      );
      expect(
        item.positionX + itemW / 2,
        lessThanOrEqualTo(canvasW / 2 - margin + 0.01),
        reason: '${item.name} tràn phải',
      );
      expect(
        item.positionY - itemH / 2,
        greaterThanOrEqualTo(-canvasH / 2 + margin - 0.01),
        reason: '${item.name} tràn trên',
      );
      expect(
        item.positionY + itemH / 2,
        lessThanOrEqualTo(canvasH / 2 - margin + 0.01),
        reason: '${item.name} tràn dưới',
      );
    }
  }

  group('Studio single item per role (US1)', () {
    test('(a) thêm 2 áo → chỉ còn 1, là món thứ hai, id món cũ bị gỡ', () {
      final s = setup();
      final firstAdded = s.notifier.addItemToCanvas(fixture('top1', 'Áo thun', 'ao'));
      final replaced = s.notifier.addItemToCanvas(fixture('top2', 'Sơ mi', 'ao'));

      expect(firstAdded, isFalse);
      expect(replaced, isTrue);

      final items = itemsOf(s.container);
      final tops = items.where((i) => i.role == 'top').toList();
      expect(tops.length, 1);
      expect(tops.single.fashionItemId, 'fashion-top2');
      expect(items.any((i) => i.fashionItemId == 'fashion-top1'), isFalse);
    });

    test('(b) thêm 2 quần → 1 quần (món thứ hai)', () {
      final s = setup();
      s.notifier.addItemToCanvas(fixture('bot1', 'Quần jean', 'quan'));
      s.notifier.addItemToCanvas(fixture('bot2', 'Quần tây', 'quan'));

      final items = itemsOf(s.container);
      final bottoms = items.where((i) => i.role == 'bottom').toList();
      expect(bottoms.length, 1);
      expect(bottoms.single.fashionItemId, 'fashion-bot2');
      expect(items.any((i) => i.fashionItemId == 'fashion-bot1'), isFalse);
    });

    test('(c) có áo + quần, thêm đầm → gỡ áo, giữ quần', () {
      final s = setup();
      s.notifier.addItemToCanvas(fixture('top1', 'Áo thun', 'ao'));
      s.notifier.addItemToCanvas(fixture('bot1', 'Quần jean', 'quan'));
      s.notifier.addItemToCanvas(fixture('dress1', 'Đầm liền', 'dam'));

      final items = itemsOf(s.container);
      expect(items.any((i) => i.role == 'top'), isFalse);
      expect(items.where((i) => i.role == 'bottom').length, 1);
      expect(items.where((i) => i.role == 'fullbody').length, 1);
      expect(items.any((i) => i.fashionItemId == 'fashion-bot1'), isTrue);
    });

    test('(d) có đầm, thêm áo → gỡ đầm', () {
      final s = setup();
      s.notifier.addItemToCanvas(fixture('dress1', 'Đầm liền', 'vay-lien'));
      s.notifier.addItemToCanvas(fixture('top1', 'Áo thun', 'ao'));

      final items = itemsOf(s.container);
      expect(items.any((i) => i.role == 'fullbody'), isFalse);
      expect(items.where((i) => i.role == 'top').length, 1);
    });

    test('(e) thêm 2 phụ kiện → cả hai còn', () {
      final s = setup();
      s.notifier.addItemToCanvas(fixture('acc1', 'Túi xách', 'tui'));
      s.notifier.addItemToCanvas(fixture('acc2', 'Kính', 'phu-kien'));

      final items = itemsOf(s.container);
      expect(items.where((i) => i.role == 'accessory').length, 2);
      expect(items.any((i) => i.fashionItemId == 'fashion-acc1'), isTrue);
      expect(items.any((i) => i.fashionItemId == 'fashion-acc2'), isTrue);
    });

    test('(f) thêm áo rồi giày → không gỡ áo (khác loại)', () {
      final s = setup();
      s.notifier.addItemToCanvas(fixture('top1', 'Áo thun', 'ao'));
      final added = s.notifier.addItemToCanvas(fixture('shoe1', 'Giày sneaker', 'giay'));

      expect(added, isFalse);
      final items = itemsOf(s.container);
      expect(items.length, 2);
      expect(items.any((i) => i.role == 'top'), isTrue);
      expect(items.any((i) => i.role == 'footwear'), isTrue);
    });

    test('(g) thêm vào canvas trống → không gỡ nhầm (count +1)', () {
      final s = setup();
      expect(itemsOf(s.container), isEmpty);

      final added = s.notifier.addItemToCanvas(fixture('top1', 'Áo thun', 'ao'));

      expect(added, isFalse);
      expect(itemsOf(s.container).length, 1);
    });

    test('(h) sau thay thế, món mới trong khung và selectedIndex trỏ món mới', () {
      final s = setup();
      s.notifier.addItemToCanvas(fixture('top1', 'Áo thun', 'ao'));
      s.notifier.addItemToCanvas(fixture('bot1', 'Quần jean', 'quan'));
      s.notifier.addItemToCanvas(fixture('top2', 'Sơ mi', 'ao'));

      final state = s.container.read(outfitStudioProvider);
      final items = state.canvasItems;
      expect(state.selectedIndex, isNotNull);
      expect(
        items[state.selectedIndex!].fashionItemId,
        'fashion-top2',
      );
      expectInsideCanvas(items);
    });

    test('(i) nón độc quyền: thêm 2 nón → chỉ còn 1 (món mới)', () {
      final s = setup();
      s.notifier.addItemToCanvas(fixture('hat1', 'Mũ lưỡi trai', 'mu'));
      s.notifier.addItemToCanvas(fixture('hat2', 'Mũ beanie', 'non'));

      final hats =
          itemsOf(s.container).where((i) => i.role == 'headwear').toList();
      expect(hats.length, 1);
      expect(hats.single.fashionItemId, 'fashion-hat2');
    });

    test('(j) phụ kiện cùng loại bị thay, khác loại thì giữ', () {
      final s = setup();
      s.notifier.addItemToCanvas(fixture('acc1', 'Dây chuyền A', 'phu-kien'));
      s.notifier.addItemToCanvas(fixture('acc2', 'Dây chuyền B', 'phu-kien'));

      var acc = itemsOf(s.container).where((i) => i.role == 'accessory').toList();
      expect(acc.length, 1);
      expect(acc.single.fashionItemId, 'fashion-acc2');

      s.notifier.addItemToCanvas(fixture('acc3', 'Túi xách', 'tui'));
      acc = itemsOf(s.container).where((i) => i.role == 'accessory').toList();
      expect(acc.length, 2);
    });
  });
}
