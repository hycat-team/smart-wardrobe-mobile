import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../data/community_error.dart';
import '../data/community_repository.dart';
import '../models/post_models.dart';
import 'community_feed_provider.dart';

class LocalMediaItem {
  final XFile? file;
  final String mediaType; // 'image' | 'video'
  final String? existingUrl;
  final String? existingPublicId;
  final int sortOrder;
  final int? bytes;
  final double? durationSeconds;

  const LocalMediaItem({
    this.file,
    required this.mediaType,
    this.existingUrl,
    this.existingPublicId,
    required this.sortOrder,
    this.bytes,
    this.durationSeconds,
  });

  bool get isLocal => file != null;
  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image';
  String get displayUrl => existingUrl ?? file?.path ?? '';
}

class PostComposerState {
  final String postType; // 'outfit' | 'media'
  final String title;
  final String content;
  final OutfitBrief? selectedOutfit;
  final List<LocalMediaItem> media;
  final bool isUploading;
  final double uploadProgress;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isEditMode;
  final String? editPublicId;
  final bool isSuccess;

  const PostComposerState({
    this.postType = 'outfit',
    this.title = '',
    this.content = '',
    this.selectedOutfit,
    this.media = const [],
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.isSubmitting = false,
    this.errorMessage,
    this.isEditMode = false,
    this.editPublicId,
    this.isSuccess = false,
  });

