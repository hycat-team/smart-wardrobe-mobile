import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wardrobe/shared/widgets/scaffold_with_nav_bar.dart';

GoRouter _createTestRouter({int initialIndex = 0}) {
  return GoRouter(
    initialLocation: initialIndex == 0
        ? '/studio'
        : initialIndex == 1
            ? '/stylist'
            : initialIndex == 2
                ? '/wardrobe'
                : initialIndex == 3
                    ? '/my-outfits'
                    : '/profile',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/studio',
                builder: (context, state) => const Scaffold(body: Text('Studio Page')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stylist',
                builder: (context, state) => const Scaffold(body: Text('Stylist Page')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wardrobe',
                builder: (context, state) => const Scaffold(body: Text('Wardrobe Page')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-outfits',
                builder: (context, state) => const Scaffold(body: Text('Outfits Page')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const Scaffold(body: Text('Profile Page')),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('ScaffoldWithNavBar Tests', () {
    testWidgets('renders all 5 tabs and Home is initially selected', (tester) async {
      final router = _createTestRouter(initialIndex: 0);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 5 tab labels exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Stylist'), findsOneWidget);
      expect(find.text('Wardrobe'), findsOneWidget);
      expect(find.text('Outfits'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify body content of branch 0 (Studio / Home)
      expect(find.text('Studio Page'), findsOneWidget);

      // When Home is active (index 0), Home icon is active
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      // Wardrobe is inactive in center, shows checkroom_outlined
      expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
    });

    testWidgets('active center Wardrobe tab displays active icon and body', (tester) async {
      final router = _createTestRouter(initialIndex: 2);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Verify body content of branch 2 (Wardrobe)
      expect(find.text('Wardrobe Page'), findsOneWidget);

      // When Wardrobe is active, checkroom_rounded is shown in center
      expect(find.byIcon(Icons.checkroom_rounded), findsOneWidget);
      // Home is inactive, shows home_outlined
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('tapping tabs navigates to correct branch and updates UI', (tester) async {
      final router = _createTestRouter(initialIndex: 0);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Home (Studio Page)
      expect(find.text('Studio Page'), findsOneWidget);

      // Tap Stylist
      await tester.tap(find.text('Stylist'));
      await tester.pumpAndSettle();
      expect(find.text('Stylist Page'), findsOneWidget);

      // Tap Wardrobe (Center Hero)
      await tester.tap(find.text('Wardrobe'));
      await tester.pumpAndSettle();
      expect(find.text('Wardrobe Page'), findsOneWidget);
      expect(find.byIcon(Icons.checkroom_rounded), findsOneWidget);

      // Tap Outfits
      await tester.tap(find.text('Outfits'));
      await tester.pumpAndSettle();
      expect(find.text('Outfits Page'), findsOneWidget);

      // Tap Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile Page'), findsOneWidget);

      // Tap Home back
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Studio Page'), findsOneWidget);
    });
  });
}
