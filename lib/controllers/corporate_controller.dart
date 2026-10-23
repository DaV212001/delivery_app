import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/storage_config.dart';
import '../controllers/auth_controller.dart';
import '../models/corporate_model.dart';
import '../services/corporate_service.dart';
import '../services/gebeta_location_service.dart';
import '../utils/api_call_status.dart';
import '../utils/location_utils.dart';

class CorporateController extends GetxController {
  static CorporateController get to => Get.find<CorporateController>();

  // State Observables
  final company = Rxn<CompanyModel>();
  final branches = <CompanyBranchModel>[].obs;
  final items = <CorporateItemModel>[].obs;
  final deliveryOptions = <CompanyDeliveryOptionModel>[].obs;

  final pendingOrders = <CompanyOrderModel>[].obs;
  final finishedOrders = <CompanyOrderModel>[].obs;

  final status = ApiCallStatus.holding.obs;
  final ordersLoading = false.obs;
  final isSubmitting = false.obs;

  // Order creation form observables
  final selectedReceiverBranch = Rxn<CompanyBranchModel>();
  final selectedItem = Rxn<CorporateItemModel>();
  final selectedDeliveryOption = Rxn<CompanyDeliveryOptionModel>();
  final calculatedDistanceKm = 0.0.obs;
  final calculatedTotalPrice = 0.0.obs;

  AuthController get _auth => Get.find<AuthController>();

  int get _companyId =>
      int.tryParse(_auth.user.companyId) ??
      int.tryParse(ConfigPreference.getUserCompanyId() ?? '0') ??
      0;

  int get _userId =>
      int.tryParse(_auth.user.id) ?? ConfigPreference.getUserId() ?? 0;

  String get _userBranchId =>
      _auth.user.branchId.isNotEmpty && _auth.user.branchId != '0'
          ? _auth.user.branchId
          : (ConfigPreference.getUserBranchId() ?? '0');

  /// The user's assigned sender branch
  CompanyBranchModel? get senderBranch {
    if (branches.isEmpty) return null;
    return branches.firstWhereOrNull(
      (b) => b.id.toString() == _userBranchId,
    );
  }

  /// Receiver branches (filtering out sender branch if desired)
  List<CompanyBranchModel> get availableReceiverBranches {
    if (branches.isEmpty) return [];
    final senderId = senderBranch?.id.toString() ?? _userBranchId;
    final filtered = branches.where((b) => b.id.toString() != senderId).toList();
    return filtered.isNotEmpty ? filtered : branches.toList();
  }

  @override
  void onInit() {
    super.onInit();
    if (_auth.user.isCorporateUser) {
      loadDashboard();
    }
  }

  /// Load company info, branches, and active orders
  Future<void> loadDashboard() async {
    final compId = _companyId;
    final uid = _userId;
    if (compId <= 0 || uid <= 0) return;

    status.value = ApiCallStatus.loading;
    ordersLoading.value = true;

    try {
      final results = await Future.wait([
        CorporateService.fetchCompany(compId),
        CorporateService.fetchBranches(compId),
        CorporateService.fetchPendingOrders(uid),
        CorporateService.fetchFinishedOrders(uid),
      ]);

      company.value = results[0] as CompanyModel?;
      branches.assignAll(results[1] as List<CompanyBranchModel>);
      pendingOrders.assignAll(results[2] as List<CompanyOrderModel>);
      finishedOrders.assignAll(results[3] as List<CompanyOrderModel>);

      status.value = ApiCallStatus.success;
    } catch (_) {
      status.value = ApiCallStatus.error;
    } finally {
      ordersLoading.value = false;
    }
  }

  /// Refresh only pending and finished orders
  Future<void> refreshOrders() async {
    final uid = _userId;
    if (uid <= 0) return;

    ordersLoading.value = true;
    try {
      final results = await Future.wait([
        CorporateService.fetchPendingOrders(uid),
        CorporateService.fetchFinishedOrders(uid),
      ]);
      pendingOrders.assignAll(results[0]);
      finishedOrders.assignAll(results[1]);
    } catch (_) {
    } finally {
      ordersLoading.value = false;
    }
  }

