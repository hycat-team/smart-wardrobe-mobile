import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../data/wardrobe_repository.dart';
import '../models/wardrobe_models.dart';
import 'wardrobe_provider.dart';

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

/// Hàm nạp 1 ảnh (signature → Cloudinary → batch-upload).
typedef BatchUploader = Future<void> Function(XFile file);

/// Chạy nạp nhiều ảnh **độc lập**: 1 ảnh lỗi (kể cả lỗi hạn mức) không chặn
/// các ảnh khác. Trả về danh sách ảnh thất bại (để thử lại).
///
/// Tách khỏi notifier để test thuần không cần dựng provider/Ref.
Future<List<XFile>> runBatchUpload(
  List<XFile> files,
  BatchUploader uploader, {
  void Function(int completed, List<XFile> failed)? onProgress,
  void Function(XFile file, Object error)? onError,
}) async {
  final failed = <XFile>[];
  var completed = 0;
  for (final file in files) {
    try {
      await uploader(file);
    } catch (e) {
      failed.add(file);
      onError?.call(file, e);
    } finally {
      completed++;
      onProgress?.call(completed, List<XFile>.unmodifiable(failed));
    }
  }
  return failed;
}

class UploadWardrobeState {
  final bool isUploading;
  final bool isAnalyzing;
  final double progress; // 0.0 to 1.0
  final bool isSuccess;
  final String? errorMessage;

  // --- Batch (US2) ---
  /// Tổng số ảnh trong lượt nạp nhiều ảnh hiện tại (0/1 = không phải batch).
  final int batchTotal;

  /// Số ảnh đã xử lý xong (thành công hoặc thất bại).
  final int batchCompleted;

  /// Các ảnh tải lên thất bại — có thể thử lại.
  final List<XFile> failedFiles;

  const UploadWardrobeState({
    this.isUploading = false,
    this.isAnalyzing = false,
    this.progress = 0.0,
    this.isSuccess = false,
    this.errorMessage,
    this.batchTotal = 0,
    this.batchCompleted = 0,
    this.failedFiles = const <XFile>[],
  });

  /// Đang chạy lượt nạp nhiều ảnh.
  bool get isBatch => batchTotal > 1;

  /// Số ảnh thất bại trong lượt hiện tại.
  int get batchFailed => failedFiles.length;

  UploadWardrobeState copyWith({
    bool? isUploading,
    bool? isAnalyzing,
    double? progress,
    bool? isSuccess,
    String? errorMessage,
    int? batchTotal,
    int? batchCompleted,
    List<XFile>? failedFiles,
  }) {
    return UploadWardrobeState(
      isUploading: isUploading ?? this.isUploading,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      progress: progress ?? this.progress,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      batchTotal: batchTotal ?? this.batchTotal,
      batchCompleted: batchCompleted ?? this.batchCompleted,
      failedFiles: failedFiles ?? this.failedFiles,
    );
  }
}

class UploadWardrobeNotifier extends StateNotifier<UploadWardrobeState> {
  final WardrobeRepository _wardrobeRepository;
  final CloudinaryService _cloudinaryService;
  final ImagePicker _picker = ImagePicker();
  final Ref _ref;

  UploadWardrobeNotifier(
    this._wardrobeRepository,
    this._cloudinaryService,
    this._ref,
  ) : super(const UploadWardrobeState());

  /// Nạp 1 ảnh (luồng cũ) — signature → Cloudinary → batch-upload → optimistic.
  Future<bool> pickAndUpload({
    required ImageSource source,
    String? categoryId,
  }) async {
    if (state.isUploading) return false;
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) return false;

      state = state.copyWith(
        isUploading: true,
        progress: 0.1,
        errorMessage: null,
        isSuccess: false,
      );

      // 1. Get upload signature
      final signature = await _wardrobeRepository.getUploadSignature();
      state = state.copyWith(progress: 0.3);

      // 2. Upload to Cloudinary with background removal (works on Web & Mobile)
      final uploadResult = await _cloudinaryService.uploadImage(
        file: pickedFile,
        signature: signature,
      );
      state = state.copyWith(progress: 0.7, isUploading: false, isAnalyzing: true);

      // 3. Submit batch upload & analysis to Backend
      final uploadResponses = await _wardrobeRepository.batchUploadWardrobeItems([
        BatchUploadItemRequest(
          categoryId: categoryId,
          imagePublicId: uploadResult.publicId,
          imageUrl: uploadResult.secureUrl,
        ),
      ]);

      state = state.copyWith(
        isAnalyzing: false,
        progress: 1.0,
        isSuccess: true,
      );

