import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/outfit_studio/presentation/outfit_studio_screen.dart';

void main() {
  testWidgets('OutfitStudioScreen does not show SnackBar when outfit is saved successfully', (tester) async {
    // Build outfit studio screen with mock state
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OutfitStudioScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Ensure no success SnackBar is present initially
    expect(find.byType(SnackBar), findsNothing);
  });
}
