import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/style_vocabulary.dart';
import '../data/style_profile_repository.dart';
import '../models/style_profile_models.dart';

class StyleProfileState {
  final bool loading;
  final bool saving;
  final bool deleting;
  final String? error;
  final StyleProfileModel? profile;
  final List<String> styles;
  final List<String> excludedStyles;
  final bool enabled;
  final StyleSuggestionModel? suggestions;
  final bool loadingSuggestions;

  const StyleProfileState({
    this.loading = true,
    this.saving = false,
    this.deleting = false,
    this.error,
    this.profile,
    this.styles = const [],
    this.excludedStyles = const [],
    this.enabled = true,
    this.suggestions,
    this.loadingSuggestions = false,
  });

  int get maxStyles => profile?.maxStyles ?? 4;
  bool get locked => profile != null && !profile!.personalizationAvailable;
  bool get hasExistingProfile => styles.isNotEmpty || excludedStyles.isNotEmpty;

  bool get dirty =>
      profile != null &&
      (enabled != profile!.enabled ||
          _sameOrder(styles, profile!.styles) == false ||
          _sameOrder(excludedStyles, profile!.excludedStyles) == false);

  static bool _sameOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  StyleProfileState copyWith({
    bool? loading,
    bool? saving,
    bool? deleting,
    String? error,
    StyleProfileModel? profile,
    List<String>? styles,
    List<String>? excludedStyles,
    bool? enabled,
    StyleSuggestionModel? suggestions,
    bool? loadingSuggestions,
  }) {
    return StyleProfileState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      deleting: deleting ?? this.deleting,
      error: error,
      profile: profile ?? this.profile,
      styles: styles ?? this.styles,
      excludedStyles: excludedStyles ?? this.excludedStyles,
      enabled: enabled ?? this.enabled,
      suggestions: suggestions ?? this.suggestions,
      loadingSuggestions: loadingSuggestions ?? this.loadingSuggestions,
    );
  }
}

class StyleProfileController extends StateNotifier<StyleProfileState> {
  final StyleProfileRepository _repository;

  StyleProfileController({StyleProfileRepository? repository})
      : _repository = repository ?? StyleProfileRepository(),
        super(const StyleProfileState());

  static String _norm(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ');

  static bool _same(String a, String b) => a.trim().toLowerCase() == b.trim().toLowerCase();

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final profile = await _repository.getProfile();
      state = state.copyWith(
        loading: false,
        profile: profile,
        styles: List<String>.from(profile.styles),
        excludedStyles: List<String>.from(profile.excludedStyles),
        enabled: profile.enabled,
      );
      if (profile.personalizationAvailable) {
        _loadSuggestions();
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> _loadSuggestions() async {
    state = state.copyWith(loadingSuggestions: true);
    try {
      final suggestions = await _repository.getSuggestions();
      state = state.copyWith(suggestions: suggestions, loadingSuggestions: false);
    } catch (_) {
      state = state.copyWith(loadingSuggestions: false);
    }
  }

  /// Returns an error message when the toggle is rejected, null on success.
  String? toggle({required bool liked, required String value}) {
    if (state.locked) return null;
    final current = liked ? state.styles : state.excludedStyles;
    final has = current.any((item) => _same(item, value));
    if (has) {
      final next = current.where((item) => !_same(item, value)).toList();
      state = state.copyWith(styles: liked ? next : null, excludedStyles: liked ? null : next);
      return null;
    }
    if (current.length >= state.maxStyles) {
      return 'Tối đa ${state.maxStyles} phong cách';
    }
    final next = [...current, value];
    state = state.copyWith(styles: liked ? next : null, excludedStyles: liked ? null : next);
    return null;
  }

  String? addCustom({required bool liked, required String value}) {
    if (state.locked) return null;
    final clean = _norm(value);
    if (clean.isEmpty) return null;
    if (clean.length > maxStyleLength) {
      return 'Mỗi phong cách tối đa $maxStyleLength ký tự';
    }
    if (state.styles.any((item) => _same(item, clean)) ||
        state.excludedStyles.any((item) => _same(item, clean))) {
      return 'Phong cách này đã có trong danh sách';
    }
    if ((liked ? state.styles.length : state.excludedStyles.length) >= state.maxStyles) {
      return 'Tối đa ${state.maxStyles} phong cách';
    }
    if (liked) {
      state = state.copyWith(styles: [...state.styles, clean]);
    } else {
      state = state.copyWith(excludedStyles: [...state.excludedStyles, clean]);
    }
    return null;
  }

  void setEnabled(bool value) => state = state.copyWith(enabled: value);

  void reset() {
    final profile = state.profile;
    if (profile == null) return;
    state = state.copyWith(
      styles: List<String>.from(profile.styles),
      excludedStyles: List<String>.from(profile.excludedStyles),
      enabled: profile.enabled,
      error: null,
    );
  }

  Future<bool> save() async {
    if (state.saving) return false;
    state = state.copyWith(saving: true, error: null);
    try {
      final profile = await _repository.updateProfile(
        styles: state.styles,
        excludedStyles: state.excludedStyles,
        enabled: state.enabled,
      );
      state = state.copyWith(
        saving: false,
        profile: profile,
        styles: List<String>.from(profile.styles),
        excludedStyles: List<String>.from(profile.excludedStyles),
        enabled: profile.enabled,
      );
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> delete() async {
    state = state.copyWith(deleting: true, error: null);
    try {
      await _repository.deleteProfile();
      state = state.copyWith(
        deleting: false,
        styles: const [],
        excludedStyles: const [],
        enabled: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(deleting: false, error: e.toString());
      return false;
    }
  }
}

final styleProfileControllerProvider =
    StateNotifierProvider<StyleProfileController, StyleProfileState>(
  (ref) => StyleProfileController(),
);