      // 4. Immediately add optimistic item with uploaded image and start SSE tracking
      _applyOptimistic(uploadResponses, uploadResult.secureUrl);

      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        isAnalyzing: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Nạp nhiều ảnh cùng lúc (FR-005..FR-008).
  ///
  /// Mỗi ảnh xử lý **độc lập**: 1 ảnh lỗi không chặn các ảnh khác. Ảnh lỗi được
  /// giữ trong [UploadWardrobeState.failedFiles] để thử lại.
  /// Trả về số ảnh nạp thành công.
  Future<int> pickAndUploadMultiple({
    required ImageSource source,
    String? categoryId,
  }) async {
    if (state.isUploading) return 0;
    List<XFile> pickedFiles;
    try {
      pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return 0;
    }

    if (pickedFiles.isEmpty) return 0;

    return _runBatch(pickedFiles, categoryId: categoryId);
  }

  /// Thử lại các ảnh đã thất bại trong lượt batch gần nhất.
  Future<int> retryFailedUploads({String? categoryId}) async {
    if (state.isUploading) return 0;
    final files = List<XFile>.from(state.failedFiles);
    if (files.isEmpty) return 0;
    return _runBatch(files, categoryId: categoryId);
  }

  /// Có phải lỗi do vượt hạn mức gói không (FR-008).
  static bool _isQuotaError(Object error) {
    final s = error.toString().toLowerCase();
    return s.contains('quota') ||
        s.contains('limit reached') ||
        s.contains('limit exceeded') ||
        s.contains('exceeded') ||
        s.contains('hạn mức') ||
        s.contains('vượt') ||
        s.contains('wardrobe limit') ||
        s.contains('plan limit');
  }

  Future<int> _runBatch(List<XFile> files, {String? categoryId}) async {
    state = UploadWardrobeState(
      isUploading: true,
      progress: 0.0,
      batchTotal: files.length,
      batchCompleted: 0,
      failedFiles: const <XFile>[],
    );

    var quotaExceeded = false;
    final failed = await runBatchUpload(
      files,
      (file) => _uploadOne(file, categoryId: categoryId),
      onError: (file, error) {
        if (_isQuotaError(error)) quotaExceeded = true;
      },
      onProgress: (completed, failedFiles) {
        state = state.copyWith(
          progress: completed / files.length,
          batchCompleted: completed,
          failedFiles: failedFiles,
        );
      },
    );

    state = state.copyWith(
      isUploading: false,
      isAnalyzing: false,
      progress: 1.0,
      isSuccess: failed.isEmpty,
      batchCompleted: files.length,
      failedFiles: failed,
      errorMessage: failed.isEmpty
          ? null
          : (quotaExceeded
              ? 'Đã vượt hạn mức gói: ${failed.length}/${files.length} ảnh không thể thêm. Các món hợp lệ đã được lưu.'
              : '${failed.length}/${files.length} ảnh tải lên thất bại.'),
    );

    return files.length - failed.length;
  }

  Future<void> _uploadOne(XFile file, {String? categoryId}) async {
    final signature = await _wardrobeRepository.getUploadSignature();
    final uploadResult = await _cloudinaryService.uploadImage(
      file: file,
      signature: signature,
    );
    final uploadResponses = await _wardrobeRepository.batchUploadWardrobeItems([
      BatchUploadItemRequest(
        categoryId: categoryId,
        imagePublicId: uploadResult.publicId,
        imageUrl: uploadResult.secureUrl,
      ),
    ]);
    _applyOptimistic(uploadResponses, uploadResult.secureUrl);
  }

  void _applyOptimistic(
    List<BatchUploadItemResponse> uploadResponses,
    String secureUrl,
  ) {
    if (uploadResponses.isNotEmpty) {
      final resItem = uploadResponses.first;
      final optimisticItem = WardrobeItemModel(
        id: resItem.id,
        status: 3, // Processing
        taskId: resItem.taskId,
        rawImageUrl: secureUrl,
        fashionItem: FashionItemModel(
          id: resItem.fashionItemId ?? '',
          imageUrl: secureUrl,
        ),
      );
      _ref.read(wardrobeProvider.notifier).addOptimisticItem(optimisticItem);
    } else {
      _ref.read(wardrobeProvider.notifier).loadItems(refresh: true);
    }
  }

  void reset() {
    state = const UploadWardrobeState();
  }
}

final uploadWardrobeProvider = StateNotifierProvider<UploadWardrobeNotifier, UploadWardrobeState>((ref) {
  final wardrobeRepo = ref.watch(wardrobeRepositoryProvider);
  final cloudinary = ref.watch(cloudinaryServiceProvider);
  return UploadWardrobeNotifier(wardrobeRepo, cloudinary, ref);
});
