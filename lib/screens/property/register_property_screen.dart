import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/my_property_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/my_property_model.dart';
import '../../services/gebeta_location_service.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/map/property_location_picker_screen.dart';

class RegisterPropertyScreen extends StatefulWidget {
  final MyPropertyModel? propertyToEdit;
  const RegisterPropertyScreen({super.key, this.propertyToEdit});

  @override
  State<RegisterPropertyScreen> createState() => _RegisterPropertyScreenState();
}

class _RegisterPropertyScreenState extends State<RegisterPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();
  final _deliveryTimeController = TextEditingController(text: '30 min');
  final _tinController = TextEditingController();
  final _latController = TextEditingController(text: '9.0209');
  final _lngController = TextEditingController(text: '38.7469');

  TimeOfDay _openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);

  int? _selectedCategoryId;
  int? _selectedTypeId;
  int? _selectedCurrencyId;

  String? _logoPath;
  String? _coverPath;
  String? _tinCertPath;
  String? _tradeLicensePath;

  bool _isGettingLocation = false;
  MyPropertyModel? _propertyToEdit;
  bool get _isEditing => _propertyToEdit != null;

  late final MyPropertyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<MyPropertyController>()
        ? Get.find<MyPropertyController>()
        : Get.put(MyPropertyController());

    _propertyToEdit = widget.propertyToEdit ??
        (Get.arguments is MyPropertyModel ? Get.arguments as MyPropertyModel : null);

    if (_propertyToEdit != null) {
      final p = _propertyToEdit!;
      _nameController.text = p.name;
      _locationController.text = p.friendlyLocation;
      _descController.text = p.description;
      _deliveryTimeController.text = p.deliveryTime.isNotEmpty ? p.deliveryTime : '30 min';
      _latController.text = p.latitude.isNotEmpty ? p.latitude : '9.0209';
      _lngController.text = p.longitude.isNotEmpty ? p.longitude : '38.7469';

      if (p.openingTime.contains(':')) {
        final parts = p.openingTime.split(':');
        final h = int.tryParse(parts[0]) ?? 8;
        final m = int.tryParse(parts[1]) ?? 0;
        _openTime = TimeOfDay(hour: h, minute: m);
      }
      if (p.closingTime.contains(':')) {
        final parts = p.closingTime.split(':');
        final h = int.tryParse(parts[0]) ?? 22;
        final m = int.tryParse(parts[1]) ?? 0;
        _closeTime = TimeOfDay(hour: h, minute: m);
      }
      _selectedCurrencyId = _controller.getCurrencyIdForProperty(p);
    }

    _controller.loadRegistrationDropdowns();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descController.dispose();
    _deliveryTimeController.dispose();
    _tinController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(Function(String path) onPicked) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        onPicked(picked.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(timeLimit: Duration(seconds: 10)),
        );
        setState(() {
          _latController.text = pos.latitude.toStringAsFixed(6);
          _lngController.text = pos.longitude.toStringAsFixed(6);
        });

        try {
          final address = await GebetaLocationService.reverseGeocode(
            pos.latitude,
            pos.longitude,
          );
          if (address.isNotEmpty &&
              _locationController.text.trim().isEmpty) {
            setState(() {
              _locationController.text = address;
            });
          }
        } catch (_) {}

        Get.snackbar(
          'Location updated',
          'GPS coordinates retrieved successfully',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (_) {
      Get.snackbar('Notice', 'Could not get GPS position. You can pick on the map.');
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _openMapLocationPicker() async {
    final double initialLat = double.tryParse(_latController.text) ?? 9.0209;
    final double initialLng = double.tryParse(_lngController.text) ?? 38.7469;

    final result = await Get.to<PropertyLocationResult>(
      () => PropertyLocationPickerScreen(
        initialLatitude: initialLat,
        initialLongitude: initialLng,
        initialAddress: _locationController.text.trim(),
      ),
    );

    if (result != null) {
      setState(() {
        _latController.text = result.latitude.toStringAsFixed(6);
        _lngController.text = result.longitude.toStringAsFixed(6);
        if (result.address.isNotEmpty && _locationController.text.trim().isEmpty) {
          _locationController.text = result.address;
        }
      });
      Get.snackbar(
        'Location Selected',
        'Pinned at ${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final min = tod.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  Future<void> _selectTime(bool isOpenTime) async {
    final initial = isOpenTime ? _openTime : _closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar('error'.tr, 'Please fill in required fields');
      return;
    }

    if (_selectedCategoryId == null && _controller.deliveryCategories.isNotEmpty) {
      _selectedCategoryId = _controller.deliveryCategories.first.id;
    }
    if (_selectedTypeId == null && _controller.deliveryTypes.isNotEmpty) {
      _selectedTypeId = _controller.deliveryTypes.first.id;
    }

    final effectiveCurrencyId = _selectedCurrencyId ??
        (_propertyToEdit != null ? _controller.getCurrencyIdForProperty(_propertyToEdit) : null) ??
        (_controller.currencies.any((c) => c.code.toUpperCase() == 'ETB')
            ? _controller.currencies.firstWhere((c) => c.code.toUpperCase() == 'ETB').id
            : (_controller.currencies.isNotEmpty ? _controller.currencies.first.id : 2));

    if (_isEditing) {
      _controller.updateExistingProperty(
        propertyId: _propertyToEdit!.id,
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId ?? 1,
        typeId: _selectedTypeId ?? 1,
        friendlyLocation: _locationController.text.trim(),
        description: _descController.text.trim(),
        deliveryTime: _deliveryTimeController.text.trim(),
        tinNumber: _tinController.text.trim().isNotEmpty ? _tinController.text.trim() : null,
        latitude: _latController.text.trim(),
        longitude: _lngController.text.trim(),
        fromTime: _formatTimeOfDay(_openTime),
        toTime: _formatTimeOfDay(_closeTime),
        logoPath: _logoPath,
        coverImagePath: _coverPath,
        tinCertificatePath: _tinCertPath,
        tradeLicensePath: _tradeLicensePath,
        currencyId: effectiveCurrencyId,
      );
    } else {
      _controller.registerNewProperty(
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId ?? 1,
        typeId: _selectedTypeId ?? 1,
        friendlyLocation: _locationController.text.trim(),
        description: _descController.text.trim(),
        deliveryTime: _deliveryTimeController.text.trim(),
        tinNumber: _tinController.text.trim().isNotEmpty ? _tinController.text.trim() : '0000000000',
        latitude: _latController.text.trim(),
        longitude: _lngController.text.trim(),
        fromTime: _formatTimeOfDay(_openTime),
        toTime: _formatTimeOfDay(_closeTime),
        logoPath: _logoPath,
        coverImagePath: _coverPath,
        tinCertificatePath: _tinCertPath,
        tradeLicensePath: _tradeLicensePath,
        currencyId: effectiveCurrencyId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'edit_property'.tr : 'register_property'.tr,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Obx(
            () => AppButton(
              text: _isEditing ? 'update_property'.tr : 'register_property'.tr,
              isLoading: _controller.isRegistering.value,
              onPressed: _handleSubmit,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Basic Store Info
                _buildCardSection(
                  context,
                  title: 'Store Information',
                  icon: Icons.storefront_rounded,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Property / Store Name *',
                        hintText: 'e.g. Bole Fresh Grocery',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter property name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Friendly Location / Area *',
                        hintText: 'e.g. Bole Rwanda, Addis Ababa',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                          tooltip: 'Pick on Map',
                          onPressed: _openMapLocationPicker,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter location area' : null,
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final cats = _controller.deliveryCategories;
                      if (cats.isEmpty && _controller.isLoadingDropdowns.value) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final selectedCat = cats.any((c) => c.id == _selectedCategoryId)
                          ? _selectedCategoryId
                          : (_propertyToEdit != null && cats.any((c) => c.name.text.toLowerCase() == _propertyToEdit!.categoryName.toLowerCase())
                              ? cats.firstWhere((c) => c.name.text.toLowerCase() == _propertyToEdit!.categoryName.toLowerCase()).id
                              : (cats.isNotEmpty ? cats.first.id : null));
                      return DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: selectedCat,
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                        items: cats.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.name.text,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                      );
                    }),
                    const SizedBox(height: 12),
                    Obx(() {
                      final types = _controller.deliveryTypes;
                      if (types.isEmpty && _controller.isLoadingDropdowns.value) {
                        return const SizedBox.shrink();
                      }
                      final selectedType = types.any((t) => t.id == _selectedTypeId)
                          ? _selectedTypeId
                          : (_propertyToEdit != null && types.any((t) => t.name.text.toLowerCase() == _propertyToEdit!.typeName.toLowerCase())
                              ? types.firstWhere((t) => t.name.text.toLowerCase() == _propertyToEdit!.typeName.toLowerCase()).id
                              : (types.isNotEmpty ? types.first.id : null));
                      return DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: selectedType,
                        decoration: InputDecoration(
                          labelText: 'Business Type *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                        items: types.map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(
                            t.name.text,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedTypeId = val),
                      );
                    }),
                    const SizedBox(height: 12),
                    Obx(() {
                      final currencies = _controller.currencies;
                      if (currencies.isEmpty && _controller.isLoadingDropdowns.value) {
                        return const SizedBox.shrink();
                      }
                      final selectedCurrency = currencies.any((c) => c.id == _selectedCurrencyId)
                          ? _selectedCurrencyId
                          : (_propertyToEdit != null && _controller.getCurrencyIdForProperty(_propertyToEdit) != null && currencies.any((c) => c.id == _controller.getCurrencyIdForProperty(_propertyToEdit))
                              ? _controller.getCurrencyIdForProperty(_propertyToEdit)
                              : (currencies.any((c) => c.code.toUpperCase() == 'ETB')
                                  ? currencies.firstWhere((c) => c.code.toUpperCase() == 'ETB').id
                                  : (currencies.isNotEmpty ? currencies.first.id : null)));
                      return DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: selectedCurrency,
                        decoration: InputDecoration(
                          labelText: 'Currency *',
                          hintText: 'Select store currency',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          prefixIcon: const Icon(Icons.monetization_on_outlined),
                        ),
                        items: currencies.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.code} (${c.symbol})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedCurrencyId = val),
                        validator: (val) => val == null ? 'Please select a currency' : null,
                      );
                    }),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Provide details about your store, products or specialty...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Section 2: Operating Schedule & Delivery
                _buildCardSection(
                  context,
                  title: 'Operating Hours & Dispatch',
                  icon: Icons.access_time_rounded,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Opens At', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(_formatTimeOfDay(_openTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Closes At', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(_formatTimeOfDay(_closeTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deliveryTimeController,
                      decoration: InputDecoration(
                        labelText: 'Estimated Prep & Delivery Time',
                        hintText: 'e.g. 30 min',
                        prefixIcon: const Icon(Icons.delivery_dining_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Section 3: Store Imagery
                _buildCardSection(
                  context,
                  title: 'Store Imagery',
                  icon: Icons.photo_camera_back_outlined,
                  children: [
                    Row(
                      children: [
                        // Store Logo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Store Logo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => _pickImage((path) => _logoPath = path),
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _logoPath != null
                                      ? Image.file(File(_logoPath!), fit: BoxFit.cover, width: double.infinity)
                                      : (_isEditing && _propertyToEdit!.logo.isNotEmpty)
                                          ? Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                AppNetworkImage(
                                                  imageUrl: _propertyToEdit!.logo,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                ),
                                                Container(
                                                  color: Colors.black26,
                                                  child: const Center(
                                                    child: Icon(Icons.edit_rounded, color: Colors.white, size: 22),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                                                  SizedBox(height: 4),
                                                  Text('Upload Logo', style: TextStyle(fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Cover Banner
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cover Banner', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => _pickImage((path) => _coverPath = path),
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _coverPath != null
                                      ? Image.file(File(_coverPath!), fit: BoxFit.cover, width: double.infinity)
                                      : (_isEditing && _propertyToEdit!.coverImage.isNotEmpty)
                                          ? Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                AppNetworkImage(
                                                  imageUrl: _propertyToEdit!.coverImage,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                ),
                                                Container(
                                                  color: Colors.black26,
                                                  child: const Center(
                                                    child: Icon(Icons.edit_rounded, color: Colors.white, size: 22),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.image_outlined, color: AppColors.primary),
                                                  SizedBox(height: 4),
                                                  Text('Upload Banner', style: TextStyle(fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Section 4: Legal & Verification
                _buildCardSection(
                  context,
                  title: 'Business Verification',
                  icon: Icons.verified_user_outlined,
                  children: [
                    TextFormField(
                      controller: _tinController,
                      decoration: InputDecoration(
                        labelText: 'TIN Number',
                        hintText: 'e.g. 00142152435235',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: Icon(
                              _tinCertPath != null ? Icons.check_circle_rounded : Icons.upload_file,
                              color: _tinCertPath != null ? Colors.green : AppColors.primary,
                              size: 18,
                            ),
                            label: Text(
                              _tinCertPath != null ? 'TIN Attached' : 'TIN Certificate',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _pickImage((path) => _tinCertPath = path),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: Icon(
                              _tradeLicensePath != null ? Icons.check_circle_rounded : Icons.upload_file,
                              color: _tradeLicensePath != null ? Colors.green : AppColors.primary,
                              size: 18,
                            ),
                            label: Text(
                              _tradeLicensePath != null ? 'License Attached' : 'Trade License',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _pickImage((path) => _tradeLicensePath = path),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Section 5: Map Location Selector
                _buildCardSection(
                  context,
                  title: 'Store Location on Map',
                  icon: Icons.map_rounded,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerLow
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.pin_drop_rounded,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pinned Coordinates',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _latController.text.isNotEmpty && _lngController.text.isNotEmpty
                                          ? '${_latController.text}, ${_lngController.text}'
                                          : 'No coordinates pinned yet',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_locationController.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.place_outlined, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _locationController.text,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.map_rounded, size: 18),
                                  label: const Text('Pick on Map'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: _openMapLocationPicker,
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                icon: _isGettingLocation
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.gps_fixed_rounded, size: 16),
                                label: const Text('GPS Position', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}
