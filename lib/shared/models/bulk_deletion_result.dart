/// Kết quả xóa hàng loạt dùng chung cho Wardrobe items và Outfits.
///
/// Bất biến: [deletedIds] + [failedIds] == danh sách id đã yêu cầu
/// (không có mục nào bị lặng lẽ bỏ qua).
class BulkDeletionResult {
  /// Các id đã xóa thành công (đã gỡ khỏi danh sách local).
  final List<String> deletedIds;

  /// Các id xóa thất bại (giữ nguyên trong danh sách local).
  final List<String> failedIds;

  /// Thông điệp lỗi thô cho các id thất bại (cùng thứ tự với [failedIds]).
  final List<String> failureMessages;

  const BulkDeletionResult({
    this.deletedIds = const [],
    this.failedIds = const [],
    this.failureMessages = const [],
  });

  /// Toàn bộ yêu cầu thành công.
  bool get isAllSuccess => failedIds.isEmpty && deletedIds.isNotEmpty;

  /// Thành công một phần: có mục xóa được, có mục thất bại.
  bool get isPartial => deletedIds.isNotEmpty && failedIds.isNotEmpty;

  /// Toàn bộ thất bại (hoặc không có gì để xóa).
  bool get isAllFailed => deletedIds.isEmpty;

  int get deletedCount => deletedIds.length;
  int get failedCount => failedIds.length;

  /// Tên hiển thị của các mục thất bại (để dialog liệt kê + thử lại).
  String describeFailures(List<String> names) {
    if (failedIds.isEmpty) return '';
    if (names.isEmpty) return '${failedIds.length} mục';
    final shown = names.take(3).join(', ');
    final rest = names.length > 3 ? ' và ${names.length - 3} mục khác' : '';
    return '$shown$rest';
  }
}
