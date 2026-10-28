import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/models/address_model.dart';
import 'package:delivery_app/models/category_model.dart';
import 'package:delivery_app/models/delivery_item.dart';
import 'package:delivery_app/models/faq_model.dart';
import 'package:delivery_app/models/multilingual_string.dart';
import 'package:delivery_app/models/order.dart';
import 'package:delivery_app/models/store.dart';
import 'package:delivery_app/models/user_profile.dart';
import 'package:delivery_app/models/wallet_model.dart';
import 'package:delivery_app/widgets/common/app_widgets.dart';

void main() {
  group('Models Serialization Tests', () {
    test('MultiLangString parses map, string, and null gracefully', () {
      final fromMap = MultiLangString.fromJson({
        'en': 'Bar and Restaurant',
        'am': 'ባር እና ሬስቶራንት',
        'or': 'Bar and Restaurant',
        'ar': 'بار ومطعم',
      });
      expect(fromMap.en, 'Bar and Restaurant');
      expect(fromMap.am, 'ባር እና ሬስቶራንት');
      expect(fromMap.ar, 'بار ومطعم');
      expect(fromMap.text, 'Bar and Restaurant');

      final fromString = MultiLangString.fromJson('Groceries');
      expect(fromString.en, 'Groceries');
      expect(fromString.text, 'Groceries');

      final fromNull = MultiLangString.fromJson(null);
      expect(fromNull.text, '');
    });

    test('CategoryModel parses backend delivery-categroy JSON', () {
      final json = {
        'id': 1,
        'image': 'https://erp.amnplc.com/public/storage/property-category/1789303613.jpg',
        'name': {
          'en': 'Bar and Restaurant',
          'or': 'Bar and Restaurant',
          'am': 'Bar and Restaurant',
        },
      };
      final cat = CategoryModel.fromJson(json);
      expect(cat.id, 1);
      expect(cat.displayName, 'Bar and Restaurant');
      expect(cat.image, contains('1789303613.jpg'));
    });

    test('CategoryModel handles alternate image keys and null safety', () {
      final jsonAlt = {
        'id': '2',
        'imageUrl': 'https://erp.amnplc.com/public/storage/property-categroy/1789467177.jpg',
        'name': 'Pharmacy',
      };
      final catAlt = CategoryModel.fromJson(jsonAlt);
      expect(catAlt.id, 2);
      expect(catAlt.image, contains('1789467177.jpg'));

      final jsonNull = {
        'id': 3,
        'image': 'null',
        'name': 'Market',
      };
      final catNull = CategoryModel.fromJson(jsonNull);
      expect(catNull.image, '');
    });

    test('sanitizeImageUrl upgrades HTTP, handles relative paths and typos', () {
      expect(
        sanitizeImageUrl('http://erp.amnplc.com/public/storage/img.jpg'),
        'https://erp.amnplc.com/public/storage/img.jpg',
      );
      expect(
        sanitizeImageUrl('/public/storage/property-categroy/123.jpg'),
        'https://erp.amnplc.com/public/storage/property-categroy/123.jpg',
      );
      expect(
        sanitizeImageUrl('storage/property-categroy/123.jpg'),
        'https://erp.amnplc.com/storage/property-categroy/123.jpg',
      );
      expect(
        sanitizeImageUrl('https://erp.amnplc.com//public//storage/img.jpg'),
        'https://erp.amnplc.com/public/storage/img.jpg',
      );
    });

    test('PromotionalBannerModel parses promotional image JSON', () {
      final json = {
        'id': 3,
        'image': 'https://erp.amnplc.com/public/storage/promotional-image/1789324321.png',
        'property_id': '1',
        'property_name': 'AMN Restaurant',
        'name': {'en': 'AMN Delivery'},
      };
      final banner = PromotionalBannerModel.fromJson(json);
      expect(banner.id, 3);
      expect(banner.propertyId, 1);
      expect(banner.propertyName, 'AMN Restaurant');
      expect(banner.name.text, 'AMN Delivery');
    });

    test('Store parses feature-store payload with backend spelling variations', () {
      final json = {
        'id': 1,
        'property_logo': 'https://erp.amnplc.com/public/storage/logo/1789312435.jpg',
        'property_cover_image': 'https://erp.amnplc.com/public/storage/cover-image/1789312435.jpg',
        'property_name': 'AMN Restaurant',
        'property_frendly_location': 'summit around birhanu hotel',
        'latitude': '8.992544091357026',
        'longitude': '38.84444991135702',
        'openning_tiem': '08:00:00',
        'closing_time': '22:00:00',
        'description': 'we serve best ethiopian foods',
        'delviery_time': '30 min',
        'type_name': {'en': 'Habesha Food'},
        'categroy_name': {'en': 'Bar and Restaurant'},
      };
      final store = Store.fromJson(json);
      expect(store.id, '1');
      expect(store.name, 'AMN Restaurant');
      expect(store.categoryDescription, 'Bar and Restaurant');
      expect(store.branch, 'summit around birhanu hotel');
      expect(store.deliveryTime, '30 min');
      expect(store.latitude, closeTo(8.9925, 0.001));
      expect(store.longitude, closeTo(38.8444, 0.001));
      expect(store.openingTime, '08:00:00');
    });

    test('DeliveryItem handles backend desacriprion typo and string prices', () {
      final json = {
        'id': 1,
        'property_id': '1',
        'menu_categroy_id': '1',
        'name': 'checkebvsa',
        'desacriprion': 'some description on checkebvsa',
        'image': 'https://erp.amnplc.com/public/storage/menu/1789316101.png',
        'price': '340',
        'status': '1',
        'special_offer': '1',
        'discount_percent': '20',
      };
      final item = DeliveryItem.fromJson(json);
      expect(item.id, '1');
      expect(item.storeId, '1');
      expect(item.name, 'checkebvsa');
      expect(item.description, 'some description on checkebvsa');
      expect(item.price, 340.0);
      expect(item.isSpecialOffer, true);
      expect(item.discountPercent, 20.0);
    });

    test('OrderModel parses active order and order detail payloads', () {
      final activeJson = {
        'id': 12,
        'property_id': '1',
        'location': 'Bole Road, Addis Ababa',
        'status': '1',
        'total_quantity': '3',
        'total_price': '550',
        'total_item': '2',
      };
      final activeOrder = OrderModel.fromActiveOrderJson(activeJson);
      expect(activeOrder.orderId, '#AMN-12');
      expect(activeOrder.deliveryAddress, 'Bole Road, Addis Ababa');
      expect(activeOrder.total, 550.0);
      expect(activeOrder.status, OrderProgressStatus.accepted);
      expect(activeOrder.status.code, 1);

      // Verify all status codes (0: Placed / Waiting for driver, 1: Accepted, 2: Driver on the way to shop, 3: Driver on the way to you, 4: Delivered, 5: Cancelled)
      expect(OrderModel.parseStatus('0'), OrderProgressStatus.placed);
      expect(OrderProgressStatus.placed.code, 0);
      expect(OrderModel.parseStatus('1'), OrderProgressStatus.accepted);
      expect(OrderModel.parseStatus('2'), OrderProgressStatus.driverToShop);
      expect(OrderModel.parseStatus('3'), OrderProgressStatus.driverToYou);
      expect(OrderModel.parseStatus('4'), OrderProgressStatus.delivered);
      expect(OrderModel.parseStatus('5'), OrderProgressStatus.cancelled);

      final detailStatusJson = {
        'id': 12,
        'property_id': '1',
        'location': 'Bole Road, Addis Ababa',
        'status': '3',
        'total_price': '550',
      };
      final detailItemsList = [
        {
          'property': 'AMN Restaurant',
          'item_name': 'checkebvsa',
          'item_price': '150',
          'quantity': '2',
        },
      ];
      final detailOrder = OrderModel.fromOrderDetailJson(
        statusJson: detailStatusJson,
        itemsList: detailItemsList,
      );
      expect(detailOrder.status, OrderProgressStatus.driverToYou);
      expect(detailOrder.status.code, 3);
      expect(detailOrder.items.length, 1);
      expect(detailOrder.items.first.item.name, 'checkebvsa');
      expect(detailOrder.storeName, 'AMN Restaurant');

      // Test fallbackStore resolution when items don't have property name
      final fallbackStore = Store.fromJson({
        'id': 1,
        'property_name': 'Fallback Dr Tyre',
      });
      final orderWithFallback = OrderModel.fromOrderDetailJson(
        statusJson: {'id': 15, 'property_id': '1'},
        itemsList: [
          {'item_name': '235/55R19', 'item_price': '67', 'quantity': 1},
        ],
        fallbackStore: fallbackStore,
      );
      expect(orderWithFallback.storeName, 'Fallback Dr Tyre');
      expect(orderWithFallback.items.first.item.name, '235/55R19');
      expect(orderWithFallback.items.first.item.price, 67.0);
    });

    test('AddressModel, Wallet, Faq, and UserProfile parse correctly', () {
      final addrJson = {
        'id': 3,
        'name': 'Home',
        'latitude': '9.02098',
        'longitude': '38.6773',
        'user_id': '1',
      };
      final addr = AddressModel.fromJson(addrJson);
      expect(addr.id, 3);
      expect(addr.name, 'Home');

      final walletBalance = WalletBalance.fromJson('330');
      expect(walletBalance.amount, 330.0);
      expect(walletBalance.formattedBirr, '330.00 Br');

      final faqJson = {
        'question': {'en': 'What does Ticket Master do?'},
        'answer': {'en': 'Ticket booking platform.'},
      };
      final faq = FaqItem.fromJson(faqJson);
      expect(faq.questionText, 'What does Ticket Master do?');
      expect(faq.answerText, 'Ticket booking platform.');

      final userJson = {
        'id': 1,
        'f_name': 'aman',
        'l_name': 'til',
        'email': 'tilahun@example.com',
        'phone': '251911058179',
        'wallet_amount': '330',
      };
      final profile = UserProfile.fromJson(userJson);
      expect(profile.name, 'aman til');
      expect(profile.walletAmount, 330.0);
    });
  });
}