  /// Load form options (branches, items, delivery options) for order creation
  Future<void> loadOrderFormDependencies() async {
    final compId = _companyId;
    if (compId <= 0) return;

    if (branches.isEmpty) {
      final bList = await CorporateService.fetchBranches(compId);
      branches.assignAll(bList);
    }

    final results = await Future.wait([
      CorporateService.fetchItems(),
      CorporateService.fetchDeliveryOptions(compId),
    ]);

    items.assignAll(results[0] as List<CorporateItemModel>);
    deliveryOptions.assignAll(results[1] as List<CompanyDeliveryOptionModel>);

    // Default pre-selections if available
    if (items.isNotEmpty && selectedItem.value == null) {
      selectedItem.value = items.first;
    }
    if (deliveryOptions.isNotEmpty && selectedDeliveryOption.value == null) {
      selectedDeliveryOption.value = deliveryOptions.first;
    }
    if (availableReceiverBranches.isNotEmpty &&
        selectedReceiverBranch.value == null) {
      selectedReceiverBranch.value = availableReceiverBranches.first;
    }

    recalculateDistanceAndPrice();
  }

  void onReceiverBranchChanged(CompanyBranchModel? branch) {
    selectedReceiverBranch.value = branch;
    recalculateDistanceAndPrice();
  }

  void onItemChanged(CorporateItemModel? item) {
    selectedItem.value = item;
  }

  void onDeliveryOptionChanged(CompanyDeliveryOptionModel? option) {
    selectedDeliveryOption.value = option;
    recalculateDistanceAndPrice();
  }

  /// Calculate distance between sender branch and receiver branch coordinates via Haversine formula
  void recalculateDistanceAndPrice() {
    final sender = senderBranch;
    final receiver = selectedReceiverBranch.value;

    if (sender != null &&
        receiver != null &&
        sender.latitude != null &&
        sender.longitude != null &&
        receiver.latitude != null &&
        receiver.longitude != null) {
      final dist = LocationUtils.calculateDistanceInKm(
        lat1: sender.latitude!,
        lon1: sender.longitude!,
        lat2: receiver.latitude!,
        lon2: receiver.longitude!,
      );
      calculatedDistanceKm.value = dist > 0.05 ? dist : 1.0;
    } else {
      calculatedDistanceKm.value = 1.0;
    }

    final rate = selectedDeliveryOption.value?.kmPrice ?? 0.0;
    calculatedTotalPrice.value = calculatedDistanceKm.value * rate;
  }

  /// Place new corporate order
  Future<void> placeOrder({
    required String remark,
    required VoidCallback onSuccess,
  }) async {
    final receiver = selectedReceiverBranch.value;
    final item = selectedItem.value;
    final vehicle = selectedDeliveryOption.value;

    if (receiver == null) {
      Get.snackbar(
        'validation_error'.tr.isNotEmpty ? 'validation_error'.tr : 'Notice',
        'Please select a destination branch',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (item == null) {
      Get.snackbar(
        'validation_error'.tr.isNotEmpty ? 'validation_error'.tr : 'Notice',
        'Please select an item to send',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (vehicle == null) {
      Get.snackbar(
        'validation_error'.tr.isNotEmpty ? 'validation_error'.tr : 'Notice',
        'Please select a delivery vehicle option',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;

    final sender = senderBranch;
    String fromFriendly = sender?.friendlyLocation ?? '';
    if (fromFriendly.trim().isEmpty &&
        sender?.latitude != null &&
        sender?.longitude != null) {
      try {
        fromFriendly = await GebetaLocationService.reverseGeocode(
          sender!.latitude!,
          sender.longitude!,
        );
      } catch (_) {}
    }
    if (fromFriendly.trim().isEmpty) {
      fromFriendly = sender?.branchName ?? '';
    }

    String toFriendly = receiver.friendlyLocation;
    if (toFriendly.trim().isEmpty &&
        receiver.latitude != null &&
        receiver.longitude != null) {
      try {
        toFriendly = await GebetaLocationService.reverseGeocode(
          receiver.latitude!,
          receiver.longitude!,
        );
      } catch (_) {}
    }
    if (toFriendly.trim().isEmpty) {
      toFriendly = receiver.branchName;
    }

    await CorporateService.createCompanyOrder(
      receiverBranchId: receiver.id,
      itemId: item.id,
      senderUserId: _userId,
      carTypeId: vehicle.id,
      kmPrice: vehicle.kmPrice,
      totalKm: calculatedDistanceKm.value,
      totalPrice: calculatedTotalPrice.value,
      remark: remark,
      fromFriendlyLocation: fromFriendly,
      toFriendlyLocation: toFriendly,
      onSuccess: (data) async {
        isSubmitting.value = false;
        Get.snackbar(
          'order_success'.tr.isNotEmpty ? 'order_success'.tr : 'Order Placed',
          'Corporate delivery request created successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.85),
          colorText: Colors.white,
        );
        await refreshOrders();
        onSuccess();
      },
      onFailure: (error) {
        isSubmitting.value = false;
        Get.snackbar(
          'Error',
          error,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.85),
          colorText: Colors.white,
        );
      },
    );
  }
}
