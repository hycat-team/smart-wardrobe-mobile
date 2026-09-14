import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/sse_service.dart';
import '../../../shared/models/bulk_deletion_result.dart';
import '../data/wardrobe_repository.dart';
import '../models/wardrobe_models.dart';

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  return WardrobeRepository();
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(wardrobeRepositoryProvider);
  return await repo.getCategories();
});

final wardrobeInsightsProvider = FutureProvider.autoDispose<WardrobeInsightsModel>((ref) async {
  final repo = ref.watch(wardrobeRepositoryProvider);
  return await repo.getWardrobeInsights();
});

final categoryDistributionProvider =
    FutureProvider.autoDispose<WardrobeCategoryDistributionResult>((ref) async {
  final repo = ref.watch(wardrobeRepositoryProvider);
  return await repo.getCategoryDistribution();
});

final wardrobeItemDetailProvider =
    FutureProvider.autoDispose.family<WardrobeItemModel, String>((ref, id) async {
  final repo = ref.watch(wardrobeRepositoryProvider);
  return await repo.getWardrobeItemById(id);
});

final selectedCategorySlugProvider = StateProvider<String?>((ref) => null);

class WardrobeState {
  final bool isLoading;
  final bool isRefreshing;
  final List<WardrobeItemModel> items;
  final int page;
  final int total;
  final String? errorMessage;
  final String? notificationMessage;
  // Chế độ chọn nhiều để xóa hàng loạt (US2). Không ảnh hưởng list/items.
  final bool isSelecting;
  final Set<String> selectedIds;

