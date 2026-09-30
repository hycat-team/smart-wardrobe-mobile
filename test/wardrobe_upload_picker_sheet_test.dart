import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression cho sheet "Thêm đồ vào tủ" (`wardrobe_screen.dart`).
///
/// Yêu cầu: bỏ option chọn 1 ảnh "Chọn từ thư viện ảnh" (trùng ý với option
/// chọn nhiều ảnh), đổi tên "Chọn nhiều ảnh cùng lúc" → "Chọn từ thư viện ảnh",
/// và bỏ hết các dòng mô tả (subtitle) + dòng giới thiệu dưới tiêu đề.
///
/// Test ở mức source vì `WardrobeScreen` cần override gần như toàn bộ
/// provider (wardrobe, categories, upload) + `GoRouter` — nặng hơn nhiều so
/// với giá trị của một check văn bản, và vẫn bắt được hồi quy.
void main() {
  late String source;
  late String code;

  setUpAll(() {
    source = File(
      'lib/features/wardrobe/presentation/wardrobe_screen.dart',
    ).readAsStringSync();
    // Bỏ comment `//` để các ghi chú "đã bỏ X" không làm test khớp nhầm —
    // test này chỉ quan tâm nội dung thật còn xuất hiện trong UI.
    code = source
        .split('\n')
        .map((l) => l.contains('//') ? l.substring(0, l.indexOf('//')) : l)
        .join('\n');
  });

  test('còn đúng 3 lựa chọn trong sheet "Thêm đồ vào tủ"', () {
    expect(code, contains('Chụp ảnh mới'));
    expect(code, contains('Chọn từ thư viện ảnh'));
    expect(code, contains('Từ tủ đồ hệ thống'));
  });

  test('bỏ option "Chọn nhiều ảnh cùng lúc"', () {
    expect(code, isNot(contains('Chọn nhiều ảnh cùng lúc')));
  });

  test('bỏ dòng mô tả "Chụp ảnh hoặc chọn từ máy để AI tự động..."', () {
    expect(code, isNot(contains('Chụp ảnh hoặc chọn từ máy để AI tự động')));
  });

  test('không còn subtitle nào trong sheet', () {
    expect(
      code,
      isNot(contains('subtitle:')),
      reason: 'đã bỏ hết dòng mô tả của các option',
    );
  });

  test('option thư viện ảnh dùng icon collections_outlined (chọn nhiều ảnh)', () {
    expect(code, contains('Icons.collections_outlined'));
    // Icon của option 1 ảnh đã bị gỡ.
    expect(code, isNot(contains('Icons.photo_library_outlined')));
  });

  test('option thư viện ảnh gọi _handleUploadMultiple', () {
    expect(code, contains('_handleUploadMultiple(ImageSource.gallery)'));
  });
}
