import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/wardrobe/models/wardrobe_models.dart';
import 'package:smart_wardrobe/features/wardrobe/utils/analysis_status.dart';

void main() {
  group('Wardrobe Analysis Status & Retry Rules (Spec 023)', () {
    test('isProcessing status returns non-retryable processing info', () {
      final item = const WardrobeItemModel(
        id: 'item-1',
        status: 3, // processing
      );

      final statusInfo = getAnalysisStatusInfo(item);
      expect(statusInfo.badgeLabel, 'Đang phân tích');
      expect(statusInfo.canRetry, false);
      expect(statusInfo.requiresCategory, false);
      expect(statusInfo.isInvalidImage, false);
    });

    test('needsReview (status 5) requires category selection and allows retry', () {
      final item = const WardrobeItemModel(
        id: 'item-2',
        status: 5, // needs_review
        fashionItem: FashionItemModel(
          id: 'f2',
          imageUrl: 'https://example.com/item2.jpg',
          reviewReason: AnalysisReasonCodes.uncertainCategory,
        ),
      );

      final statusInfo = getAnalysisStatusInfo(item);
      expect(statusInfo.badgeLabel, 'Cần chọn danh mục');
      expect(statusInfo.canRetry, true);
      expect(statusInfo.requiresCategory, true);
      expect(statusInfo.isInvalidImage, false);
    });

    test('Failed with multiple_items_detected blocks retry and flags invalid image', () {
      final item = const WardrobeItemModel(
        id: 'item-3',
        status: 4, // failed
        fashionItem: FashionItemModel(
          id: 'f3',
          imageUrl: 'https://example.com/item3.jpg',
          processingErrorReason: AnalysisReasonCodes.multipleItemsDetected,
        ),
      );

      final statusInfo = getAnalysisStatusInfo(item);
      expect(statusInfo.badgeLabel, 'Ảnh có nhiều món');
      expect(statusInfo.canRetry, false); // Nút Thử lại phải bị ẩn!
      expect(statusInfo.requiresCategory, false);
      expect(statusInfo.isInvalidImage, true);
    });

    test('Failed with full_body_outfit_detected blocks retry and flags invalid image', () {
      final item = const WardrobeItemModel(
        id: 'item-4',
        status: 4, // failed
        fashionItem: FashionItemModel(
          id: 'f4',
          imageUrl: 'https://example.com/item4.jpg',
          processingErrorReason: AnalysisReasonCodes.fullBodyOutfitDetected,
        ),
      );

      final statusInfo = getAnalysisStatusInfo(item);
      expect(statusInfo.badgeLabel, 'Ảnh toàn thân');
      expect(statusInfo.canRetry, false); // Nút Thử lại phải bị ẩn!
      expect(statusInfo.requiresCategory, false);
      expect(statusInfo.isInvalidImage, true);
    });

    test('Failed with temporary errors allows direct retry without category', () {
      final itemTemp = const WardrobeItemModel(
        id: 'item-5',
        status: 4, // failed
        fashionItem: FashionItemModel(
          id: 'f5',
          imageUrl: 'https://example.com/item5.jpg',
          processingErrorReason: AnalysisReasonCodes.analysisTemporaryError,
        ),
      );

      final statusInfoTemp = getAnalysisStatusInfo(itemTemp);
      expect(statusInfoTemp.badgeLabel, 'Lỗi tạm thời');
      expect(statusInfoTemp.canRetry, true);
      expect(statusInfoTemp.requiresCategory, false);
      expect(statusInfoTemp.isInvalidImage, false);

      final itemExceeded = const WardrobeItemModel(
        id: 'item-6',
        status: 4, // failed
        fashionItem: FashionItemModel(
          id: 'f6',
          imageUrl: 'https://example.com/item6.jpg',
          processingErrorReason: AnalysisReasonCodes.autoRetryExceeded,
        ),
      );

      final statusInfoExceeded = getAnalysisStatusInfo(itemExceeded);
      expect(statusInfoExceeded.badgeLabel, 'Lỗi tạm thời');
      expect(statusInfoExceeded.canRetry, true);
      expect(statusInfoExceeded.requiresCategory, false);
      expect(statusInfoExceeded.isInvalidImage, false);
    });

    test('Failed with unknown reason code falls back safely to general retryable error', () {
      final itemUnknown = const WardrobeItemModel(
        id: 'item-7',
        status: 4, // failed
        fashionItem: FashionItemModel(
          id: 'f7',
          imageUrl: 'https://example.com/item7.jpg',
          processingErrorReason: 'some_unknown_server_error_123',
        ),
      );

      final statusInfo = getAnalysisStatusInfo(itemUnknown);
      expect(statusInfo.badgeLabel, 'Lỗi phân tích');
      expect(statusInfo.canRetry, true);
      expect(statusInfo.requiresCategory, false);
      expect(statusInfo.isInvalidImage, false);
    });

    test('Active items in wardrobe return ready status', () {
      final item = const WardrobeItemModel(
        id: 'item-8',
        status: 0, // inWardrobe
      );

      final statusInfo = getAnalysisStatusInfo(item);
      expect(statusInfo.badgeLabel, 'Khả dụng');
      expect(statusInfo.canRetry, false);
      expect(statusInfo.requiresCategory, false);
      expect(statusInfo.isInvalidImage, false);
    });
  });
}
