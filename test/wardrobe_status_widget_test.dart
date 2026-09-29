import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/wardrobe/models/wardrobe_models.dart';
import 'package:smart_wardrobe/features/wardrobe/presentation/item_detail_screen.dart';
import 'package:smart_wardrobe/features/wardrobe/providers/wardrobe_provider.dart';
import 'package:smart_wardrobe/features/wardrobe/utils/analysis_status.dart';

void main() {
  testWidgets('ItemDetailScreen renders needsReview UI with category selector and retry button', (tester) async {
    final item = const WardrobeItemModel(
      id: 'item-review',
      status: 5, // needs_review
      fashionItem: FashionItemModel(
        id: 'f-review',
        imageUrl: 'https://example.com/test.jpg',
        reviewReason: AnalysisReasonCodes.uncertainCategory,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wardrobeItemDetailProvider('item-review').overrideWith((ref) => Future.value(item)),
          categoriesProvider.overrideWith((ref) => Future.value([
                const CategoryModel(id: 'cat-1', name: 'Áo sơ mi', slug: 'ao-so-mi'),
                const CategoryModel(id: 'cat-2', name: 'Quần âu', slug: 'quan-au'),
              ])),
        ],
        child: MaterialApp(
          home: ItemDetailScreen(
            itemId: 'item-review',
            initialItem: item,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify badge and description
    expect(find.text('Cần chọn danh mục'), findsAtLeastNWidgets(1));
    expect(find.text('Chọn danh mục trang phục:'), findsOneWidget);
    expect(find.text('Gửi phân tích lại'), findsOneWidget);

    // Studio button should be disabled
    final studioButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Phối đồ Studio'),
    );
    expect(studioButton.onPressed, isNull);
  });

  testWidgets('ItemDetailScreen blocks retry button on invalid image (multiple_items_detected)', (tester) async {
    final item = const WardrobeItemModel(
      id: 'item-invalid',
      status: 4, // failed
      fashionItem: FashionItemModel(
        id: 'f-invalid',
        imageUrl: 'https://example.com/test.jpg',
        processingErrorReason: AnalysisReasonCodes.multipleItemsDetected,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wardrobeItemDetailProvider('item-invalid').overrideWith((ref) => Future.value(item)),
        ],
        child: MaterialApp(
          home: ItemDetailScreen(
            itemId: 'item-invalid',
            initialItem: item,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify badge
    expect(find.text('Ảnh có nhiều món'), findsAtLeastNWidgets(1));
    // Verify suggestions
    expect(find.text('Vui lòng chụp cận cảnh một món đồ duy nhất.'), findsOneWidget);

    // CRITICAL: Retry button MUST NOT exist for invalid images!
    expect(find.text('Thử lại phân tích'), findsNothing);
    expect(find.text('Gửi phân tích lại'), findsNothing);

    // Studio button should be disabled
    final studioButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Phối đồ Studio'),
    );
    expect(studioButton.onPressed, isNull);
  });

  testWidgets('ItemDetailScreen enables retry button on temporary error', (tester) async {
    final item = const WardrobeItemModel(
      id: 'item-temp',
      status: 4, // failed
      fashionItem: FashionItemModel(
        id: 'f-temp',
        imageUrl: 'https://example.com/test.jpg',
        processingErrorReason: AnalysisReasonCodes.analysisTemporaryError,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wardrobeItemDetailProvider('item-temp').overrideWith((ref) => Future.value(item)),
        ],
        child: MaterialApp(
          home: ItemDetailScreen(
            itemId: 'item-temp',
            initialItem: item,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify badge and retry button
    expect(find.text('Lỗi tạm thời'), findsAtLeastNWidgets(1));
    expect(find.text('Thử lại phân tích'), findsOneWidget);

    // Studio button should be disabled
    final studioButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Phối đồ Studio'),
    );
    expect(studioButton.onPressed, isNull);
  });
}
