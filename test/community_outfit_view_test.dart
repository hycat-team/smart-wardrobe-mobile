import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/community/models/post_models.dart';
import 'package:smart_wardrobe/features/outfit_studio/models/outfit_models.dart';
import 'package:smart_wardrobe/features/outfit_studio/utils/outfit_canvas_exporter.dart';

void main() {
  group('Community Outfit View & Studio Canvas Integration Tests', () {
    test('Post.coverImageUrl returns outfit coverImageUrl when post has outfit and media is empty', () {
      const outfitBrief = OutfitBrief(
        id: 'outfit-123',
        name: 'Set dạo phố mùa thu',
        coverImageUrl: 'https://res.cloudinary.com/demo/image/upload/v1/outfit_canvas.png',
      );

      final post = Post(
        id: 'p-1',
        publicId: 'post-pub-1',
        postType: 'outfit',
        status: 'published',
        content: 'Chia sẻ set đồ mới phối hôm nay!',
        sharePath: '/community/posts/post-pub-1',
        createdAt: '2026-09-28T12:00:00Z',
        updatedAt: '2026-09-28T12:00:00Z',
        outfit: outfitBrief,
        media: const [],
      );

      expect(post.isOutfit, isTrue);
      expect(post.media.isEmpty, isTrue);
      expect(post.coverImageUrl, 'https://res.cloudinary.com/demo/image/upload/v1/outfit_canvas.png');
      expect(post.outfit?.name, 'Set dạo phố mùa thu');
      expect(post.outfit?.id, 'outfit-123');
    });

    test('UserOutfitModel parses items and attributes correctly for detail view', () {
      final json = {
        'id': 'outfit-456',
        'name': 'Set công sở thanh lịch',
        'description': 'Phối áo sơ mi lụa cùng quần âu ống suông',
        'coverImageUrl': 'https://res.cloudinary.com/demo/image/upload/v1/canvas_full.png',
        'createdAt': '2026-09-28T10:00:00Z',
        'items': [
          {
            'id': 'oi-1',
            'itemContext': 'user_wardrobe',
            'positionX': 0.0,
            'positionY': -100.0,
            'scale': 1.0,
            'layerOrder': 1,
            'fashionItem': {
              'id': 'fi-top-1',
              'imageUrl': 'https://res.cloudinary.com/demo/image/upload/v1/shirt.png',
              'color': 'Trắng',
              'colorHex': '#FFFFFF',
              'style': 'Công sở',
              'category': {
                'id': 'cat-1',
                'name': 'Áo sơ mi',
                'slug': 'ao-so-mi',
              },
            },
          },
          {
            'id': 'oi-2',
            'itemContext': 'user_wardrobe',
            'positionX': 0.0,
            'positionY': 80.0,
            'scale': 1.0,
            'layerOrder': 2,
            'fashionItem': {
              'id': 'fi-bottom-1',
              'imageUrl': 'https://res.cloudinary.com/demo/image/upload/v1/pants.png',
              'color': 'Đen',
              'colorHex': '#1A1A1A',
              'style': 'Thanh lịch',
              'category': {
                'id': 'cat-2',
                'name': 'Quần tây',
                'slug': 'quan-tay',
              },
            },
          },
        ],
      };

      final outfit = UserOutfitModel.fromJson(json);
      expect(outfit.id, 'outfit-456');
      expect(outfit.name, 'Set công sở thanh lịch');
      expect(outfit.items.length, 2);
      expect(outfit.items[0].fashionItem?.category?.name, 'Áo sơ mi');
      expect(outfit.items[0].fashionItem?.colorHex, '#FFFFFF');
      expect(outfit.items[1].fashionItem?.category?.name, 'Quần tây');
      expect(outfit.items[1].fashionItem?.colorHex, '#1A1A1A');
    });

    test('SaveOutfitReq encodes coverImageUrl and coverPublicId properly', () {
      const req = SaveOutfitReq(
        name: 'Set đồ mùa hè',
        description: 'Set năng động thoáng mát',
        coverImageUrl: 'https://res.cloudinary.com/demo/image/upload/v1/custom_canvas.png',
        coverPublicId: 'smart_wardrobe/outfits/custom_canvas',
        items: [
          SaveOutfitItemReq(
            fashionItemId: 'fi-1',
            positionX: 10,
            positionY: 20,
            scale: 1.25,
            layerOrder: 1,
          ),
        ],
      );

      final json = req.toJson();
      expect(json['name'], 'Set đồ mùa hè');
      expect(json['description'], 'Set năng động thoáng mát');
      expect(json['coverImageUrl'], 'https://res.cloudinary.com/demo/image/upload/v1/custom_canvas.png');
      expect(json['coverPublicId'], 'smart_wardrobe/outfits/custom_canvas');
      expect((json['items'] as List).length, 1);
    });

    test('OutfitCanvasExporter.compositeOutfitToBytes returns null on empty items and handles export gracefully', () async {
      final emptyResult = await OutfitCanvasExporter.compositeOutfitToBytes(
        items: const [],
        canvasWidth: 400,
        canvasHeight: 500,
      );
      expect(emptyResult, isNull);

      final item1 = CanvasItem(
        id: 'c-1',
        fashionItemId: 'fi-1',
        imageUrl: '', // empty url is skipped gracefully
        name: 'Áo thun trắng',
        positionX: 0,
        positionY: -50,
      );
      final item2 = CanvasItem(
        id: 'c-2',
        fashionItemId: 'fi-2',
        imageUrl: '',
        name: 'Quần jeans',
        positionX: 0,
        positionY: 80,
      );

      final result = await OutfitCanvasExporter.compositeOutfitToBytes(
        items: [item1, item2],
        canvasWidth: 300,
        canvasHeight: 400,
      );
      expect(result, isNotNull);
      // Valid PNG header check: [137, 80, 78, 71] (0x89, 'P', 'N', 'G')
      expect(result!.length, greaterThan(8));
      expect(result[0], 0x89);
      expect(result[1], 0x50);
      expect(result[2], 0x4E);
      expect(result[3], 0x47);
    });
  });
}
