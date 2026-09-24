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
import 'package:smart_wardrobe/features/home/presentation/home_screen.dart';
import 'package:smart_wardrobe/features/wardrobe/presentation/wardrobe_screen.dart';
import 'package:smart_wardrobe/features/wardrobe/presentation/item_detail_screen.dart';
import 'package:smart_wardrobe/features/wardrobe/presentation/system_catalog_screen.dart';
import 'package:smart_wardrobe/features/wardrobe/presentation/wardrobe_insights_screen.dart';
import 'package:smart_wardrobe/features/wardrobe/presentation/wardrobe_statistics_screen.dart';
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
import 'package:smart_wardrobe/features/profile/presentation/payment_result_screen.dart';
import 'package:smart_wardrobe/features/profile/models/user_profile_models.dart';
import 'package:smart_wardrobe/core/config/release_flags.dart';
import 'package:smart_wardrobe/features/profile/presentation/widgets/web_guidance_card.dart';

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

/// Đích đến mà user định tới khi bị redirect về /login (deep-link thanh toán,
/// web returnUrl, cold-start...). Đăng nhập xong sẽ quay lại đây thay vì
/// rơi về home làm mất thông báo kết quả.
final pendingRedirectProvider = StateProvider<String?>((ref) => null);

bool _isAuthPath(String location) {
  final path = Uri.tryParse(location)?.path ?? location;
  return path == '/login' ||
      path == '/auth/register' ||
      path == '/auth/forgot-password' ||
      path == '/auth/preferences';
}

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

      // 1. Chưa đăng nhập mà vào bất kỳ trang nào khác trang auth -> giữ lại
      // đích đến (kẻo deep-link kết quả thanh toán bị mất) rồi về /login.
      if (!isAuth && !isAuthPage) {
        ref.read(pendingRedirectProvider.notifier).state =
            state.uri.toString();
        return '/login';
      }

      // 2. Đã đăng nhập mà đang ở trang auth -> quay lại đích đến đã giữ,
      // không có thì vào trang chính /wardrobe như cũ.
      if (isAuth && isAuthPage) {
        final pending = ref.read(pendingRedirectProvider.notifier).state;
        ref.read(pendingRedirectProvider.notifier).state = null;
        if (pending != null &&
            pending.isNotEmpty &&
            !_isAuthPath(pending)) {
          return pending;
        }
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
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
        builder: (context, state) => const OutfitsListScreen(showBackButton: true),
      ),
      GoRoute(
        path: '/my-outfits',
        redirect: (context, state) => '/outfits',
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
        path: '/wardrobe/catalog',
        builder: (context, state) => const SystemCatalogScreen(),
      ),
      GoRoute(
        path: '/wardrobe/insights',
        builder: (context, state) => const WardrobeInsightsScreen(),
      ),
      GoRoute(
        path: '/wardrobe/statistics',
        builder: (context, state) => const WardrobeStatisticsScreen(),
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
        // Chặn ở bản phát hành Play khi trả phí bị ẩn (spec 008, FR-021).
        redirect: (context, state) =>
            ReleaseFlags.enablePaidFeatures ? null : '/profile',
        builder: (context, state) => const WalletDetailScreen(),
      ),
      GoRoute(
        path: '/profile/subscription',
        redirect: (context, state) =>
            ReleaseFlags.enablePaidFeatures ? null : '/profile',
        builder: (context, state) => const SubscriptionDetailScreen(),
      ),
      GoRoute(
        path: '/profile/subscription/upgrade',
        redirect: (context, state) =>
            ReleaseFlags.enablePaidFeatures ? null : '/profile',
        builder: (context, state) => const SubscriptionUpgradeScreen(),
      ),
      GoRoute(
        // Luồng thanh toán đã chuyển lên website (009-web-payment-redirect):
        // mọi đường vào màn hình chờ/kết quả cũ đều hiển thị thông báo
        // hết hiệu lực + hướng dẫn lên website, không mở checkout.
        path: '/profile/subscription/waiting',
        redirect: (context, state) =>
            ReleaseFlags.enablePaidFeatures ? null : '/profile',
        builder: (context, state) {
          final pending = state.extra as PendingPayment?;
          if (pending == null) {
            return const SubscriptionUpgradeScreen();
          }
          return PaymentWaitingScreen(pending: pending);
        },
      ),
      GoRoute(
        path: '/profile/payment/result',
        builder: (context, state) => const ExpiredPaymentScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Tab "Home" -> Trang chủ tổng quan & gợi ý
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1: Tab "Wardrobe" -> Tủ đồ số cá nhân
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wardrobe',
                builder: (context, state) => const WardrobeScreen(),
              ),
            ],
          ),
          // Branch 2: Tab "AI Outfit" (Center Hero) -> Outfit Studio & AI phối đồ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/studio',
                builder: (context, state) => const OutfitStudioScreen(),
              ),
            ],
          ),
          // Branch 3: Tab "AI Chat" -> AI Stylist Trò chuyện tư vấn
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stylist',
                builder: (context, state) => const StylistScreen(),
              ),
            ],
          ),
          // Branch 4: Tab "Profile" -> Tài khoản cá nhân, số đo & gói dịch vụ
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

/// Màn hình hiển thị khi người dùng truy cập các đường thanh toán cũ
/// (màn hình chờ / kết quả PayOS) còn sót từ phiên bản trước.
///
/// Không mở checkout — chỉ thông báo hết hiệu lực + hướng dẫn lên
/// website (FR-009).
class ExpiredPaymentScreen extends StatelessWidget {
  const ExpiredPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Thông báo thanh toán'),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: WebGuidanceCard.expired(),
      ),
    );
  }
}
