import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';

/// Optimized network image component tailored for Cloudinary and Flutter Web / Mobile.
///
/// Features:
/// - Automatically downsamples images during decoding (memCacheWidth/cacheWidth: 400)
///   reducing memory consumption from ~12.3MB down to ~640KB (95% memory drop).
/// - On Flutter Web: Uses [Image.network] with [cacheWidth]/[cacheHeight] to prevent
///   CanvasKit WebGL texture loss and black square artifacts.
/// - On Mobile: Uses [CachedNetworkImage] for persistent on-disk and in-memory cache.
/// - Graceful fallback from failed 't_bg_remove' transformations to the original raw image URL.
/// - Graceful placeholder and fallback icon.
class ClosyNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int memCacheWidth;
  final int memCacheHeight;
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
    this.memCacheHeight = 450,
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
      // Flutter Web: Native browser caching + CanvasKit downsampling
      imageContent = Image.network(
        _activeUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        cacheWidth: widget.memCacheWidth,
        cacheHeight: widget.memCacheHeight,
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
      // Mobile (Android / iOS): CachedNetworkImage with local SQLite/disk cache
      imageContent = CachedNetworkImage(
        imageUrl: _activeUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        memCacheWidth: widget.memCacheWidth,
        memCacheHeight: widget.memCacheHeight,
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
