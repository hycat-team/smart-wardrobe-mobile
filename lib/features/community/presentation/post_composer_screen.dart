import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/closy_network_image.dart';
import '../../../../shared/widgets/closy_toast.dart';
import '../models/post_models.dart';
import '../../outfit_studio/presentation/widgets/outfit_detail_page.dart';
import '../providers/post_composer_provider.dart';
import 'widgets/outfit_picker_sheet.dart';

class PostComposerScreen extends ConsumerStatefulWidget {
  final String? editPublicId;

  const PostComposerScreen({
    super.key,
    this.editPublicId,
  });

  @override
  ConsumerState<PostComposerScreen> createState() => _PostComposerScreenState();
}

class _PostComposerScreenState extends ConsumerState<PostComposerScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _initializedFromEdit = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _syncControllersWithState(PostComposerState state) {
    if (!_initializedFromEdit && state.isEditMode && state.content.isNotEmpty) {
      _titleController.text = state.title;
      _contentController.text = state.content;
      _initializedFromEdit = true;
    }
  }

  Future<void> _pickOutfit() async {
    final result = await showModalBottomSheet<OutfitBrief>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OutfitPickerSheet(),
    );

    if (result != null) {
      ref
          .read(postComposerProvider(widget.editPublicId).notifier)
          .setSelectedOutfit(result);
    }
  }

  Future<void> _handleSubmit() async {
    final notifier = ref.read(postComposerProvider(widget.editPublicId).notifier);
    notifier.setTitle(_titleController.text);
    notifier.setContent(_contentController.text);

    final success = await notifier.submit();
    if (success && mounted) {
      ClosyToast.success(
        context,
        widget.editPublicId != null
            ? 'Cập nhật bài viết thành công!'
            : 'Đăng bài viết mới thành công!',
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final composerState = ref.watch(postComposerProvider(widget.editPublicId));
    final composerNotifier =
        ref.read(postComposerProvider(widget.editPublicId).notifier);

    _syncControllersWithState(composerState);

    final isSubmitting = composerState.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: AppColors.primary),
            tooltip: 'Quay lại',
            onPressed: () => context.pop(),
          ),
        title: Text(
          widget.editPublicId != null ? 'Chỉnh sửa bài viết' : 'Tạo bài viết mới',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        widget.editPublicId != null ? 'Lưu' : 'Đăng',
                        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner
            if (composerState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        composerState.errorMessage!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Upload progress bar
            if (composerState.isUploading || composerState.isSubmitting) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: composerState.uploadProgress > 0 ? composerState.uploadProgress : null,
                  backgroundColor: AppColors.surfaceSubtle,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accentSandDark),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                composerState.isUploading
                    ? 'Đang tải tệp lên máy chủ...'
                    : 'Đang xử lý bài viết...',
                style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
            ],

            // 1. Loại bài viết (Chỉ chọn khi tạo mới)
            if (!composerState.isEditMode) ...[
              Text(
                'LOẠI BÀI VIẾT',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeOption(
                    title: 'Bộ phối (Outfit)',
                    icon: Icons.style_outlined,
                    isSelected: composerState.postType == 'outfit',
                    onTap: () => composerNotifier.setPostType('outfit'),
                  ),
                  const SizedBox(width: 12),
                  _buildTypeOption(
                    title: 'Hình ảnh / Video',
                    icon: Icons.photo_library_outlined,
                    isSelected: composerState.postType == 'media',
                    onTap: () => composerNotifier.setPostType('media'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // 2. Chọn Outfit (nếu là bài outfit)
            if (composerState.postType == 'outfit') ...[
              Text(
                'BỘ PHỐI ĐÍNH KÈM',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (composerState.selectedOutfit == null)
                InkWell(
                  onTap: _pickOutfit,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accentSandDark,
                        style: BorderStyle.solid,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.add_circle_outline_rounded,
                            size: 32, color: AppColors.accentSandDark),
                        const SizedBox(height: 8),
                        Text(
                          'Chọn bộ phối từ tủ đồ của bạn',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: () {
                    showClosyOutfitDetail(
                      context,
                      outfitId: composerState.selectedOutfit!.id,
                      brief: composerState.selectedOutfit,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        if (composerState.selectedOutfit!.coverImageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ClosyNetworkImage(
                              imageUrl: composerState.selectedOutfit!.coverImageUrl!,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.style_outlined, color: AppColors.accentSandDark),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                composerState.selectedOutfit!.name,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Chạm để xem trước cả outfit',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  color: AppColors.accentSandDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, color: AppColors.primary),
                          tooltip: 'Xem trước cả outfit',
                          onPressed: () {
                            showClosyOutfitDetail(
                              context,
                              outfitId: composerState.selectedOutfit!.id,
                              brief: composerState.selectedOutfit,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                          tooltip: 'Đổi bộ phối',
                          onPressed: _pickOutfit,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],

            // 3. Tiêu đề bài viết
            Text(
              'TIÊU ĐỀ (TÙY CHỌN)',
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Nhập tiêu đề ấn tượng cho bài viết...',
                hintStyle: GoogleFonts.beVietnamPro(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 4. Nội dung bài viết
            Text(
              'NỘI DUNG',
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 5,
              maxLength: 5000,
              decoration: InputDecoration(
                hintText: 'Chia sẻ cảm hứng, cách phối phụ kiện hoặc mẹo phong cách...',
                hintStyle: GoogleFonts.beVietnamPro(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 5. Media Attachments Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HÌNH ẢNH & VIDEO (${composerState.media.length}/10)',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: composerState.media.length >= 10
                          ? null
                          : () => composerNotifier.pickImages(),
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                      label: const Text('Thêm ảnh'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                    TextButton.icon(
                      onPressed: composerState.media.length >= 10
                          ? null
                          : () => composerNotifier.pickVideo(),
                      icon: const Icon(Icons.video_call_outlined, size: 20),
                      label: const Text('Thêm video'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (composerState.media.isNotEmpty)
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: composerState.media.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = composerState.media[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 100,
                            height: 100,
                            color: AppColors.surfaceSubtle,
                            child: item.isLocal && !kIsWeb && item.file != null
                                ? (item.isVideo
                                    ? Container(
                                        color: const Color(0xFF1E1B18),
                                        child: const Center(
                                          child: Icon(Icons.videocam_rounded,
                                              color: Colors.white, size: 32),
                                        ),
                                      )
                                    : Image.file(
                                        File(item.file!.path),
                                        fit: BoxFit.cover,
                                      ))
                                : ClosyNetworkImage(
                                    imageUrl: item.displayUrl,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        if (item.isVideo)
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.videocam_rounded, color: Colors.white, size: 12),
                                  SizedBox(width: 2),
                                  Text('Video', style: TextStyle(color: Colors.white, fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => composerNotifier.removeMedia(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF3EFEA) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.accentSandDark : AppColors.border,
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
