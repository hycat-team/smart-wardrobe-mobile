import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/closy_network_image.dart';
import '../../../../shared/widgets/media_viewer_overlay.dart';
import '../../../community/models/post_models.dart';
import '../../models/outfit_models.dart';
import '../../providers/ai_outfit_provider.dart';
import '../../providers/outfit_studio_provider.dart';
import '../../providers/outfits_list_provider.dart';
import '../../../wardrobe/providers/wardrobe_provider.dart';

/// Ảnh bìa bộ phối chiếm phần lớn khung hình (~78%), phần thông tin còn lại
/// nằm bên dưới. Đo theo chiều cao vùng nhìn thật (không tính AppBar).
const double kOutfitCoverRatio = 0.78;

/// Mở trang **chi tiết bộ phối toàn màn hình**.
///
/// - [siblings]: danh sách outfit để **vuốt trái/phải** xem outfit trước/sau.
///   Truyền `[outfit]` (1 phần tử) khi chỉ xem trước 1 outfit (composer).
/// - [initialIndex]: vị trí khởi tạo trong [siblings] → hiển thị bộ đếm "3 / 12".
/// - [onDelete]: callback xoá (thường mở dialog xác nhận ở màn gọi).
Future<void> showClosyOutfitDetail(
  BuildContext context, {
  required String outfitId,
  OutfitBrief? brief,
  UserOutfitModel? initialOutfit,
  List<UserOutfitModel>? siblings,
  int initialIndex = 0,
  VoidCallback? onDelete,
}) {
  final list = (siblings == null || siblings.isEmpty)
      ? <UserOutfitModel>[if (initialOutfit != null) initialOutfit]
      : siblings;
  final start = initialIndex.clamp(0, list.isEmpty ? 0 : list.length - 1);

  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => OutfitDetailPage(
        outfitId: outfitId,
        brief: brief,
        initialOutfit: initialOutfit,
        siblings: list,
        initialIndex: start,
        onDelete: onDelete,
      ),
    ),
  );
}

/// Trang chi tiết bộ phối toàn màn hình, vuốt ngang để xem các outfit liền kề.
class OutfitDetailPage extends ConsumerStatefulWidget {
  final String outfitId;
  final OutfitBrief? brief;
  final UserOutfitModel? initialOutfit;
  final List<UserOutfitModel> siblings;
  final int initialIndex;
  final VoidCallback? onDelete;

  const OutfitDetailPage({
    super.key,
    required this.outfitId,
    this.brief,
    this.initialOutfit,
    required this.siblings,
    this.initialIndex = 0,
    this.onDelete,
  });

  @override
  ConsumerState<OutfitDetailPage> createState() => _OutfitDetailPageState();
}

class _OutfitDetailPageState extends ConsumerState<OutfitDetailPage> {
  late final PageController _pageController;
  late final List<UserOutfitModel> _pages;
  late int _currentIndex;

  /// id → outfit đã nạp đầy đủ (có `items`).
  final Map<String, UserOutfitModel> _detailCache = {};
  final Set<String> _loadingIds = <String>{};

  /// Trạng thái mở/thu gọn của dropdown "Các món đồ trong set".
  /// Mặc định thu gọn vì ảnh bìa đã chiến phần lớn khung hình.
  bool _itemsExpanded = false;

  /// Outfit của trang đang xem — thanh hành động dính đáy cần để gọi
  /// nút "Xem bộ phối trong studio" đúng bộ phối đang hiển thị.
  UserOutfitModel? _currentOutfit;

