import '../models/wardrobe_models.dart';

/// Các mã lý do phân tích từ BE (Spec 023-analyze-status-handling).
class AnalysisReasonCodes {
  static const String uncertainCategory = 'uncertain_category';
  static const String multipleItemsDetected = 'multiple_items_detected';
  static const String fullBodyOutfitDetected = 'full_body_outfit_detected';
  static const String analysisTemporaryError = 'analysis_temporary_error';
  static const String autoRetryExceeded = 'auto_retry_exceeded';
}

/// Thông tin UI và quy tắc điều hướng tương ứng với trạng thái phân tích.
class AnalysisStatusInfo {
  final String badgeLabel;
  final String detailMessage;
  final String? suggestion;
  final bool canRetry;
  final bool requiresCategory;
  final bool isInvalidImage;

  const AnalysisStatusInfo({
    required this.badgeLabel,
    required this.detailMessage,
    this.suggestion,
    this.canRetry = false,
    this.requiresCategory = false,
    this.isInvalidImage = false,
  });
}

/// Lấy thông tin hiển thị UI dựa trên trạng thái nghiệp vụ và mã lý do của món đồ.
AnalysisStatusInfo getAnalysisStatusInfo(WardrobeItemModel item) {
  // 1. Đang xử lý
  if (item.isProcessing) {
    return const AnalysisStatusInfo(
      badgeLabel: 'Đang phân tích',
      detailMessage: 'AI đang phân tích chất liệu, màu sắc và phong cách của trang phục...',
      canRetry: false,
      requiresCategory: false,
      isInvalidImage: false,
    );
  }

  // 2. Cần rà soát danh mục (needsReview = 5)
  if (item.needsReview) {
    return const AnalysisStatusInfo(
      badgeLabel: 'Cần chọn danh mục',
      detailMessage:
          'AI đã nhận diện được trang phục nhưng chưa chắc chắn về danh mục. Vui lòng chọn danh mục phù hợp bên dưới để hoàn tất phân tích.',
      suggestion: 'Chọn danh mục bên dưới để tiếp tục.',
      canRetry: true,
      requiresCategory: true,
      isInvalidImage: false,
    );
  }

  // 3. Phân tích thất bại (failed = 4)
  if (item.isFailed) {
    final reason = item.processingErrorReason?.toLowerCase().trim() ?? '';

    if (reason == AnalysisReasonCodes.multipleItemsDetected) {
      return const AnalysisStatusInfo(
        badgeLabel: 'Ảnh có nhiều món',
        detailMessage: 'Ảnh chứa nhiều món đồ hoặc trang phục phức tạp. AI chỉ có thể phân tích chính xác từng món đơn lẻ.',
        suggestion: 'Vui lòng chụp cận cảnh một món đồ duy nhất.',
        canRetry: false,
        requiresCategory: false,
        isInvalidImage: true,
      );
    }

    if (reason == AnalysisReasonCodes.fullBodyOutfitDetected) {
      return const AnalysisStatusInfo(
        badgeLabel: 'Ảnh toàn thân',
        detailMessage: 'Ảnh chụp toàn thân người mẫu hoặc cả set đồ. AI cần ảnh chụp riêng từng món trang phục.',
        suggestion: 'Vui lòng chụp cận cảnh một món đồ duy nhất.',
        canRetry: false,
        requiresCategory: false,
        isInvalidImage: true,
      );
    }

    if (reason == AnalysisReasonCodes.analysisTemporaryError ||
        reason == AnalysisReasonCodes.autoRetryExceeded) {
      return const AnalysisStatusInfo(
        badgeLabel: 'Lỗi tạm thời',
        detailMessage: 'Đã xảy ra gián đoạn trong quá trình phân tích AI. Bạn có thể nhấn Thử lại để gửi lại yêu cầu.',
        suggestion: 'Nhấn "Thử lại" để phân tích lại.',
        canRetry: true,
        requiresCategory: false,
        isInvalidImage: false,
      );
    }

    // Mã lạ hoặc không có mã
    return const AnalysisStatusInfo(
      badgeLabel: 'Lỗi phân tích',
      detailMessage: 'Không thể phân tích trang phục này. Bạn có thể thử lại hoặc tải lên một hình ảnh rõ nét hơn.',
      suggestion: 'Thử lại hoặc tải ảnh khác.',
      canRetry: true,
      requiresCategory: false,
      isInvalidImage: false,
    );
  }

  // 4. Khả dụng trong tủ đồ (inWardrobe = 0)
  return const AnalysisStatusInfo(
    badgeLabel: 'Khả dụng',
    detailMessage: 'Trang phục đã sẵn sàng để phối đồ.',
    canRetry: false,
    requiresCategory: false,
    isInvalidImage: false,
  );
}
