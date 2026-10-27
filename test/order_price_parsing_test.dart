import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/models/order.dart';

void main() {
  group('OrderModel Price & Currency Parsing Tests', () {
    test('Correctly calculates total when payment_amount is "0" but item_total_price is present', () {
      final jsonOrder15 = {
        'id': 15,
        'property_id': '3',
        'date_only': '2026-10-05',
        'customer_id': '2',
        'location': 'Office',
        'status': '0',
        'payment_type': '0',
        'payment_status': '0',
        'total_quantity': '1',
        'item_total_price': '77.09',
        'delivery_option_id': '0',
        'km_price': '0',
        'total_km_price': '0',
        'payment_amount': '0',
        'total_item': '1',
        'currency_id': '1',
      };

      final order15 = OrderModel.fromActiveOrderJson(jsonOrder15);
      expect(order15.total, 77.09);
      expect(order15.subtotal, 77.09);
      expect(order15.deliveryFee, 0.0);
      expect(order15.displayCurrency, 'ETB');

      final jsonOrder24 = {
        'id': 24,
        'property_id': '3',
        'date_only': '2026-10-13',
        'customer_id': '2',
        'location': 'niyo',
        'status': '0',
        'payment_type': '0',
        'payment_status': '0',
        'total_quantity': '1',
        'item_total_price': '21728.39',
        'delivery_option_id': '0',
        'km_price': '0',
        'total_km_price': '0',
        'payment_amount': '0',
        'total_item': '1',
        'currency_id': '1',
      };

      final order24 = OrderModel.fromActiveOrderJson(jsonOrder24);
      expect(order24.total, 21728.39);
      expect(order24.subtotal, 21728.39);
      expect(order24.deliveryFee, 0.0);
      expect(order24.displayCurrency, 'ETB');
    });

    test('Correctly prioritizes payment_amount when payment_amount is greater than 0', () {
      final jsonPaid = {
        'id': 16,
        'item_total_price': '100.00',
        'total_km_price': '50.00',
        'payment_amount': '150.00',
        'currency_id': '3',
      };
      final order = OrderModel.fromActiveOrderJson(jsonPaid);
      expect(order.total, 150.0);
      expect(order.displayCurrency, 'USD');
    });

    test('Order #15 detail parsing: item price is 67 but total is 77.09 with 10.09 tax', () {
      final statusJson = {
        'id': 15,
        'property_id': '3',
        'payment_amount': '0',
        'item_total_price': '77.09',
        'total_km_price': '0',
        'status': '0',
      };
      final items = [
        {
          'id': 27,
          'item_name': '235/55R19',
          'price': '67',
          'quantity': 1,
          'currency_id': '1',
        }
      ];

      final orderDetail = OrderModel.fromOrderDetailJson(
        statusJson: statusJson,
        itemsList: items,
      );
      // Authoritative total must be 77.09, not overwritten to 67
      expect(orderDetail.total, 77.09);
      expect(orderDetail.subtotal, 67.0);
      expect(orderDetail.taxAndFees, closeTo(10.09, 0.001));
      expect(orderDetail.deliveryFee, 0.0);
      expect(orderDetail.displayCurrency, 'ETB');
    });

    test('Order #24 detail parsing: item price is 19750 but total is 21728.39', () {
      final statusJson = {
        'id': 24,
        'property_id': '3',
        'payment_amount': '0',
        'item_total_price': '21728.39',
        'total_km_price': '0',
        'status': '0',
      };
      final items = [
        {
          'id': 38,
          'item_name': '205/55R16',
          'price': '19750',
          'quantity': 1,
          'currency_id': '1',
        }
      ];

      final orderDetail = OrderModel.fromOrderDetailJson(
        statusJson: statusJson,
        itemsList: items,
      );
      expect(orderDetail.total, 21728.39);
      expect(orderDetail.subtotal, 19750.0);
      expect(orderDetail.taxAndFees, closeTo(1978.39, 0.001));
      expect(orderDetail.displayCurrency, 'ETB');
    });

    test('Dynamic currency resolution for AED (id: 2), USD (id: 3), Yuan (id: 4)', () {
      final orderAed = OrderModel.fromOrderDetailJson(
        statusJson: {
          'id': 100,
          'payment_amount': '50',
          'currency_id': '2',
        },
        itemsList: const [],
      );
      expect(orderAed.displayCurrency, 'AED');

      final orderUsd = OrderModel.fromOrderDetailJson(
        statusJson: {
          'id': 101,
          'payment_amount': '25',
          'currency_id': '3',
        },
        itemsList: const [],
      );
      expect(orderUsd.displayCurrency, 'USD');

      final orderYuan = OrderModel.fromOrderDetailJson(
        statusJson: {
          'id': 102,
          'payment_amount': '180',
          'currency_id': '4',
        },
        itemsList: const [],
      );
      expect(orderYuan.displayCurrency, 'Yuan');
    });
  });
}
