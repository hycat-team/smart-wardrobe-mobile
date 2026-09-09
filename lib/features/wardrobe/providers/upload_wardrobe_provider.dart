import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../data/wardrobe_repository.dart';
import '../models/wardrobe_models.dart';
import 'wardrobe_provider.dart';

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

class UploadWardrobeState {
  final bool isUploading;
  final bool isAnalyzing;
  final double progress; // 0.0 to 1.0
  final bool isSuccess;
  final String? errorMessage;

  const UploadWardrobeState({
    this.isUploading = false,
    this.isAnalyzing = false,
    this.progress = 0.0,
    this.isSuccess = false,
    this.errorMessage,
  });

  UploadWardrobeState copyWith({
    bool? isUploading,
    bool? isAnalyzing,
    double? progress,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return UploadWardrobeState(
      isUploading: isUploading ?? this.isUploading,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      progress: progress ?? this.progress,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
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

  Future<bool> pickAndUpload({
    required ImageSource source,
    String? categoryId,
  }) async {
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
      if (uploadResponses.isNotEmpty) {
        final resItem = uploadResponses.first;
        final optimisticItem = WardrobeItemModel(
          id: resItem.id,
          status: 3, // Processing
          taskId: resItem.taskId,
          rawImageUrl: uploadResult.secureUrl,
          fashionItem: FashionItemModel(
            id: resItem.fashionItemId ?? '',
            imageUrl: uploadResult.secureUrl,
          ),
        );
        _ref.read(wardrobeProvider.notifier).addOptimisticItem(optimisticItem);
      } else {
        _ref.read(wardrobeProvider.notifier).loadItems(refresh: true);
      }

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

  void reset() {
    state = const UploadWardrobeState();
  }
}

final uploadWardrobeProvider = StateNotifierProvider<UploadWardrobeNotifier, UploadWardrobeState>((ref) {
  final wardrobeRepo = ref.watch(wardrobeRepositoryProvider);
  final cloudinary = ref.watch(cloudinaryServiceProvider);
  return UploadWardrobeNotifier(wardrobeRepo, cloudinary, ref);
});
