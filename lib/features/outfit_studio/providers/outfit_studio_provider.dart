import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../wardrobe/models/wardrobe_models.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../layout/canvas_layout.dart';
import '../models/outfit_models.dart';
import 'ai_outfit_provider.dart';
import '../../auth/providers/auth_provider.dart';

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

  /// true khi có outfit vừa được nạp từ ngoài vào canvas (từ list "Mở Trên
  /// Studio") và màn Studio cần nhảy sang tab canvas. Screen consume 1 lần.
  final bool openCanvasRequested;

  /// Kích thước canvas thực tế (do màn hình báo về, logical px).
  /// Dùng để kẹp vị trí item vào khung nhìn khi nạp set (US 005).
  /// null = chưa đo được → dùng fallback 360x520.
  final double? canvasWidth;
  final double? canvasHeight;

  /// true khi bộ phối vừa được nạp theo kích thước fallback (chưa đo được
  /// canvas thật) và cần bố trí lại ngay khi màn hình báo kích thước.
  final bool pendingRelayout;

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
    this.openCanvasRequested = false,
    this.canvasWidth,
    this.canvasHeight,
    this.pendingRelayout = false,
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
    bool? openCanvasRequested,
    bool clearError = false,
    bool clearSuccess = false,
    double? canvasWidth,
    double? canvasHeight,
    bool? pendingRelayout,
    bool clearPendingRelayout = false,
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
      openCanvasRequested: openCanvasRequested ?? this.openCanvasRequested,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      pendingRelayout:
          clearPendingRelayout ? false : (pendingRelayout ?? this.pendingRelayout),
    );
  }
}

class OutfitStudioNotifier extends StateNotifier<OutfitStudioState> {
  final Ref _ref;

