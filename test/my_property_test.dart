import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/models/my_property_model.dart';
import 'package:delivery_app/models/my_menu_category_model.dart';
import 'package:delivery_app/models/my_menu_item_model.dart';

void main() {
  group('MyPropertyModel Tests', () {
    test('parses API response correctly with field aliases and typos', () {
      final json = {
        'id': 3,
        'property_logo': 'https://sales.amnplc.com/public/storage/logo/1790947071.png',
        'property_cover_image': 'https://sales.amnplc.com/public/storage/cover-image/1790947071.png',
        'property_name': 'Dr Tyre',
        'property_frendly_location': 'Teklehaimanot',
        'latitude': '9.160400',
        'longitude': '38.724747',
        'openning_tiem': '07:00:00',
        'closing_time': '17:30:00',
        'description': 'Quality commercial tyres available.',
        'delviery_time': '1 Hour',
        'status': '1',
        'type_name': {
          'en': 'COMMERCIAL TYRES',
          'am': 'COMMERCIAL TYRES',
        },
        'delviery_type_image': 'https://erp.amnplc.com/public/storage/delivery-type/1789554433.jpg',
        'categroy_name': {
          'en': 'COMMERCIAL CAR TRIES',
        },
        'delviery_categroy_image': 'https://erp.amnplc.com/public/storage/property-category/1791184516.jpg',
      };

      final property = MyPropertyModel.fromJson(json);

      expect(property.id, 3);
      expect(property.name, 'Dr Tyre');
      expect(property.friendlyLocation, 'Teklehaimanot');
      expect(property.openingTime, '07:00:00');
      expect(property.closingTime, '17:30:00');
      expect(property.deliveryTime, '1 Hour');
      expect(property.isActive, isTrue);
      expect(property.isUnderReview, isFalse);
      expect(property.isCurrentlyOpenAt(DateTime(2026, 1, 1, 10, 0)), isTrue);
      expect(property.isCurrentlyOpenAt(DateTime(2026, 1, 1, 20, 0)), isFalse);
      expect(property.typeName, 'COMMERCIAL TYRES');
      expect(property.categoryName, 'COMMERCIAL CAR TRIES');
      expect(property.logo, contains('1790947071.png'));
    });

    test('status 0 correctly marks property as isUnderReview and inactive', () {
      final json = {
        'id': 5,
        'property_name': 'New Branch',
        'status': '0',
        'openning_tiem': '08:00:00',
        'closing_time': '20:00:00',
      };
      final property = MyPropertyModel.fromJson(json);
      expect(property.isActive, isFalse);
      expect(property.isUnderReview, isTrue);
    });
  });

  group('MyMenuCategoryModel Tests', () {
    test('parses menu category response correctly', () {
      final json = {
        'id': 4,
        'name': 'TRACTOR TYRES',
        'property_name': 'Dr Tyre',
        'property_id': '3',
      };

      final cat = MyMenuCategoryModel.fromJson(json);

      expect(cat.id, 4);
      expect(cat.name, 'TRACTOR TYRES');
      expect(cat.propertyName, 'Dr Tyre');
      expect(cat.propertyId, '3');
    });
  });

  group('MyMenuItemModel Tests', () {
    test('parses menu item response and computes active and discounted prices', () {
      final json = {
        'id': 2,
        'property_id': '3',
        'menu_categroy_id': '3',
        'name': '185/65R14',
        'desacriprion': '185/65R14 tires are commonly used on compact sedans',
        'image': 'https://erp.amnplc.com/public/storage/menu/1790966295.webp',
        'price': '17000',
        'status': '1',
        'special_offer': '1',
        'discount_percent': '10',
      };

      final item = MyMenuItemModel.fromJson(json);

      expect(item.id, 2);
      expect(item.propertyId, '3');
      expect(item.menuCategoryId, '3');
      expect(item.name, '185/65R14');
      expect(item.description, contains('compact sedans'));
      expect(item.price, 17000.0);
      expect(item.status, 1);
      expect(item.isActive, isTrue);
      expect(item.specialOffer, isTrue);
      expect(item.discountPercent, 10.0);
      expect(item.effectivePrice, 15300.0);
      expect(item.formattedPrice, '17000 Br');
    });

    test('copyWith updates status accurately for optimistic updates', () {
      final item = MyMenuItemModel(
        id: 10,
        propertyId: '1',
        menuCategoryId: '2',
        name: 'Item A',
        description: 'Test',
        image: '',
        price: 100,
        status: 1,
        specialOffer: false,
      );

      final updated = item.copyWith(status: 0);

      expect(item.isActive, isTrue);
      expect(updated.isActive, isFalse);
      expect(updated.name, 'Item A');
    });

    test('multi-property list handles multiple merchant branches with distinct IDs and details', () {
      final listJson = [
        {
          'id': 1,
          'property_name': 'Bole Cafe & Bakery',
          'property_frendly_location': 'Bole Medhanialem',
          'openning_tiem': '07:30:00',
          'closing_time': '21:30:00',
          'delviery_time': '20 min',
          'status': '1',
          'categroy_name': {'en': 'Cafe & Bakery'},
        },
        {
          'id': 2,
          'property_name': 'Fresh Market - Kazanchis',
          'property_frendly_location': 'Kazanchis Menelik II',
          'openning_tiem': '08:00:00',
          'closing_time': '22:00:00',
          'delviery_time': '30 min',
          'status': '1',
          'categroy_name': {'en': 'Grocery & Produce'},
        },
      ];

      final properties = listJson.map((j) => MyPropertyModel.fromJson(j)).toList();

      expect(properties.length, 2);
      expect(properties[0].id, 1);
      expect(properties[0].name, 'Bole Cafe & Bakery');
      expect(properties[1].id, 2);
      expect(properties[1].name, 'Fresh Market - Kazanchis');
      expect(properties[0].friendlyLocation, 'Bole Medhanialem');
      expect(properties[1].friendlyLocation, 'Kazanchis Menelik II');
    });
  });
}
