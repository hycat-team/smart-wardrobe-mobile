import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/outfit_studio/models/outfit_models.dart';
import 'package:smart_wardrobe/features/outfit_studio/utils/outfit_name_check.dart';

UserOutfitModel _o(String id, String name) => UserOutfitModel(id: id, name: name);

void main() {
  group('findDuplicateOutfitByName', () {
    test('trùng tên chính xác → trả về bộ phối đã có', () {
      final dup = findDuplicateOutfitByName(
        'Set đồ công sở',
        [_o('a', 'Set đồ cuối tuần'), _o('b', 'Set đồ công sở')],
      );
      expect(dup?.id, 'b');
    });

    test('không phân biệt hoa/thường', () {
      final dup = findDuplicateOutfitByName(
        'SET ĐỒ CÔNG SỞ',
        [_o('a', 'set đồ công sở')],
      );
      expect(dup?.id, 'a');
    });

    test('bỏ khoảng trắng thừa ở hai đầu', () {
      final dup = findDuplicateOutfitByName(
        '  Set đồ dự tiệc  ',
        [_o('a', 'Set đồ dự tiệc')],
      );
      expect(dup?.id, 'a');
    });

    test('tên khác → null', () {
      final dup = findDuplicateOutfitByName(
        'Set mới',
        [_o('a', 'Set đồ cuối tuần')],
      );
      expect(dup, isNull);
    });

    test('tên rỗng → null, không báo trùng', () {
      final dup = findDuplicateOutfitByName('   ', [_o('a', 'Set đồ')]);
      expect(dup, isNull);
    });

    test('danh sách rỗng → null', () {
      expect(findDuplicateOutfitByName('Bất kỳ', const []), isNull);
    });
  });
}
