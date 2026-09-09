import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/auth/data/auth_repository.dart';
import 'package:smart_wardrobe/features/auth/models/auth_models.dart';
import 'package:smart_wardrobe/features/outfit_studio/data/outfit_repository.dart';
import 'package:smart_wardrobe/features/outfit_studio/models/outfit_models.dart';

class RealHttpOverrides extends HttpOverrides {}

void main() {
  HttpOverrides.global = RealHttpOverrides();

  group('Outfit Studio Integration Tests', () {
    final authRepo = AuthRepository();
    final outfitRepo = OutfitRepository();

    setUpAll(() async {
      await authRepo.login(
        const LoginRequest(loginName: 'user', password: '123456'),
      );
    });

    test('Fetch user wardrobe items succeeds and returns real items', () async {
      final items = await outfitRepo.getUserWardrobeItems();
      expect(items.isNotEmpty, true);
      expect(items.first.fashionItem?.imageUrl.isNotEmpty, true);
    });

    test('AI Outfit Recommendation generates stylish outfit with alternatives', () async {
      final req = const AIOutfitRecommendationReq(
        occasion: 'casual',
        styleTarget: 'minimalist',
        season: 'summer',
        weather: 'warm',
        colorTone: 'light',
        details: 'Dạo phố cuối tuần',
      );

      final res = await outfitRepo.getAIRecommendation(req);
      expect(res.title.isNotEmpty, true);
      expect(res.explanation.isNotEmpty, true);
      expect(res.items.isNotEmpty, true);
    });

    test('Save Outfit, Fetch My Outfits and Detail, then Delete Outfit succeeds', () async {
      final items = await outfitRepo.getUserWardrobeItems();
      expect(items.isNotEmpty, true);

      final saveReq = SaveOutfitReq(
        name: 'Set Test Flow ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Tạo tự động từ integration test',
        items: [
          SaveOutfitItemReq(
            fashionItemId: items.first.fashionItem!.id,
            positionX: 0,
            positionY: -50,
            scale: 1.0,
            layerOrder: 1,
          ),
        ],
      );

      final saveRes = await outfitRepo.saveOutfit(saveReq);
      final newOutfitId = saveRes['id']?.toString() ?? '';
      expect(newOutfitId.isNotEmpty, true);

      // 1. Fetch user outfits list
      final outfits = await outfitRepo.getMyOutfits();
      expect(outfits.isNotEmpty, true);
      final found = outfits.any((o) => o.id == newOutfitId);
      expect(found, true);

      // 2. Fetch outfit detail
      final detail = await outfitRepo.getOutfitDetail(newOutfitId);
      expect(detail.id, newOutfitId);
      expect(detail.items.isNotEmpty, true);

      // 3. Delete outfit
      await outfitRepo.deleteOutfit(newOutfitId);
      final afterDelete = await outfitRepo.getMyOutfits();
      expect(afterDelete.any((o) => o.id == newOutfitId), false);
    });
  });
}
