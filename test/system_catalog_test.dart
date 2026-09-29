import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/wardrobe/models/wardrobe_models.dart';
import 'package:smart_wardrobe/features/wardrobe/providers/system_catalog_provider.dart';

WardrobeItemModel _item({
  required String id,
  String? imageUrl,
  String? rawImageUrl,
}) {
  return WardrobeItemModel(
    id: id,
    rawImageUrl: rawImageUrl,
    fashionItem: imageUrl == null
        ? null
        : FashionItemModel(id: 'f_$id', imageUrl: imageUrl),
  );
}

void main() {
  group('SystemCatalogState.visibleItems (US3)', () {
    test('ẩn mẫu hệ thống thiếu ảnh', () {
      final state = SystemCatalogState(items: [
        _item(
          id: 'with-fashion',
          imageUrl: 'https://res.cloudinary.com/demo/image/upload/v1/a.jpg',
        ),
        _item(id: 'blank'),
        _item(id: 'empty-url', imageUrl: ''),
        _item(
          id: 'with-raw',
          rawImageUrl: 'https://res.cloudinary.com/demo/image/upload/v1/c.jpg',
        ),
      ]);

      expect(
        state.visibleItems.map((e) => e.id),
        ['with-fashion', 'with-raw'],
      );
    });

    test('visibleItems rỗng khi mọi mẫu thiếu ảnh (empty state)', () {
      final state = SystemCatalogState(items: [
        _item(id: 'a'),
        _item(id: 'b', imageUrl: ''),
      ]);

      expect(state.visibleItems, isEmpty);
    });

    test('mẫu có ảnh vẫn hiển thị và áp t_bg_remove', () {
      final state = SystemCatalogState(items: [
        _item(
          id: 'x',
          imageUrl: 'https://res.cloudinary.com/demo/image/upload/v1/x.jpg',
        ),
      ]);

      expect(state.visibleItems.single.id, 'x');
      expect(state.visibleItems.single.displayImageUrl, contains('t_bg_remove'));
    });
  });
}
