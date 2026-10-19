import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/storage_config.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/courier_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/theme/app_colors.dart';
import 'courier_history_screen.dart';

class CourierScreen extends StatefulWidget {
  const CourierScreen({super.key});

  @override
  State<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends State<CourierScreen> {
  late final CourierController _courierController;

  // Controllers
  late final TextEditingController _senderNameController;
  late final TextEditingController _senderPhoneController;
  late final TextEditingController _receiverNameController;
  late final TextEditingController _receiverPhoneController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _courierController = Get.isRegistered<CourierController>()
        ? Get.find<CourierController>()
        : Get.put(CourierController());

    // Default sender name & phone from profile or saved config
    String initialSenderName = 'Abel Seyoum';
    String initialSenderPhone = '+251944070484';

    if (Get.isRegistered<AuthController>()) {
      final authUser = Get.find<AuthController>().user;
      if (authUser.name.isNotEmpty && authUser.name != 'Customer') {
        initialSenderName = authUser.name;
      }
      if (authUser.phone.isNotEmpty) {
        initialSenderPhone = authUser.phone;
      }
    } else {
      final savedName = ConfigPreference.getUserName();
      if (savedName != null && savedName.isNotEmpty) {
        initialSenderName = savedName;
      }
      final savedPhone = ConfigPreference.getUserPhone();
      if (savedPhone != null && savedPhone.isNotEmpty) {
        initialSenderPhone = savedPhone;
      }
    }

    _senderNameController = TextEditingController(text: initialSenderName);
    _senderPhoneController = TextEditingController(text: initialSenderPhone);
    _receiverNameController = TextEditingController();
    _receiverPhoneController = TextEditingController();
    _descriptionController = TextEditingController();

    _senderPhoneController.addListener(() => setState(() {}));
    _receiverPhoneController.addListener(() => setState(() {}));

    // Pre-fill default pick-up address & coordinates if profile has an active address
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ProfileController>()) {
        final profile = Get.find<ProfileController>();
        if (profile.selectedAddress.value != null &&
            _courierController.pickupAddress.value == null) {
          final addr = profile.selectedAddress.value!;
          _courierController.setLocation(
            isPickup: true,
            lat: addr.latitude,
            lng: addr.longitude,
            address: addr.name,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int _countPhoneDigits(String text) {
    String cleaned = text.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.startsWith('+251')) {
      cleaned = cleaned.substring(4);
    } else if (cleaned.startsWith('251')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length > 9 ? 9 : digits.length;
  }

  /// Coordinate input is strictly handled via Gebeta Map selection
  Future<void> _pickLocationOnMap({required bool isPickup}) async {
    await _courierController.selectLocationOnMap(isPickup: isPickup);
  }

  void _onContinue() {
    final pickupAddress = _courierController.pickupAddress.value;
    final dropoffAddress = _courierController.dropoffAddress.value;

    if (pickupAddress == null || pickupAddress.trim().isEmpty) {
      Get.snackbar(
        'pickup_address'.tr,
        'select_pickup_address'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (dropoffAddress == null || dropoffAddress.trim().isEmpty) {
      Get.snackbar(
        'dropoff_address'.tr,
        'select_dropoff_address'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (_receiverNameController.text.trim().isEmpty) {
      Get.snackbar(
        'receiver_information'.tr,
        'enter_receiver_name'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final receiverDigits = _countPhoneDigits(_receiverPhoneController.text);
    if (receiverDigits < 9) {
      Get.snackbar(
        'receiver_information'.tr,
        'enter_receiver_phone'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    // Confirmation Bottom Sheet
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.two_wheeler_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'courier_delivery'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkOutlineVariant
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Pick-up',
                      value: pickupAddress,
                      subValue: _courierController.pickupLatitude.value != null
                          ? '${_courierController.pickupLatitude.value!.toStringAsFixed(4)}, ${_courierController.pickupLongitude.value!.toStringAsFixed(4)}'
                          : null,
                      icon: Icons.trip_origin_rounded,
                      iconColor: AppColors.primary,
                    ),
                    const Divider(height: 20),
                    _SummaryRow(
                      label: 'Drop-off',
                      value: dropoffAddress,
                      subValue: _courierController.dropoffLatitude.value != null
                          ? '${_courierController.dropoffLatitude.value!.toStringAsFixed(4)}, ${_courierController.dropoffLongitude.value!.toStringAsFixed(4)}'
                          : null,
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.secondary,
                    ),
                    const Divider(height: 20),
                    _SummaryRow(
                      label: 'Distance',
                      value: '${_courierController.calculatedDistanceKm.value} km',
                      icon: Icons.route_rounded,
                      iconColor: const Color(0xFF0284C7),
                    ),
                    const Divider(height: 20),
                    _SummaryRow(
                      label: 'Receiver',
                      value:
                          '${_receiverNameController.text.trim()} (${_receiverPhoneController.text.trim()})',
                      icon: Icons.person_rounded,
                    ),
                    if (_descriptionController.text.trim().isNotEmpty) ...[
                      const Divider(height: 20),
                      _SummaryRow(
                        label: 'Package',
                        value: _descriptionController.text.trim(),
                        icon: Icons.inventory_2_outlined,
                      ),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimated Delivery Fee',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_courierController.calculatedTotalPrice.value.toStringAsFixed(2)} ETB',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                final isSubmitting = _courierController.isSubmitting.value;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final success = await _courierController.submitOrder(
                              receiverName: _receiverNameController.text,
                              receiverPhone: _receiverPhoneController.text,
                              description: _descriptionController.text,
                            );

                            if (success) {
                              Get.back(); // close bottom sheet
                              Get.snackbar(
                                'courier_request_success'.tr,
                                'courier_request_success_sub'.tr,
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: AppColors.primary,
                                colorText: Colors.white,
                                duration: const Duration(seconds: 4),
                                margin: const EdgeInsets.all(16),
                                icon: const Icon(Icons.check_circle_rounded,
                                    color: Colors.white),
                              );
                              // Open Delivery History screen to view the submitted order
                              Get.to(() => const CourierHistoryScreen());
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Confirm & Request Courier',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // 1. Top Header Banner with Curved Bottom & History Action Button
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AppBar Row: Back Arrow + "Courier" + Delivery History Icon with Badge
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => Get.back(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'courier_title'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Obx(() {
                          final activeCount =
                              _courierController.activeOrders.length;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                tooltip: 'Delivery History',
                                icon: const Icon(
                                  Icons.history_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                onPressed: () =>
                                    Get.to(() => const CourierHistoryScreen()),
                              ),
                              if (activeCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$activeCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Subheader: "Courier Delivery" + Motorcycle/Scooter Icon
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Courier Delivery',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            Icons.delivery_dining_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Main Courier Creation Form
          Expanded(
            child: _buildCreationForm(theme, isDark),
          ),
        ],
      ),
    );
  }

  /// Creation Form with Map-First Coordinate Picking
  Widget _buildCreationForm(ThemeData theme, bool isDark) {
    final senderDigits = _countPhoneDigits(_senderPhoneController.text);
    final receiverDigits = _countPhoneDigits(_receiverPhoneController.text);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Overlapping Address Cards (Map-Powered)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      // Pick-up Address Card (Coordinates strictly mapped)
                      Obx(() {
                        final lat = _courierController.pickupLatitude.value;
                        final lng = _courierController.pickupLongitude.value;
                        final addr = _courierController.pickupAddress.value;

                        return _AddressCard(
                          hint: 'pickup_address'.tr,
                          value: addr,
                          coordinatesText: lat != null && lng != null
                              ? '📍 ${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E'
                              : null,
                          isDark: isDark,
                          onTap: () => _pickLocationOnMap(isPickup: true),
                        );
                      }),

                      const SizedBox(height: 12),

                      // Drop-off Address Card (Coordinates strictly mapped)
                      Obx(() {
                        final lat = _courierController.dropoffLatitude.value;
                        final lng = _courierController.dropoffLongitude.value;
                        final addr = _courierController.dropoffAddress.value;

                        return _AddressCard(
                          hint: 'dropoff_address'.tr,
                          value: addr,
                          coordinatesText: lat != null && lng != null
                              ? '📍 ${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E'
                              : null,
                          isDark: isDark,
                          onTap: () => _pickLocationOnMap(isPickup: false),
                        );
                      }),

                      // Dynamic Distance & Price Calculation Bar
                      Obx(() {
                        if (!_courierController.hasCoordinatesSelected) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.route_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_courierController.calculatedDistanceKm.value} km',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${_courierController.kmPrice.value.toStringAsFixed(0)} ETB/km)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${_courierController.calculatedTotalPrice.value.toStringAsFixed(2)} ETB',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Sender Information Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'sender_information'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sender Name
                      TextField(
                        controller: _senderNameController,
                        decoration: InputDecoration(
                          hintText: 'sender_name'.tr,
                          fillColor: isDark
                              ? AppColors.darkSurfaceContainerLow
                              : Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutlineVariant
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Sender Phone Number
                      TextField(
                        controller: _senderPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '+2519XXXXXXXX',
                          fillColor: isDark
                              ? AppColors.darkSurfaceContainerLow
                              : Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutlineVariant
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 6),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$senderDigits/9',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkOnSurfaceVariant
                                  : AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Receiver Information Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'receiver_information'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Receiver Name
                      TextField(
                        controller: _receiverNameController,
                        decoration: InputDecoration(
                          hintText: 'receiver_name'.tr,
                          fillColor: isDark
                              ? AppColors.darkSurfaceContainerLow
                              : Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutlineVariant
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Receiver Phone Number
                      TextField(
                        controller: _receiverPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '+251  9XXXXXXXX',
                          fillColor: isDark
                              ? AppColors.darkSurfaceContainerLow
                              : Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutlineVariant
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 6),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$receiverDigits/9',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkOnSurfaceVariant
                                  : AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Description Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'description'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'courier_description_hint'.tr,
                          fillColor: isDark
                              ? AppColors.darkSurfaceContainerLow
                              : Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutlineVariant
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),

        // 5. Fixed Bottom "Continue" Button
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'continue_btn'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Address selection card displaying location marker, address text, coordinates chip, and map badge
class _AddressCard extends StatelessWidget {
  final String hint;
  final String? value;
  final String? coordinatesText;
  final bool isDark;
  final VoidCallback onTap;

  const _AddressCard({
    required this.hint,
    required this.value,
    this.coordinatesText,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkOutlineVariant : const Color(0xFFE2E8F0),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Pin Icon with Base Line
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  Container(
                    width: 14,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Address text / Coordinates pill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasValue ? value! : hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasValue
                            ? (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                            : (isDark
                                ? AppColors.darkOnSurfaceVariant.withValues(alpha: 0.6)
                                : const Color(0xFF94A3B8)),
                        fontSize: 14.5,
                        fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (coordinatesText != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        coordinatesText!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Map Pin Action Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.map_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Map',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;
  final Color? iconColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.subValue,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subValue != null)
                Text(
                  subValue!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
