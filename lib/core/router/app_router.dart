import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wardrobe/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:smart_wardrobe/features/auth/presentation/login_screen.dart';
import 'package:smart_wardrobe/features/auth/presentation/register_screen.dart';
import 'package:smart_wardrobe/features/auth/presentation/preferences_screen.dart';
import 'package:smart_wardrobe/features/auth/presentation/forgot_password_screen.dart';
import 'package:smart_wardrobe/features/auth/providers/auth_provider.dart';
import 'package:smart_wardrobe/features/onboarding/presentation/onboarding_screen.dart';
import 'package:smart_wardrobe/features/wardrobe/presentation/wardrobe_screen.dart';
import 'package:smart_wardrobe/features/wardrobe/presentation/item_detail_screen.dart';
import 'package:smart_wardrobe/features/wardrobe/presentation/wardrobe_insights_screen.dart';
import 'package:smart_wardrobe/features/wardrobe/models/wardrobe_models.dart';
import 'package:smart_wardrobe/features/outfit_studio/presentation/outfit_studio_screen.dart';
import 'package:smart_wardrobe/features/outfit_studio/presentation/outfits_list_screen.dart';
import 'package:smart_wardrobe/features/stylist/presentation/stylist_screen.dart';
import 'package:smart_wardrobe/features/profile/presentation/profile_screen.dart';
import 'package:smart_wardrobe/features/profile/presentation/wallet_detail_screen.dart';
import 'package:smart_wardrobe/features/profile/presentation/body_profile_screen.dart';
import 'package:smart_wardrobe/features/profile/presentation/profile_edit_screen.dart';
import 'package:smart_wardrobe/features/profile/presentation/change_password_screen.dart';
import 'package:smart_wardrobe/features/profile/presentation/subscription_detail_screen.dart';
import 'package:smart_wardrobe/features/profile/presentation/subscription_upgrade_screen.dart';
import 'package:smart_wardrobe/features/profile/presentation/payment_waiting_screen.dart';
import 'package:smart_wardrobe/features/profile/models/user_profile_models.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouterNotifier extends ChangeNotifier {
  final Ref _ref;

  AppRouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authStateProvider,
      (previous, next) {
        if (previous?.isAuthenticated != next.isAuthenticated) {
          notifyListeners();
        }
      },
    );
  }
}

final appRouterNotifierProvider = Provider<AppRouterNotifier>((ref) {
  return AppRouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(appRouterNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isAuth = authState.isAuthenticated;
      final path = state.uri.path;

      final isAuthPage = path == '/login' ||
          path == '/auth/register' ||
          path == '/auth/forgot-password' ||
          path == '/auth/preferences';

      // 1. Chưa đăng nhập mà vào bất kỳ trang nào khác trang auth -> Buộc chuyển hướng về /login
      if (!isAuth && !isAuthPage) {
        return '/login';
      }

      // 2. Đã đăng nhập mà đang ở trang auth -> Chuyển hướng vào trang chính /wardrobe
      if (isAuth && isAuthPage) {
        return '/wardrobe';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/wardrobe',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/preferences',
        builder: (context, state) => const PreferencesScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/outfits',
        builder: (context, state) => const OutfitsListScreen(),
      ),
      GoRoute(
        path: '/wardrobe/item/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final item = state.extra as WardrobeItemModel?;
          return ItemDetailScreen(itemId: id, initialItem: item);
        },
      ),
      GoRoute(
        path: '/wardrobe/insights',
        builder: (context, state) => const WardrobeInsightsScreen(),
      ),
      GoRoute(
        path: '/profile/body',
        builder: (context, state) => const BodyProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/profile/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/profile/wallet',
        builder: (context, state) => const WalletDetailScreen(),
      ),
      GoRoute(
        path: '/profile/subscription',
        builder: (context, state) => const SubscriptionDetailScreen(),
      ),
      GoRoute(
        path: '/profile/subscription/upgrade',
        builder: (context, state) => const SubscriptionUpgradeScreen(),
      ),
      GoRoute(
        path: '/profile/subscription/waiting',
        builder: (context, state) {
          final link = state.extra as PaymentLinkModel?;
          if (link == null) {
            return const SubscriptionUpgradeScreen();
          }
          return PaymentWaitingScreen(paymentLink: link);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wardrobe',
                builder: (context, state) => const WardrobeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/studio',
                builder: (context, state) => const OutfitStudioScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stylist',
                builder: (context, state) => const StylistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-outfits',
                builder: (context, state) => const OutfitsListScreen(showBackButton: false),
              ),
            ],
          ),
          // StatefulShellBranch(
          //   routes: [
          //     GoRoute(
          //       path: '/curates',
          //       builder: (context, state) => const MarketplaceScreen(),
          //     ),
          //   ],
          // ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
