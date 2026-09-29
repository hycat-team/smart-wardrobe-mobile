import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/closy_network_image.dart';
import '../../../../shared/widgets/media_viewer_overlay.dart';
import '../../models/post_models.dart';
import 'community_video_player.dart';

class MediaGrid extends StatelessWidget {
  final List<PostMedia> media;
  final bool enableVideoPlayer;
  final void Function(int index)? onMediaTap;

  const MediaGrid({
    super.key,
    required this.media,
    this.enableVideoPlayer = true,
    this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    // 1 item duy nhất
    if (media.length == 1) {
      final item = media.first;
      if (item.isVideo && enableVideoPlayer) {
        return CommunityVideoPlayer(videoUrl: item.mediaUrl);
      }
      return GestureDetector(
        onTap: () {
          if (item.isVideo) {
            _showVideoPlayer(context, item.mediaUrl);
          } else if (onMediaTap != null) {
            onMediaTap!(0);
          } else {
            _showMediaGallery(context, 0);
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              ClosyNetworkImage(
                imageUrl: item.mediaUrl,
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
              ),
              if (item.isVideo)
                const Positioned.fill(
                  child: Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      radius: 24,
                      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // 2 items
    if (media.length == 2) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(child: _buildMediaItem(context, media[0], 0)),
            const SizedBox(width: 6),
            Expanded(child: _buildMediaItem(context, media[1], 1)),
          ],
        ),
      );
    }

    // 3 items
    if (media.length == 3) {
      return SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildMediaItem(context, media[0], 0),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(child: _buildMediaItem(context, media[1], 1)),
                  const SizedBox(height: 6),
                  Expanded(child: _buildMediaItem(context, media[2], 2)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4 items trở lên (lưới 2x2, item thứ 4 có badge +N nếu > 4)
    final remainingCount = media.length - 4;
    return SizedBox(
      height: 240,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildMediaItem(context, media[0], 0)),
                const SizedBox(width: 6),
                Expanded(child: _buildMediaItem(context, media[1], 1)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildMediaItem(context, media[2], 2)),
                const SizedBox(width: 6),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildMediaItem(context, media[3], 3),
                      if (remainingCount > 0)
                        GestureDetector(
                          onTap: () {
                            if (onMediaTap != null) {
                              onMediaTap!(3);
                            } else {
                              _showMediaGallery(context, 3);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '+$remainingCount',
                                style: GoogleFonts.beVietnamPro(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(BuildContext context, PostMedia item, int index) {
    final isVideo = item.isVideo;
    return GestureDetector(
      onTap: () {
        if (isVideo) {
          _showVideoPlayer(context, item.mediaUrl);
          return;
        }
        if (onMediaTap != null) {
          onMediaTap!(index);
        } else {
          _showMediaGallery(context, index);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isVideo)
              Container(color: const Color(0xFF1E1B18))
            else
              ClosyNetworkImage(
                imageUrl: item.mediaUrl,
                fit: BoxFit.cover,
              ),
            if (isVideo)
              const Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  radius: 20,
                  child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                ),
              ),
            if (isVideo)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Mở trình phát video. Không có nút đóng — tap vùng trống quanh video
  /// (inset padding) để thoát, nhờ `barrierDismissible` mặc định của dialog.
  void _showVideoPlayer(BuildContext context, String videoUrl) {
    showDialog(
      context: context,
      barrierColor: kMediaViewerBarrierColor,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CommunityVideoPlayer(videoUrl: videoUrl, autoPlay: true),
        ),
      ),
    );
  }

  /// Mở ảnh toàn màn hình; danh sách chỉ gồm **ảnh** (video giữ player riêng).
  void _showMediaGallery(BuildContext context, int index) {
    final imageIndexes = <int>[];
    for (var i = 0; i < media.length; i++) {
      if (!media[i].isVideo) imageIndexes.add(i);
    }
    if (imageIndexes.isEmpty) return;
    final initial = imageIndexes.indexOf(index);
    openMediaViewer(
      context,
      imageUrls:
          imageIndexes.map((i) => media[i].mediaUrl).toList(growable: false),
      // Bấm vào ô "+N" hoặc ô video → mở từ ảnh đầu tiên.
      initialIndex: initial < 0 ? 0 : initial,
    );
  }
}

