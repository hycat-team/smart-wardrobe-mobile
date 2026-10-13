import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

/// Render nội dung tin nhắn Stylist dạng Markdown theo tông Quiet Luxury.
///
/// Spec 016 — US4 (FR-009): tách thành widget công khai để unit-test được,
/// thay cho `Text(msg.cleanContent)` thô trong `stylist_screen.dart`.
class StylistMarkdownText extends StatelessWidget {
  const StylistMarkdownText({
    super.key,
    required this.data,
    this.isUser = false,
  });

  final String data;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isUser ? const Color(0xFF1A1A1A) : AppColors.textPrimary;
    return MarkdownBody(
      data: data,
      styleSheet: _styleSheet(textColor),
    );
  }

  MarkdownStyleSheet _styleSheet(Color textColor) {
    final body = GoogleFonts.beVietnamPro(
      fontSize: 14,
      color: textColor,
      height: 1.5,
    );
    final heading = GoogleFonts.playfairDisplay(color: textColor);
    final link = GoogleFonts.beVietnamPro(
      fontSize: 14,
      color: AppColors.primary,
      height: 1.5,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );

    return MarkdownStyleSheet(
      p: body,
      a: link,
      em: body.copyWith(fontStyle: FontStyle.italic),
      strong: body.copyWith(fontWeight: FontWeight.w700),
      h1: heading.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      h2: heading.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      h3: heading.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      h4: heading.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      h5: heading.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      h6: heading.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      code: GoogleFonts.beVietnamPro(
        fontSize: 13,
        color: textColor,
        backgroundColor: AppColors.surfaceSubtle,
      ),
      codeblockDecoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      blockquote: GoogleFonts.beVietnamPro(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      blockquoteDecoration: const BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border(
          left: BorderSide(color: AppColors.accentSand, width: 3),
        ),
      ),
      blockquotePadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      listBullet: body,
      blockSpacing: 8,
    );
  }
}
