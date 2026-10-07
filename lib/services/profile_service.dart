import '../constants/api_endpoints.dart';
import '../models/address_model.dart';
import '../models/user_profile.dart';
import '../models/wallet_model.dart';
import '../utils/templates/dio_template.dart';

class ProfileService {
  /// Fetch user profile
  static Future<UserProfile?> fetchProfile(dynamic customerId) async {
    UserProfile? profile;
    await DioService.dioGet(
      path: ApiEndpoints.profile(customerId),
      onSuccess: (response) {
        final resData = response.data;
        if (resData is Map<String, dynamic>) {
          profile = UserProfile.fromJson(resData);
        }
      },
    );
    return profile;
  }

  /// Update user profile
  static Future<void> updateProfile({
    required dynamic customerId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required Function(Map<String, dynamic> data) onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPut(
      path: ApiEndpoints.profile(customerId),
      data: {
        'f_name': firstName,
        'l_name': lastName,
        'email': email,
        'phone': phone,
      },
      onSuccess: (response) {
        final resData = response.data;
        if (resData is Map<String, dynamic>) {
          if (resData['success'] == false) {
            onFailure(resData['message']?.toString() ?? 'Failed to update profile');
            return;
          }
          final userMap = resData['data'] is Map<String, dynamic>
              ? resData['data'] as Map<String, dynamic>
              : (resData['user'] is Map<String, dynamic>
                  ? resData['user'] as Map<String, dynamic>
                  : resData);
          onSuccess(userMap);
        } else {
          onSuccess({});
        }
      },
      onFailure: (error, response) {
        String msg = 'Failed to update profile';
        if (response.data is Map<String, dynamic>) {
          final errMap = response.data['errors'];
          if (errMap is Map && errMap.isNotEmpty) {
            final firstErrorList = errMap.values.first;
            if (firstErrorList is List && firstErrorList.isNotEmpty) {
              msg = firstErrorList.first.toString();
            } else if (firstErrorList != null) {
              msg = firstErrorList.toString();
            }
          } else {
            msg = response.data['message']?.toString() ?? msg;
          }
        }
        onFailure(msg);
      },
    );
  }

  /// Fetch wallet balance
  static Future<WalletBalance> fetchWalletAmount(dynamic customerId) async {
    WalletBalance balance = const WalletBalance(amount: 0.0);
    await DioService.dioGet(
      path: ApiEndpoints.walletAmount(customerId),
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          balance = WalletBalance.fromJson(data['data']);
        }
      },
    );
    return balance;
  }

  /// Fetch wallet transactions
  static Future<List<WalletTransaction>> fetchWalletTransactions(dynamic customerId) async {
    final list = <WalletTransaction>[];
    await DioService.dioGet(
      path: ApiEndpoints.walletTransactions(customerId),
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(WalletTransaction.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Top-up wallet
  static Future<void> topupWallet({
    required int userId,
    required double amount,
    required String date,
    required Function(String? checkoutUrl, String message) onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPost(
      path: ApiEndpoints.walletPayment,
      data: {
        'user_id': userId,
        'amount': amount,
        'date': date,
      },
      onSuccess: (response) {
        String? checkoutUrl;
        String message = 'Hosted Link';

        if (response.data is Map<String, dynamic>) {
          final resData = response.data as Map<String, dynamic>;
          message = resData['message']?.toString() ?? message;

          if (resData['data'] is Map<String, dynamic>) {
            final inner = resData['data'] as Map<String, dynamic>;
            checkoutUrl = inner['checkout_url']?.toString() ??
                inner['payment_url']?.toString() ??
                inner['url']?.toString();
          }

          checkoutUrl ??= resData['checkout_url']?.toString() ??
              resData['payment_url']?.toString() ??
              resData['url']?.toString();
        }

        onSuccess(checkoutUrl, message);
      },
      onFailure: (error, response) {
        String msg = 'Wallet top-up failed';
        if (response.data is Map<String, dynamic>) {
          msg = response.data['message']?.toString() ?? msg;
        }
        onFailure(msg);
      },
    );
  }

  /// Fetch delivery addresses
  static Future<List<AddressModel>> fetchDeliveryAddresses(dynamic customerId) async {
    final list = <AddressModel>[];
    await DioService.dioGet(
      path: ApiEndpoints.deliveryAddresses(customerId),
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(AddressModel.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Add delivery address
  static Future<void> addDeliveryAddress({
    required AddressModel address,
    required Function() onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPost(
      path: ApiEndpoints.deliveryAddress,
      data: address.toJson(),
      onSuccess: (_) => onSuccess(),
      onFailure: (error, response) {
        String msg = 'Failed to add address';
        if (response.data is Map<String, dynamic>) {
          msg = response.data['message']?.toString() ?? msg;
        }
        onFailure(msg);
      },
    );
  }

  /// Edit delivery address
  static Future<void> editDeliveryAddress({
    required AddressModel address,
    required Function() onSuccess,
    required Function(String error) onFailure,
  }) async {
    if (address.id == null) {
      onFailure('Address ID is required');
      return;
    }
    await DioService.dioPut(
      path: ApiEndpoints.deliveryAddressDetail(address.id),
      data: address.toJson(),
      onSuccess: (_) => onSuccess(),
      onFailure: (error, response) {
        String msg = 'Failed to update address';
        if (response.data is Map<String, dynamic>) {
          final errMap = response.data['errors'];
          if (errMap is Map && errMap.isNotEmpty) {
            final firstErrorList = errMap.values.first;
            if (firstErrorList is List && firstErrorList.isNotEmpty) {
              msg = firstErrorList.first.toString();
            } else if (firstErrorList != null) {
              msg = firstErrorList.toString();
            }
          } else {
            msg = response.data['message']?.toString() ?? msg;
          }
        }
        onFailure(msg);
      },
    );
  }

  /// Delete delivery address
  static Future<void> deleteDeliveryAddress({
    required dynamic addressId,
    required Function() onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioDelete(
      path: ApiEndpoints.deliveryAddressDetail(addressId),
      onSuccess: (_) => onSuccess(),
      onFailure: (error, response) {
        String msg = 'Failed to delete address';
        if (response.data is Map<String, dynamic>) {
          msg = response.data['message']?.toString() ?? msg;
        }
        onFailure(msg);
      },
    );
  }
}