  @override
  void initState() {
    super.initState();
    _pages = List<UserOutfitModel>.from(widget.siblings);
    _currentIndex = widget.initialIndex.clamp(0, _pages.length - 1);
    _pageController = PageController(initialPage: _currentIndex);

    // Nạp sẵn trang hiện tại (và trang đầu nếu khởi tạo từ brief).
    for (final o in _pages) {
      _detailCache[o.id] = o;
    }
    final seed = widget.initialOutfit;
    if (seed != null) {
      _detailCache[seed.id] = seed;
    }
    // Nạp chi tiết trang đang xem (danh sách không kèm món đồ).
    if (_pages.isNotEmpty) {
      _maybeLoadDetail(_pages[_currentIndex]);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Gọi API lấy chi tiết outfit. Trả `null` nếu lỗi (đã ghi nhận id đang tải).
  Future<UserOutfitModel?> _fetchDetail(String outfitId) async {
    if (_loadingIds.contains(outfitId)) return null;
    _loadingIds.add(outfitId);
    try {
      final detail =
          await ref.read(outfitRepositoryProvider).getOutfitDetail(outfitId);
      if (mounted) {
        setState(() => _detailCache[outfitId] = detail);
      }
      return detail;
    } catch (_) {
      return null;
    } finally {
      _loadingIds.remove(outfitId);
    }
  }

  /// Gọi API lấy chi tiết khi outfit chưa có danh sách món.
  Future<void> _maybeLoadDetail(UserOutfitModel outfit) async {
    if (outfit.items.isNotEmpty) return;
    await _fetchDetail(outfit.id);
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    final outfit = _pages[index];
    _maybeLoadDetail(outfit);
    // Vuốt gần cuối → nối thêm trang mới để xem tiếp.
    if (index >= _pages.length - 3) {
      ref.read(outfitsListProvider.notifier).loadMore();
    }
  }

  /// Đồng bộ list khi `loadMore()` bổ sung outfit mới.
  void _syncSiblings() {
    final list = ref.read(outfitsListProvider).outfits;
    if (list.isEmpty) return;
    if (list.length == _pages.length) return;
    final ids = _pages.map((e) => e.id).toSet();
    final extra = list.where((o) => !ids.contains(o.id)).toList();
    if (extra.isEmpty) return;
    setState(() => _pages.addAll(extra));
  }

  /// Các món của outfit đã bị gỡ khỏi tủ đồ → không mở được trong Studio.
  ///
  /// Đối chiếu `fashionItem.id` của outfit với các món đang có trong tủ
  /// (`outfitStudioProvider.wardrobeItems`, dự phòng `wardrobeProvider.items`).
  List<OutfitItemDetailModel> _missingWardrobeItems(UserOutfitModel outfit) {
    final studioItems = ref.read(outfitStudioProvider).wardrobeItems;
    final source = studioItems.isNotEmpty
        ? studioItems
        : ref.read(wardrobeProvider).items;
    final availableIds =
        source.map((w) => w.fashionItem?.id).whereType<String>().toSet();

    // Tủ chưa nạp được (mạng lỗi) thì không chặn người dùng.
    if (availableIds.isEmpty) return const [];

    return outfit.items
        .where((i) => i.fashionItem == null || !availableIds.contains(i.fashionItem!.id))
        .toList();
  }

  void _showMissingItemsDialog(List<OutfitItemDetailModel> missing) {
    final labels = <String>{
      for (final m in missing)
        () {
          final name = m.fashionItem?.category?.name.trim() ?? '';
          return name.isEmpty ? 'món đồ' : name;
        }(),
    };
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Chưa thể xem trong Studio',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        content: Text(
          'Bạn đã gỡ ${labels.join(', ')} khỏi tủ đồ nên chưa thể mở bộ phối này '
          'trong Studio. Hãy thêm lại các món đồ đó vào tủ đồ rồi thử lại.',
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInStudio(UserOutfitModel outfit) async {
    // Danh sách (`GET /me/outfits`) chỉ trả về outfit KHÔNG kèm món đồ, nên
    // `items` thường rỗng lúc mở trang. Phải nạp chi tiết trước, nếu không
    // sẽ vào Studio với canvas trống.
    var target = outfit;
    if (target.items.isEmpty) {
      setState(() {});
      final detail = await _fetchDetail(target.id);
      if (!mounted) return;
      if (detail == null) {
        _showErrorDialog(
          'Chưa tải được bộ phối',
          'Vui lòng kiểm tra kết nối mạng rồi thử lại.',
        );
        return;
      }
      target = detail;
    }

    if (target.items.isEmpty) {
      _showErrorDialog(
        'Bộ phối chưa có món đồ',
        'Bộ phối này không có món nào trong tủ nên không thể hiển thị trên Studio.',
      );
      return;
    }

    final missing = _missingWardrobeItems(target);
    if (missing.isNotEmpty) {
      _showMissingItemsDialog(missing);
      return;
    }

    final hasItems = ref.read(outfitStudioProvider).canvasItems.isNotEmpty;
    var replace = true;
    if (hasItems) {
      replace = await showDialog<bool>(
            context: context,
            builder: (dialogCtx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Thay đồ trên canvas?',
                style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
              ),
              content: const Text(
                'Canvas đang có đồ bạn dàn dở. Mở outfit này sẽ thay thế toàn bộ bố cục hiện tại.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('Giữ lại',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Ghi đè'),
                ),
              ],
            ),
          ) ==
          true;
    }

    if (!mounted || !replace) return;
    // Nạp bộ phối lên canvas TRƯỚC khi rời trang, rồi mới điều hướng.
    Navigator.of(context).pop();
    ref.read(outfitsListProvider.notifier).loadIntoStudio(target);
    if (mounted) context.go('/studio');
  }

