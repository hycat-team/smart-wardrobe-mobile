import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import 'closy_network_image.dart';

/// Mở ảnh toàn màn hình (overlay đen) — dùng chung cho bài đăng cộng đồng và
/// trang chi tiết outfit.
///
/// - [useRootNavigator] + `showGeneralDialog` để không bị "dismissed by
///   another route" khi mở từ bottom sheet / route lồng nhau.
/// - Ảnh **cố định**: ở mức zoom 1 ảnh vừa trọn khung và **không kéo được**;
///   pinch để zoom, khi đang zoom mới kéo được (chặn tại mép ảnh, không hở viền).
/// - Vuốt ngang để đổi ảnh (khi có nhiều ảnh).
/// - **Đóng bằng cách tap vùng trống ngoài ảnh** (không có nút đóng).
/// - **Nền trắng phủ đúng khung ảnh** (không phải trắng cả màn hình): ảnh có
///   nền sáng không còn bị "cắt" khỏi nền tối; vùng ngoài ảnh vẫn là nền bổ
///   sung **trong suốt** (`kMediaViewerBarrierColor`) để nhìn thấy nhẹ nội
///   dung phía sau, và chip đếm ảnh / tên set vẫn nằm trên nền tối.
Future<void> openMediaViewer(
  BuildContext context, {
  required List<String> imageUrls,
  int initialIndex = 0,
  String? caption,
}) {
  final urls =
      imageUrls.where((u) => u.trim().isNotEmpty).toList(growable: false);
  if (urls.isEmpty) return Future<void>.value();

  final index = initialIndex.clamp(0, urls.length - 1);

  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierColor: kMediaViewerBarrierColor,
    barrierLabel: 'Xem ảnh',
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => MediaViewerOverlay(
      imageUrls: urls,
      initialIndex: index,
      caption: caption,
    ),
  );
}

/// Màu nền bổ xung trong suốt — dùng chung với trình phát video
/// (`media_grid.dart` → `_showVideoPlayer`) để ảnh và video đồng nhất.
const Color kMediaViewerBarrierColor = Color(0xD9000000); // ~87% đen

/// Overlay xem ảnh toàn màn hình.
class MediaViewerOverlay extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? caption;

  const MediaViewerOverlay({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.caption,
  });

  @override
  State<MediaViewerOverlay> createState() => _MediaViewerOverlayState();
}

class _MediaViewerOverlayState extends State<MediaViewerOverlay> {
  late final PageController _pageController;
  late int _currentIndex;

  /// Điều khiển zoom/kéo của ảnh hiện tại.
  final TransformationController _transformController =
      TransformationController();

  /// true khi ảnh đang zoom (> 1) → mới cho phép kéo.
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _transformController.addListener(_onTransform);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransform);
    _transformController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTransform() {
    final zoomed =
        _transformController.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  /// Chuyển ảnh: reset zoom về 1 để ảnh mới luôn cố định.
  void _onPageChanged(int index) {
    _transformController.value = Matrix4.identity();
    setState(() {
      _currentIndex = index;
      _isZoomed = false;
    });
  }

  /// Khi nhả tay mà ảnh về đúng mức 1 → snap lại căn giữa cho chắc.
  void _onInteractionEnd() {
    if (_transformController.value.getMaxScaleOnAxis() <= 1.01) {
      _transformController.value = Matrix4.identity();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imageUrls.length;

    return Scaffold(
      // Trong suốt để lộ nền bổ sung 87% đen phía sau, đồng bộ với video.
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Lớp 1: phủ toàn màn — tap VÙNG TRỐNG (ngoài ảnh) để đóng.
          // Ảnh bên trong tự hấp thụ tap của nó (xem `_buildPage`).
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: total == 1
                  ? _buildPage(0)
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: total,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) => _buildPage(index),
                    ),
            ),
          ),

          // Bộ đếm ảnh (chỉ khi có nhiều ảnh) — không chặn tap.
          if (total > 1)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: IgnorePointer(
                  child: Container(
                    margin: const EdgeInsets.all(14),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0x66000000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / $total',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Tên outfit (nếu có) — không chặn tap.
          if (widget.caption != null && widget.caption!.trim().isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: IgnorePointer(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x59000000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.caption!.trim(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 1.0,
      maxScale: 4.0,
      // Không dùng boundaryMargin → ảnh bị chặn đúng mép, không hở viền.
      boundaryMargin: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      // Chỉ kéo được khi đang zoom; chưa zoom thì ảnh cố định.
      panEnabled: _isZoomed,
      scaleEnabled: true,
      trackpadScrollCausesScale: false,
      onInteractionEnd: (_) => _onInteractionEnd(),
      child: Center(
        // FittedBox giữ ảnh vừa trọn khung, đúng tỉ lệ gốc.
        child: GestureDetector(
          // Callback rỗng: chỉ "nuốt" tap TRONG vùng ảnh để không đóng
          // nhầm. Tap ngoài ảnh rơi xuống GestureDetector phủ toàn màn ở trên.
          onTap: () {},
          child: FittedBox(
            fit: BoxFit.contain,
            // Nền trắng **đúng khung ảnh**: ảnh bìa outfit, ảnh sản phẩm và
            // avatar đều có nền sáng. Trước đây ảnh nổi thành một mảng trắng
            // bị cắt khỏi nền tối 87% đen nên thấy rõ mép. Bọc `ColoredBox` ngay
            // sau ảnh (trong `FittedBox`) để trắng phủ đúng bề rộng/cao của ảnh
            // — vùng ngoài khung ảnh vẫn giữ nền tối, chip đếm ảnh và tên set
            // vẫn đọc tốt trên nền tối.
            //
            // Bọc trong `FittedBox` (child được layout với constraint không
            // chặn) nên `ColoredBox` ôm đúng kích thước tự nhiên của ảnh, tự
            // co theo tỉ lệ gốc thay vì giãn hết khung.
            child: ColoredBox(
              color: Colors.white,
              child: ClosyNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
                memCacheWidth: 1200,
                errorWidget: Container(
                  color: AppColors.surfaceSubtle,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textSecondary,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Không tải được ảnh',
                        style: GoogleFonts.beVietnamPro(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
