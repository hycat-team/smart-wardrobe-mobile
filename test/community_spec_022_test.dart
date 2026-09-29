import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/core/services/cloudinary_service.dart';
import 'package:smart_wardrobe/features/community/models/post_models.dart';
import 'package:smart_wardrobe/features/community/providers/community_feed_provider.dart';
import 'package:smart_wardrobe/features/wardrobe/models/wardrobe_models.dart';

void main() {
  group('Spec 022 Community Social Compliance Tests', () {
    test('PostMediaReq serializes bytes and durationSeconds (N1)', () {
      const mediaReq = PostMediaReq(
        mediaType: 'video',
        mediaUrl: 'https://res.cloudinary.com/demo/video/upload/sample.mp4',
        publicId: 'sample_id',
        sortOrder: 0,
        bytes: 2048576,
        durationSeconds: 15.54321,
      );

      final json = mediaReq.toJson();
      expect(json['mediaType'], 'video');
      expect(json['mediaUrl'], 'https://res.cloudinary.com/demo/video/upload/sample.mp4');
      expect(json['publicId'], 'sample_id');
      expect(json['sortOrder'], 0);
      expect(json['bytes'], 2048576);
      expect(json['durationSeconds'], 15.54321);
    });

    test('PostMedia deserializes bytes and durationSeconds from response', () {
      final json = {
        'id': 'media-1',
        'mediaType': 'video',
        'mediaUrl': 'https://res.cloudinary.com/demo/video/upload/v1/vid.mp4',
        'publicId': 'vid_pub_1',
        'sortOrder': 0,
        'bytes': 5242880,
        'durationSeconds': 22.35,
      };

      final media = PostMedia.fromJson(json);
      expect(media.mediaType, 'video');
      expect(media.isVideo, isTrue);
      expect(media.bytes, 5242880);
      expect(media.durationSeconds, 22.35);

      final serialized = media.toJson();
      expect(serialized['bytes'], 5242880);
      expect(serialized['durationSeconds'], 22.35);
    });

    test('UploadSignatureModel parses allowedFormats (N2, S3)', () {
      final json = {
        'apiKey': 'test-api-key',
        'folder': 'smart_wardrobe/posts',
        'signature': 'test-signature-sha1',
        'timestamp': 1727500000,
        'resourceType': 'image',
        'allowedFormats': 'jpg,jpeg,png,webp,avif,gif',
      };

      final signature = UploadSignatureModel.fromJson(json);
      expect(signature.apiKey, 'test-api-key');
      expect(signature.folder, 'smart_wardrobe/posts');
      expect(signature.resourceType, 'image');
      expect(signature.allowedFormats, 'jpg,jpeg,png,webp,avif,gif');
      expect(signature.publicId, isNull);
    });

    test('CloudinaryUploadResult includes bytes and duration', () {
      const uploadRes = CloudinaryUploadResult(
        secureUrl: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        publicId: 'sample',
        bytes: 1048576,
        duration: null,
      );

      expect(uploadRes.secureUrl, contains('sample.jpg'));
      expect(uploadRes.bytes, 1048576);
      expect(uploadRes.duration, isNull);
    });

    test('CommunityFeedState default sort is hot per BE spec §3.6', () {
      const state = CommunityFeedState();
      expect(state.sort, 'hot');
      expect(state.tab, 'explore');
    });
  });
}
