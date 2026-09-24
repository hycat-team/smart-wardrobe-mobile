import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/profile_repository.dart';
import '../models/body_profile_models.dart';
import '../models/user_profile_models.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

// ==========================================
// 1. User Profile State & Notifier
// ==========================================

class UserProfileState {
  final bool isLoading;
  final bool isUpdating;
  final UserModel? user;
  final String? errorMessage;
  final String? successMessage;

  const UserProfileState({
    this.isLoading = false,
    this.isUpdating = false,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  UserProfileState copyWith({
    bool? isLoading,
    bool? isUpdating,
    UserModel? user,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return UserProfileState(
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final ProfileRepository _repository;
  final Ref _ref;

  UserProfileNotifier(this._repository, this._ref) : super(const UserProfileState()) {
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.getUserProfile();
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> updateProfile(UpdateProfileRequest request) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);
    try {
      final updatedUser = await _repository.updateProfile(request);
      state = state.copyWith(
        isUpdating: false,
        user: updatedUser,
        successMessage: 'Cập nhật thông tin cá nhân thành công.',
      );
      _ref.read(authStateProvider.notifier).checkAuthStatus();
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> changePassword(ChangePasswordRequest request) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);
    try {
      await _repository.changePassword(request);
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Đổi mật khẩu thành công.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> uploadAvatar(XFile file) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);
    try {
      final signature = await _repository.getAvatarSignature();
      final uploadResult = await _repository.uploadAvatarFile(file, signature);
      await _repository.updateAvatar(uploadResult['avatarUrl']!, uploadResult['publicId']!);

      await loadUserProfile();
      _ref.read(authStateProvider.notifier).checkAuthStatus();

      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Cập nhật ảnh đại diện thành công.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return UserProfileNotifier(repo, ref);
});

// ==========================================
// 2. Subscription & Daily Quota Providers
// ==========================================

class SubscriptionOverviewState {
  final bool isLoading;
  final UserSubscriptionModel subscription;
  final DailyQuotaModel dailyQuota;
  // true sau lần tải hạn mức thành công đầu tiên — dùng để phân biệt
  // "chưa có số liệu" (hiện skeleton/lỗi) với số 0 thật (US4, FR-014).
  final bool quotaLoaded;
  final String? errorMessage;

  const SubscriptionOverviewState({
    this.isLoading = false,
    this.subscription = const UserSubscriptionModel(),
    this.dailyQuota = const DailyQuotaModel(),
    this.quotaLoaded = false,
    this.errorMessage,
  });

  SubscriptionOverviewState copyWith({
    bool? isLoading,
    UserSubscriptionModel? subscription,
    DailyQuotaModel? dailyQuota,
    bool? quotaLoaded,
    String? errorMessage,
  }) {
    return SubscriptionOverviewState(
      isLoading: isLoading ?? this.isLoading,
      subscription: subscription ?? this.subscription,
      dailyQuota: dailyQuota ?? this.dailyQuota,
      quotaLoaded: quotaLoaded ?? this.quotaLoaded,
      errorMessage: errorMessage,
    );
  }
}

class SubscriptionOverviewNotifier extends StateNotifier<SubscriptionOverviewState> {
  final ProfileRepository _repository;

  SubscriptionOverviewNotifier(this._repository) : super(const SubscriptionOverviewState()) {
    loadOverview();
  }

  Future<void> loadOverview() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final subFuture = _repository.getMySubscription();
      final quotaFuture = _repository.getDailyQuota();
      final results = await Future.wait([subFuture, quotaFuture]);

      state = state.copyWith(
        isLoading: false,
        subscription: results[0] as UserSubscriptionModel,
        dailyQuota: results[1] as DailyQuotaModel,
        quotaLoaded: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> checkSubscriptionStatus() async {
    try {
      final sub = await _repository.getMySubscription();
      final quota = await _repository.getDailyQuota();
      state = state.copyWith(
        subscription: sub,
        dailyQuota: quota,
        quotaLoaded: true,
      );
      return sub.isPremium;
    } catch (_) {
      return false;
    }
  }
}


final subscriptionOverviewProvider =
    StateNotifierProvider<SubscriptionOverviewNotifier, SubscriptionOverviewState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return SubscriptionOverviewNotifier(repo);
});

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlanModel>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getSubscriptionPlans();
});

// ==========================================
// 3. Body Profile
// ==========================================

class BodyProfileState {
  final bool isLoading;
  final bool isSaving;
  final BodyProfileModel profile;
  final String? errorMessage;
  final String? successMessage;

  const BodyProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.profile = const BodyProfileModel(),
    this.errorMessage,
    this.successMessage,
  });

  BodyProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    BodyProfileModel? profile,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return BodyProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class BodyProfileNotifier extends StateNotifier<BodyProfileState> {
  final ProfileRepository _repository;

  BodyProfileNotifier(this._repository) : super(const BodyProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _repository.getBodyProfile();
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> updateProfile(BodyProfileModel updatedProfile) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final saved = await _repository.updateBodyProfile(updatedProfile);
      state = state.copyWith(
        isSaving: false,
        profile: saved,
        successMessage: 'Đã lưu hồ sơ số đo & dáng người thành công.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final bodyProfileProvider =
    StateNotifierProvider<BodyProfileNotifier, BodyProfileState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return BodyProfileNotifier(repo);
});


// ==========================================
// Wallet State & Provider
// ==========================================

class WalletState {
  final WalletModel wallet;
  final bool isLoading;
  final String? errorMessage;

  const WalletState({
    this.wallet = const WalletModel(),
    this.isLoading = false,
    this.errorMessage,
  });

  WalletState copyWith({
    WalletModel? wallet,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WalletState(
      wallet: wallet ?? this.wallet,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final ProfileRepository _repository;

  WalletNotifier(this._repository) : super(const WalletState()) {
    loadWallet();
  }

  Future<void> loadWallet() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final wallet = await _repository.getWallet();
      state = state.copyWith(wallet: wallet, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return WalletNotifier(repo);
});

final walletStatementsProvider = FutureProvider.autoDispose<List<WalletStatementModel>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.getWalletStatements();
});
