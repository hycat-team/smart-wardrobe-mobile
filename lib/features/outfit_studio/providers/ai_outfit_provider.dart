import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/outfit_repository.dart';
import '../models/outfit_models.dart';

final outfitRepositoryProvider = Provider<OutfitRepository>((ref) {
  return OutfitRepository();
});

class AIOutfitState {
  final bool isLoading;
  final RecommendedOutfitRes? recommendation;
  final String? errorMessage;
  final String selectedOccasion;
  final String selectedStyle;
  final String selectedSeason;
  final String selectedWeather;
  final String selectedColorTone;
  final String details;

  const AIOutfitState({
    this.isLoading = false,
    this.recommendation,
    this.errorMessage,
    this.selectedOccasion = 'casual',
    this.selectedStyle = 'minimalist',
    this.selectedSeason = 'summer',
    this.selectedWeather = 'warm',
    this.selectedColorTone = 'light',
    this.details = '',
  });

  AIOutfitState copyWith({
    bool? isLoading,
    RecommendedOutfitRes? recommendation,
    String? errorMessage,
    String? selectedOccasion,
    String? selectedStyle,
    String? selectedSeason,
    String? selectedWeather,
    String? selectedColorTone,
    String? details,
    bool clearError = false,
    bool clearRecommendation = false,
  }) {
    return AIOutfitState(
      isLoading: isLoading ?? this.isLoading,
      recommendation: clearRecommendation ? null : (recommendation ?? this.recommendation),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedOccasion: selectedOccasion ?? this.selectedOccasion,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      selectedSeason: selectedSeason ?? this.selectedSeason,
      selectedWeather: selectedWeather ?? this.selectedWeather,
      selectedColorTone: selectedColorTone ?? this.selectedColorTone,
      details: details ?? this.details,
    );
  }
}

class AIOutfitNotifier extends StateNotifier<AIOutfitState> {
  final OutfitRepository _repository;

  AIOutfitNotifier(this._repository) : super(const AIOutfitState());

  void setOccasion(String occasion) => state = state.copyWith(selectedOccasion: occasion);
  void setStyle(String style) => state = state.copyWith(selectedStyle: style);
  void setSeason(String season) => state = state.copyWith(selectedSeason: season);
  void setWeather(String weather) => state = state.copyWith(selectedWeather: weather);
  void setColorTone(String tone) => state = state.copyWith(selectedColorTone: tone);
  void setDetails(String details) => state = state.copyWith(details: details);

  Future<bool> generateOutfit() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final req = AIOutfitRecommendationReq(
        occasion: state.selectedOccasion,
        styleTarget: state.selectedStyle,
        season: state.selectedSeason,
        weather: state.selectedWeather,
        colorTone: state.selectedColorTone,
        details: state.details.isNotEmpty ? state.details : null,
      );

      final res = await _repository.getAIRecommendation(req);
      state = state.copyWith(
        isLoading: false,
        recommendation: res,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Hoán đổi món chính trong nhóm gợi ý với một món đồ thay thế (alternative)
  void swapAlternative(int groupIndex, RecommendedItemRes newPrimary) {
    if (state.recommendation == null) return;
    final currentItems = List<RecommendedItemGroup>.from(state.recommendation!.items);
    if (groupIndex < 0 || groupIndex >= currentItems.length) return;

    final targetGroup = currentItems[groupIndex];
    final oldPrimary = targetGroup.primary;

    final newAlternatives = List<RecommendedItemRes>.from(targetGroup.alternatives);
    newAlternatives.removeWhere((item) => item.id == newPrimary.id);
    if (oldPrimary != null) {
      newAlternatives.add(oldPrimary);
    }

    currentItems[groupIndex] = RecommendedItemGroup(
      role: targetGroup.role,
      primary: newPrimary,
      alternatives: newAlternatives,
    );

    final updatedRecommendation = RecommendedOutfitRes(
      title: state.recommendation!.title,
      explanation: state.recommendation!.explanation,
      items: currentItems,
      isFallback: state.recommendation!.isFallback,
      remainingQuota: state.recommendation!.remainingQuota,
    );

    state = state.copyWith(recommendation: updatedRecommendation);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final aiOutfitProvider = StateNotifierProvider<AIOutfitNotifier, AIOutfitState>((ref) {
  final repo = ref.watch(outfitRepositoryProvider);
  return AIOutfitNotifier(repo);
});
