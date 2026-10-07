import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/auth/presentation/widgets/splash_screen.dart';

/// Spec 015 — FR-005 / SC-002: ngưỡng 1 giây của màn hình khởi động.
///
/// Widget thật nằm trong `main.dart` (private `_SplashGate`) nên ở đây dựng lại
/// đúng cơ chế: giữ splash cho tới khi `settled` hoặc hết ngân sách 1 giây, và
/// bắt buộc đã vẽ ít nhất một frame trước khi ẩn.
class SplashGateHarness extends StatefulWidget {
  final bool isChecking;
  final VoidCallback onSplashShown;

  const SplashGateHarness({
    super.key,
    required this.isChecking,
    required this.onSplashShown,
  });

  @override
  State<SplashGateHarness> createState() => _SplashGateHarnessState();
}

class _SplashGateHarnessState extends State<SplashGateHarness> {
  static const Duration maxVisible = Duration(seconds: 1);

  bool _painted = false;
  bool _timedOut = false;
  bool _reported = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _painted = true);
    });
    _timer = Timer(maxVisible, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hide = _timedOut || (_painted && !widget.isChecking);
    if (hide) return const Text('APP');
    if (!_reported) {
      _reported = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onSplashShown());
    }
    return const SplashScreen();
  }
}

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('SC-002 — splash hiện ở lần mở app đầu tiên', (tester) async {
    var shown = false;
    await tester.pumpWidget(wrap(SplashGateHarness(
      isChecking: true,
      onSplashShown: () => shown = true,
    )));

    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump();
    expect(shown, isTrue, reason: 'splash phải được vẽ ra, không chỉ dựng cây');
  });

  testWidgets('FR-005 — kiểm tra xong sớm thì ẩn ngay, không thêm độ trễ',
      (tester) async {
    await tester.pumpWidget(wrap(SplashGateHarness(
      isChecking: true,
      onSplashShown: () {},
    )));
    expect(find.byType(SplashScreen), findsOneWidget);

    // Máy chủ trả lời nhanh: chuyển sang "đã xong".
    await tester.pumpWidget(wrap(SplashGateHarness(
      isChecking: false,
      onSplashShown: () {},
    )));

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('APP'), findsOneWidget);
  });

  testWidgets('FR-005 — kiểm tra chậm thì splash tự ẩn sau 1 giây',
      (tester) async {
    await tester.pumpWidget(wrap(SplashGateHarness(
      isChecking: true,
      onSplashShown: () {},
    )));
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(SplashScreen), findsOneWidget,
        reason: 'chưa hết ngân sách 1 giây thì phải giữ splash');

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(SplashScreen), findsNothing,
        reason: 'quá 1 giây thì bắt buộc ẩn dù máy chủ còn chậm');
    expect(find.text('APP'), findsOneWidget);
  });
}