  PostComposerState copyWith({
    String? postType,
    String? title,
    String? content,
    OutfitBrief? selectedOutfit,
    bool clearOutfit = false,
    List<LocalMediaItem>? media,
    bool? isUploading,
    double? uploadProgress,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool? isEditMode,
    String? editPublicId,
    bool? isSuccess,
  }) {
    return PostComposerState(
      postType: postType ?? this.postType,
      title: title ?? this.title,
      content: content ?? this.content,
      selectedOutfit: clearOutfit ? null : (selectedOutfit ?? this.selectedOutfit),
      media: media ?? this.media,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isEditMode: isEditMode ?? this.isEditMode,
      editPublicId: editPublicId ?? this.editPublicId,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class PostComposerNotifier extends StateNotifier<PostComposerState> {
  final CommunityRepository _repository;
  final CloudinaryService _cloudinaryService;
  final Ref? _ref;
  final ImagePicker _picker = ImagePicker();

  PostComposerNotifier(
    this._repository,
    this._cloudinaryService,
    this._ref, {
    String? editPublicId,
  }) : super(PostComposerState(
          isEditMode: editPublicId != null,
          editPublicId: editPublicId,
        )) {
    if (editPublicId != null) {
      _loadExistingPost(editPublicId);
    }
  }

  Future<void> _loadExistingPost(String publicId) async {
    try {
      final post = await _repository.getPostDetail(publicId);
      final mediaItems = post.media.map((m) {
        return LocalMediaItem(
          mediaType: m.mediaType,
          existingUrl: m.mediaUrl,
          existingPublicId: m.publicId,
          sortOrder: m.sortOrder,
        );
      }).toList();

      state = state.copyWith(
        postType: post.postType,
        title: post.title ?? '',
        content: post.content,
        selectedOutfit: post.outfit,
        media: mediaItems,
        isEditMode: true,
        editPublicId: publicId,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: extractCommunityErrorMessage(e));
    }
  }

  void setPostType(String type) {
    if (state.isEditMode) return; // Không cho phép đổi postType khi chỉnh sửa
    state = state.copyWith(postType: type, clearError: true);
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setContent(String content) {
    state = state.copyWith(content: content);
  }

  void setSelectedOutfit(OutfitBrief? outfit) {
    state = state.copyWith(
      selectedOutfit: outfit,
      clearOutfit: outfit == null,
      clearError: true,
    );
  }

  /// Chọn nhiều ảnh qua ImagePicker
  Future<void> pickImages() async {
    final remainingSlots = 10 - state.media.length;
    if (remainingSlots <= 0) {
      state = state.copyWith(errorMessage: 'Tối đa 10 tệp hình ảnh/video cho mỗi bài viết.');
      return;
    }

    try {
      final pickedFiles = await _picker.pickMultiImage(limit: remainingSlots);
      if (pickedFiles.isEmpty) return;

      const allowedImageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'avif', 'gif'};
      final newMedia = [...state.media];
      for (final f in pickedFiles) {
        if (newMedia.length >= 10) break;

        final ext = f.name.split('.').last.toLowerCase();
        if (!allowedImageExtensions.contains(ext)) {
          state = state.copyWith(
            errorMessage: 'Định dạng ảnh "${f.name}" không hợp lệ. Chỉ chấp nhận: jpg, jpeg, png, webp, avif, gif',
          );
          return;
        }

        final length = await f.length();
        if (length > 10 * 1024 * 1024) {
          state = state.copyWith(errorMessage: 'Ảnh "${f.name}" vượt quá giới hạn dung lượng 10MB.');
          return;
        }
        newMedia.add(
          LocalMediaItem(
            file: f,
            mediaType: 'image',
            sortOrder: newMedia.length,
            bytes: length,
          ),
        );
      }

      state = state.copyWith(media: newMedia, clearError: true);
    } catch (_) {
      state = state.copyWith(errorMessage: 'Không thể chọn ảnh từ thiết bị.');
    }
  }

  /// Chọn 1 video qua ImagePicker (tối đa 60 giây, <=100MB)
  Future<void> pickVideo() async {
    final remainingSlots = 10 - state.media.length;
    if (remainingSlots <= 0) {
      state = state.copyWith(errorMessage: 'Tối đa 10 tệp hình ảnh/video cho mỗi bài viết.');
      return;
    }

    try {
      final file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (file == null) return;

      const allowedVideoExtensions = {'mp4', 'webm', 'mov', 'm4v', 'mkv', 'avi'};
      final ext = file.name.split('.').last.toLowerCase();
      if (!allowedVideoExtensions.contains(ext)) {
        state = state.copyWith(
          errorMessage: 'Định dạng video "${file.name}" không hợp lệ. Chỉ chấp nhận: mp4, webm, mov, m4v, mkv, avi',
        );
        return;
      }

      final length = await file.length();
      if (length > 100 * 1024 * 1024) {
        state = state.copyWith(errorMessage: 'Video vượt quá giới hạn dung lượng 100MB.');
        return;
      }

      final newMedia = [...state.media];
      newMedia.add(
        LocalMediaItem(
          file: file,
          mediaType: 'video',
          sortOrder: newMedia.length,
          bytes: length,
        ),
      );

      state = state.copyWith(media: newMedia, clearError: true);
    } catch (_) {
      state = state.copyWith(errorMessage: 'Không thể chọn video từ thiết bị.');
    }
  }

  void removeMedia(int index) {
    if (index < 0 || index >= state.media.length) return;
    final newMedia = [...state.media]..removeAt(index);
    // Cập nhật lại sortOrder
    final reordered = List.generate(
      newMedia.length,
      (i) => LocalMediaItem(
        file: newMedia[i].file,
        mediaType: newMedia[i].mediaType,
        existingUrl: newMedia[i].existingUrl,
        existingPublicId: newMedia[i].existingPublicId,
        sortOrder: i,
        bytes: newMedia[i].bytes,
        durationSeconds: newMedia[i].durationSeconds,
      ),
    );
    state = state.copyWith(media: reordered);
  }

  /// Kiểm tra tính hợp lệ của dữ liệu trước khi đăng
  String? validate() {
    if (state.title.trim().length > 150) {
      return 'Tiêu đề không được vượt quá 150 ký tự.';
    }
    if (state.content.trim().length > 5000) {
      return 'Nội dung bài viết không được vượt quá 5000 ký tự.';
    }
    if (state.postType == 'outfit') {
      if (state.selectedOutfit == null) {
        return 'Vui lòng chọn một bộ phối từ tủ đồ của bạn.';
      }
    } else {
      // media post
      if (state.content.trim().isEmpty && state.media.isEmpty) {
        return 'Vui lòng nhập nội dung bài viết hoặc chọn ít nhất một hình ảnh/video.';
      }
    }
    if (state.media.length > 10) {
      return 'Tối đa 10 tệp hình ảnh/video cho mỗi bài viết.';
    }
    return null;
  }

  /// Tải lên media và submit bài viết
  Future<bool> submit() async {
    final validationError = validate();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    state = state.copyWith(
      isUploading: true,
      isSubmitting: true,
      uploadProgress: 0.1,
      clearError: true,
    );

    try {
      final uploadedMediaReqs = <PostMediaReq>[];

      // 1. Upload các file local lên Cloudinary qua signature
      for (int i = 0; i < state.media.length; i++) {
        final item = state.media[i];
        if (item.isLocal && item.file != null) {
          final signature = await _repository.getUploadSignaturePost(
            resourceType: item.mediaType,
          );
          final uploadRes = await _cloudinaryService.uploadImage(
            file: item.file!,
            signature: signature,
            resourceType: item.mediaType,
            applyBgRemoval: false,
          );

          final fileLength = await item.file!.length();
          final finalBytes = uploadRes.bytes ?? item.bytes ?? fileLength;
          final finalDuration = uploadRes.duration ?? item.durationSeconds;

          uploadedMediaReqs.add(
            PostMediaReq(
              mediaType: item.mediaType,
              mediaUrl: uploadRes.secureUrl,
              publicId: uploadRes.publicId,
              sortOrder: i,
              bytes: finalBytes,
              durationSeconds: finalDuration,
            ),
          );
        } else if (item.existingUrl != null) {
          uploadedMediaReqs.add(
            PostMediaReq(
              mediaType: item.mediaType,
              mediaUrl: item.existingUrl!,
              publicId: item.existingPublicId,
              sortOrder: i,
              bytes: item.bytes,
              durationSeconds: item.durationSeconds,
            ),
          );
        }
        state = state.copyWith(
          uploadProgress: 0.1 + (0.7 * (i + 1) / (state.media.isEmpty ? 1 : state.media.length)),
        );
      }

      state = state.copyWith(isUploading: false);

      // 2. Gửi request tạo hoặc sửa bài viết
      if (state.isEditMode && state.editPublicId != null) {
        final updateReq = UpdatePostReq(
          title: state.title.trim().isNotEmpty ? state.title.trim() : null,
          content: state.content.trim(),
          outfitId: state.selectedOutfit?.id,
          media: uploadedMediaReqs.isNotEmpty ? uploadedMediaReqs : null,
        );
        final updatedPost = await _repository.updatePost(state.editPublicId!, updateReq);
        _ref?.read(communityFeedProvider.notifier).updatePost(updatedPost);
      } else {
        final createReq = CreatePostReq(
          postType: state.postType,
          title: state.title.trim().isNotEmpty ? state.title.trim() : null,
          content: state.content.trim(),
          outfitId: state.selectedOutfit?.id,
          media: uploadedMediaReqs.isNotEmpty ? uploadedMediaReqs : null,
        );
        await _repository.createPost(createReq);
        // Refresh feed để bài mới xuất hiện trên đầu
        _ref?.read(communityFeedProvider.notifier).loadFeed(isRefresh: true);
      }

      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        uploadProgress: 1.0,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        isSubmitting: false,
        errorMessage: extractCommunityErrorMessage(e),
      );
      return false;
    }
  }
}

final postComposerProvider = StateNotifierProvider.autoDispose
    .family<PostComposerNotifier, PostComposerState, String?>((ref, editPublicId) {
  final repo = ref.watch(communityRepositoryProvider);
  final cloudinary = CloudinaryService();
  return PostComposerNotifier(repo, cloudinary, ref, editPublicId: editPublicId);
});
