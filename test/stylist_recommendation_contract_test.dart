import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/outfit_studio/models/outfit_models.dart';
import 'package:smart_wardrobe/features/stylist/data/outfit_query_matcher.dart';
// Spec 015 — T053/T056: import hàm làm phẳng THẬT trong tầng repository thay vì
// chép lại logic. Trước đây test dựng bản sao riêng nên bug null-check trong
// `brand!` không bao giờ bị bắt.
import 'package:smart_wardrobe/features/stylist/data/stylist_repository.dart';
import 'package:smart_wardrobe/features/stylist/models/stylist_models.dart';

/// Spec 015 — kiểm thử hợp đồng dữ liệu của thẻ gợi ý stylist.
///
/// Cố tình dựng payload đúng y như máy chủ (`dto/recommendation.go`) thay vì dùng
/// tên trường "đẹp" hơn, để chặn đúng lỗi đã xảy ra trước đây: đọc
/// `data.items[i].imageUrl` ở cấp sai nên mọi thẻ ra rỗng.
OutfitRecommendationModel parseRecommendation(Map<String, dynamic> data) {
  final parsed = RecommendedOutfitRes.fromJson(data);

  final flat = flattenRecommendationGroups(parsed.items);

  return OutfitRecommendationModel(
    id: 'rec_test',
    title: parsed.title,
    explanation: parsed.explanation.isEmpty ? null : parsed.explanation,
    items: flat,
    isFallback: parsed.isFallback,
    remainingQuota: parsed.remainingQuota,
  );
}

Map<String, dynamic> _fashionItem({
  required String id,
  required String imageUrl,
  String? categoryName,
  String? color,
}) =>
    {
      'id': id,
      'imageUrl': imageUrl,
      'category': {'id': 1, 'name': categoryName ?? 'Áo sơ mi'},
      'color': color ?? 'Trắng',
    };

