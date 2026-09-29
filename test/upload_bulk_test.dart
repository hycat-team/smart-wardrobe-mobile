import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_wardrobe/features/wardrobe/providers/upload_wardrobe_provider.dart';

void main() {
  group('UploadWardrobeState (US2)', () {
    test('mặc định không phải batch', () {
      const s = UploadWardrobeState();
      expect(s.isBatch, isFalse);
      expect(s.batchFailed, 0);
      expect(s.failedFiles, isEmpty);
    });

    test('isBatch true khi có hơn 1 ảnh', () {
      const s = UploadWardrobeState(batchTotal: 4, batchCompleted: 2);
      expect(s.isBatch, isTrue);
      expect(s.batchCompleted, 2);
    });

    test('copyWith giữ nguyên batch fields', () {
      final s = const UploadWardrobeState(batchTotal: 3)
          .copyWith(batchCompleted: 2, failedFiles: [XFile('x.jpg')]);
      expect(s.batchTotal, 3);
      expect(s.batchCompleted, 2);
      expect(s.batchFailed, 1);
    });
  });

  group('runBatchUpload (US2)', () {
    test('ảnh lỗi không chặn các ảnh khác', () async {
      final files = [
        XFile('a.jpg'),
        XFile('b.jpg'),
        XFile('c.jpg'),
        XFile('d.jpg'),
      ];
      final success = <String>[];

      final failed = await runBatchUpload(files, (f) async {
        if (f.name == 'b.jpg') throw Exception('upload boom');
        success.add(f.name);
      });

      expect(success, ['a.jpg', 'c.jpg', 'd.jpg']);
      expect(failed.map((f) => f.name), ['b.jpg']);
    });

    test('onProgress tăng dần và phản ánh ảnh lỗi', () async {
      final files = [XFile('1.jpg'), XFile('2.jpg'), XFile('3.jpg')];
      final progress = <String>[];

      await runBatchUpload(
        files,
        (f) async {
          if (f.name == '2.jpg') throw Exception('nope');
        },
        onProgress: (c, failed) => progress.add('$c:${failed.length}'),
      );

      expect(progress, ['1:0', '2:1', '3:1']);
    });

    test('hạn mức: vượt quota 1 ảnh -> chỉ ảnh đó thất bại', () async {
      final files = List.generate(5, (i) => XFile('img$i.jpg'));
      var ok = 0;

      final failed = await runBatchUpload(files, (f) async {
        if (f.name == 'img3.jpg') throw Exception('Quota exceeded');
        ok++;
      });

      expect(ok, 4);
      expect(failed.single.name, 'img3.jpg');
    });

    test('tất cả thành công -> không có ảnh thất bại', () async {
      final files = [XFile('a.jpg'), XFile('b.jpg')];
      final failed = await runBatchUpload(files, (f) async {});
      expect(failed, isEmpty);
    });

    test('onError nhận đúng lỗi của ảnh thất bại (phục vụ phân loại quota)', () async {
      final files = [XFile('ok.jpg'), XFile('quota.jpg')];
      final errors = <String, String>{};

      final failed = await runBatchUpload(
        files,
        (f) async {
          if (f.name == 'quota.jpg') throw Exception('Quota exceeded');
        },
        onError: (f, e) => errors[f.name] = e.toString(),
      );

      expect(failed.single.name, 'quota.jpg');
      expect(errors.keys, ['quota.jpg']);
      expect(errors['quota.jpg']!.toLowerCase(), contains('quota'));
    });
  });
}
