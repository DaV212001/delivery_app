import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/storage_config.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/theme/app_colors.dart';

class CourierScreen extends StatefulWidget {
  const CourierScreen({super.key});

  @override
  State<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends State<CourierScreen> {
  // Address selection state
  String? _pickupAddress;
  String? _dropoffAddress;

  // Controllers
  late final TextEditingController _senderNameController;
  late final TextEditingController _senderPhoneController;
  late final TextEditingController _receiverNameController;
  late final TextEditingController _receiverPhoneController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    // Default sender name from profile or Abel Seyoum
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

    // Pre-fill default pick-up address if profile has an active address
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ProfileController>()) {
        final profile = Get.find<ProfileController>();
        if (profile.selectedAddress.value != null) {
          setState(() {
            _pickupAddress = profile.selectedAddress.value!.name;
          });
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
    // Strip country code prefix (+251 or 0) to count the 9 significant digits
    String cleaned = text.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.startsWith('+251')) {
      cleaned = cleaned.substring(4);
    } else if (cleaned.startsWith('251')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    // Only count numeric digits
    final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length > 9 ? 9 : digits.length;
  }

  void _showAddressModal({required bool isPickup}) {
    final theme = Theme.of(context);
    final addressTextController = TextEditingController();

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            Text(
              isPickup ? 'pickup_address'.tr : 'dropoff_address'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 14),

            // Input field
            TextField(
              controller: addressTextController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: isPickup
                    ? 'Enter pick-up address or landmark...'
                    : 'Enter drop-off address or landmark...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                  onPressed: () {
                    final text = addressTextController.text.trim();
                    if (text.isNotEmpty) {
                      setState(() {
                        if (isPickup) {
                          _pickupAddress = text;
                        } else {
                          _dropoffAddress = text;
                        }
                      });
                      Get.back();
                    }
                  },
                ),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  setState(() {
                    if (isPickup) {
                      _pickupAddress = text.trim();
                    } else {
                      _dropoffAddress = text.trim();
                    }
                  });
                  Get.back();
                }
              },
            ),
            const SizedBox(height: 14),

            // Quick current GPS location option
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                'Use Current Location',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              subtitle: Text(
                'Addis Ababa, Ethiopia',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              onTap: () {
                setState(() {
                  if (isPickup) {
                    _pickupAddress = 'Current Location (Addis Ababa)';
                  } else {
                    _dropoffAddress = 'Current Location (Addis Ababa)';
                  }
                });
                Get.back();
              },
            ),

            const Divider(),

            // Saved addresses from Profile
            if (Get.isRegistered<ProfileController>()) ...[
              Obx(() {
                final addresses = Get.find<ProfileController>().addresses;
                if (addresses.isEmpty) return const SizedBox.shrink();

                return Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: addresses.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final addr = addresses[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          addr.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            if (isPickup) {
                              _pickupAddress = addr.name;
                            } else {
                              _dropoffAddress = addr.name;
                            }
                          });
                          Get.back();
                        },
                      );
                    },
                  ),
                );
              }),
            ],
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _onContinue() {
    if (_pickupAddress == null || _pickupAddress!.trim().isEmpty) {
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

    if (_dropoffAddress == null || _dropoffAddress!.trim().isEmpty) {
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
                  color: isDark ? AppColors.darkOutlineVariant : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Pick-up',
                    value: _pickupAddress!,
                    icon: Icons.trip_origin_rounded,
                    iconColor: AppColors.primary,
                  ),
                  const Divider(height: 20),
                  _SummaryRow(
                    label: 'Drop-off',
                    value: _dropoffAddress!,
                    icon: Icons.location_on_rounded,
                    iconColor: AppColors.secondary,
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
                      const Text(
                        '95.00 ETB',
                        style: TextStyle(
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
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Get.back(); // close sheet
                  Get.snackbar(
                    'courier_request_success'.tr,
                    'courier_request_success_sub'.tr,
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: AppColors.primary,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 4),
                    margin: const EdgeInsets.all(16),
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  );
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    Get.back(); // return to home
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Confirm & Request Courier',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final senderDigits = _countPhoneDigits(_senderPhoneController.text);
    final receiverDigits = _countPhoneDigits(_receiverPhoneController.text);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header Banner with Curved Bottom
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 20, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // AppBar Row: Back Arrow + "Courier"
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
                              ],
                            ),
                            const SizedBox(height: 14),

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
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Icon(
                                    Icons.delivery_dining_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Overlapping Address Cards
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      children: [
                        // Pick-up Address Card
                        _AddressCard(
                          hint: 'pickup_address'.tr,
                          value: _pickupAddress,
                          isDark: isDark,
                          onTap: () => _showAddressModal(isPickup: true),
                        ),

                        const SizedBox(height: 12),

                        // Drop-off Address Card
                        _AddressCard(
                          hint: 'dropoff_address'.tr,
                          value: _dropoffAddress,
                          isDark: isDark,
                          onTap: () => _showAddressModal(isPickup: false),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Sender Information Section
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

                  // 4. Receiver Information Section
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

                  // 5. Description Section
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

          // 6. Fixed Bottom "Continue" Button
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
      ),
    );
  }
}

/// Address selection card displaying location marker with horizontal base line
class _AddressCard extends StatelessWidget {
  final String hint;
  final String? value;
  final bool isDark;
  final VoidCallback onTap;

  const _AddressCard({
    required this.hint,
    required this.value,
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
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
              // Pin Icon with Base Line (Matching Screenshot)
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

              // Address text / placeholder
              Expanded(
                child: Text(
                  hasValue ? value! : hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasValue
                        ? (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                        : (isDark
                            ? AppColors.darkOnSurfaceVariant.withValues(alpha: 0.6)
                            : const Color(0xFF94A3B8)),
                    fontSize: 15,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                hasValue ? Icons.edit_location_alt_outlined : Icons.chevron_right_rounded,
                color: hasValue
                    ? AppColors.primary
                    : (isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFFCBD5E1)),
                size: 20,
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
  final IconData icon;
  final Color? iconColor;

  const _SummaryRow({
    required this.label,
    required this.value,
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
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
