import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/profile/models/user_profile_models.dart';
import 'package:smart_wardrobe/core/deeplink/payment_deeplink_handler.dart';

void main() {
  test('PayOS success append (code=00&status=PAID) -> success', () {
    final r = PaymentResult.fromQuery({
      'result': 'success',
      'kind': 'topup',
      'amount': '100000',
      'code': '00',
      'id': 'abc123',
      'cancel': 'false',
      'status': 'PAID',
      'orderCode': '987654',
    });
    expect(r.status, PaymentResultStatus.success);
    expect(r.orderCode, 987654);
    expect(r.amount, 100000);
    expect(r.isTopUp, isTrue);
  });

  test('PayOS cancel (cancel=true) -> cancelled', () {
    final r = PaymentResult.fromQuery({
      'result': 'success',
      'kind': 'purchase',
      'code': '01',
      'cancel': 'true',
      'status': 'CANCELLED',
      'orderCode': '111',
    });
    expect(r.status, PaymentResultStatus.cancelled);
    expect(r.isTopUp, isFalse);
  });

  test('own web returnUrl without PayOS params -> fallback works', () {
    final r = PaymentResult.fromQuery({
      'result': 'cancelled',
      'kind': 'topup',
      'amount': '50000',
    });
    expect(r.status, PaymentResultStatus.cancelled);
    expect(r.formattedAmount, '50.000 đ');
  });

  test('deep-link keeps PayOS query when mapping to result route', () {
    final route = PaymentDeepLinkHandler.mapForTest(Uri.parse(
        'smartwardrobe://wallet/topup/success?code=00&cancel=false&status=PAID&orderCode=555'));
    expect(route, isNotNull);
    expect(route, contains('/profile/payment/result'));
    expect(route, contains('status=PAID'));
    expect(route, contains('orderCode=555'));
    final parsed = Uri.parse('https://x$route');
    final r = PaymentResult.fromQuery(parsed.queryParameters);
    expect(r.status, PaymentResultStatus.success);
  });

  test('PaymentReturnUrls embeds amount, uses result param', () {
    final u = PaymentReturnUrls.forTopUp(
        isWeb: true, webOrigin: 'https://app.vercel.app', amount: 200000);
    expect(u.returnUrl, contains('result=success'));
    expect(u.returnUrl, contains('amount=200000'));
    expect(u.cancelUrl, contains('result=cancelled'));
  });
}
