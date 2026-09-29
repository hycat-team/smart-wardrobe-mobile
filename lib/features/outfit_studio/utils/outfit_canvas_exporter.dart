import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/outfit_models.dart';

/// Bộ trích xuất và xuất ảnh chụp bộ phối Studio chuẩn Quiet Luxury.
/// Đảm bảo luôn chụp ĐẦY ĐỦ toàn bộ trang phục trên Canvas thay vì chỉ 1 món.
class OutfitCanvasExporter {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.bytes,
    ),
  );

  /// Chụp trực tiếp từ RenderRepaintBoundary của Canvas
  static Future<Uint8List?> captureFromBoundary(GlobalKey boundaryKey, {double pixelRatio = 2.0}) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('[OutfitCanvasExporter] RepaintBoundary context is null');
        return null;
      }
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes != null && bytes.isNotEmpty) {
        debugPrint('[OutfitCanvasExporter] RepaintBoundary capture success: ${bytes.lengthInBytes} bytes');
        return bytes;
      }
    } catch (e) {
      debugPrint('[OutfitCanvasExporter] RepaintBoundary capture failed: $e (Falling back to composite)');
    }
    return null;
  }

  /// Ghép ảnh toàn bộ trang phục độc lập bằng Canvas/PictureRecorder.
  /// Tuyệt đối an toàn trước lỗi Tainted Canvas (CORS Web) và StateError: Boundary not clean.
  static Future<Uint8List?> compositeOutfitToBytes({
    required List<CanvasItem> items,
    required double canvasWidth,
    required double canvasHeight,
    double pixelRatio = 2.0,
  }) async {
    if (items.isEmpty) return null;

    final targetW = (canvasWidth > 0 ? canvasWidth : 400.0) * pixelRatio;
    final targetH = (canvasHeight > 0 ? canvasHeight : 500.0) * pixelRatio;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, targetW, targetH));

      // 1. Nền Quiet Luxury ấm áp (#FAFAFA)
      final bgPaint = Paint()..color = const Color(0xFFFAFAFA);
      canvas.drawRect(Rect.fromLTWH(0, 0, targetW, targetH), bgPaint);

      final centerX = targetW / 2;
      final centerY = targetH / 2;
      const double itemScaleMultiplier = 1.25;

      // Sắp xếp theo layerOrder (lớp dưới vẽ trước, lớp trên vẽ sau)
      final sortedItems = List<CanvasItem>.from(items)
        ..sort((a, b) => a.layerOrder.compareTo(b.layerOrder));

      for (final item in sortedItems) {
        if (item.imageUrl.isEmpty) continue;
        try {
          final image = await _fetchUiImage(item.imageUrl);
          if (image == null) continue;

          final baseS = item.baseScale > 0 ? item.baseScale : 100.0;
          final ratioW = item.boxRatioW > 0 ? item.boxRatioW : 2.0;
          final ratioH = item.boxRatioH > 0 ? item.boxRatioH : 2.0;

          final itemW = baseS * ratioW * item.scale * itemScaleMultiplier * pixelRatio;
          final itemH = baseS * ratioH * item.scale * itemScaleMultiplier * pixelRatio;

          final left = centerX + (item.positionX * pixelRatio) - (itemW / 2);
          final top = centerY + (item.positionY * pixelRatio) - (itemH / 2);

          final dstRect = Rect.fromLTWH(left, top, itemW, itemH);
          final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

          final fitted = applyBoxFit(BoxFit.contain, srcRect.size, dstRect.size);
          final sourceRect = Alignment.center.inscribe(fitted.source, srcRect);
          final destinationRect = Alignment.center.inscribe(fitted.destination, dstRect);

          final paint = Paint()..filterQuality = ui.FilterQuality.medium;
          canvas.drawImageRect(image, sourceRect, destinationRect, paint);
        } catch (itemErr) {
          debugPrint('[OutfitCanvasExporter] Error compositing item ${item.name}: $itemErr');
        }
      }

      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(targetW.toInt(), targetH.toInt());
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      debugPrint('[OutfitCanvasExporter] Programmatic composite success: ${bytes?.lengthInBytes} bytes');
      return bytes;
    } catch (e) {
      debugPrint('[OutfitCanvasExporter] Programmatic composite failed: $e');
      return null;
    }
  }

  /// Tải và decode hình ảnh thành ui.Image qua byte buffer
  static Future<ui.Image?> _fetchUiImage(String url) async {
    try {
      final res = await _dio.get<List<int>>(url);
      if (res.data != null && res.data!.isNotEmpty) {
        final codec = await ui.instantiateImageCodec(Uint8List.fromList(res.data!));
        final frame = await codec.getNextFrame();
        return frame.image;
      }
    } catch (e) {
      debugPrint('[OutfitCanvasExporter] Failed fetching $url: $e');
    }
    return null;
  }

  /// Chụp toàn diện: thử RepaintBoundary trước, nếu lỗi tự động composite toàn bộ món đồ
  static Future<Uint8List?> captureFullOutfit({
    required GlobalKey boundaryKey,
    required List<CanvasItem> items,
    required double canvasWidth,
    required double canvasHeight,
  }) async {
    // 1. Thử boundary nhanh
    final boundaryBytes = await captureFromBoundary(boundaryKey);
    if (boundaryBytes != null && boundaryBytes.isNotEmpty) {
      return boundaryBytes;
    }

    // 2. Fallback composite độc lập
    debugPrint('[OutfitCanvasExporter] Boundary returned null, executing composite fallback...');
    return await compositeOutfitToBytes(
      items: items,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
    );
  }
}
