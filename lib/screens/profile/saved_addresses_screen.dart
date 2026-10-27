import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/address_model.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/map/locked_map_preview.dart';
import '../../widgets/map/property_location_picker_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  final bool selectMode;

  const SavedAddressesScreen({
    super.key,
    this.selectMode = false,
  });

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  late final ProfileController _profileController;

  @override
  void initState() {
    super.initState();
    _profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    if (_profileController.isAuthenticated && _profileController.addresses.isEmpty) {
      _profileController.loadAddresses();
    }
  }

  bool get _isSelectMode =>
      widget.selectMode || (Get.arguments is Map && Get.arguments['selectMode'] == true);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'saved_addresses'.tr.isNotEmpty ? 'saved_addresses'.tr : 'Saved Addresses',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: 'add_address'.tr.isNotEmpty ? 'add_address'.tr : 'Add Address',
            onPressed: () => _showAddAddressDialog(context, _profileController),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text(
          'add_address'.tr.isNotEmpty ? 'add_address'.tr : 'Add Address',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () => _showAddAddressDialog(context, _profileController),
      ),
      body: Obx(() {
        if (_profileController.isLoadingAddresses.value && _profileController.addresses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_profileController.addresses.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_off_outlined,
                      size: 46,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'no_saved_addresses'.tr.isNotEmpty
                        ? 'no_saved_addresses'.tr
                        : 'No saved addresses yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save your frequent delivery locations like Home, Office, or Gym for quick 1-tap ordering.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    width: 200,
                    text: 'add_address'.tr.isNotEmpty ? 'add_address'.tr : 'Add Address',
                    onPressed: () => _showAddAddressDialog(context, _profileController),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _profileController.loadAddresses(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: _profileController.addresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final addr = _profileController.addresses[index];
              final isSelected = _profileController.selectedAddress.value?.id == addr.id ||
                  _profileController.selectedAddress.value?.name == addr.name;

              return Material(
                color: isDark ? AppColors.darkSurfaceContainerLow : Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: isSelected ? 2 : 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    _profileController.selectAddress(addr);
                    if (_isSelectMode) {
                      Get.back(result: addr);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.08)),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : AppColors.surfaceContainerLow),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.location_on_outlined,
                            color: isSelected ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      addr.name,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? AppColors.primary : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'DEFAULT',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${addr.latitude.toStringAsFixed(4)}, ${addr.longitude.toStringAsFixed(4)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (addr.id != null) ...[
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                            tooltip: 'edit_address'.tr,
                            onPressed: () => _showEditAddressDialog(context, _profileController, addr),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            tooltip: 'delete'.tr,
                            onPressed: () => _confirmDelete(context, _profileController, addr),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void _confirmDelete(BuildContext context, ProfileController profileController, AddressModel addr) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              'delete_address'.tr.isNotEmpty && 'delete_address'.tr != 'delete_address'
                  ? 'delete_address'.tr
                  : 'Delete Address',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text('Are you sure you want to remove "${addr.name}" from your saved addresses?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Get.back();
              if (addr.id != null) {
                profileController.deleteAddress(addr.id!);
              }
            },
            child: Text('delete'.tr.isNotEmpty ? 'delete'.tr : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditAddressDialog(
    BuildContext context,
    ProfileController profileController,
    AddressModel address,
  ) {
    _showAddressEditorDialog(
      context: context,
      profileController: profileController,
      address: address,
    );
  }

  void _showAddAddressDialog(BuildContext context, ProfileController profileController) {
    _showAddressEditorDialog(
      context: context,
      profileController: profileController,
      address: null,
    );
  }

  void _showAddressEditorDialog({
    required BuildContext context,
    required ProfileController profileController,
    AddressModel? address,
  }) {
    final isEditing = address != null;
    final nameCtrl = TextEditingController(text: address?.name ?? '');
    double selectedLat = (address?.latitude is num)
        ? (address!.latitude as num).toDouble()
        : double.tryParse(address?.latitude.toString() ?? '') ?? 9.0209;
    double selectedLng = (address?.longitude is num)
        ? (address!.longitude as num).toDouble()
        : double.tryParse(address?.longitude.toString() ?? '') ?? 38.7469;
    String locationLabel = address?.name ?? '';

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  isEditing ? Icons.edit_location_alt_rounded : Icons.add_location_alt_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'edit_address'.tr : 'add_address'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'address_name'.tr,
                      hintText: 'e.g. Home, Office, Bole Atlas',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LockedLocationPickerCard(
                    latitude: selectedLat,
                    longitude: selectedLng,
                    address: locationLabel,
                    buttonLabel: isEditing
                        ? 'change_location_on_map'.tr
                        : 'select_location_on_map'.tr,
                    onPickOnMap: () async {
                      final result = await Get.to<PropertyLocationResult>(
                        () => PropertyLocationPickerScreen(
                          title: 'Pin Delivery Address',
                          initialLatitude: selectedLat,
                          initialLongitude: selectedLng,
                          initialAddress: nameCtrl.text.trim().isNotEmpty
                              ? nameCtrl.text.trim()
                              : locationLabel,
                        ),
                      );
                      if (result != null) {
                        setDialogState(() {
                          selectedLat = result.latitude;
                          selectedLng = result.longitude;
                          if (result.address.isNotEmpty) {
                            locationLabel = result.address;
                            if (nameCtrl.text.trim().isEmpty) {
                              nameCtrl.text = result.address;
                            }
                          }
                        });
                      }
                    },
                    onAddressResolved: (resolved) {
                      setDialogState(() {
                        locationLabel = resolved;
                        if (nameCtrl.text.trim().isEmpty) {
                          nameCtrl.text = resolved;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('cancel'.tr),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final label = nameCtrl.text.trim().isNotEmpty
                      ? nameCtrl.text.trim()
                      : (locationLabel.isNotEmpty ? locationLabel : 'Home');
                  if (isEditing && address.id != null) {
                    profileController.editAddress(address.id!, label, selectedLat, selectedLng);
                  } else {
                    profileController.addAddress(label, selectedLat, selectedLng);
                  }
                },
                child: Text('save'.tr),
              ),
            ],
          );
        },
      ),
    );
  }
}
