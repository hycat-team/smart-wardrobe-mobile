import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/core/services/cloudinary_service.dart';
import 'package:smart_wardrobe/features/community/data/community_repository.dart';
import 'package:smart_wardrobe/features/community/models/post_models.dart';
import 'package:smart_wardrobe/features/community/providers/post_composer_provider.dart';

class FakeCommunityRepoForComposer extends CommunityRepository {
  CreatePostReq? lastCreateReq;
  UpdatePostReq? lastUpdateReq;

  @override
  Future<Post> createPost(CreatePostReq req) async {
    lastCreateReq = req;
    return Post(
      id: 'post-new-1',
      publicId: 'pub-new-1',
      postType: req.postType,
      status: 'published',
      title: req.title,
      content: req.content,
      sharePath: '/community/posts/pub-new-1',
      createdAt: '2026-09-27T12:00:00Z',
      updatedAt: '2026-09-27T12:00:00Z',
    );
  }

  @override
  Future<Post> updatePost(String publicId, UpdatePostReq req) async {
    lastUpdateReq = req;
    return Post(
      id: 'post-up-1',
      publicId: publicId,
      postType: 'outfit',
      status: 'published',
      title: req.title,
      content: req.content ?? '',
      sharePath: '/community/posts/$publicId',
      createdAt: '2026-09-27T12:00:00Z',
      updatedAt: '2026-09-27T12:00:00Z',
    );
  }
}

void main() {
  group('PostComposer Validation Tests (US2)', () {
    test('Validate Outfit post requires selected outfit', () {
      final repo = FakeCommunityRepoForComposer();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = PostComposerNotifier(repo, CloudinaryService(), null);

      notifier.setPostType('outfit');
      notifier.setContent('Đây là outfit của tôi');

      // Selected outfit is null
      final err = notifier.validate();
      expect(err, 'Vui lòng chọn một bộ phối từ tủ đồ của bạn.');

      // Set outfit
      notifier.setSelectedOutfit(const OutfitBrief(id: 'outfit-1', name: 'Autumn Chic'));
      expect(notifier.validate(), isNull);
    });

    test('Validate Media post requires content or at least one media item', () {
      final repo = FakeCommunityRepoForComposer();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = PostComposerNotifier(repo, CloudinaryService(), null);

      notifier.setPostType('media');
      notifier.setContent('   '); // empty content

      final err = notifier.validate();
      expect(err, 'Vui lòng nhập nội dung bài viết hoặc chọn ít nhất một hình ảnh/video.');

      // With text content
      notifier.setContent('Chia sẻ phong cách mới');
      expect(notifier.validate(), isNull);
    });

    test('Validate title <= 150 and content <= 5000', () {
      final repo = FakeCommunityRepoForComposer();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = PostComposerNotifier(repo, CloudinaryService(), null);

      notifier.setPostType('media');
      notifier.setTitle('A' * 151);
      notifier.setContent('Hợp lệ');

      expect(notifier.validate(), 'Tiêu đề không được vượt quá 150 ký tự.');

      notifier.setTitle('Tiêu đề hợp lệ');
      notifier.setContent('B' * 5001);
      expect(notifier.validate(), 'Nội dung bài viết không được vượt quá 5000 ký tự.');
    });

    test('DTO CreatePostReq and UpdatePostReq contain NO resale/transfer fields (FR-022)', () {
      const createReq = CreatePostReq(
        postType: 'outfit',
        title: 'Bộ đồ vintage',
        content: 'Phong cách cổ điển',
        outfitId: 'outfit-101',
        media: [
          PostMediaReq(
            mediaType: 'image',
            mediaUrl: 'https://cloudinary.com/test.jpg',
            publicId: 'cld-123',
            sortOrder: 0,
          ),
        ],
      );

      final json = createReq.toJson();
      expect(json['postType'], 'outfit');
      expect(json['title'], 'Bộ đồ vintage');
      expect(json['content'], 'Phong cách cổ điển');
      expect(json['outfitId'], 'outfit-101');
      expect(json['media'], isA<List>());

      // Strict FR-022 checks:
      expect(json.containsKey('items'), isFalse);
      expect(json.containsKey('totalPrice'), isFalse);
      expect(json.containsKey('contactInfo'), isFalse);
      expect(json.containsKey('transferState'), isFalse);
      expect(json.containsKey('buyerUserId'), isFalse);
      expect(json.containsKey('soldAt'), isFalse);

      const updateReq = UpdatePostReq(
        title: 'Bộ đồ cập nhật',
        content: 'Nội dung mới',
      );
      final updateJson = updateReq.toJson();
      expect(updateJson['title'], 'Bộ đồ cập nhật');
      expect(updateJson['content'], 'Nội dung mới');
      expect(updateJson.containsKey('postType'), isFalse); // update không đổi postType
      expect(updateJson.containsKey('totalPrice'), isFalse);
    });
  });
}