  @override
  Widget build(BuildContext context) {
    _syncSiblings();
    final total = _pages.length;
    final showCounter = total > 1;
    // Thanh đáy dùng bộ phối đang xem; luôn có dữ liệu sau khi initState.
    final currentOutfit = _currentOutfit ??
        (_pages.isNotEmpty
            ? (_detailCache[_pages[_currentIndex].id] ??
                _pages[_currentIndex])
            : null);

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      // Thanh hành động dính đáy: luôn hiện dù cuộn lên/xuống.
      bottomNavigationBar: currentOutfit == null
          ? null
          : _buildStickyActionBar(currentOutfit),
      body: SafeArea(
        child: Column(
          children: [
            // Thanh trên: nút quay lại `<` + tiêu đề + bộ đếm
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: AppColors.primary),
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Chi tiết bộ phối',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (showCounter)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.6),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / $total',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Nội dung: vuốt ngang để xem outfit trước/sau
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: total,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final outfit = _detailCache[_pages[index].id] ?? _pages[index];
                  // Ảnh bìa chiếm phần lớn khung hình → cần chiều cao vùng
                  // nhìn thật, đo bằng LayoutBuilder (bỏ AppBar) chứ không
                  // hardcode theo kích thước màn hình.
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (index == _currentIndex) {
                        _currentOutfit = outfit;
                      }
                      return _buildPageContent(outfit, constraints.maxHeight);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(UserOutfitModel outfit, double viewportHeight) {
    final name = outfit.name.isNotEmpty
        ? outfit.name
        : (widget.brief?.name ?? 'Bộ phối trang phục');
    final coverUrl = outfit.coverImageUrl ?? widget.brief?.coverImageUrl;
    final items = outfit.items;
    final isLoading = items.isEmpty && _loadingIds.contains(outfit.id);
      // Ảnh bìa chiếm ~78% chiều cao vùng nhìn, phần còn lại nằm bên dưới.
      // Ảnh nằm trong Container có viền 0.8px → phần ảnh thực nhỏ hơn 1.6px.
      final coverHeight = viewportHeight * kOutfitCoverRatio;

    // Nội dung trang chi tiết ngắn (vài chục món) nên dựng hết một lần:
    // nút hành động nằm dưới ảnh bìa vẫn tồn tại trong cây, chỉ cần cuộn tới.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // Ảnh bìa — bấm để xem toàn màn (nền bổ xung trong suốt)
        if (coverUrl != null && coverUrl.isNotEmpty) ...[
          GestureDetector(
            onTap: () => openMediaViewer(
              context,
              imageUrls: [coverUrl],
              caption: name,
            ),
            child: Container(
              height: coverHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ClosyNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.contain,
                      memCacheWidth: 1000,
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Phóng to',
                              style: TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Tên + ngày
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (outfit.formattedDate.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 0.6),
                ),
                child: Text(
                  outfit.formattedDate,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
          ],
        ),

        if (outfit.description != null && outfit.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            outfit.description!,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],

        const SizedBox(height: 20),

        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          )
        else if (items.isNotEmpty) ...[
          _buildItemsDropdown(items),
        ],

        // Hành động nằm ở thanh dính đáy (bottomNavigationBar).
        const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Thanh hành động dính đáy màn hình: luôn nhìn thấy dù cuộn lên/xuống.
  Widget _buildStickyActionBar(UserOutfitModel outfit) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: <Widget>[
              if (widget.onDelete != null) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onDelete!();
                  },
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.redAccent),
                  label: const Text('Xoá',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 0.8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openInStudio(outfit),
                  icon: const Icon(Icons.style_outlined, size: 18),
                  label: Text(
                    'Xem bộ phối trong studio',
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dropdown "Các món đồ trong set" — mặc định thu gọn, bấm tiêu đề để
  /// mở/đóng danh sách món.
  Widget _buildItemsDropdown(List<OutfitItemDetailModel> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bấm được, cao ≥44px để dễ chạm.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _itemsExpanded = !_itemsExpanded),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Các món đồ trong set (${items.length} món)',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _itemsExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Danh sách món — co giãn mượt khi mở/đóng.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _itemsExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: items
                          .map((item) => Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _buildItemTile(item),
                              ))
                          .toList(),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(OutfitItemDetailModel item) {
    final fItem = item.fashionItem;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: fItem != null && fItem.imageUrl.isNotEmpty
                  ? ClosyNetworkImage(
                      imageUrl: fItem.imageUrl,
                      fit: BoxFit.contain,
                      memCacheWidth: 150,
                    )
                  : const Icon(Icons.checkroom,
                      size: 24, color: AppColors.accentSandDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fItem?.category?.name ?? 'Món đồ thời trang',
                  style:
                      GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (fItem?.style != null && fItem!.style!.isNotEmpty)
                  Text(
                    fItem.style!,
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          if (fItem?.colorHex != null && fItem!.colorHex!.isNotEmpty)
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _parseColorHex(fItem.colorHex!),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 0.8),
              ),
            ),
        ],
      ),
    );
  }

  Color _parseColorHex(String hex) {
    try {
      var clean = hex.replaceAll('#', '');
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse('0x$clean'));
    } catch (_) {
      return Colors.transparent;
    }
  }
}
