import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wardrobe/shared/widgets/scaffold_with_nav_bar.dart';

GoRouter _createTestRouter({int initialIndex = 0}) {
  return GoRouter(
    initialLocation: initialIndex == 0
        ? '/home'
        : initialIndex == 1
            ? '/wardrobe'
            : initialIndex == 2
                ? '/studio'
                : initialIndex == 3
                    ? '/stylist'
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
                path: '/home',
                builder: (context, state) => const Scaffold(body: Text('Home Page')),
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
                path: '/studio',
                builder: (context, state) => const Scaffold(body: Text('AI Outfit Page')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stylist',
                builder: (context, state) => const Scaffold(body: Text('AI Chat Page')),
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
    testWidgets('renders all 5 tabs matching Image 2 and Home is initially selected', (tester) async {
      final router = _createTestRouter(initialIndex: 0);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 5 tab labels exist according to Image 2
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Wardrobe'), findsOneWidget);
      expect(find.text('AI Outfit'), findsOneWidget);
      expect(find.text('AI Chat'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify body content of branch 0 (Home Page)
      expect(find.text('Home Page'), findsOneWidget);

      // When Home is active (index 0), Home icon is active
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      // Center hero AI Outfit has sparkle star icon
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      // Wardrobe is inactive, shows checkroom_outlined
      expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
      // AI Chat is inactive, shows chat_bubble_outline_rounded
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    });

    testWidgets('active center AI Outfit tab displays active state and body', (tester) async {
      final router = _createTestRouter(initialIndex: 2);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Verify body content of branch 2 (AI Outfit Page)
      expect(find.text('AI Outfit Page'), findsOneWidget);

      // Center hero button shows auto_awesome_rounded
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
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

      // Initially on Home Page
      expect(find.text('Home Page'), findsOneWidget);

      // Tap Wardrobe (Tab 1)
      await tester.tap(find.text('Wardrobe'));
      await tester.pumpAndSettle();
      expect(find.text('Wardrobe Page'), findsOneWidget);
      expect(find.byIcon(Icons.checkroom_rounded), findsOneWidget);

      // Tap AI Outfit (Center Hero Tab 2)
      await tester.tap(find.text('AI Outfit'));
      await tester.pumpAndSettle();
      expect(find.text('AI Outfit Page'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

      // Tap AI Chat (Tab 3)
      await tester.tap(find.text('AI Chat'));
      await tester.pumpAndSettle();
      expect(find.text('AI Chat Page'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);

      // Tap Profile (Tab 4)
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile Page'), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      // Tap Home back (Tab 0)
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Home Page'), findsOneWidget);
    });
  });
}
