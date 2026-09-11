import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';

/// Optimized network image component tailored for Cloudinary and Flutter Web / Mobile.
///
/// Features:
/// - Automatically downsamples images during decoding ([memCacheWidth]: 400)
///   reducing memory consumption from ~12.3MB down to ~640KB (95% memory drop).
/// - Decode is constrained by WIDTH ONLY so the source aspect ratio is always
///   preserved: passing both width and height to the decoder forces the bitmap
///   into an exact rectangle and visibly distorts non-square photos.
/// - On Flutter Web: Uses [Image.network] with [cacheWidth] to prevent
///   CanvasKit WebGL texture loss and black square artifacts.
/// - On Mobile: Uses [CachedNetworkImage] for persistent on-disk and in-memory cache.
/// - Graceful fallback from failed 't_bg_remove' transformations to the original raw image URL.
/// - Graceful placeholder and fallback icon.
///
/// Sizing guide (decode width cap per surface):
/// - Grid cards / small thumbs: 150-400 (card ~170-200pt wide, 400 ~= 2x retina).
/// - Full-width detail / cover: 800.
class ClosyNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  /// Decode width cap in pixels. Height scales proportionally to preserve
  /// the source aspect ratio. Never pass a fixed decode height.
  final int memCacheWidth;
  final BorderRadius? borderRadius;

  const ClosyNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth = 450,
    this.borderRadius,
  });

  @override
  State<ClosyNetworkImage> createState() => _ClosyNetworkImageState();
}

class _ClosyNetworkImageState extends State<ClosyNetworkImage> {
  late String _activeUrl;
  bool _hasFallenBackFromTransform = false;

  @override
  void initState() {
    super.initState();
    _activeUrl = widget.imageUrl;
  }

  @override
  void didUpdateWidget(ClosyNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _activeUrl = widget.imageUrl;
      _hasFallenBackFromTransform = false;
    }
  }

  void _handleImageLoadError() {
    // If the URL contains t_bg_remove and failed, attempt fallback to the raw original URL
    if (!_hasFallenBackFromTransform && _activeUrl.contains('/upload/t_bg_remove/')) {
      if (mounted) {
        setState(() {
          _hasFallenBackFromTransform = true;
          _activeUrl = _activeUrl.replaceFirst('/upload/t_bg_remove/', '/upload/');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeUrl.isEmpty) {
      return _buildFallback();
    }

    Widget imageContent;

    if (kIsWeb) {
      // Flutter Web: Native browser caching + CanvasKit downsampling.
      // NOTE: cacheWidth only (no cacheHeight) to preserve aspect ratio.
      imageContent = Image.network(
        _activeUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        cacheWidth: widget.memCacheWidth,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return widget.placeholder ?? _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          if (!_hasFallenBackFromTransform && _activeUrl.contains('/upload/t_bg_remove/')) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _handleImageLoadError());
            return widget.placeholder ?? _buildPlaceholder();
          }
          return widget.errorWidget ?? _buildFallback();
        },
      );
    } else {
      // Mobile (Android / iOS): CachedNetworkImage with local SQLite/disk cache.
      // NOTE: memCacheWidth only (no memCacheHeight) to preserve aspect ratio.
      imageContent = CachedNetworkImage(
        imageUrl: _activeUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        memCacheWidth: widget.memCacheWidth,
        maxWidthDiskCache: 600,
        maxHeightDiskCache: 600,
        filterQuality: FilterQuality.medium,
        placeholder: (ctx, _) => widget.placeholder ?? _buildPlaceholder(),
        errorWidget: (ctx, _, __) {
          if (!_hasFallenBackFromTransform && _activeUrl.contains('/upload/t_bg_remove/')) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _handleImageLoadError());
            return widget.placeholder ?? _buildPlaceholder();
          }
          return widget.errorWidget ?? _buildFallback();
        },
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildPlaceholder() {
    return Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentSand.withOpacity(0.8)),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return const Center(
      child: Icon(
        Icons.checkroom_rounded,
        size: 36,
        color: AppColors.accentSandDark,
      ),
    );
  }
}
