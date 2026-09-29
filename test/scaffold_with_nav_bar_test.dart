import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wardrobe/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:smart_wardrobe/core/router/app_router.dart';

GoRouter _createTestRouter({int initialIndex = 0}) {
  const locations = <String>[
    '/wardrobe',
    '/community',
    '/studio',
    '/stylist',
    '/profile',
  ];
  return GoRouter(
    initialLocation: locations[initialIndex],
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wardrobe',
                builder: (context, state) =>
                    const Scaffold(body: Text('Wardrobe Page')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (context, state) =>
                    const Scaffold(body: Text('Community Page')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/studio',
                builder: (context, state) =>
                    const Scaffold(body: Text('AI Outfit Page')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stylist',
                builder: (context, state) =>
                    const Scaffold(body: Text('Stylist Page')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) =>
                    const Scaffold(body: Text('Profile Page')),
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
    testWidgets('renders 5 tabs with Wardrobe initially selected (spec 012)',
        (tester) async {
      final router = _createTestRouter(initialIndex: 0);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // 5 nhãn tab theo spec 012: Tủ đồ, Cộng đồng, Phối đồ AI, Stylist AI, Hồ sơ.
      expect(find.text('Tủ đồ'), findsOneWidget);
      expect(find.text('Cộng đồng'), findsOneWidget);
      expect(find.text('Phối đồ AI'), findsOneWidget);
      expect(find.text('Stylist AI'), findsOneWidget);
      expect(find.text('Hồ sơ'), findsOneWidget);
      // Home đã ẩn hoàn toàn.
      expect(find.text('Home'), findsNothing);
      expect(find.text('Wardrobe'), findsNothing);

      // Body của branch 0.
      expect(find.text('Wardrobe Page'), findsOneWidget);

      // Wardrobe active -> icon đặc; Community inactive -> icon outline.
      expect(find.byIcon(Icons.checkroom_rounded), findsOneWidget);
      expect(find.byIcon(Icons.public_outlined), findsOneWidget);
      // Center hero AI Outfit có icon ngôi sao.
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });

    testWidgets('active center AI Outfit tab displays active state and body',
        (tester) async {
      final router = _createTestRouter(initialIndex: 2);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('AI Outfit Page'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      // Wardrobe inactive -> outline.
      expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
    });

    testWidgets('tapping tabs navigates to correct branch and updates UI',
        (tester) async {
      final router = _createTestRouter(initialIndex: 0);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Wardrobe Page'), findsOneWidget);

      // Community (Tab 1)
      await tester.tap(find.text('Cộng đồng'));
      await tester.pumpAndSettle();
      expect(find.text('Community Page'), findsOneWidget);
      expect(find.byIcon(Icons.public), findsOneWidget);

      // AI Outfit (Center Hero Tab 2)
      await tester.tap(find.text('Phối đồ AI'));
      await tester.pumpAndSettle();
      expect(find.text('AI Outfit Page'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

      // Stylist AI (Tab 3)
      await tester.tap(find.text('Stylist AI'));
      await tester.pumpAndSettle();
      expect(find.text('Stylist Page'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);

      // Hồ sơ (Tab 4)
      await tester.tap(find.text('Hồ sơ'));
      await tester.pumpAndSettle();
      expect(find.text('Profile Page'), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      // Quay lại Tủ đồ (Tab 0)
      await tester.tap(find.text('Tủ đồ'));
      await tester.pumpAndSettle();
      expect(find.text('Wardrobe Page'), findsOneWidget);
    });

    test('kPostLoginRoute defaults to /wardrobe (spec 013)', () {
      expect(kPostLoginRoute, equals('/wardrobe'));
    });
  });
}
