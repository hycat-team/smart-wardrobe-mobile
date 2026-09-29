import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/shared/widgets/closy_toast.dart';

void main() {
  testWidgets('ClosyToast renders top pop-up notification with correct message and type', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    ClosyToast.error(
                      context,
                      'Bạn đã dùng hết lượt tạo trang phục bằng AI trong hôm nay.',
                    );
                  },
                  child: const Text('Show Toast'),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Tap button to show toast
    await tester.tap(find.text('Show Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Toast message and error icon should be visible
    expect(find.text('Bạn đã dùng hết lượt tạo trang phục bằng AI trong hôm nay.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

    // Verify it is positioned near the top of the screen
    final toastFinder = find.text('Bạn đã dùng hết lượt tạo trang phục bằng AI trong hôm nay.');
    final topLeft = tester.getTopLeft(toastFinder);
    expect(topLeft.dy, lessThan(120.0)); // Top area of the screen

    // After 2 seconds + reverse animation, toast should be gone
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Bạn đã dùng hết lượt tạo trang phục bằng AI trong hôm nay.'), findsNothing);
  });

  testWidgets('ClosyToast dismisses immediately on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    ClosyToast.success(context, 'Thao tác thành công');
                  },
                  child: const Text('Show Success'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Success'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Thao tác thành công'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

    // Tap on the toast to dismiss early
    await tester.tap(find.text('Thao tác thành công'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Thao tác thành công'), findsNothing);
  });
}
