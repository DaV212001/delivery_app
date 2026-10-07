import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/my_property_controller.dart';
import '../../../core/theme/app_colors.dart';

void showAddEditCategoryDialog({
  required BuildContext context,
  required MyPropertyController controller,
  int? categoryId,
  String? initialName,
}) {
  final textController = TextEditingController(text: initialName ?? '');
  final isEditing = categoryId != null;

  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isEditing ? 'edit_category'.tr : 'add_category'.tr,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'category_name'.tr,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: textController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. Beverages, Bakery, Burgers',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('cancel'.tr),
        ),
        Obx(() {
          if (controller.isActionLoading.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            );
          }
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final name = textController.text.trim();
              if (name.isEmpty) {
                Get.snackbar('error'.tr, 'Please enter a category name');
                return;
              }
              if (isEditing) {
                controller.editCategory(categoryId, name);
              } else {
                controller.addCategory(name);
              }
            },
            child: Text('save'.tr),
          );
        }),
      ],
    ),
  );
}
