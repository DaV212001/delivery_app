import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/models/currency_model.dart';
import 'package:delivery_app/models/my_property_model.dart';
import 'package:delivery_app/models/my_menu_item_model.dart';
import 'package:delivery_app/models/delivery_item.dart';
import 'package:delivery_app/models/special_offer.dart';
import 'package:delivery_app/controllers/my_property_controller.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('CurrencyModel Tests', () {
    test('parses CurrencyModel correctly from JSON', () {
      final json = {
        'id': 1,
        'code': 'USD',
        'symbol': '\$',
        'name': 'US Dollar',
      };
      final curr = CurrencyModel.fromJson(json);
      expect(curr.id, 1);
      expect(curr.code, 'USD');
      expect(curr.symbol, '\$');
      expect(curr.name, 'US Dollar');

      final outputJson = curr.toJson();
      expect(outputJson['id'], 1);
      expect(outputJson['code'], 'USD');
      expect(outputJson['symbol'], '\$');
    });

    test('parses CurrencyModel with string ID or missing fields safely', () {
      final json = {
        'id': '2',
        'currency_code': 'ETB',
        'currency_symbol': 'Br',
      };
      final curr = CurrencyModel.fromJson(json);
      expect(curr.id, 2);
      expect(curr.code, 'ETB');
      expect(curr.symbol, 'Br');
    });
  });

  group('MyPropertyModel Currency Tests', () {
    test('parses currency string from API response', () {
      final json = {
        'id': 10,
        'property_name': 'Global Cafe',
        'currency': 'USD',
      };
      final prop = MyPropertyModel.fromJson(json);
      expect(prop.currency, 'USD');
    });

    test('falls back to currency_name or currency_code if currency field missing', () {
      final json = {
        'id': 11,
        'property_name': 'Addis Coffee',
        'currency_code': 'EUR',
      };
      final prop = MyPropertyModel.fromJson(json);
      expect(prop.currency, 'EUR');
    });

    test('defaults to ETB if no currency is specified', () {
      final json = {
        'id': 12,
        'property_name': 'Default Coffee',
      };
      final prop = MyPropertyModel.fromJson(json);
      expect(prop.currency, 'ETB');
    });
  });

  group('MyMenuItemModel and DeliveryItem Currency Display Tests', () {
    test('MyMenuItemModel uses parsed currency in displayCurrency and formattedPrice', () {
      final itemUsd = MyMenuItemModel.fromJson({
        'id': 101,
        'property_id': '10',
        'name': 'Burger',
        'price': '15',
        'currency': 'USD',
      });
      expect(itemUsd.currency, 'USD');
      expect(itemUsd.displayCurrency, 'USD');
      expect(itemUsd.formattedPrice, '15 USD');

      final itemDefault = MyMenuItemModel.fromJson({
        'id': 102,
        'property_id': '10',
        'name': 'Injera',
        'price': '250',
      });
      expect(itemDefault.currency, isNull);
      expect(itemDefault.displayCurrency, 'Br');
      expect(itemDefault.formattedPrice, '250 Br');
    });

    test('DeliveryItem uses parsed currency in displayCurrency and formattedPrice', () {
      final deliveryItem = DeliveryItem.fromJson({
        'id': 'd1',
        'name': 'Espresso',
        'price': 3.5,
        'currency': '\$',
      });
      expect(deliveryItem.currency, '\$');
      expect(deliveryItem.displayCurrency, '\$');
      expect(deliveryItem.formattedPrice, '4 \$'); // 3.5 rounded to 4 with toStringAsFixed(0)
    });

    test('SpecialOffer handles currency and transfers it to DeliveryItem', () {
      const offer = SpecialOffer(
        id: 'so1',
        name: 'Combo Meal',
        storeName: 'KFC',
        branchName: 'Bole',
        discountedPrice: 200,
        originalPrice: 250,
        discountPercent: 20,
        imageUrl: '',
        storeId: '5',
        currency: 'ETB',
      );
      expect(offer.displayCurrency, 'ETB');
      expect(offer.formattedDiscountedPrice, '200.0 ETB');
      final dItem = offer.toDeliveryItem();
      expect(dItem.currency, 'ETB');
      expect(dItem.displayCurrency, 'ETB');
    });

    test('SpecialOffer decodes numeric currency IDs correctly', () {
      const offerEtb = SpecialOffer(
        id: 'so2',
        name: 'Burger',
        storeName: 'Injoy',
        branchName: 'Bole',
        discountedPrice: 150,
        originalPrice: 200,
        discountPercent: 25,
        imageUrl: '',
        storeId: '6',
        currency: '1',
      );
      expect(offerEtb.displayCurrency, 'ETB');

      const offerUsd = SpecialOffer(
        id: 'so3',
        name: 'Steak',
        storeName: 'Grill',
        branchName: 'Bole',
        discountedPrice: 20,
        originalPrice: 25,
        discountPercent: 20,
        imageUrl: '',
        storeId: '7',
        currency: '3',
      );
      expect(offerUsd.displayCurrency, 'USD');

      const offerAed = SpecialOffer(
        id: 'so4',
        name: 'Shawarma',
        storeName: 'Dubai Express',
        branchName: 'Bole',
        discountedPrice: 30,
        originalPrice: 40,
        discountPercent: 25,
        imageUrl: '',
        storeId: '8',
        currency: '2',
      );
      expect(offerAed.displayCurrency, 'AED');
    });

    test('SpecialOffer falls back to deliveryItem currency or default Br', () {
      final item = DeliveryItem.fromJson({
        'id': 'd2',
        'name': 'Pasta',
        'price': 180,
        'currency': '1',
      });
      final offerFromItem = SpecialOffer(
        id: 'so4',
        name: 'Pasta Deal',
        storeName: 'Italiano',
        branchName: 'Sarbet',
        discountedPrice: 150,
        originalPrice: 180,
        discountPercent: 16.6,
        imageUrl: '',
        storeId: '8',
        deliveryItem: item,
      );
      expect(offerFromItem.displayCurrency, 'ETB');

      const offerDefault = SpecialOffer(
        id: 'so5',
        name: 'Standard Offer',
        storeName: 'Store',
        branchName: 'Branch',
        discountedPrice: 100,
        originalPrice: 120,
        discountPercent: 16.6,
        imageUrl: '',
        storeId: '9',
      );
      expect(offerDefault.displayCurrency, 'Br');
    });
  });

  group('MyPropertyController Currency Cross-Referencing Tests', () {
    late MyPropertyController controller;

    setUp(() async {
      Get.testMode = true;
      Get.reset();
      SharedPreferences.setMockInitialValues({});
      await ConfigPreference.init();
      if (!Get.isRegistered<AuthController>()) {
        Get.put(AuthController());
      }
      controller = Get.put(MyPropertyController());
      controller.currencies.assignAll([
        const CurrencyModel(id: 1, code: 'USD', symbol: '\$', name: 'US Dollar'),
        const CurrencyModel(id: 2, code: 'ETB', symbol: 'Br', name: 'Ethiopian Birr'),
        const CurrencyModel(id: 3, code: 'EUR', symbol: '€', name: 'Euro'),
      ]);
    });

    tearDown(() {
      Get.reset();
    });

    test('cross-references property currency name to currency ID accurately', () {
      final propUsd = MyPropertyModel.fromJson({
        'id': 1,
        'property_name': 'US Store',
        'currency': 'USD',
      });
      expect(controller.getCurrencyIdForProperty(propUsd), 1);
      expect(controller.getPropertyCurrencyCode(propUsd), 'USD');

      final propBirr = MyPropertyModel.fromJson({
        'id': 2,
        'property_name': 'Addis Store',
        'currency': 'ETB',
      });
      expect(controller.getCurrencyIdForProperty(propBirr), 2);
      expect(controller.getPropertyCurrencyCode(propBirr), 'ETB');

      final propSymbol = MyPropertyModel.fromJson({
        'id': 3,
        'property_name': 'Euro Store',
        'currency': '€',
      });
      expect(controller.getCurrencyIdForProperty(propSymbol), 3);
      expect(controller.getPropertyCurrencyCode(propSymbol), 'EUR');

      final propByNumericId = MyPropertyModel.fromJson({
        'id': 4,
        'property_name': 'Numeric Store',
        'currency': '1',
      });
      expect(controller.getCurrencyIdForProperty(propByNumericId), 1);
    });

    test('falls back to ETB ID 2 if property currency cannot be matched', () {
      final unknownProp = MyPropertyModel.fromJson({
        'id': 99,
        'property_name': 'Unknown Currency Store',
        'currency': 'XYZ',
      });
      expect(controller.getCurrencyIdForProperty(unknownProp), 2);
    });
  });
}
