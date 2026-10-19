import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/models/corporate_model.dart';
import 'package:delivery_app/models/user_profile.dart';
import 'package:delivery_app/utils/location_utils.dart';

void main() {
  group('Corporate User Eligibility Tests', () {
    test('User with type 1 and valid company & branch IDs is eligible', () {
      final json = {
        'id': 2,
        'f_name': 'Abel',
        'l_name': 'Seyoum',
        'email': 'readatwattpad@gmail.com',
        'phone': '251944070484',
        'profile_image': '',
        'wallet_amount': '220',
        'status': '1',
        'type': '1',
        'have_property': '0',
        'company_id': '1',
        'branch_id': '2',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, '2');
      expect(profile.name, 'Abel Seyoum');
      expect(profile.type, '1');
      expect(profile.companyId, '1');
      expect(profile.branchId, '2');
      expect(profile.isCorporateUser, isTrue);
    });

    test('User with type != 1 is not corporate user', () {
      final json = {
        'id': 2,
        'f_name': 'Abel',
        'l_name': 'Seyoum',
        'type': '0',
        'company_id': '1',
        'branch_id': '2',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.isCorporateUser, isFalse);
    });

    test('User with company_id == 0 is not corporate user', () {
      final json = {
        'id': 2,
        'f_name': 'Abel',
        'l_name': 'Seyoum',
        'type': '1',
        'company_id': '0',
        'branch_id': '2',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.isCorporateUser, isFalse);
    });

    test('User with branch_id == 0 is not corporate user', () {
      final json = {
        'id': 2,
        'f_name': 'Abel',
        'l_name': 'Seyoum',
        'type': '1',
        'company_id': '1',
        'branch_id': '0',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.isCorporateUser, isFalse);
    });
  });

  group('Corporate Models Deserialization Tests', () {
    test('CompanyModel parses successfully', () {
      final json = {
        'id': 1,
        'name': 'Commercial Bank of Ethiopia',
        'description': 'Commercial Bank of Ethiopia',
      };
      final company = CompanyModel.fromJson(json);
      expect(company.id, 1);
      expect(company.name, 'Commercial Bank of Ethiopia');
    });

    test('CompanyBranchModel parses longtude / longitude safely', () {
      final json = {
        'id': 2,
        'branch_name': 'Beklobet Branch',
        'friendly_location': 'Beklobet Branch',
        'latitude': '8.9978594',
        'longtude': '38.7587239',
        'description': null,
      };
      final branch = CompanyBranchModel.fromJson(json);
      expect(branch.id, 2);
      expect(branch.branchName, 'Beklobet Branch');
      expect(branch.latitude, closeTo(8.99785, 0.0001));
      expect(branch.longitude, closeTo(38.75872, 0.0001));
    });

    test('CorporateItemModel and CompanyDeliveryOptionModel parse correctly', () {
      final itemJson = {'id': 1, 'name': 'posta'};
      final item = CorporateItemModel.fromJson(itemJson);
      expect(item.id, 1);
      expect(item.name, 'posta');

      final optionJson = {'id': 1, 'car_name': 'MoterBick', 'km_price': '13.50'};
      final option = CompanyDeliveryOptionModel.fromJson(optionJson);
      expect(option.id, 1);
      expect(option.carName, 'MoterBick');
      expect(option.kmPrice, 13.50);
    });

    test('CompanyOrderModel parses pending and finished orders correctly', () {
      final orderJson = {
        'id': 8,
        'status': '0',
        'from_branch': 'Main Branch',
        'to_branch': 'Beklobet Branch',
        'item': 'posta',
        'sender_f_name': 'haymanot',
        'sender_l_name': 'yirga',
        'sender_phone': '251918254389',
        'receiver_f_name': 'Abel',
        'receiver_l_name': 'Seyoum',
        'receiver_phone': '251944070484',
        'driver_f_name': null,
        'driver_l_name': null,
        'driver_phone': null,
        'car_type': null,
        'km_price': '25.5',
        'total_km': '12.4',
        'total_price': '316.2',
        'date_time': '2026-10-16 11:33:14',
      };

      final order = CompanyOrderModel.fromJson(orderJson);
      expect(order.id, 8);
      expect(order.isPending, isTrue);
      expect(order.isFinished, isFalse);
      expect(order.fromBranch, 'Main Branch');
      expect(order.toBranch, 'Beklobet Branch');
      expect(order.senderFullName, 'haymanot yirga');
      expect(order.receiverFullName, 'Abel Seyoum');
      expect(order.hasDriver, isFalse);
      expect(order.totalPrice, 316.2);
    });
  });

  group('Haversine Distance & Pricing Calculation Tests', () {
    test('Calculates distance between branches and multiplies by rate', () {
      // Main Branch (9.0165513, 38.7543284) to Beklobet Branch (8.9978594, 38.7587239)
      final dist = LocationUtils.calculateDistanceInKm(
        lat1: 9.0165513,
        lon1: 38.7543284,
        lat2: 8.9978594,
        lon2: 38.7587239,
      );

      expect(dist, greaterThan(1.5));
      expect(dist, lessThan(3.0));

      const ratePerKm = 13.0;
      final totalPrice = dist * ratePerKm;
      expect(totalPrice, greaterThan(20.0));
      expect(totalPrice, lessThan(40.0));
    });
  });
}
