import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wardrobe/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:smart_wardrobe/features/auth/presentation/login_screen.dart';
import 'package:smart_wardrobe/features/auth/presentation/register_screen.dart';
import 'package:smart_wardrobe/features/auth/presentation/preferences_screen.dart';
import 'package:smart_wardrobe/features/auth/presentation/forgot_password_screen.dart';
import 'package:smart_wardrobe/features/auth/presentation/auth_callback_screen.dart';
import 'package:smart_wardrobe/features/auth/providers/auth_provider.dart';
import 'package:smart_wardrobe/features/onboarding/presentation/onboarding_screen.dart';
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
import 'package:smart_wardrobe/features/profile/presentation/privacy_policy_screen.dart';
import 'package:smart_wardrobe/features/profile/presentation/subscription_detail_screen.dart';
import 'package:smart_wardrobe/features/profile/presentation/subscription_upgrade_screen.dart';
import 'package:smart_wardrobe/features/profile/presentation/payment_waiting_screen.dart';
import 'package:smart_wardrobe/features/profile/models/user_profile_models.dart';
import 'package:smart_wardrobe/core/config/release_flags.dart';
import 'package:smart_wardrobe/features/profile/presentation/widgets/web_guidance_card.dart';
import 'package:smart_wardrobe/features/community/presentation/community_feed_screen.dart';
import 'package:smart_wardrobe/features/community/presentation/post_detail_screen.dart';
import 'package:smart_wardrobe/features/community/presentation/post_composer_screen.dart';
import 'package:smart_wardrobe/features/community/presentation/public_profile_screen.dart';
import 'package:smart_wardrobe/features/community/presentation/community_search_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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

/// Đích mặc định sau khi đăng nhập thành công (khi không có pendingRedirect).
/// Dùng chung cho mọi luồng đăng nhập (mật khẩu, Google mobile/web).
/// Spec 013: Mặc định vào tủ đồ (/wardrobe).
const String kPostLoginRoute = '/wardrobe';

bool _isAuthPath(String location) {
  final path = Uri.tryParse(location)?.path ?? location;
  return path == '/login' ||
      path == '/auth/register' ||
      path == '/auth/forgot-password' ||
      path == '/auth/preferences' ||
      path == '/auth/callback';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(appRouterNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isAuth = authState.isAuthenticated;
      final path = state.uri.path;

      final isAuthPage = path == '/login' ||
          path == '/auth/register' ||
          path == '/auth/forgot-password' ||
          path == '/auth/preferences' ||
          path == '/auth/callback';

      final isPublicCommunityPage = path == '/community' ||
          path == '/community/search' ||
          path.startsWith('/community/posts/') ||
          path.startsWith('/users/');

      // 1. Chưa đăng nhập mà vào bất kỳ trang nào khác trang auth/public community -> giữ lại
      // đích đến (kẻo deep-link kết quả thanh toán bị mất) rồi về /login.
      if (!isAuth && !isAuthPage && !isPublicCommunityPage) {
        final destination = state.uri.toString();
        // KHÔNG ghi provider trực tiếp trong `redirect`: callback này chạy
        // khi widget tree đang build, ghi StateProvider sẽ làm Riverpod throw
        // "Tried to modify a provider while the widget tree was building".
        // Hẹn sang microtask để áp dụng sau khi build xong.
        Future.microtask(() {
          ref.read(pendingRedirectProvider.notifier).state = destination;
        });
        return '/login';
      }

      // 2. Đã đăng nhập mà đang ở trang auth -> quay lại đích đến đã giữ,
      // không có thì vào trang chính /home như cũ.
      if (isAuth && isAuthPage) {
        final pending = ref.read(pendingRedirectProvider);
        if (pending != null) {
          // Xoá pending cũng phải hoãn khỏi lúc build (cùng lý do trên).
          Future.microtask(() {
            ref.read(pendingRedirectProvider.notifier).state = null;
          });
        }
        if (pending != null &&
            pending.isNotEmpty &&
            !_isAuthPath(pending)) {
          return pending;
        }
        return kPostLoginRoute;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/community',
      ),
      GoRoute(
        // Home đã ẩn khỏi thanh điều hướng (spec 012) — deep-link cũ về Community.
        path: '/home',
        redirect: (context, state) => '/community',
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
        // Callback luồng đăng nhập Google web (BE redirect về đây kèm cookie).
        path: '/auth/callback',
        builder: (context, state) => const AuthCallbackScreen(),
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
        path: '/community/posts/:publicId',
        builder: (context, state) {
          final publicId = state.pathParameters['publicId'] ?? '';
          final autoFocusComment = state.uri.queryParameters['focus'] == 'comment';
          return PostDetailScreen(
            publicId: publicId,
            autoFocusComment: autoFocusComment,
          );
        },
      ),
      GoRoute(
        path: '/community/create',
        builder: (context, state) {
          final editId = state.uri.queryParameters['editId'];
          return PostComposerScreen(editPublicId: editId);
        },
      ),
      GoRoute(
        path: '/community/search',
        builder: (context, state) => const CommunitySearchScreen(),
      ),
      GoRoute(
        path: '/users/:username',
        builder: (context, state) {
          final username = state.pathParameters['username'] ?? '';
          return PublicProfileScreen(username: username);
        },
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
        // Chính sách bảo mật: luôn mở được ở mọi bản build (kể cả bản Play
        // ẩn trả phí) để reviewer và người dùng đều xem được.
        path: '/profile/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        // Số dư + lịch sử giao dịch: chỉ đọc, không thu tiền trong app →
        // mở được ở mọi bản build (kể cả bản Play ẩn trả phí).
        path: '/profile/wallet',
        builder: (context, state) => const WalletDetailScreen(),
      ),
      GoRoute(
        // Danh sách gói + quyền lợi: chỉ đọc. Nâng cấp thực hiện trên web.
        path: '/profile/subscription',
        builder: (context, state) => const SubscriptionDetailScreen(),
      ),
      GoRoute(
        // Bảng so sánh gói + hướng dẫn nâng cấp trên web: chỉ đọc.
        path: '/profile/subscription/upgrade',
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
          // Branch 0: Tab "Tủ đồ" -> Tủ đồ số cá nhân
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wardrobe',
                builder: (context, state) => const WardrobeScreen(),
              ),
            ],
          ),
          // Branch 1: Tab "Cộng đồng" -> Bảng tin cộng đồng
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (context, state) => const CommunityFeedScreen(),
              ),
            ],
          ),
          // Branch 2: Tab "Phối đồ AI" (Center Hero) -> Outfit Studio & AI phối đồ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/studio',
                builder: (context, state) => const OutfitStudioScreen(),
              ),
            ],
          ),
          // Branch 3: Tab "Stylist AI" -> AI Stylist Trò chuyện tư vấn
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stylist',
                builder: (context, state) => const StylistScreen(),
              ),
            ],
          ),
          // Branch 4: Tab "Hồ sơ" -> Tài khoản cá nhân, số đo & gói dịch vụ
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
