/// Bộ khoá nhận diện câu hỏi có liên quan tới cách phối đồ / trang phục.
///
/// Spec 015 — FR-021, R7.
///
/// Sao chép nguyên văn bộ khoá máy chủ dùng trong prompt của stylist
/// (`services/commerce/internal/modules/fashion/application/usecase/ai/chat/helper.go`):
/// `tu do|ao|quan|vay|chan vay|dam|giay|ao-khoac|ao khoac|do cua|mac|phoi|style
/// |gu|mac gi|goi y|bo do|do`.
///
/// Máy chủ khớp SAU khi bỏ dấu tiếng Việt và hạ chữ thường; ứng dụng làm y hệt
/// để hai bên không lệch nhau.
///
/// Vì sao không dùng `contains('phối')`:
/// - Quá hẹp — bỏ sót câu như "mặc gì cho đi làm", "áo gì hợp với quần nâu".
/// - `contains('outfit')` của bản cũ khớp cả từ tiếng Anh trong câu hỏi
///   không liên quan tới thời trang.
const List<String> _outfitKeywords = [
  'tu do',
  'ao',
  'quan',
  'vay',
  'chan vay',
  'dam',
  'giay',
  'ao khoac',
  'do cua',
  'mac',
  'phoi',
  'style',
  'gu',
  'mac gi',
  'goi y',
  'bo do',
  'do',
];

/// Bỏ dấu tiếng Việt + hạ chữ thường, khớp cách máy chủ làm.
String normalizeVietnamese(String input) {
  const from = 'àáạảãâầấậẩẫăằắặẳẵặèéẹẻẽêềếệễễìíịỉĩòóọỏõôồốộỗổơờớợởỡùúụủũưừứựửữỳýỷỹỵđĐ';
  const to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydd';
  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final idx = from.indexOf(ch);
    buffer.write(idx >= 0 ? to[idx] : ch);
  }
  return buffer.toString();
}

/// `true` khi câu hỏi có liên quan tới cách phối đồ / trang phục.
bool isOutfitRelatedQuery(String content) {
  final normalized = normalizeVietnamese(content);
  for (final kw in _outfitKeywords) {
    // So khớp theo ranh giới từ để tránh "do" khớp nhầm trong từ dài hơn.
    var index = normalized.indexOf(kw);
    while (index != -1) {
      final before = index == 0 ? ' ' : normalized[index - 1];
      final afterIndex = index + kw.length;
      final after =
          afterIndex >= normalized.length ? ' ' : normalized[afterIndex];
      final isBoundary = !_isWordChar(before) && !_isWordChar(after);
      if (isBoundary) return true;
      index = normalized.indexOf(kw, index + 1);
    }
  }
  return false;
}

bool _isWordChar(String ch) {
  final code = ch.codeUnitAt(0);
  // Chỉ coi ký tự chữ/số là "từ"; dấu cách và dấu câu là ranh giới.
  return (code >= 0x30 && code <= 0x39) || (code >= 0x61 && code <= 0x7a);
}
