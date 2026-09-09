import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../wardrobe/models/wardrobe_models.dart';
import '../models/outfit_models.dart';
import 'ai_outfit_provider.dart';

class OutfitStudioState {
  final List<CanvasItem> canvasItems;
  final int? selectedIndex;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final List<WardrobeItemModel> wardrobeItems;
  final bool isLoadingWardrobe;
  final String selectedDrawerCategory;
  final String? _drawerSearchQuery;

  const OutfitStudioState({
    this.canvasItems = const [],
    this.selectedIndex,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.wardrobeItems = const [],
    this.isLoadingWardrobe = false,
    this.selectedDrawerCategory = 'All',
    String? drawerSearchQuery = '',
  }) : _drawerSearchQuery = drawerSearchQuery;

  String get drawerSearchQuery => _drawerSearchQuery ?? '';

  /// Danh sách item sau khi đã lọc theo category và search query
  List<WardrobeItemModel> get filteredWardrobeItems {
    final query = drawerSearchQuery.trim().toLowerCase();

    return wardrobeItems.where((item) {
      // 1. Lọc theo Category
      if (selectedDrawerCategory != 'All') {
        final catName = (item.category?.name ?? item.fashionItem?.category?.name ?? '').toLowerCase();
        final catSlug = (item.category?.slug ?? item.fashionItem?.category?.slug ?? '').toLowerCase();
        final selected = selectedDrawerCategory.toLowerCase();

        bool match = false;
        if (selected == 'áo') {
          match = catName.contains('áo') || catSlug.contains('ao') || catSlug.contains('top') || catSlug.contains('shirt');
        } else if (selected == 'quần') {
          match = catName.contains('quần') || catSlug.contains('quan') || catSlug.contains('pant') || catSlug.contains('jean') || catSlug.contains('bottom');
        } else if (selected == 'váy') {
          match = catName.contains('váy') || catName.contains('đầm') || catSlug.contains('vay') || catSlug.contains('dam') || catSlug.contains('dress');
        } else if (selected == 'giày') {
          match = catName.contains('giày') || catSlug.contains('giay') || catSlug.contains('shoe') || catSlug.contains('sneaker');
        } else if (selected == 'phụ kiện') {
          match = catName.contains('phụ kiện') || catName.contains('mũ') || catName.contains('nón') || catName.contains('túi') || catSlug.contains('phu-kien') || catSlug.contains('accessory');
        } else {
          match = catName.contains(selected) || catSlug.contains(selected);
        }
        if (!match) return false;
      }

      // 2. Lọc theo Search Query
      if (query.isNotEmpty) {
        final title = item.displayTitle.toLowerCase();
        final color = (item.fashionItem?.color ?? '').toLowerCase();
        final style = (item.fashionItem?.style ?? '').toLowerCase();
        final cat = (item.category?.name ?? item.fashionItem?.category?.name ?? '').toLowerCase();
        if (!title.contains(query) && !color.contains(query) && !style.contains(query) && !cat.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  OutfitStudioState copyWith({
    List<CanvasItem>? canvasItems,
    int? selectedIndex,
    bool clearSelection = false,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    List<WardrobeItemModel>? wardrobeItems,
    bool? isLoadingWardrobe,
    String? selectedDrawerCategory,
    String? drawerSearchQuery,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return OutfitStudioState(
      canvasItems: canvasItems ?? this.canvasItems,
      selectedIndex: clearSelection ? null : (selectedIndex ?? this.selectedIndex),
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      wardrobeItems: wardrobeItems ?? this.wardrobeItems,
      isLoadingWardrobe: isLoadingWardrobe ?? this.isLoadingWardrobe,
      selectedDrawerCategory: selectedDrawerCategory ?? this.selectedDrawerCategory,
      drawerSearchQuery: drawerSearchQuery ?? this.drawerSearchQuery,
    );
  }
}

class OutfitStudioNotifier extends StateNotifier<OutfitStudioState> {
  final Ref _ref;

  OutfitStudioNotifier(this._ref) : super(const OutfitStudioState()) {
    loadWardrobe();
  }

  Future<void> loadWardrobe() async {
    state = state.copyWith(isLoadingWardrobe: true);
    try {
      final repo = _ref.read(outfitRepositoryProvider);
      final items = await repo.getUserWardrobeItems();
      state = state.copyWith(
        isLoadingWardrobe: false,
        wardrobeItems: items,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingWardrobe: false,
        errorMessage: 'Không thể tải tủ đồ cá nhân: ${e.toString()}',
      );
    }
  }

  void setDrawerCategory(String category) {
    state = state.copyWith(selectedDrawerCategory: category);
  }

  void setDrawerSearchQuery(String query) {
    state = state.copyWith(drawerSearchQuery: query);
  }

  void selectItem(int? index) {
    if (index == null) {
      state = state.copyWith(clearSelection: true);
    } else {
      state = state.copyWith(selectedIndex: index);
    }
  }

  void addItemToCanvas(WardrobeItemModel item) {
    final fashionItem = item.fashionItem;
    if (fashionItem == null) return;

    final items = List<CanvasItem>.from(state.canvasItems);

    final catSlug = fashionItem.category?.slug.toLowerCase() ?? '';
    double defaultY = 0;
    double defaultX = 0;
    String role = 'item';

    if (catSlug.contains('ao') || catSlug.contains('top') || catSlug.contains('shirt') || catSlug.contains('jacket')) {
      defaultY = -120;
      role = 'top';
    } else if (catSlug.contains('quan') || catSlug.contains('pant') || catSlug.contains('jean') || catSlug.contains('bottom')) {
      defaultY = 80;
      role = 'bottom';
    } else if (catSlug.contains('dam') || catSlug.contains('dress') || catSlug.contains('vay')) {
      defaultY = -20;
      role = 'fullbody';
    } else if (catSlug.contains('giay') || catSlug.contains('shoe') || catSlug.contains('sneaker')) {
      defaultY = 220;
      role = 'footwear';
    } else if (catSlug.contains('phu-kien') || catSlug.contains('non') || catSlug.contains('mu') || catSlug.contains('accessory')) {
      defaultX = -130;
      defaultY = -90;
      role = 'accessory';
    }

    final newItem = CanvasItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fashionItemId: fashionItem.id,
      imageUrl: fashionItem.imageUrl,
      name: item.displayTitle,
      role: role,
      positionX: defaultX,
      positionY: defaultY,
      scale: 1.0,
      layerOrder: items.length + 1,
    );

    items.add(newItem);
    state = state.copyWith(
      canvasItems: items,
      selectedIndex: items.length - 1,
    );
  }

  /// Nạp các món được AI gợi ý trực tiếp vào Studio Canvas để user tinh chỉnh
  void loadFromAIRecommendation(RecommendedOutfitRes res) {
    final items = <CanvasItem>[];
    int layer = 1;

    for (final group in res.items) {
      final primary = group.primary;
      if (primary == null || primary.fashionItem == null) continue;

      final fashionItem = primary.fashionItem!;
      double posX = 0;
      double posY = 0;
      final role = group.role.toLowerCase();

      if (role == 'top') {
        posY = -120;
      } else if (role == 'bottom') {
        posY = 80;
      } else if (role == 'fullbody') {
        posY = -20;
      } else if (role == 'footwear') {
        posY = 220;
      } else if (role == 'accessory') {
        posX = -130;
        posY = -90;
      }

      items.add(
        CanvasItem(
          id: '${primary.id}_${DateTime.now().millisecondsSinceEpoch}',
          fashionItemId: fashionItem.id,
          imageUrl: fashionItem.imageUrl,
          name: primary.displayName,
          role: group.role,
          positionX: posX,
          positionY: posY,
          scale: 1.0,
          layerOrder: layer++,
        ),
      );
    }

    state = state.copyWith(
      canvasItems: items,
      clearSelection: true,
      successMessage: 'Đã nạp set đồ AI vào Studio để chỉnh sửa!',
    );
  }

  void updateItemPosition(int index, double dx, double dy) {
    if (index < 0 || index >= state.canvasItems.length) return;
    final items = List<CanvasItem>.from(state.canvasItems);
    items[index] = items[index].copyWith(
      positionX: items[index].positionX + dx,
      positionY: items[index].positionY + dy,
    );
    state = state.copyWith(canvasItems: items);
  }

  void updateItemScale(int index, double newScale) {
    if (index < 0 || index >= state.canvasItems.length) return;
    final items = List<CanvasItem>.from(state.canvasItems);
    items[index] = items[index].copyWith(scale: newScale.clamp(0.4, 2.5));
    state = state.copyWith(canvasItems: items);
  }

  void bringForward(int index) {
    if (index < 0 || index >= state.canvasItems.length - 1) return;
    final items = List<CanvasItem>.from(state.canvasItems);
    final item = items.removeAt(index);
    items.insert(index + 1, item);
    for (int i = 0; i < items.length; i++) {
      items[i].layerOrder = i + 1;
    }
    state = state.copyWith(canvasItems: items, selectedIndex: index + 1);
  }

  void sendBackward(int index) {
    if (index <= 0 || index >= state.canvasItems.length) return;
    final items = List<CanvasItem>.from(state.canvasItems);
    final item = items.removeAt(index);
    items.insert(index - 1, item);
    for (int i = 0; i < items.length; i++) {
      items[i].layerOrder = i + 1;
    }
    state = state.copyWith(canvasItems: items, selectedIndex: index - 1);
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.canvasItems.length) return;
    final items = List<CanvasItem>.from(state.canvasItems);
    items.removeAt(index);
    state = state.copyWith(canvasItems: items, clearSelection: true);
  }

  void clearCanvas() {
    state = state.copyWith(canvasItems: [], clearSelection: true);
  }

  Future<bool> saveOutfit(String name, {String? description}) async {
    if (state.canvasItems.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng thêm ít nhất 1 món đồ lên canvas.');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final repo = _ref.read(outfitRepositoryProvider);

      final saveItems = state.canvasItems
          .map(
            (i) => SaveOutfitItemReq(
              fashionItemId: i.fashionItemId,
              positionX: i.positionX,
              positionY: i.positionY,
              scale: i.scale,
              layerOrder: i.layerOrder,
            ),
          )
          .toList();

      final firstImageUrl = state.canvasItems.first.imageUrl;

      final req = SaveOutfitReq(
        name: name.trim().isNotEmpty ? name.trim() : 'Outfit ${DateTime.now().day}/${DateTime.now().month}',
        description: description,
        coverImageUrl: firstImageUrl.isNotEmpty ? firstImageUrl : null,
        items: saveItems,
      );

      await repo.saveOutfit(req);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Lưu bộ trang phục thành công!',
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

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final outfitStudioProvider = StateNotifierProvider<OutfitStudioNotifier, OutfitStudioState>((ref) {
  return OutfitStudioNotifier(ref);
});
