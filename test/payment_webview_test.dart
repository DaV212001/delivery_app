import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/screens/wallet/payment_webview_screen.dart';

void main() {
  group('PaymentWebViewScreen Receipt URL Detection Tests', () {
    test('isReceiptUrl detects receipt in path', () {
      expect(
        PaymentWebViewScreen.isReceiptUrl('https://checkout.chapa.co/checkout/receipt/6c65342a-9286-4f40-845b-381dd006b5b5'),
        isTrue,
      );
      expect(
        PaymentWebViewScreen.isReceiptUrl('https://api.amnplc.com/payment/receipt/4582'),
        isTrue,
      );
    });

    test('isReceiptUrl detects receipt in query parameters', () {
      expect(
        PaymentWebViewScreen.isReceiptUrl('https://checkout.chapa.co/callback?status=success&view=receipt'),
        isTrue,
      );
      expect(
        PaymentWebViewScreen.isReceiptUrl('https://api.amnplc.com/checkout?receipt_id=98721'),
        isTrue,
      );
    });

    test('isReceiptUrl is case insensitive', () {
      expect(
        PaymentWebViewScreen.isReceiptUrl('https://checkout.chapa.co/checkout/RECEIPT/12345'),
        isTrue,
      );
      expect(
        PaymentWebViewScreen.isReceiptUrl('https://checkout.chapa.co/checkout/Receipt/abc'),
        isTrue,
      );
    });

    test('isReceiptUrl returns false for non-receipt URLs', () {
      expect(
        PaymentWebViewScreen.isReceiptUrl('https://checkout.chapa.co/checkout/web/6c65342a-9286-4f40-845b-381dd006b5b5'),
        isFalse,
      );
      expect(
        PaymentWebViewScreen.isReceiptUrl('https://api.amnplc.com/api/wallet-payment'),
        isFalse,
      );
      expect(
        PaymentWebViewScreen.isReceiptUrl('https://telebirr.et/pay?id=123'),
        isFalse,
      );
      expect(
        PaymentWebViewScreen.isReceiptUrl(''),
        isFalse,
      );
    });
  });

  group('Payment Flow Logic Verification', () {
    test('Receipt detection triggers callback', () async {
      bool callbackInvoked = false;

      Future<void> onReceipt() async {
        callbackInvoked = true;
      }

      // Simulate URL evaluation during redirection
      const testUrl = 'https://checkout.chapa.co/checkout/receipt/tx-883921';
      if (PaymentWebViewScreen.isReceiptUrl(testUrl)) {
        await onReceipt();
      }

      expect(callbackInvoked, isTrue);
    });
  });
}
