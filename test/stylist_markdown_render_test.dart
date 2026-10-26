import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/stylist/presentation/widgets/stylist_markdown_text.dart';

Future<void> _pump(WidgetTester tester, String data, {bool isUser = false}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StylistMarkdownText(data: data, isUser: isUser),
      ),
    ),
  );
}

Iterable<TextSpan> _leafSpans(InlineSpan span) sync* {
  if (span is! TextSpan) return;
  if (span.text != null && span.text!.isNotEmpty) yield span;
  final children = span.children;
  if (children != null) {
    for (final child in children) {
      yield* _leafSpans(child);
    }
  }
}

Iterable<TextSpan> _allSpans(WidgetTester tester) => tester
    .widgetList<RichText>(find.byType(RichText))
    .expand((rt) => _leafSpans(rt.text));

void main() {
  testWidgets('Markdown có đậm + danh sách render, không lộ ký tự thô',
      (tester) async {
    await _pump(tester, '**đậm**\n\n- mục một\n- mục hai');
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownBody), findsOneWidget);

    final spans = _allSpans(tester).toList();
    final bold = spans.firstWhere(
      (s) => s.text == 'đậm',
      orElse: () => throw StateError('Không tìm thấy span đậm'),
    );
    expect(bold.style?.fontWeight, FontWeight.w700);
    expect(spans.any((s) => (s.text ?? '').contains('**')), isFalse);
  });

  testWidgets('Văn bản thuần render an toàn', (tester) async {
    await _pump(tester, 'Chào bạn, đây là văn bản thuần.');
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(
      _allSpans(tester).any(
        (s) => (s.text ?? '').contains('văn bản thuần'),
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Markdown chưa đóng render an toàn, không ném exception',
      (tester) async {
    await _pump(tester, '**chưa đóng\n\n```\nmã chưa đóng');
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Chuỗi chứa escaped \\n từ SSE stream được render thành Markdown chuẩn',
      (tester) async {
    // Giả lập chuỗi nhận từ live chat có ký tự literal \n thay vì byte 0x0A
    const rawStreamText =
        '**Gợi ý phối đồ:**\\n- Áo sơ mi trắng\\n- Quần âu xếp ly';
    await _pump(tester, rawStreamText);
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownBody), findsOneWidget);
    final spans = _allSpans(tester).toList();
    final bold = spans.firstWhere(
      (s) => s.text == 'Gợi ý phối đồ:',
      orElse: () => throw StateError('Không tìm thấy span đậm'),
    );
    expect(bold.style?.fontWeight, FontWeight.w700);
    expect(spans.any((s) => (s.text ?? '').contains(r'\n')), isFalse);
  });
}
