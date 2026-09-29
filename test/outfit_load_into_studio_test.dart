import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/outfit_studio/models/outfit_models.dart';
import 'package:smart_wardrobe/features/outfit_studio/providers/outfits_list_provider.dart';
import 'package:smart_wardrobe/features/outfit_studio/providers/outfit_studio_provider.dart';

UserOutfitModel _outfit(String id) => UserOutfitModel(
      id: id,
      name: 'Bộ phối $id',
      coverImageUrl: 'https://example.com/$id.png',
      items: [
        OutfitItemDetailModel(
          id: '$id-i1',
          layerOrder: 1,
          fashionItem: RecommendedFashionItemBrief(
            id: 'fi-top',
            imageUrl: 'https://example.com/top.png',
            category: RecommendedCategoryBrief(
              id: 'c1',
              name: 'Áo',
              slug: 'ao',
            ),
          ),
        ),
        OutfitItemDetailModel(
          id: '$id-i2',
          layerOrder: 2,
          fashionItem: RecommendedFashionItemBrief(
            id: 'fi-shoe',
            imageUrl: 'https://example.com/shoe.png',
            category: RecommendedCategoryBrief(
              id: 'c2',
              name: 'Giày',
              slug: 'giay',
            ),
          ),
        ),
      ],
    );

void main() {
  group('Nạp bộ phối vào Studio', () {
    test('canvas có món đồ sau khi loadIntoStudio', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(outfitsListProvider.notifier)
          .loadIntoStudio(_outfit('o1'));

      final items = container.read(outfitStudioProvider).canvasItems;
      expect(items, isNotEmpty, reason: 'canvas phải có đồ, không được trống');
      expect(items.length, 2);
    });

    test('yêu cầu nhảy sang tab Studio Thủ Công được bật', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(outfitsListProvider.notifier)
          .loadIntoStudio(_outfit('o1'));

      expect(container.read(outfitStudioProvider).openCanvasRequested, isTrue);
    });

    test('canvas chưa đo được → đánh dấu chờ bố trí lại', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(outfitsListProvider.notifier)
          .loadIntoStudio(_outfit('o1'));

      expect(
        container.read(outfitStudioProvider).pendingRelayout,
        isTrue,
        reason: 'lần đầu mở Studio chưa có kích thước thật',
      );
    });

    test('đo canvas xong → bố trí lại rồi tắt cờ chờ', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(outfitStudioProvider.notifier);
      container.read(outfitsListProvider.notifier).loadIntoStudio(_outfit('o1'));
      expect(notifier.state.pendingRelayout, isTrue);

      notifier.setCanvasSize(400, 800);

      final after = container.read(outfitStudioProvider);
      expect(after.canvasWidth, 400);
      expect(after.canvasHeight, 800);
      expect(after.pendingRelayout, isFalse);
      expect(after.canvasItems, isNotEmpty,
          reason: 'bố trí lại không được làm mất đồ trên canvas');
    });

    test('canvas đã có kích thước thật → không chờ bố trí lại', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(outfitStudioProvider.notifier).setCanvasSize(400, 800);
      container.read(outfitsListProvider.notifier).loadIntoStudio(_outfit('o1'));

      expect(container.read(outfitStudioProvider).pendingRelayout, isFalse);
    });
  });
}
