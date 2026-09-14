import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/bulk_deletion_result.dart';
import '../layout/canvas_layout.dart';
import '../models/outfit_models.dart';
import 'ai_outfit_provider.dart';
import 'outfit_studio_provider.dart';

class OutfitsListState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<UserOutfitModel> outfits;
  final int page;
  final int total;
  final String? errorMessage;
  final UserOutfitModel? selectedDetail;
  final bool isLoadingDetail;
  // Chế độ chọn nhiều để xóa hàng loạt (US2).
  final bool isSelecting;
  final Set<String> selectedIds;

  const OutfitsListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.outfits = const [],
    this.page = 1,
    this.total = 0,
    this.errorMessage,
    this.selectedDetail,
    this.isLoadingDetail = false,
    this.isSelecting = false,
    this.selectedIds = const {},
  });

  int get selectedCount => selectedIds.length;

  /// Còn trang tiếp theo để tải (scroll vô hạn — US 006).
  bool get hasMore => outfits.length < total;

  OutfitsListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<UserOutfitModel>? outfits,
    int? page,
    int? total,
    String? errorMessage,
    UserOutfitModel? selectedDetail,
    bool? isLoadingDetail,
    bool clearError = false,
    bool clearDetail = false,
    bool? isSelecting,
    Set<String>? selectedIds,
  }) {
    return OutfitsListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      outfits: outfits ?? this.outfits,
      page: page ?? this.page,
      total: total ?? this.total,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedDetail: clearDetail ? null : (selectedDetail ?? this.selectedDetail),
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      isSelecting: isSelecting ?? this.isSelecting,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class OutfitsListNotifier extends StateNotifier<OutfitsListState> {
  final Ref _ref;

  OutfitsListNotifier(this._ref) : super(const OutfitsListState()) {
    fetchOutfits();
  }

  Future<void> fetchOutfits() async {
    state = state.copyWith(
        isLoading: true, isLoadingMore: false, clearError: true);
    try {
      final repo = _ref.read(outfitRepositoryProvider);
      final result = await repo.getMyOutfitsPaginated(page: 1);
      state = state.copyWith(
        isLoading: false,
        outfits: result.items,
        page: result.page,
        total: result.total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Tải thêm trang outfit tiếp theo nối vào cuối (scroll vô hạn — US 006).
  /// 1 request tại 1 thời điểm, dedupe theo id, giữ nguyên tick chọn.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final repo = _ref.read(outfitRepositoryProvider);
      final result =
          await repo.getMyOutfitsPaginated(page: nextPage);
      if (!mounted) return;
      final existingIds = state.outfits.map((o) => o.id).toSet();
      final fresh =
          result.items.where((o) => !existingIds.contains(o.id)).toList();
      state = state.copyWith(
        isLoadingMore: false,
        outfits: [...state.outfits, ...fresh],
        page: result.page,
        total: result.total,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<UserOutfitModel?> fetchOutfitDetail(String id) async {
    state = state.copyWith(isLoadingDetail: true, clearDetail: true);
    try {
      final repo = _ref.read(outfitRepositoryProvider);
      final detail = await repo.getOutfitDetail(id);
      state = state.copyWith(
        isLoadingDetail: false,
        selectedDetail: detail,
      );
      return detail;
    } catch (e) {
      state = state.copyWith(
        isLoadingDetail: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> deleteOutfit(String id) async {
    final result = await deleteOutfits([id]);
    return result.isAllSuccess;
  }

  /// Xóa hàng loạt outfit: xóa tuần tự từng id, mục thành công gỡ khỏi
  /// list ngay, mục thất bại giữ lại để báo + thử lại (US2).
  Future<BulkDeletionResult> deleteOutfits(List<String> ids) async {
    if (ids.isEmpty) return const BulkDeletionResult();
    try {
      final repo = _ref.read(outfitRepositoryProvider);
      final result = await repo.deleteOutfits(ids);
      if (result.deletedIds.isNotEmpty) {
        final deleted = result.deletedIds.toSet();
        final remaining =
            state.outfits.where((o) => !deleted.contains(o.id)).toList();
        state = state.copyWith(
          outfits: remaining,
          total: state.total > deleted.length
              ? state.total - deleted.length
              : remaining.length,
        );
      }
      if (result.failedIds.isEmpty) {
        state = state.copyWith(isSelecting: false, selectedIds: const {});
      } else {
        state = state.copyWith(
          errorMessage: 'Không thể xoá ${result.failedCount} bộ trang phục. Vui lòng thử lại.',
        );
      }
      return result;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return BulkDeletionResult(
        failedIds: ids,
        failureMessages: [e.toString().replaceAll('Exception: ', '')],
      );
    }
  }

  // --- Chế độ chọn nhiều (US2) ---

  void enterSelection([String? seedId]) {
    state = state.copyWith(
      isSelecting: true,
      selectedIds: seedId == null ? const {} : {seedId},
    );
  }

  void exitSelection() {
    state = state.copyWith(isSelecting: false, selectedIds: const {});
  }

  void toggleSelect(String id) {
    final next = Set<String>.from(state.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(selectedIds: next);
  }

  void selectAll() {
    state = state.copyWith(
      selectedIds: state.outfits.map((o) => o.id).toSet(),
    );
  }

  /// Nạp các món đồ của một outfit đã lưu vào Studio Canvas để chỉnh sửa.
  /// Giữ đúng vị trí/tỉ lệ/lớp đã lưu; outfit legacy (mọi món ở gốc tọa độ)
  /// thì tự dàn theo vai trò; mọi trường hợp đều kẹp vào khung + tách
  /// chồng lấn, 1 món ra giữa (US 005).
  void loadIntoStudio(UserOutfitModel outfit) {
    var canvasItems = <CanvasItem>[];
    int layer = 1;

    for (final item in outfit.items) {
      final fItem = item.fashionItem;
      if (fItem == null) continue;

      final role = normalizeRole(
        '',
        categorySlug: fItem.category?.slug,
        categoryName: fItem.category?.name,
      );
      canvasItems.add(
        CanvasItem(
          id: '${item.id}_${DateTime.now().millisecondsSinceEpoch}',
          fashionItemId: fItem.id,
          imageUrl: fItem.imageUrl,
          name: fItem.category?.name ?? 'Món đồ',
          role: role.name,
          positionX: item.positionX,
          positionY: item.positionY,
          scale: item.scale,
          layerOrder: item.layerOrder > 0 ? item.layerOrder : layer++,
        ),
      );
    }

    // Legacy: outfit lưu trước khi có tọa độ → tự dàn theo vai trò.
    final hasStoredLayout =
        canvasItems.any((c) => c.positionX != 0 || c.positionY != 0);
    if (!hasStoredLayout && canvasItems.isNotEmpty) {
      final occurrence = <CanvasRole, int>{};
      final relaid = <CanvasItem>[];
      for (final c in canvasItems) {
        final role = normalizeRole(c.role);
        final occ = occurrence[role] ?? 0;
        occurrence[role] = occ + 1;
        final slot = roleSlot(role, occ);
        relaid.add(c.copyWith(
          positionX: slot.x,
          positionY: slot.y,
          layerOrder: slot.layer,
        ));
      }
      canvasItems = relaid;
    }

    final studio = _ref.read(outfitStudioProvider);
    final laidOut = layoutCanvasItems(
      canvasItems,
      canvasWidth: studio.canvasWidth ?? 360,
      canvasHeight: studio.canvasHeight ?? 520,
    );

    _ref.read(outfitStudioProvider.notifier).state =
        _ref.read(outfitStudioProvider.notifier).state.copyWith(
              canvasItems: laidOut,
              clearSelection: true,
              successMessage: 'Đã nạp "${outfit.name}" vào Studio để chỉnh sửa!',
            );
    // Báo màn Studio nhảy sang đúng tab canvas, bất kể đang ở tab nào.
    _ref.read(outfitStudioProvider.notifier).requestOpenCanvas();
  }
}

final outfitsListProvider = StateNotifierProvider<OutfitsListNotifier, OutfitsListState>((ref) {
  return OutfitsListNotifier(ref);
});
