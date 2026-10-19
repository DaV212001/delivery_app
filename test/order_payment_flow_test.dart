import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/models/order.dart';
import 'package:delivery_app/models/property_delivery_option.dart';
import 'package:delivery_app/controllers/cart_controller.dart';
import 'package:delivery_app/screens/wallet/payment_webview_screen.dart';
import 'package:delivery_app/utils/location_utils.dart';
import 'package:delivery_app/data/mock_data.dart';

void main() {
  group('Order & Payment Flow New Specifications Tests', () {
    test('OrderCreateRequest serializes with exact required keys and values', () {
      const request = OrderCreateRequest(
        customerId: 1,
        location: 'Bole Road, Addis Ababa',
        date: '2026-10-19T10:31:15.000000Z',
        paymentType: '0',
        totalQuantity: 3,
        menuIds: [101, 102],
        quantities: [2, 1],
        prices: [150.00, 250.00],
        itemTotalPrice: 550.00,
        totalItem: 2,
        propertyId: 1,
        customerLatitude: 9.0320,
        customerLongitude: 38.7469,
        propertyLatitude: 9.0320,
        propertyLongitude: 38.7469,
        deliveryOption: 1,
        kmPrice: 13,
        totalKmPrice: 130,
      );

      final json = request.toJson();

      expect(json['customer_id'], 1);
      expect(json['location'], 'Bole Road, Addis Ababa');
      expect(json['date'], '2026-10-19T10:31:15.000000Z');
      expect(json['payment_type'], '0');
      expect(json['total_quantity'], 3);
      expect(json['menu_id'], [101, 102]);
      expect(json['quantity'], [2, 1]);
      expect(json['price'], [150.00, 250.00]);
      expect(json['item_total_price'], 550.00);
      expect(json['total_item'], 2);
      expect(json['property_id'], 1);
      expect(json['customer_latitude'], 9.0320);
      expect(json['customer_longitude'], 38.7469);
      expect(json['property_latitude'], 9.0320);
      expect(json['property_longitude'], 38.7469);
      expect(json['delivery_option'], 1);
      expect(json['km_price'], 13);
      expect(json['total_km_price'], 130);
    });

    test('PropertyDeliveryOption model parses backend response', () {
      final json = {
        'id': null,
        'image': 'https://api.amnplc.com/assets/images%20(78).jpeg',
        'name': 'MoterBick',
        'km_price': '13',
      };

      final option = PropertyDeliveryOption.fromJson(json);
      expect(option.id, isNull);
      expect(option.name, 'MoterBick');
      expect(option.kmPrice, 13.0);
      expect(option.image, 'https://api.amnplc.com/assets/images%20(78).jpeg');
    });

    test('Haversine distance calculation and total_km_price derivation', () {
      // Coordinate pair: Addis Ababa Bole to Piassa (~6 km)
      final distance = LocationUtils.calculateDistanceInKm(
        lat1: 9.0054,
        lon1: 38.7636,
        lat2: 9.0300,
        lon2: 38.7500,
      );

      expect(distance, greaterThan(2.0));
      expect(distance, lessThan(6.0));

      const kmPrice = 13.0;
      final totalKmPrice = double.parse((kmPrice * distance).toStringAsFixed(2));
      expect(totalKmPrice, greaterThan(26.0));
      expect(totalKmPrice, lessThan(78.0));
    });

    test('CartController calculates totalKmPrice and total = item_total_price + total_km_price', () {
      final cart = CartController();
      cart.clearCart();

      cart.addItem(
        item: MockData.freshStrawberries, // price 5.49
        quantity: 2,
      );
      expect(cart.subtotal, closeTo(10.98, 0.01));

      // Set coordinates 10 km apart
      cart.customerLatitude.value = 9.0000;
      cart.customerLongitude.value = 38.7000;
      cart.propertyLatitude.value = 9.0900;
      cart.propertyLongitude.value = 38.7000;

      const option = PropertyDeliveryOption(
        id: 1,
        image: '',
        name: 'MoterBick',
        kmPrice: 13.0,
      );
      cart.selectedDeliveryOption.value = option;

      final dist = cart.distanceInKm;
      expect(dist, greaterThan(9.0));
      expect(cart.totalKmPrice, closeTo(dist * 13.0, 0.05));
      expect(cart.total, closeTo(cart.subtotal + cart.totalKmPrice, 0.05));
    });

    test('Cash payment is only available for orders under 2000 ETB', () {
      final cart = CartController();
      cart.clearCart();

      // Small item: total < 2000
      cart.addItem(item: MockData.freshStrawberries, quantity: 2);
      expect(cart.total, lessThan(2000.0));
      expect(cart.isCashAllowed, isTrue);

      // Add expensive items so total exceeds 2000
      cart.addItem(
        item: MockData.ancEarbuds, // 89.99 * 25 > 2000
        quantity: 25,
      );
      expect(cart.total, greaterThan(2000.0));
      expect(cart.isCashAllowed, isFalse);
    });

    test('PaymentWebViewScreen detects receipt URL correctly', () {
      expect(PaymentWebViewScreen.isReceiptUrl('https://api.amnplc.com/receipt/12345'), isTrue);
      expect(PaymentWebViewScreen.isReceiptUrl('https://checkout.chapa.co/payment/receipt?ref=abc'), isTrue);
      expect(PaymentWebViewScreen.isReceiptUrl('https://checkout.chapa.co/checkout/payment/123'), isFalse);
    });

    test('CartController paymentTypeNumeric returns correct code for payment methods', () {
      final cart = CartController();

      cart.selectedPaymentMethod.value = 'cash';
      expect(cart.paymentTypeNumeric, '0');

      cart.selectedPaymentMethod.value = 'chapa';
      expect(cart.paymentTypeNumeric, '1');

      cart.selectedPaymentMethod.value = 'wallet';
      expect(cart.paymentTypeNumeric, '2');
    });
  });
}
