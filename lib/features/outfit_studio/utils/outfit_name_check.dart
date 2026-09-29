import '../models/outfit_models.dart';

/// Kiểm tra tên bộ phối mới có trùng với bộ phối đã lưu hay không.
///
/// BE (`POST /outfits`) không validate trùng tên nên việc này làm **hoàn
/// toàn phía client**. So sánh không phân biệt hoa/thường và bỏ khoảng trắng
/// thừa ở hai đầu.
///
/// Trả về bộ phối bị trùng (để hiển thị tên), hoặc `null` nếu không trùng.
UserOutfitModel? findDuplicateOutfitByName(
  String newName,
  List<UserOutfitModel> existing,
) {
  final normalized = newName.trim().toLowerCase();
  if (normalized.isEmpty) return null;

  for (final outfit in existing) {
    if (outfit.name.trim().toLowerCase() == normalized) return outfit;
  }
  return null;
}