  const WardrobeState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.items = const [],
    this.page = 1,
    this.total = 0,
    this.errorMessage,
    this.notificationMessage,
    this.isSelecting = false,
    this.selectedIds = const {},
  });

  int get selectedCount => selectedIds.length;

  WardrobeState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    List<WardrobeItemModel>? items,
    int? page,
    int? total,
    String? errorMessage,
    String? notificationMessage,
    bool? isSelecting,
    Set<String>? selectedIds,
  }) {
    return WardrobeState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      errorMessage: errorMessage ?? this.errorMessage,
      notificationMessage: notificationMessage,
      isSelecting: isSelecting ?? this.isSelecting,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class WardrobeNotifier extends StateNotifier<WardrobeState> {
  final WardrobeRepository _repository;
  final Ref _ref;
  final Map<String, SSESubscription> _activeSubscriptions = {};
  Timer? _pollingSafetyTimer;

  WardrobeNotifier(this._repository, this._ref) : super(const WardrobeState()) {
    loadItems();
  }

  @override
  void dispose() {
    _pollingSafetyTimer?.cancel();
    for (final sub in _activeSubscriptions.values) {
      sub.cancel();
    }
    _activeSubscriptions.clear();
    super.dispose();
  }

  Future<void> loadItems({bool refresh = false}) async {
    final currentCategorySlug = _ref.read(selectedCategorySlugProvider);
    if (refresh) {
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final result = await _repository.getMyWardrobeItems(
        page: refresh ? 1 : state.page,
        categorySlug: currentCategorySlug,
      );

      // Preserve any optimistic items that are still processing and not in server result yet
      final serverItemIds = result.items.map((e) => e.id.toLowerCase()).toSet();
      final pendingOptimistic = state.items
          .where((it) => it.isProcessing && !serverItemIds.contains(it.id.toLowerCase()))
          .toList();

      final mergedList = [...pendingOptimistic, ...result.items];

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        items: mergedList,
        page: result.page,
        total: result.total + pendingOptimistic.length,
      );

      // Auto-listen to SSE for any items currently in processing state (status == 3)
      _checkAndSubscribeProcessingItems(mergedList);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void addOptimisticItem(WardrobeItemModel item) {
    debugPrint('[WardrobeNotifier] Adding optimistic item: ${item.id}, taskId: ${item.taskId}');
    final existingIndex = state.items.indexWhere((it) => it.id == item.id);
    List<WardrobeItemModel> updatedList;
    if (existingIndex >= 0) {
      updatedList = List<WardrobeItemModel>.from(state.items);
      updatedList[existingIndex] = item;
    } else {
      updatedList = [item, ...state.items];
    }

    state = state.copyWith(
      items: updatedList,
      total: state.total + (existingIndex >= 0 ? 0 : 1),
    );

    if (item.taskId != null && item.taskId!.isNotEmpty) {
      _subscribeToTask(item.taskId!);
    }

    // Always start safety polling as well to guarantee updates on Web/Mobile
    _startSafetyPolling();
  }

  void _checkAndSubscribeProcessingItems(List<WardrobeItemModel> items) {
    final processingItems = items.where((it) => it.isProcessing).toList();
    for (final item in processingItems) {
      final taskId = item.taskId;
      if (taskId != null && taskId.isNotEmpty) {
        _subscribeToTask(taskId);
      }
    }

    if (processingItems.isNotEmpty) {
      _startSafetyPolling();
    }
  }

  void _startSafetyPolling() {
    _pollingSafetyTimer?.cancel();
    int attempts = 0;
    _pollingSafetyTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      if (!mounted) {
        timer.cancel();
        return;
      }

      final hasProcessing = state.items.any((it) => it.isProcessing);
      if (!hasProcessing || attempts > 12) {
        timer.cancel();
        return;
      }

      debugPrint('[WardrobeNotifier] Safety poll attempt $attempts for processing items...');
      try {
        final currentCategorySlug = _ref.read(selectedCategorySlugProvider);
        final result = await _repository.getMyWardrobeItems(
          page: 1,
          categorySlug: currentCategorySlug,
        );

        bool hasFinished = false;
        final updatedItems = state.items.map((existing) {
          if (!existing.isProcessing) return existing;
          final serverMatch = result.items.cast<WardrobeItemModel?>().firstWhere(
                (it) => it?.id.toLowerCase() == existing.id.toLowerCase() ||
                    (it?.taskId != null && it?.taskId?.toLowerCase() == existing.taskId?.toLowerCase()),
                orElse: () => null,
              );

          if (serverMatch != null && !serverMatch.isProcessing) {
            hasFinished = true;
            return serverMatch;
          }
          return existing;
        }).toList();

        if (hasFinished) {
          state = state.copyWith(
            items: updatedItems,
            notificationMessage: 'Trang phục đã được AI phân tích hoàn tất!',
          );
          _ref.invalidate(wardrobeInsightsProvider);
          _ref.invalidate(categoryDistributionProvider);
          timer.cancel();
        }
      } catch (e) {
        debugPrint('[WardrobeNotifier] Safety poll error: $e');
      }
    });
  }

  void _subscribeToTask(String taskId) {
    if (_activeSubscriptions.containsKey(taskId)) return;

    debugPrint('[WardrobeNotifier] Starting SSE subscription for task: $taskId');
    final sub = _repository.subscribeTaskSSE(
      taskId: taskId,
      onEvent: (payload) => _handleTaskEvent(taskId, payload),
      onDone: () => _handleTaskDone(taskId),
      onError: (error) => _handleTaskError(taskId, error),
    );

    _activeSubscriptions[taskId] = sub;
  }

  void _handleTaskEvent(String taskId, WardrobeTaskSSEPayload payload) {
    debugPrint('[WardrobeNotifier] Handling SSE event for task: $taskId, status: ${payload.status}');

    final targetItemId = payload.itemId ?? payload.item?.id;
    final itemStatusStr = payload.status;
    final sseItem = payload.item;

    int nextStatus = 0; // InWardrobe
    if (itemStatusStr == 'completed') {
      nextStatus = 0;
    } else if (itemStatusStr == 'failed') {
      nextStatus = 4;
    } else if (itemStatusStr == 'needs_review') {
      nextStatus = 5;
    } else {
      nextStatus = 3; // processing
    }

    // Optimistically update matching item in state
    final updatedItems = state.items.map((it) {
      final isMatch = (targetItemId != null && it.id.toLowerCase() == targetItemId.toLowerCase()) ||
          (it.taskId != null && it.taskId!.toLowerCase() == taskId.toLowerCase());

      if (!isMatch) return it;

      return it.copyWith(
        status: nextStatus,
        category: sseItem?.category ?? it.category,
        fashionItem: sseItem?.fashionItem ?? it.fashionItem,
        price: sseItem?.price ?? it.price,
      );
    }).toList();

    String? notif;
    if (nextStatus == 0) {
      notif = 'Trang phục đã được AI phân tích hoàn tất!';
    } else if (nextStatus == 5) {
      notif = 'AI cần bạn xác nhận lại danh mục trang phục.';
    } else if (nextStatus == 4) {
      notif = payload.error ?? 'AI không thể nhận diện trang phục.';
    }

    state = state.copyWith(
      items: updatedItems,
      notificationMessage: notif,
    );

    _ref.invalidate(wardrobeInsightsProvider);
    _ref.invalidate(categoryDistributionProvider);
    if (targetItemId != null) {
      _ref.invalidate(wardrobeItemDetailProvider(targetItemId));
    }
  }

  void _handleTaskDone(String taskId) {
    debugPrint('[WardrobeNotifier] SSE Task done: $taskId');
    final sub = _activeSubscriptions.remove(taskId);
    sub?.cancel();

    // Trigger full refresh from server to ensure complete consistency
    loadItems(refresh: true);
    _ref.invalidate(wardrobeInsightsProvider);
    _ref.invalidate(categoryDistributionProvider);
  }

  void _handleTaskError(String taskId, dynamic error) {
    debugPrint('[WardrobeNotifier] SSE Task error for $taskId: $error');
    final sub = _activeSubscriptions.remove(taskId);
    sub?.cancel();

    // Fallback: reload items after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) loadItems(refresh: true);
    });
  }

  void clearNotification() {
    state = state.copyWith(notificationMessage: null);
  }

  void selectCategory(String? slug) {
    _ref.read(selectedCategorySlugProvider.notifier).state = slug;
    loadItems(refresh: true);
  }

  Future<bool> deleteItem(String id) async {
    final result = await deleteItems([id]);
    return result.isAllSuccess;
  }

  /// Xóa hàng loạt món đồ trong một lần gọi bulk (US2).
  /// Xóa optimistic khỏi list; thất bại thì rollback nguyên list cũ.
  Future<BulkDeletionResult> deleteItems(List<String> ids) async {
    if (ids.isEmpty) return const BulkDeletionResult();
    final previousItems = List<WardrobeItemModel>.from(state.items);
    final previousTotal = state.total;
    final toDelete = ids.toSet();
    state = state.copyWith(
      items: state.items.where((it) => !toDelete.contains(it.id)).toList(),
      total: state.total > toDelete.length ? state.total - toDelete.length : 0,
    );
    try {
      await _repository.deleteWardrobeItems(ids);
      state = state.copyWith(isSelecting: false, selectedIds: const {});
      // Invalidate stats
      _ref.invalidate(wardrobeInsightsProvider);
      _ref.invalidate(categoryDistributionProvider);
      return BulkDeletionResult(deletedIds: ids);
    } catch (e) {
      state = state.copyWith(
        items: previousItems,
        total: previousTotal,
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
      selectedIds: state.items.map((it) => it.id).toSet(),
    );
  }

  Future<WardrobeItemModel?> updateItem(
    String id, {
    double? price,
    String? categoryId,
  }) async {
    try {
      final updated = await _repository.updateWardrobeItem(
        id,
        price: price,
        categoryId: categoryId,
      );

      final index = state.items.indexWhere((it) => it.id == id);
      if (index != -1) {
        final newItems = List<WardrobeItemModel>.from(state.items);
        newItems[index] = updated;
        state = state.copyWith(items: newItems);
      }
      _ref.invalidate(wardrobeItemDetailProvider(id));
      _ref.invalidate(wardrobeInsightsProvider);
      _ref.invalidate(categoryDistributionProvider);
      return updated;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }
}

final wardrobeProvider = StateNotifierProvider<WardrobeNotifier, WardrobeState>((ref) {
  final repo = ref.watch(wardrobeRepositoryProvider);
  return WardrobeNotifier(repo, ref);
});
