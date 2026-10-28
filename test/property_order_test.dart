import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/models/property_order_model.dart';
import 'package:delivery_app/models/order.dart';

void main() {
  group('PropertyOrderModel Tests', () {
    test('parses order_by_property_id JSON correctly', () {
      final json = {
        'id': 25,
        'property_id': '1',
        'date_only': '2026-10-19',
        'customer_id': '1',
        'location': 'Bole Road, Addis Ababa',
        'date': '2026-09-18 00:00:00',
        'status': '0',
        'payment_type': '0',
        'payment_status': '0',
        'total_quantity': '3',
        'item_total_price': '550',
        'delivery_option_id': '1',
        'km_price': '13',
        'total_km_price': '130',
        'payment_amount': '680',
        'total_item': '2',
        'reason': null,
        'customer_latitude': '9.032',
        'customer_longitude': '38.7469',
        'property_latitude': '9.032',
        'property_longtude': '38.7469',
        'driver_id': null,
        'order_type': '1',
        'created_at': '2026-10-19T10:31:15.000000Z',
        'updated_at': '2026-10-19T10:31:15.000000Z',
      };

      final order = PropertyOrderModel.fromJson(json);

      expect(order.id, 25);
      expect(order.propertyId, 1);
      expect(order.customerId, '1');
      expect(order.location, 'Bole Road, Addis Ababa');
      expect(order.orderCode, '#AMN-25');
      expect(order.status, OrderProgressStatus.placed);
      expect(order.isActive, isTrue);
      expect(order.isDelivered, isFalse);
      expect(order.isCancelled, isFalse);
      expect(order.paymentAmount, 680.0);
      expect(order.itemTotalPrice, 550.0);
      expect(order.totalKmPrice, 130.0);
      expect(order.effectiveTotal, 680.0);
      expect(order.paymentMethodLabel, 'Cash on Delivery');
      expect(order.paymentStatusLabel, 'Pay on Delivery');
      expect(order.totalItem, 2);
      expect(order.totalQuantity, 3);
      expect(order.customerLatitude, 9.032);
      expect(order.customerLongitude, 38.7469);
      expect(order.propertyLatitude, 9.032);
      expect(order.propertyLongitude, 38.7469);
    });

    test('enriches with customer details from my_order_detail and converts to OrderModel', () {
      final json = {
        'id': 15,
        'property_id': '3',
        'date_only': '2026-10-05',
        'customer_id': '2',
        'location': 'Office',
        'date': '2026-10-05 00:00:00',
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
      };

      var order = PropertyOrderModel.fromJson(json);
      expect(order.customerFullName, 'Customer #2');

      // Enrich
      order = order.copyWith(
        customerFirstName: 'Abel',
        customerLastName: 'Seyoum',
        customerPhone: '251944070484',
        items: [
          const PropertyOrderItemModel(
            menuId: '11',
            name: '235/55R19',
            imageUrl: 'https://erp.amnplc.com/public/storage/menu/1790971140.webp',
            price: 67.0,
            quantity: 1,
          ),
        ],
      );

      expect(order.customerFullName, 'Abel Seyoum');
      expect(order.customerPhone, '251944070484');
      expect(order.items.length, 1);
      expect(order.items.first.name, '235/55R19');

      // Convert to OrderModel for tracking
      final trackingOrder = order.toOrderModel(currencyCode: 'ETB');
      expect(trackingOrder.orderId, '#AMN-15');
      expect(trackingOrder.deliveryAddress, 'Office');
      expect(trackingOrder.items.length, 1);
      expect(trackingOrder.items.first.item.name, '235/55R19');
    });

    test('correctly handles different order statuses', () {
      final deliveredJson = {
        'id': 1,
        'property_id': '1',
        'status': '4',
        'payment_type': '1',
        'payment_status': '1',
        'item_total_price': '200',
        'payment_amount': '250',
      };
      final deliveredOrder = PropertyOrderModel.fromJson(deliveredJson);
      expect(deliveredOrder.status, OrderProgressStatus.delivered);
      expect(deliveredOrder.isDelivered, isTrue);
      expect(deliveredOrder.isActive, isFalse);
      expect(deliveredOrder.paymentMethodLabel, 'Online (Chapa)');
      expect(deliveredOrder.paymentStatusLabel, 'Paid');

      final cancelledJson = {
        'id': 2,
        'property_id': '1',
        'status': '5',
        'payment_type': '2',
        'payment_status': '0',
        'item_total_price': '100',
      };
      final cancelledOrder = PropertyOrderModel.fromJson(cancelledJson);
      expect(cancelledOrder.status, OrderProgressStatus.cancelled);
      expect(cancelledOrder.isCancelled, isTrue);
      expect(cancelledOrder.isActive, isFalse);
      expect(cancelledOrder.paymentMethodLabel, 'AMN Wallet');
    });
  });
}
