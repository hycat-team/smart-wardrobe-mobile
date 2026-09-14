import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/home/presentation/home_screen.dart';
import 'package:smart_wardrobe/features/profile/providers/profile_provider.dart';
import 'package:smart_wardrobe/features/auth/models/auth_models.dart';
import 'package:smart_wardrobe/features/wardrobe/models/wardrobe_models.dart';
import 'package:smart_wardrobe/features/wardrobe/providers/wardrobe_provider.dart';
import 'package:smart_wardrobe/features/outfit_studio/providers/outfits_list_provider.dart';

class FakeWardrobeNotifier extends StateNotifier<WardrobeState> implements WardrobeNotifier {
  FakeWardrobeNotifier() : super(const WardrobeState(total: 48, items: []));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeOutfitsListNotifier extends StateNotifier<OutfitsListState> implements OutfitsListNotifier {
  FakeOutfitsListNotifier() : super(const OutfitsListState(outfits: []));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserProfileNotifier extends StateNotifier<UserProfileState> implements UserProfileNotifier {
  FakeUserProfileNotifier()
      : super(
          const UserProfileState(
            user: UserModel(
              id: 'user-1',
              username: 'maianh',
              email: 'maianh@example.com',
              firstName: 'Mai Anh',
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('HomeScreen renders header, AI stylist card, stats, and categories', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier()),
          wardrobeProvider.overrideWith((ref) => FakeWardrobeNotifier()),
          outfitsListProvider.overrideWith((ref) => FakeOutfitsListNotifier()),
          categoryDistributionProvider.overrideWith(
            (ref) async => const WardrobeCategoryDistributionResult(
              totalItems: 48,
              categories: [
                CategoryDistributionModel(categoryId: '1', categoryName: 'Áo khoác', itemCount: 8, percentage: 16.7),
                CategoryDistributionModel(categoryId: '2', categoryName: 'Đầm & Váy', itemCount: 12, percentage: 25.0),
                CategoryDistributionModel(categoryId: '3', categoryName: 'Phụ kiện', itemCount: 15, percentage: 31.25),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Header
    expect(find.text('BỘ SƯU TẬP HÔM NAY'), findsOneWidget);
    expect(find.textContaining('Xin chào, Mai Anh'), findsOneWidget);

    // Verify AI Stylist Hero Card
    expect(find.text('AI Stylist gợi ý'), findsOneWidget);
    expect(find.text('Phong cách Parisian Minimalist'), findsOneWidget);
    expect(find.text('Khám phá ngay'), findsOneWidget);

    // Verify Quick Stats
    expect(find.text('Tủ đồ hiện có'), findsOneWidget);
    expect(find.text('Outfits đã lưu'), findsOneWidget);

    // Verify Categories Section
    expect(find.text('TỦ ĐỒ CỦA BẠN'), findsOneWidget);
    expect(find.text('Xem tất cả'), findsOneWidget);
    expect(find.text('Áo khoác'), findsOneWidget);
    expect(find.text('Đầm & Váy'), findsOneWidget);
    expect(find.text('Phụ kiện'), findsOneWidget);
  });
}
