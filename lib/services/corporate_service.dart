import '../constants/api_endpoints.dart';
import '../models/corporate_model.dart';
import '../utils/templates/dio_template.dart';

class CorporateService {
  /// Fetch company details by company ID
  static Future<CompanyModel?> fetchCompany(dynamic companyId) async {
    CompanyModel? company;
    await DioService.dioGet(
      path: ApiEndpoints.myCompany(companyId),
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
          company = CompanyModel.fromJson(data['data'] as Map<String, dynamic>);
        }
      },
    );
    return company;
  }

  /// Fetch all branches for a given company
  static Future<List<CompanyBranchModel>> fetchBranches(dynamic companyId) async {
    final list = <CompanyBranchModel>[];
    await DioService.dioGet(
      path: ApiEndpoints.branchByCompanyId(companyId),
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(CompanyBranchModel.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch items available for corporate dispatch
  static Future<List<CorporateItemModel>> fetchItems() async {
    final list = <CorporateItemModel>[];
    await DioService.dioGet(
      path: ApiEndpoints.itemList,
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(CorporateItemModel.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch delivery options / vehicles available for the company
  static Future<List<CompanyDeliveryOptionModel>> fetchDeliveryOptions(dynamic companyId) async {
    final list = <CompanyDeliveryOptionModel>[];
    await DioService.dioGet(
      path: ApiEndpoints.companyDeliveryOptions(companyId),
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(CompanyDeliveryOptionModel.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch pending corporate orders for a user
  static Future<List<CompanyOrderModel>> fetchPendingOrders(dynamic userId) async {
    final list = <CompanyOrderModel>[];
    await DioService.dioGet(
      path: ApiEndpoints.pendingCompanyOrders(userId),
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(CompanyOrderModel.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch finished corporate orders for a user
  static Future<List<CompanyOrderModel>> fetchFinishedOrders(dynamic userId) async {
    final list = <CompanyOrderModel>[];
    await DioService.dioGet(
      path: ApiEndpoints.finishedCompanyOrders(userId),
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(CompanyOrderModel.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Create a new corporate delivery order
  static Future<void> createCompanyOrder({
    required int receiverBranchId,
    required int itemId,
    required int senderUserId,
    required int carTypeId,
    required double kmPrice,
    required double totalKm,
    required double totalPrice,
    required String remark,
    String? fromFriendlyLocation,
    String? toFriendlyLocation,
    required Function(Map<String, dynamic> data) onSuccess,
    required Function(String error) onFailure,
  }) async {
    final payload = {
      'reciver_branch_id': receiverBranchId,
      'receiver_branch_id': receiverBranchId,
      'item_id': itemId,
      'sender_user_id': senderUserId,
      'driver_id': 0,
      'car_type_id': carTypeId,
      'km_price': kmPrice,
      'total_km': double.parse(totalKm.toStringAsFixed(2)),
      'total_price': double.parse(totalPrice.toStringAsFixed(2)),
      'satus': 0,
      'status': 0,
      'remark': remark,
      'from_friendly_location': fromFriendlyLocation?.trim() ?? '',
      'to_friendly_location': toFriendlyLocation?.trim() ?? '',
    };

    await DioService.dioPost(
      path: ApiEndpoints.companyOrder,
      data: payload,
      onSuccess: (response) {
        if (response.data is Map<String, dynamic>) {
          onSuccess(response.data as Map<String, dynamic>);
        } else {
          onSuccess({'message': 'Company order placed successfully'});
        }
      },
      onFailure: (error, response) {
        String msg = 'Failed to create corporate order';
        if (response.data is Map<String, dynamic>) {
          msg = response.data['message']?.toString() ?? msg;
        }
        onFailure(msg);
      },
    );
  }
}
