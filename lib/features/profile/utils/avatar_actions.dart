import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/closy_toast.dart';
import '../providers/profile_provider.dart';

final ImagePicker _picker = ImagePicker();

/// Mở sheet trượt lên với các hành động về ảnh đại diện.
///
/// Dùng chung cho trang Hồ sơ (`/profile`) và trang Cá nhân cộng đồng khi
/// `isMe = true` — hai nơi cần hành vi giống hệt nhau.
///
/// - [onView]: "Xem ảnh đại diện" — mở ảnh toàn màn hình (dùng
///   `openMediaViewer` để đồng bộ nền/zoom/đóng bằng tap vùng trống).
/// - [onPick]: "Chọn ảnh đại diện" — mở thư viện ảnh rồi tải lên.
///
/// Nút "Chọn ảnh đại diện" bị ẩn nếu người dùng chưa có ảnh — không có gì
/// để xem nên không cần nhắc tới thao tác xem.
///
/// UI bám sát sheet "Thêm đồ vào tủ" (`wardrobe_screen.dart`): full-width,
/// nền `AppColors.surface`, bo tròn 24 ở trên, handle bar 40×4, `ListTile`
/// icon trong vòng tròn `surfaceSubtle`, chữ 15/w600. Không có tiêu đề vì
/// chỉ có 2 lựa chọn.
Future<void> showAvatarActionSheet(
  BuildContext context, {
  required bool hasAvatar,
  required VoidCallback onView,
  required VoidCallback onPick,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _AvatarActionSheet(
      hasAvatar: hasAvatar,
      onView: onView,
      onPick: onPick,
    ),
  );
}

class _AvatarActionSheet extends StatelessWidget {
  final bool hasAvatar;
  final VoidCallback onView;
  final VoidCallback onPick;

  const _AvatarActionSheet({
    required this.hasAvatar,
    required this.onView,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    // Navigator của chính sheet để pop đúng route, tách khỏi `context` ngoài.
    final navigator = Navigator.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (hasAvatar) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_size_select_actual_outlined,
                        color: AppColors.primary),
                  ),
                  title: const Text('Xem ảnh đại diện',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  onTap: () {
                    navigator.pop();
                    onView();
                  },
                ),
                const SizedBox(height: 8),
              ],
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                ),
                title: const Text('Chọn ảnh đại diện',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                onTap: () {
                  navigator.pop();
                  onPick();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chọn ảnh từ thư viện rồi tải lên làm ảnh đại diện.
///
/// Gom luôn chọn ảnh + nén + gọi API + thông báo kết quả, để trang Hồ sơ,
/// trang Cá nhân cộng đồng (isMe) và nút camera nhỏ không lặp lại đoạn code
/// giống nhau.
Future<void> pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
  final picked = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 1024,
    maxHeight: 1024,
  );
  if (picked == null || !context.mounted) return;

  ClosyToast.info(context, 'Đang tải ảnh đại diện lên ...');

  final success =
      await ref.read(userProfileProvider.notifier).uploadAvatar(picked);
  if (!context.mounted) return;

  if (success) {
    ClosyToast.success(context, 'Cập nhật ảnh đại diện thành công!');
  } else {
    final error = ref.read(userProfileProvider).errorMessage ??
        'Không thể tải ảnh đại diện';
    ClosyToast.error(context, error);
  }
}

