import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// Ô nhập mã OTP 6 chữ số dùng chung cho Đăng ký / Quên mật khẩu.
///
/// Viền ô được vẽ bằng [Container] kích thước cố định thay vì để
/// [InputDecorator] của [TextFormField] tự tính (trạng thái focus làm
/// kích thước/bo góc ô bị lệch so với các ô còn lại).
class OtpInput extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  /// Gọi khi ô cuối cùng được nhập (đủ 6 ký tự) để tự động xác thực.
  final VoidCallback? onCompleted;

  final double boxWidth;
  final double boxHeight;

  const OtpInput({
    super.key,
    required this.controllers,
    required this.focusNodes,
    this.onCompleted,
    this.boxWidth = 44,
    this.boxHeight = 54,
  });

  @override
  Widget build(BuildContext context) {
    assert(controllers.length == focusNodes.length);
    final lastIndex = controllers.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(controllers.length, (index) {
        return _OtpBox(
          controller: controllers[index],
          focusNode: focusNodes[index],
          width: boxWidth,
          height: boxHeight,
          onChanged: (value) {
            if (value.isNotEmpty && index < lastIndex) {
              focusNodes[index + 1].requestFocus();
            } else if (value.isEmpty && index > 0) {
              focusNodes[index - 1].requestFocus();
            }
            if (index == lastIndex && value.isNotEmpty) {
              onCompleted?.call();
            }
          },
        );
      }),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double width;
  final double height;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.width,
    required this.height,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final focused = focusNode.hasFocus;
        return Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focused ? AppColors.primary : AppColors.border,
              width: focused ? 1.8 : 1.0,
            ),
          ),
          child: child,
        );
      },
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          height: 1.0,
        ),
        cursorColor: AppColors.primary,
        cursorWidth: 2,
        cursorHeight: 24,
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          counterText: '',
        ),
        onChanged: onChanged,
      ),
    );
  }
}
