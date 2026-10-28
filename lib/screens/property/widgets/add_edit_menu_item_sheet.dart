import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/my_property_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/my_menu_item_model.dart';
import '../../../utils/currency_utils.dart';
import '../../../widgets/common/app_widgets.dart';
import 'add_edit_category_dialog.dart';

void showAddEditMenuItemSheet({
  required BuildContext context,
  required MyPropertyController controller,
  MyMenuItemModel? itemToEdit,
}) {
  final isEditing = itemToEdit != null;
  final nameCtrl = TextEditingController(text: itemToEdit?.name ?? '');
  final priceCtrl = TextEditingController(
    text: itemToEdit != null ? itemToEdit.price.toStringAsFixed(0) : '',
  );
  final descCtrl = TextEditingController(text: itemToEdit?.description ?? '');
  final discountCtrl = TextEditingController(
    text: itemToEdit?.discountPercent != null && itemToEdit!.discountPercent! > 0
        ? itemToEdit.discountPercent!.toStringAsFixed(0)
        : '',
  );

  final selectedCatId = Rx<dynamic>(
    itemToEdit?.menuCategoryId ?? (controller.categories.isNotEmpty ? controller.categories.first.id : null),
  );
  final isSpecialOffer = RxBool(itemToEdit?.specialOffer ?? false);
  final pickedImagePath = Rx<String?>(null);

  final formKey = GlobalKey<FormState>();

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (picked != null) {
      pickedImagePath.value = picked.path;
    }
  }

  Get.bottomSheet(
    Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header handle & title
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'edit_menu_item'.tr : 'add_menu_item'.tr,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Image picker section
                    Center(
                      child: Obx(() {
                        final path = pickedImagePath.value;
                        final currentImg = itemToEdit?.image ?? '';

                        Widget preview;
                        if (path != null) {
                          preview = Image.file(
                            File(path),
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          );
                        } else if (currentImg.isNotEmpty) {
                          preview = AppNetworkImage(
                            imageUrl: currentImg,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          );
                        } else {
                          preview = Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.primary),
                              const SizedBox(height: 6),
                              Text(
                                'add_photo'.tr,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          );
                        }

                        return GestureDetector(
                          onTap: () {
                            Get.bottomSheet(
                              Container(
                                color: Theme.of(context).cardColor,
                                child: SafeArea(
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.photo_library_outlined),
                                        title: Text('choose_from_gallery'.tr),
                                        onTap: () {
                                          Get.back();
                                          pickImage(ImageSource.gallery);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt_outlined),
                                        title: Text('take_a_photo'.tr),
                                        onTap: () {
                                          Get.back();
                                          pickImage(ImageSource.camera);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                style: BorderStyle.solid,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: preview,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Item Name
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: '${'item_name'.tr} *',
                        hintText: 'e.g. Avocado Toast, Burger Combo',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 14),

                    // Category Selector Row
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() {
                            final cats = controller.categories;
                            if (cats.isEmpty) {
                              return Text(
                                'No categories created yet. Click "+ Add" to create one.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              );
                            }

                            // Ensure selected is valid
                            final current = selectedCatId.value;
                            final validValue = cats.any((c) => c.id.toString() == current?.toString())
                                ? cats.firstWhere((c) => c.id.toString() == current?.toString()).id
                                : cats.first.id;

                            return DropdownButtonFormField<dynamic>(
                              isExpanded: true,
                              initialValue: validValue,
                              decoration: InputDecoration(
                                labelText: 'category'.tr,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                              ),
                              items: cats.map((cat) {
                                return DropdownMenuItem<dynamic>(
                                  value: cat.id,
                                  child: Text(
                                    cat.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                selectedCatId.value = val;
                              },
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add_rounded),
                          tooltip: 'add_category'.tr,
                          onPressed: () => showAddEditCategoryDialog(
                            context: context,
                            controller: controller,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Price Field
                    Obx(
                      () {
                        final storeProp = controller.selectedProperty.value;
                        final currencyCode = storeProp != null
                            ? controller.getPropertyCurrencyCode(storeProp)
                            : (itemToEdit?.currency != null && itemToEdit!.currency!.isNotEmpty
                                ? CurrencyUtils.resolveCode(itemToEdit.currency)
                                : controller.getPropertyCurrencyCode(null));
                        return TextFormField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: '${'price'.tr} ($currencyCode) *',
                            hintText: 'e.g. 250',
                            suffixText: currencyCode,
                            suffixStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter price';
                            if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Special Offer Switch & Discount
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSpecialOffer.value
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSpecialOffer.value
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_offer_outlined,
                                      color: isSpecialOffer.value ? AppColors.primary : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'special_offer'.tr,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: isSpecialOffer.value,
                                  activeTrackColor: AppColors.primary,
                                  onChanged: (val) => isSpecialOffer.value = val,
                                ),
                              ],
                            ),
                            if (isSpecialOffer.value) ...[
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: discountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: '${'discount_percent'.tr} (%)',
                                  hintText: 'e.g. 15',
                                  suffixText: '%',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: '${'description'.tr} *',
                        hintText: 'Describe ingredients, options, or details...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    Obx(
                      () => AppButton(
                        text: isEditing ? 'update_item'.tr : 'add_menu_item'.tr,
                        isLoading: controller.isActionLoading.value,
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;

                          final catId = selectedCatId.value;
                          if (catId == null && controller.categories.isNotEmpty) {
                            selectedCatId.value = controller.categories.first.id;
                          }

                          final parsedPrice = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                          final parsedDiscount = double.tryParse(discountCtrl.text.trim()) ?? 0.0;

                          controller.saveMenuItem(
                            editingId: itemToEdit?.id,
                            name: nameCtrl.text.trim(),
                            menuCategoryId: selectedCatId.value ?? 0,
                            price: parsedPrice,
                            description: descCtrl.text.trim(),
                            specialOffer: isSpecialOffer.value,
                            discountPercent: parsedDiscount,
                            imagePath: pickedImagePath.value,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    isScrollControlled: true,
  );
}