  OutfitStudioNotifier(this._ref) : super(const OutfitStudioState()) {
    // Khởi tạo ngay với dữ liệu tủ đồ hiện có nếu có sẵn
    final initialWardrobe = _ref.read(wardrobeProvider).items;
    if (initialWardrobe.isNotEmpty) {
      state = state.copyWith(wardrobeItems: initialWardrobe);
    }

    // Lắng nghe thay đổi từ wardrobeProvider để tủ đồ Studio luôn đồng bộ realtime
    _ref.listen<WardrobeState>(wardrobeProvider, (previous, next) {
      if (next.items.isNotEmpty) {
        state = state.copyWith(wardrobeItems: next.items);
      }
    });

    _ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (!next.isAuthenticated) {
        state = const OutfitStudioState();
      } else if (previous?.user?.id != next.user?.id) {
        state = const OutfitStudioState();
        if (next.isAuthenticated) {
          loadWardrobe();
        }
      }
    });

    if (_ref.read(authStateProvider).isAuthenticated) {
      loadWardrobe();
    }
  }

  Future<void> loadWardrobe() async {
    final cached = _ref.read(wardrobeProvider).items;
    if (cached.isNotEmpty) {
      state = state.copyWith(wardrobeItems: cached);
    }

    state = state.copyWith(isLoadingWardrobe: state.wardrobeItems.isEmpty);
    try {
      final repo = _ref.read(outfitRepositoryProvider);
      final items = await repo.getUserWardrobeItems();
      if (items.isNotEmpty) {
        state = state.copyWith(
          isLoadingWardrobe: false,
          wardrobeItems: items,
        );
      } else if (cached.isNotEmpty) {
        state = state.copyWith(
          isLoadingWardrobe: false,
          wardrobeItems: cached,
        );
      } else {
        // Dự phòng: yêu cầu wardrobeProvider nạp đồ
        await _ref.read(wardrobeProvider.notifier).loadItems();
        final refreshed = _ref.read(wardrobeProvider).items;
        state = state.copyWith(
          isLoadingWardrobe: false,
          wardrobeItems: refreshed,
        );
      }
    } catch (e) {
      final fallback = _ref.read(wardrobeProvider).items;
      state = state.copyWith(
        isLoadingWardrobe: false,
        wardrobeItems: fallback.isNotEmpty ? fallback : state.wardrobeItems,
      );
    }
  }

  /// Thay thế món đồ đang chọn trên canvas bằng một món đồ mới từ tủ đồ
  void replaceItemOnCanvas(int index, WardrobeItemModel newItem) {
    if (index < 0 || index >= state.canvasItems.length) return;
    final fashionItem = newItem.fashionItem;
    if (fashionItem == null) return;

    final oldItem = state.canvasItems[index];
    final role = normalizeRole(
      null,
      categorySlug: newItem.category?.slug ?? fashionItem.category?.slug,
      categoryName: newItem.category?.name ?? fashionItem.category?.name,
    );
    final boxRatio = roleBoundingBoxRatios[role] ?? roleBoundingBoxRatios[CanvasRole.unknown]!;

    final replaced = oldItem.copyWith(
      fashionItemId: fashionItem.id,
      imageUrl: newItem.displayImageUrl,
      name: newItem.displayTitle,
      role: role.name,
      boxRatioW: boxRatio.widthRatio,
      boxRatioH: boxRatio.heightRatio,
    );

    final updated = List<CanvasItem>.from(state.canvasItems);
    updated[index] = replaced;
    state = state.copyWith(canvasItems: updated, selectedIndex: index);
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

  /// Màn hình báo kích thước canvas thực tế (gọi post-frame từ LayoutBuilder).
  /// Chỉ notify khi lệch > 1px để tránh vòng rebuild.
  void setCanvasSize(double width, double height) {
    final oldW = state.canvasWidth;
    final oldH = state.canvasHeight;
    if (oldW != null &&
        oldH != null &&
        (width - oldW).abs() <= 1 &&
        (height - oldH).abs() <= 1) {
      return;
    }
    state = state.copyWith(canvasWidth: width, canvasHeight: height);

    // Bộ phối nạp từ ngoài được bố trí theo kích thước canvas TẠI LÚC NẠP.
    // Lần đầu mở Studio kích thước thật chưa có nên phải dùng fallback
    // 360x520 → vị trí lệch so với khung nhìn. Khi đo được kích thước thật
    // thì bố trí lại một lần (guard ≤1px phía trên chặn vòng rebuild).
    if (state.pendingRelayout) {
      state = state.copyWith(
        canvasItems: layoutCanvasItems(
          state.canvasItems,
          canvasWidth: width,
          canvasHeight: height,
        ),
        clearPendingRelayout: true,
      );
    }
  }

  void addItemToCanvas(WardrobeItemModel item) {
    final fashionItem = item.fashionItem;
    if (fashionItem == null) return;

    final items = List<CanvasItem>.from(state.canvasItems);
    final role = normalizeRole(
      null,
      categorySlug: item.category?.slug ?? fashionItem.category?.slug,
      categoryName: item.category?.name ?? fashionItem.category?.name,
    );

    final hasFullbody = items.any((it) => it.role == CanvasRole.fullbody.name);
    final coordinateMap = hasFullbody ? roleCoordinatesFullbody : roleCoordinatesSeparate;
    final placement = coordinateMap[role] ?? coordinateMap[CanvasRole.other]!;
    final boxRatio = roleBoundingBoxRatios[role] ?? roleBoundingBoxRatios[CanvasRole.unknown]!;

    final initialScale = items.isNotEmpty
        ? (items.map((it) => it.scale).reduce((a, b) => a + b) / items.length)
        : 1.0;

    final newItem = CanvasItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fashionItemId: fashionItem.id,
      imageUrl: item.displayImageUrl,
      name: item.displayTitle,
      role: role.name,
      positionX: placement.x,
      positionY: placement.y,
      scale: initialScale,
      layerOrder: placement.zIndex,
      baseScale: placement.scale,
      boxRatioW: boxRatio.widthRatio,
      boxRatioH: boxRatio.heightRatio,
    );

    items.add(newItem);
    state = state.copyWith(
      canvasItems: items,
      selectedIndex: items.length - 1,
    );
  }

  /// Nạp các món được AI gợi ý trực tiếp vào Studio Canvas để user tinh chỉnh.
  /// Bố cục chuẩn giải phẫu cơ thể học tương thích với Web FE:
  /// Loại trừ top/bottom khi có fullbody, dedupe vai trò chính,
  /// phụ kiện 2+ so le, gắn baseScale và bounding box ratio theo vai trò.
  void loadFromAIRecommendation(RecommendedOutfitRes res) {
    final normalized = <({dynamic group, CanvasRole role})>[];
    for (final group in res.items) {
      final primary = group.primary;
      if (primary == null || primary.fashionItem == null) continue;

      final fashionItem = primary.fashionItem!;
      final role = normalizeRole(
        group.role,
        categorySlug: fashionItem.category?.slug,
        categoryName: fashionItem.category?.name,
      );
      normalized.add((group: group, role: role));
    }

    // 1. Nếu có đầm liền thân (fullbody), loại bỏ áo (top) và quần (bottom)
    final hasFullbody = normalized.any((i) => i.role == CanvasRole.fullbody);
    final filtered = hasFullbody
        ? normalized.where((i) => i.role != CanvasRole.top && i.role != CanvasRole.bottom).toList()
        : normalized;

    // 2. Khử trùng lặp: mỗi vai trò chính chỉ xuất hiện tối đa 1 lần (trừ accessory và other)
    final seenRoles = <CanvasRole>{};
    final deduped = <({dynamic group, CanvasRole role})>[];
    for (final item in filtered) {
      if (item.role != CanvasRole.accessory &&
          item.role != CanvasRole.other &&
          item.role != CanvasRole.unknown) {
        if (seenRoles.contains(item.role)) continue;
        seenRoles.add(item.role);
      }
      deduped.add(item);
    }

    // 3. Chọn bảng tọa độ theo loại cấu trúc
    final coordinateMap = hasFullbody ? roleCoordinatesFullbody : roleCoordinatesSeparate;
    var accessoryCount = 0;
    final items = <CanvasItem>[];

    for (final entry in deduped) {
      final group = entry.group;
      final role = entry.role;
      final primary = group.primary!;
      final fashionItem = primary.fashionItem!;

      RolePlacement placement;
      if (role == CanvasRole.accessory) {
        placement = getAccessoryPlacement(accessoryCount, hasFullbody: hasFullbody);
        accessoryCount++;
      } else {
        placement = coordinateMap[role] ?? coordinateMap[CanvasRole.other]!;
      }

      final boxRatio = roleBoundingBoxRatios[role] ?? roleBoundingBoxRatios[CanvasRole.unknown]!;

      items.add(
        CanvasItem(
          id: '${primary.id}_${DateTime.now().millisecondsSinceEpoch}',
          fashionItemId: fashionItem.id,
          imageUrl: fashionItem.imageUrl,
          name: primary.displayName,
          role: role.name,
          positionX: placement.x,
          positionY: placement.y,
          scale: 1.0,
          layerOrder: placement.zIndex,
          baseScale: placement.scale,
          boxRatioW: boxRatio.widthRatio,
          boxRatioH: boxRatio.heightRatio,
        ),
      );
    }

    final laidOut = layoutCanvasItems(
      items,
      canvasWidth: state.canvasWidth ?? 360,
      canvasHeight: state.canvasHeight ?? 520,
    );
    state = state.copyWith(
      canvasItems: laidOut,
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
    items[index] = items[index].copyWith(scale: newScale.clamp(0.15, 3.0));
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

  Future<bool> saveOutfit(
    String name, {
    String? description,
    Uint8List? canvasBytes,
  }) async {
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

      String? coverUrl;
      String? coverPublicId;

      if (canvasBytes != null && canvasBytes.isNotEmpty) {
        try {
          final sig = await repo.getUploadSignatureOutfit();
          final cloudService = CloudinaryService();
          final uploadRes = await cloudService.uploadImage(
            file: XFile.fromData(canvasBytes, name: 'outfit_canvas.png', mimeType: 'image/png'),
            signature: sig,
            applyBgRemoval: false,
          );
          coverUrl = uploadRes.secureUrl;
          coverPublicId = uploadRes.publicId;
        } catch (e) {
          debugPrint('Upload canvas snapshot failed, falling back to item image: $e');
        }
      }

      if (coverUrl == null || coverUrl.isEmpty) {
        final firstImageUrl = state.canvasItems.first.imageUrl;
        coverUrl = firstImageUrl.isNotEmpty ? firstImageUrl : null;
      }

      final req = SaveOutfitReq(
        name: name.trim().isNotEmpty ? name.trim() : 'Bộ phối ${DateTime.now().day}/${DateTime.now().month}',
        description: description,
        coverImageUrl: coverUrl,
        coverPublicId: coverPublicId,
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

  /// Đánh dấu cần nhảy sang tab Studio canvas (dùng sau loadIntoStudio).
  void requestOpenCanvas() {
    state = state.copyWith(openCanvasRequested: true);
  }

  /// Screen đã xử lý yêu cầu nhảy tab — xóa cờ để không nhảy lại.
  void consumeCanvasOpenRequest() {
    if (state.openCanvasRequested) {
      state = state.copyWith(openCanvasRequested: false);
    }
  }
}

final outfitStudioProvider = StateNotifierProvider<OutfitStudioNotifier, OutfitStudioState>((ref) {
  return OutfitStudioNotifier(ref);
});