void main() {
  group('Spec 015 — thẻ gợi ý stylist theo hợp đồng máy chủ', () {
    test('FR-018 — làm phẳng primary + alternatives kèm ảnh từ fashionItem', () {
      final rec = parseRecommendation({
        'title': 'Phong cách công sở',
        'explanation': 'Chọn theo tông lạnh.',
        'fallback': false,
        'items': [
          {
            'role': 'top',
            'primary': {
              'id': 'ri_1',
              'itemContext': 'user_wardrobe',
              'fashionItem': _fashionItem(
                id: 'fi_1',
                imageUrl: 'https://img/ao.jpg',
                categoryName: 'Áo sơ mi',
              ),
            },
            'alternatives': [
              {
                'id': 'ri_2',
                'itemContext': 'user_wardrobe',
                'fashionItem': _fashionItem(
                  id: 'fi_2',
                  imageUrl: 'https://img/blouse.jpg',
                  categoryName: 'Blouse',
                ),
              },
            ],
          },
        ],
      });

      expect(rec.title, 'Phong cách công sở');
      expect(rec.isFallback, isFalse);
      expect(rec.items.length, 2, reason: '1 primary + 1 alternative');
      expect(rec.items.first.imageUrl, 'https://img/ao.jpg');
      expect(rec.items.first.role, 'top');
      expect(rec.items.first.isAlternative, isFalse);
      expect(rec.items.last.imageUrl, 'https://img/blouse.jpg');
      expect(rec.items.last.isAlternative, isTrue);
    });

    test('FR-018 — lấy được ảnh khi máy chủ dùng brandItem thay fashionItem', () {
      final rec = parseRecommendation({
        'title': 'Gợi ý thương hiệu',
        'items': [
          {
            'role': 'footwear',
            'primary': {
              'id': 'ri_3',
              'itemContext': 'brand_item',
              'brandItem': {
                'id': 'bi_1',
                'imageUrl': 'https://img/giay.jpg',
                'category': {'id': 9, 'name': 'Giày'},
                'brandName': 'JIL SANDER',
                'price': 4200000.0,
              },
            },
            'alternatives': [],
          },
        ],
      });

      expect(rec.items.length, 1);
      expect(rec.items.first.imageUrl, 'https://img/giay.jpg');
      expect(rec.items.first.brand, 'JIL SANDER');
      expect(rec.items.first.category, 'Giày');
    });

    test('FR-017 — nhóm không có món nào thì không tạo thẻ rỗng', () {
      final rec = parseRecommendation({
        'title': 'Tủ đồ trống',
        'items': [
          {
            'role': 'top',
            'primary': null,
            'alternatives': [],
          },
          {
            'role': 'bottom',
            'primary': {'id': 'ri_4', 'itemContext': 'user_wardrobe'},
            'alternatives': [],
          },
        ],
      });

      expect(rec.items, isEmpty,
          reason: 'nhóm rỗng và nhóm thiếu cả 2 nguồn đều phải bị bỏ qua');
    });

    test('FR-019 — món không có ảnh thì giữ thẻ, imageUrl = null', () {
      final rec = parseRecommendation({
        'title': 'Thiếu ảnh',
        'items': [
          {
            'role': 'headwear',
            'primary': {
              'id': 'ri_5',
              'itemContext': 'user_wardrobe',
              'fashionItem': _fashionItem(
                id: 'fi_5',
                imageUrl: '',
                categoryName: 'Mũ',
              ),
            },
            'alternatives': [],
          },
        ],
      });

      expect(rec.items.length, 1);
      expect(rec.items.first.imageUrl, isNull);
      expect(rec.items.first.hasImage, isFalse);
      expect(rec.items.first.roleLabelVi, 'Mũ / Nón',
          reason: 'UI sẽ hiện nhãn vai trò thay khung trống');
    });

    test('FR-029/FR-030 — mang cờ dự phòng và hạn mức còn lại tới UI', () {
      final rec = parseRecommendation({
        'title': 'Bộ sưu tập dự phòng',
        'fallback': true,
        'remainingQuota': 0,
        'items': [],
      });

      expect(rec.isFallback, isTrue);
      expect(rec.remainingQuota, 0);
    });
  });

  group('Spec 015 — hồi quy converge (Phase 9)', () {
    test('T052 — fromJson giữ được cờ dự phòng và hạn mức', () {
      // Regression: factory bỏ sót hai trường nên parse lại từ JSON thì cờ dự
      // phòng rơi về false và hạn mức về 0 — nhãn dự phòng biến mất (FR-029).
      final fromServerKey = OutfitRecommendationModel.fromJson({
        'id': 'rec_1',
        'title': 'Dự phòng',
        'fallback': true,
        'remainingQuota': 0,
      });
      expect(fromServerKey.isFallback, isTrue,
          reason: 'phải đọc khoá `fallback` mà máy chủ thật sự gửi');
      expect(fromServerKey.remainingQuota, 0);

      // Hạn mức còn lại > 0 vẫn phải mang sang được.
      final withQuota = OutfitRecommendationModel.fromJson({
        'id': 'rec_2',
        'title': 'Chuẩn',
        'fallback': true,
        'remainingQuota': 2,
      });
      expect(withQuota.remainingQuota, 2);
      expect(withQuota.isFallback, isTrue);

      // Khoá cũ `isFallback` vẫn phải hiểu, và mặc định là gợi ý chuẩn.
      expect(
        OutfitRecommendationModel.fromJson({'id': 'r', 'title': 't', 'isFallback': true})
            .isFallback,
        isTrue,
      );
      expect(
        OutfitRecommendationModel.fromJson({'id': 'r', 'title': 't'}).isFallback,
        isFalse,
      );
    });

    test('T052 — remainingQuota dạng chuỗi vẫn parse được', () {
      expect(
        OutfitRecommendationModel.fromJson(
            {'id': 'r', 'title': 't', 'remainingQuota': '3'}).remainingQuota,
        3,
      );
      expect(
        OutfitRecommendationModel.fromJson(
            {'id': 'r', 'title': 't', 'remainingQuota': null}).remainingQuota,
        0,
      );
    });

    test('T053 — fashionItem có id rỗng và không có brandItem thì không ném lỗi', () {
      // Bản trước viết `(fashion?.id.isNotEmpty ?? false) ? fashion!.id : (brand!.id...)`.
      // Với `fashionItem` tồn tại nhưng `id` rỗng và KHÔNG có `brandItem`, biểu
      // thức ép buộc đọc `brand!.id` ném null-check — hỏng cả lượt gợi ý.
      final groups = [
        RecommendedItemGroup.fromJson({
          'role': 'top',
          'primary': {
            'id': 'slot-1',
            'fashionItem': {'id': '', 'imageUrl': ''},
          },
          'alternatives': [
            {
              'id': 'slot-2',
              'fashionItem': _fashionItem(id: 'f2', imageUrl: 'https://x/2.jpg'),
            },
          ],
        }),
      ];

      final flat = flattenRecommendationGroups(groups);

      // Không ném lỗi là mục tiêu chính. Món thiếu `fashionItem.id` vẫn nhận định
      // danh từ `res.id` (thuộc chuỗi id gốc, giữ nguyên hành vi trước đây), và
      // món thay thế vẫn hiện — lượt gợi ý không bị hỏng toàn bộ.
      expect(flat.length, 2);
      expect(flat.first.id, 'slot-1');
      expect(flat.last.id, 'f2');
      expect(flat.last.imageUrl, 'https://x/2.jpg');
    });

    test('T053 — ưu tiên định danh món tủ đồ, thiếu mới lấy món thương hiệu', () {
      final flat = flattenRecommendationGroups([
        RecommendedItemGroup.fromJson({
          'role': 'footwear',
          'primary': {
            'id': 'slot',
            'fashionItem': _fashionItem(id: 'f-wardrobe', imageUrl: 'https://x/a.jpg'),
          },
        }),
        RecommendedItemGroup.fromJson({
          'role': 'accessory',
          'primary': {
            'id': 'slot',
            'brandItem': {'id': 'b-1', 'imageUrl': 'https://x/b.jpg'},
          },
        }),
        RecommendedItemGroup.fromJson({
          'role': 'other',
          // Không nguồn nào có id → chỉ còn id của chính `RecommendedItemRes`.
          'primary': {'id': 'slot-3', 'fashionItem': {'imageUrl': ''}},
        }),
      ]);

      expect(flat.map((e) => e.id), ['f-wardrobe', 'b-1', 'slot-3']);
    });

    test('T056 — model rỗng do thất bại không sinh món nào cho carousel', () {
      // Repository trả model rỗng khi lỗi; provider gán nó vào message. Điều kiện
      // hiển thị carousel phải dựa trên `items` rỗng chứ không dựa trên việc
      // `outfitRecommendation` có null hay không.
      const failed = OutfitRecommendationModel(id: '', title: '');

      final msg = ChatMessageModel(
        id: 'ai_1',
        content: 'Xin lỗi, phần gợi ý tạm thời không có.',
        sender: 'ASSISTANT',
        timestamp: DateTime(2026, 10, 2),
        outfitRecommendation: failed,
      );

      expect(msg.outfitRecommendation, isNotNull);
      expect(msg.suggestedItems, isEmpty,
          reason: 'carousel phải bị chặn bởi items rỗng, không hiện khung trống');
    });
  });

  group('Spec 015 — nhãn vai trò', () {
    test('FR-031 — ánh xạ đúng điển từ máy chủ sang tiếng Việt', () {
      expect(outfitRoleLabelVi('top'), 'Áo');
      expect(outfitRoleLabelVi('bottom'), 'Quần / Váy');
      expect(outfitRoleLabelVi('fullbody'), 'Váy liền / Đầm');
      expect(outfitRoleLabelVi('outerwear'), 'Áo khoác');
      expect(outfitRoleLabelVi('footwear'), 'Giày dép');
      expect(outfitRoleLabelVi('headwear'), 'Mũ / Nón');
      expect(outfitRoleLabelVi('accessory'), 'Phụ kiện');
      expect(outfitRoleLabelVi('other'), 'Món khác');
    });

    test('FR-032 — vai trò lạ hiện nguyên chuỗi gốc, không upper-case', () {
      expect(outfitRoleLabelVi('costume'), 'costume');
      expect(outfitRoleLabelVi('SWIMWEAR'), 'SWIMWEAR');
    });
  });

  group('Spec 015 — thất bại thì không bịa danh sách món (FR-022, FR-023)', () {
    test('FR-023 — mô phỏng repository lỗi trả về model rỗng, không kèm món bịa', () {
      // Khối fallback Unsplash từng nhúng sẵn trong repository: gọi
      // /ai/outfit-recommendations hỏng là người dùng thấy ngay một bộ 4 món
      // "gợi ý" không liên quan tới tủ đồ. Hành vi đúng là trả về rỗng.
      const failed = OutfitRecommendationModel(id: '', title: '');

      expect(failed.items, isEmpty);
      expect(failed.isFallback, isFalse);
    });

    test('FR-024 — lịch sử từ máy chủ không mang thẻ gợi ý (T038)', () {
      // Máy chủ không gửi `outfitRecommendation`/`suggestedItems`, nên nạp lại lịch
      // sử phải cho thẻ rỗng thay vì âm thầm dựng lên từ trường không tồn tại.
      final restored = ChatMessageModel.fromJson({
        'id': 'm1',
        'content': 'Gợi ý [ACTION:REDIRECT_OUTFIT]',
        'sender': 'ASSISTANT',
        'createdAt': '2026-10-02T10:00:00Z',
      });

      expect(restored.suggestedItems, isEmpty);
      expect(restored.outfitRecommendation, isNull);
      // Marker vẫn phải được lọc khỏi phần hiển thị (FR-027, T039).
      expect(restored.hasOutfitRedirect, isTrue);
      expect(restored.cleanContent, 'Gợi ý');
    });
  });

  group('Spec 015 — nhận diện câu hỏi về trang phục', () {
    test('FR-021 — khớp câu có dấu và không dấu', () {
      expect(isOutfitRelatedQuery('Mặc gì đi làm mát thế này'), isTrue);
      expect(isOutfitRelatedQuery('Áo gì hợp với quần nâu'), isTrue);
      expect(isOutfitRelatedQuery('gợi ý bộ đồ dạo phố nhé'), isTrue);
    });

    test('FR-021 — không khớp câu không liên quan tới thời trang', () {
      expect(isOutfitRelatedQuery('Hôm nay thời tiết thế nào'), isFalse);
      expect(isOutfitRelatedQuery('Cảm ơn bạn nhiều'), isFalse);
    });

    test('FR-021 — so khớp theo ranh giới từ, không khớp chuỗi bị chứa', () {
      expect(isOutfitRelatedQuery('dodat'), isFalse,
          reason: '"do" chỉ khớp khi là từ độc lập');
      expect(isOutfitRelatedQuery('không có gì cả'), isFalse);
    });
  });
}
