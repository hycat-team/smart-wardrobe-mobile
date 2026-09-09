import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/wardrobe/models/wardrobe_models.dart';
import 'package:smart_wardrobe/features/profile/models/body_profile_models.dart';

void main() {
  group('Phase 1 - Wardrobe Models Tests', () {
    test('WardrobeItemModel parses JSON correctly with fashion attributes', () {
      final json = {
        'id': 'item-123',
        'status': 0,
        'price': 450000.0,
        'isLocked': false,
        'fashionItem': {
          'id': 'fashion-123',
          'imageUrl': 'https://res.cloudinary.com/test.jpg',
          'color': 'Đen',
          'colorHex': '#111111',
          'style': 'Minimalist',
          'material': 'Cotton 100%',
          'pattern': 'Trơn',
          'fit': 'Regular',
          'seasonality': 'Bốn mùa',
          'category': {
            'id': 'cat-1',
            'name': 'Áo thun',
            'slug': 'ao-thun',
          },
        },
      };

      final item = WardrobeItemModel.fromJson(json);

      expect(item.id, 'item-123');
      expect(item.price, 450000.0);
      expect(item.formattedPrice, contains('450.000'));
      expect(item.statusLabel, 'Trong tủ đồ');
      expect(item.displayTitle, 'Đen Minimalist Áo thun');
      expect(item.fashionItem?.colorHex, '#111111');
      expect(item.fashionItem?.material, 'Cotton 100%');
    });

    test('WardrobeInsightsModel calculates and formats values accurately', () {
      final json = {
        'data': {
          'totalItems': 24,
          'totalWardrobeValueVnd': 15800000.0,
          'underutilizedItemsCount': 3,
          'underutilizedItems': [
            {
              'itemId': 'u-1',
              'name': 'Áo blazer dạ',
              'categoryName': 'Áo khoác',
              'purchasePriceVnd': 1200000.0,
              'lastWornDaysAgo': 45,
              'imageUrl': 'https://example.com/blazer.jpg',
            }
          ],
        }
      };

      final insights = WardrobeInsightsModel.fromJson(json);

      expect(insights.totalItems, 24);
      expect(insights.totalWardrobeValueVnd, 15800000.0);
      expect(insights.underutilizedItemsCount, 3);
      expect(insights.underutilizedItems.length, 1);
      expect(insights.underutilizedItems.first.name, 'Áo blazer dạ');
      expect(insights.underutilizedItems.first.lastWornDaysAgo, 45);
    });

    test('CategoryDistributionModel parses percentages properly', () {
      final json = {
        'categoryId': 'cat-tops',
        'categoryName': 'Áo',
        'itemCount': 10,
        'percentage': 41.6,
      };

      final model = CategoryDistributionModel.fromJson(json);
      expect(model.categoryName, 'Áo');
      expect(model.itemCount, 10);
      expect(model.percentage, 41.6);
    });
  });

  group('Phase 1 - Body Profile Models Tests', () {
    test('BodyProfileModel computes BMI and categories correctly', () {
      // Height 170cm, Weight 60kg -> BMI = 60 / (1.7 * 1.7) = 20.76 -> Cân đối
      const profile = BodyProfileModel(
        heightCm: 170.0,
        weightKg: 60.0,
        bodyShape: 'hourglass',
        chestCm: 88.0,
        waistCm: 64.0,
        hipCm: 92.0,
      );

      expect(profile.bmi, closeTo(20.76, 0.1));
      expect(profile.bmiCategory, contains('Cân đối'));
      expect(profile.bodyShapeTitle, 'Đồng hồ cát');
      expect(profile.bodyShapeStylingAdvice, isNotEmpty);
    });

    test('BodyProfileModel serializes to JSON matching backend API expectations', () {
      const profile = BodyProfileModel(
        heightCm: 165.0,
        weightKg: 52.0,
        bodyShape: 'pear',
        chestCm: 84.0,
        waistCm: 62.0,
        hipCm: 94.0,
        verifiedByUser: true,
      );

      final json = profile.toJson();
      expect(json['heightCm'], 165.0);
      expect(json['weightKg'], 52.0);
      expect(json['bodyShape'], 'pear');
      expect(json['measurements']['chestCm'], 84.0);
      expect(json['measurements']['waistCm'], 62.0);
      expect(json['measurements']['hipCm'], 94.0);
      expect(json['verifiedByUser'], true);
    });
  });
}
