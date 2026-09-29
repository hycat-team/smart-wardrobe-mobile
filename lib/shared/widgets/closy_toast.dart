import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_wardrobe/core/router/app_router.dart';

enum ClosyToastType {
  error,
  warning,
  success,
  info,
}

/// Unified Top Pop-up Toast tuân thủ hệ thiết kế Quiet Luxury
/// Tự động hiển thị ở đỉnh màn hình (bên dưới Safe Area) trong 2 giây rồi tự ẩn.
class ClosyToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext? context, {
    required String message,
    ClosyToastType type = ClosyToastType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    hide();

    final overlayState = context != null
        ? Overlay.maybeOf(context, rootOverlay: true) ?? rootNavigatorKey.currentState?.overlay
        : rootNavigatorKey.currentState?.overlay;

    if (overlayState == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ClosyToastOverlayWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          if (_currentEntry == entry) {
            hide();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  static void error(
    BuildContext? context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    show(context, message: message, type: ClosyToastType.error, duration: duration);
  }

  static void success(
    BuildContext? context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    show(context, message: message, type: ClosyToastType.success, duration: duration);
  }

  static void warning(
    BuildContext? context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    show(context, message: message, type: ClosyToastType.warning, duration: duration);
  }

  static void info(
    BuildContext? context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    show(context, message: message, type: ClosyToastType.info, duration: duration);
  }

  static void hide() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentEntry != null) {
      try {
        _currentEntry?.remove();
      } catch (_) {}
      _currentEntry = null;
    }
  }
}

class _ClosyToastOverlayWidget extends StatefulWidget {
  final String message;
  final ClosyToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ClosyToastOverlayWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ClosyToastOverlayWidget> createState() => _ClosyToastOverlayWidgetState();
}

class _ClosyToastOverlayWidgetState extends State<_ClosyToastOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    // Tự động đóng sau đúng thời lượng quy định (mặc định 2 giây)
    _autoDismissTimer = Timer(widget.duration, () {
      _dismissWithAnimation();
    });
  }

  void _dismissWithAnimation() {
    if (!mounted) return;
    _autoDismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top > 0 ? mediaQuery.padding.top + 8 : 44.0;

    final style = _resolveStyle(widget.type);

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: Material(
        type: MaterialType.transparency,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _offsetAnimation,
            child: GestureDetector(
              onTap: _dismissWithAnimation,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -4) {
                  _dismissWithAnimation();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: style.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: style.borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(style.icon, color: style.iconColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: style.textColor,
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: style.textColor.withOpacity(0.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastStyle _resolveStyle(ClosyToastType type) {
    switch (type) {
      case ClosyToastType.error:
        return const _ToastStyle(
          backgroundColor: Color(0xFFFFF6F6),
          borderColor: Color(0xFFF1D2D0),
          iconColor: Color(0xFFB44439),
          icon: Icons.error_outline_rounded,
          textColor: Color(0xFF6E2822),
        );
      case ClosyToastType.warning:
        return const _ToastStyle(
          backgroundColor: Color(0xFFFFFDF5),
          borderColor: Color(0xFFEDE0C8),
          iconColor: Color(0xFFA67C33),
          icon: Icons.warning_amber_rounded,
          textColor: Color(0xFF594119),
        );
      case ClosyToastType.success:
        return const _ToastStyle(
          backgroundColor: Color(0xFFF6FAF7),
          borderColor: Color(0xFFD6E8DB),
          iconColor: Color(0xFF2E6F40),
          icon: Icons.check_circle_outline_rounded,
          textColor: Color(0xFF1E482B),
        );
      case ClosyToastType.info:
        return const _ToastStyle(
          backgroundColor: Color(0xFFFAF8F5),
          borderColor: Color(0xFFE8E3DC),
          iconColor: Color(0xFF6B665E),
          icon: Icons.info_outline_rounded,
          textColor: Color(0xFF2C2A29),
        );
    }
  }
}

class _ToastStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final IconData icon;
  final Color textColor;

  const _ToastStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
    required this.textColor,
  });
}
