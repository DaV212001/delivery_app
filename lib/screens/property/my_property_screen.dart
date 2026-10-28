import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/my_property_controller.dart';
import '../../constants/pages.dart';
import '../../core/theme/app_colors.dart';
import '../../models/my_menu_item_model.dart';
import '../../models/my_property_model.dart';
import '../../widgets/common/app_widgets.dart';
import 'widgets/add_edit_category_dialog.dart';
import 'widgets/add_edit_menu_item_sheet.dart';

class MyPropertyScreen extends StatelessWidget {
  const MyPropertyScreen({super.key});

  void _showPropertySwitcherSheet(BuildContext context, MyPropertyController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Get.bottomSheet(
      Material(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      'Your Properties',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add New'),
                      onPressed: () {
                        Get.back();
                        Get.toNamed(AppRoutes.registerProperty);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Column(
                    children: controller.properties.map((prop) {
                      final isSelected = controller.selectedProperty.value?.id == prop.id;
                      return ListTile(
                        onTap: () {
                          controller.selectProperty(prop);
                          Get.back();
                        },
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: prop.logo.isNotEmpty
                              ? AppNetworkImage(imageUrl: prop.logo, width: 44, height: 44, fit: BoxFit.cover)
                              : const Icon(Icons.storefront_rounded, color: AppColors.primary),
                        ),
                        title: Text(
                          prop.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                        subtitle: Text(prop.friendlyLocation.isNotEmpty ? prop.friendlyLocation : 'Addis Ababa'),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                            : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showManageCategoriesSheet(BuildContext context, MyPropertyController controller) {
    final theme = Theme.of(context);

    Get.bottomSheet(
      Material(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    Expanded(
                      child: Text(
                        'manage_categories'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text('add_category'.tr),
                      onPressed: () {
                        Get.back();
                        showAddEditCategoryDialog(context: context, controller: controller);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final cats = controller.categories;
                  if (cats.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No categories yet',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: cats.map((cat) {
                      final count = controller.menuItems
                          .where((m) => m.menuCategoryId?.toString() == cat.id.toString())
                          .length;
                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.category_outlined, size: 18, color: AppColors.primary),
                        ),
                        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('$count items'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                          tooltip: 'edit_category'.tr,
                          onPressed: () {
                            Get.back();
                            showAddEditCategoryDialog(
                              context: context,
                              controller: controller,
                              categoryId: cat.id,
                              initialName: cat.name,
                            );
                          },
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
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
    final controller = Get.isRegistered<MyPropertyController>()
        ? Get.find<MyPropertyController>()
        : Get.put(MyPropertyController());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Obx(() {
          final prop = controller.selectedProperty.value;
          final propCount = controller.properties.length;

          if (prop == null || propCount <= 1) {
            return Text(
              prop?.name ?? 'my_property'.tr,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            );
          }

          // Switcher dropdown trigger in appbar
          return InkWell(
            onTap: () => _showPropertySwitcherSheet(context, controller),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      prop.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down_rounded, size: 22),
                ],
              ),
            ),
          );
        }),
        actions: [
          // 1. Orders action with real-time active orders badge
          Obx(() {
            final prop = controller.selectedProperty.value;
            if (prop == null) return const SizedBox.shrink();

            final activeCount = controller.activeOrdersCount;
            return IconButton(
              tooltip: 'store_orders'.tr,
              icon: Badge(
                isLabelVisible: activeCount > 0,
                label: Text('$activeCount'),
                backgroundColor: Colors.orange,
                child: const Icon(Icons.receipt_long_rounded),
              ),
              onPressed: () {
                Get.toNamed(AppRoutes.propertyOrders, arguments: prop);
              },
            );
          }),

          // 2. Clean overflow options menu (consolidates schedules, edit, all stores & register)
          Obx(() {
            final prop = controller.selectedProperty.value;
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'Options',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (value) {
                switch (value) {
                  case 'schedules':
                    if (prop != null) {
                      Get.toNamed(AppRoutes.propertySchedules, arguments: prop);
                    }
                    break;
                  case 'edit':
                    if (prop != null) {
                      Get.toNamed(AppRoutes.editProperty, arguments: prop);
                    }
                    break;
                  case 'all_stores':
                    if (Navigator.of(context).canPop()) {
                      Get.back();
                    } else {
                      Get.toNamed(AppRoutes.myProperty);
                    }
                    break;
                  case 'register':
                    Get.toNamed(AppRoutes.registerProperty);
                    break;
                }
              },
              itemBuilder: (context) => [
                if (prop != null) ...[
                  PopupMenuItem(
                    value: 'schedules',
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text('manage_schedules'.tr),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text('edit_property'.tr),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                ],
                if (controller.properties.length > 1)
                  PopupMenuItem(
                    value: 'all_stores',
                    child: Row(
                      children: [
                        const Icon(Icons.store_mall_directory_outlined, size: 18),
                        const SizedBox(width: 12),
                        Text('all_stores'.tr),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'register',
                  child: Row(
                    children: [
                      const Icon(Icons.add_business_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text('register_new_property'.tr),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      floatingActionButton: Obx(() {
        if (controller.selectedProperty.value == null) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: Text('add_menu_item'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
          onPressed: () => showAddEditMenuItemSheet(
            context: context,
            controller: controller,
          ),
        );
      }),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final property = controller.selectedProperty.value;

        // EMPTY STATE: User has no properties registered yet
        if (property == null || controller.properties.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => controller.loadProperties(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.storefront_rounded,
                          size: 42,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'no_property_yet'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'no_property_desc'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    AppButton(
                      text: 'register_property'.tr,
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      onPressed: () => Get.toNamed(AppRoutes.registerProperty),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // POPULATED DASHBOARD: Merchant Overview & Catalog
        return RefreshIndicator(
          onRefresh: () => controller.loadProperties(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 0. Multi-Store Context Switcher Pills (when merchant has multiple properties)
                if (controller.properties.length > 1) ...[
                  _buildStoreSwitcherPills(context, controller, isDark),
                  const SizedBox(height: 14),
                ],

                // 1. Property Overview Hero Card
                _buildPropertyHeroCard(context, property, isDark),
                const SizedBox(height: 20),

                // 2. Category Filter Pills
                _buildCategorySection(context, controller, isDark),
                const SizedBox(height: 18),

                // 3. Search & Menu Catalog Section
                _buildCatalogSection(context, controller, isDark),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStoreSwitcherPills(
    BuildContext context,
    MyPropertyController controller,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final primaryColor = AppColors.primary;
    final selectedId = controller.selectedProperty.value?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.storefront_rounded, size: 16, color: primaryColor),
                const SizedBox(width: 6),
                Text(
                  'active_store'.tr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => _showPropertySwitcherSheet(context, controller),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'all_stores'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 16, color: primaryColor),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...controller.properties.map((prop) {
                final isSelected = prop.id == selectedId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => controller.selectProperty(prop),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor
                              : (isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : (theme.dividerColor.withValues(alpha: 0.12)),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (prop.logo.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: AppNetworkImage(
                                  imageUrl: prop.logo,
                                  width: 18,
                                  height: 18,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ] else ...[
                              Icon(
                                Icons.storefront_rounded,
                                size: 16,
                                color: isSelected ? Colors.white : primaryColor,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              prop.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // Add New Store Quick Chip
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.toNamed(AppRoutes.registerProperty),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'register_new_property'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyHeroCard(BuildContext context, MyPropertyModel property, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image & Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Cover
              Container(
                height: 120,
                width: double.infinity,
                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                child: property.coverImage.isNotEmpty
                    ? AppNetworkImage(
                        imageUrl: property.coverImage,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.storefront, color: Colors.white70, size: 36),
                        ),
                      ),
              ),
              // Logo Avatar overlaid
              Positioned(
                left: 16,
                bottom: -24,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: property.logo.isNotEmpty
                        ? AppNetworkImage(imageUrl: property.logo, width: 64, height: 64, fit: BoxFit.cover)
                        : const Icon(Icons.business_rounded, color: AppColors.primary, size: 28),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Under Review Notice Banner
          if (property.isUnderReview)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: Colors.amber.shade800, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'property_under_review_title'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'property_under_review_desc'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.amber.shade100 : Colors.amber.shade900,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Name & Live Status Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        property.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Live Status Chip (based on opening/closing times)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (property.isOpen ? Colors.green : Colors.grey).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: property.isOpen ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            property.isOpen ? 'store_open'.tr : 'store_closed'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: property.isOpen ? Colors.green.shade700 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (property.friendlyLocation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.friendlyLocation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),

                // Responsive Store Badges (Category, Business Type, Dispatch, Currency)
                Builder(
                  builder: (context) {
                    final myPropController = Get.isRegistered<MyPropertyController>()
                        ? Get.find<MyPropertyController>()
                        : null;
                    final currencyCode = myPropController?.getPropertyCurrencyCode(property) ?? property.currency;

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (property.categoryName.isNotEmpty)
                          _buildBadgeChip(
                            icon: Icons.category_outlined,
                            label: property.categoryName,
                            isDark: isDark,
                          ),
                        if (property.typeName.isNotEmpty && property.typeName != property.categoryName)
                          _buildBadgeChip(
                            icon: Icons.storefront_outlined,
                            label: property.typeName,
                            isDark: isDark,
                          ),
                        if (property.deliveryTime.isNotEmpty)
                          _buildBadgeChip(
                            icon: Icons.delivery_dining_outlined,
                            label: property.deliveryTime,
                            isDark: isDark,
                          ),
                        if (currencyCode.isNotEmpty)
                          _buildBadgeChip(
                            icon: Icons.monetization_on_outlined,
                            label: currencyCode,
                            color: Colors.teal,
                            isDark: isDark,
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Store Orders Navigation Tile
                InkWell(
                  onTap: () => Get.toNamed(AppRoutes.propertyOrders, arguments: property),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.blue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'store_orders'.tr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Obx(() {
                                    final myPropCtrl = Get.isRegistered<MyPropertyController>()
                                        ? Get.find<MyPropertyController>()
                                        : null;
                                    final active = myPropCtrl?.activeOrdersCount ?? 0;
                                    if (active == 0) return const SizedBox.shrink();
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$active active',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Obx(() {
                                final myPropCtrl = Get.isRegistered<MyPropertyController>()
                                    ? Get.find<MyPropertyController>()
                                    : null;
                                final total = myPropCtrl?.propertyOrders.length ?? 0;
                                final revenue = myPropCtrl?.totalOrdersRevenue ?? 0.0;
                                final currCode = myPropCtrl?.getPropertyCurrencyCode(property) ?? property.currency;
                                return Text(
                                  total > 0
                                      ? '$total orders • ${revenue.toStringAsFixed(0)} $currCode sales'
                                      : 'Track incoming customer orders & sales',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Operating Schedules & Shifts Navigation Tile
                InkWell(
                  onTap: () => Get.toNamed(AppRoutes.propertySchedules, arguments: property),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'manage_schedules'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Configure weekly shifts & opening hours',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                        icon: const Icon(Icons.receipt_long_rounded, size: 16),
                        label: Obx(() {
                          final myPropCtrl = Get.isRegistered<MyPropertyController>()
                              ? Get.find<MyPropertyController>()
                              : null;
                          final count = myPropCtrl?.activeOrdersCount ?? 0;
                          return Text(
                            count > 0 ? 'Orders ($count)' : 'Orders',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                        onPressed: () => Get.toNamed(AppRoutes.propertyOrders, arguments: property),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                        icon: const Icon(Icons.calendar_month_outlined, size: 16),
                        label: Text(
                          'schedules'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => Get.toNamed(AppRoutes.propertySchedules, arguments: property),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(
                          'edit_property'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => Get.toNamed(AppRoutes.editProperty, arguments: property),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeChip({
    required IconData icon,
    required String label,
    required bool isDark,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: chipColor.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: chipColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, MyPropertyController controller, bool isDark) {
    final theme = Theme.of(context);
    return Obx(() {
      final cats = controller.categories;
      final selectedId = controller.selectedCategoryId.value;
      final totalItems = controller.menuItems.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'menu_categories'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showManageCategoriesSheet(context, controller),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune_rounded, size: 15, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'manage_categories'.tr,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                tooltip: 'add_category'.tr,
                onPressed: () => showAddEditCategoryDialog(
                  context: context,
                  controller: controller,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "All" Chip
                PillChip(
                  label: 'All ($totalItems)',
                  isSelected: selectedId == null,
                  onTap: () => controller.filterByCategory(null),
                ),
                const SizedBox(width: 8),
                ...cats.map((cat) {
                  final isSelected = selectedId == cat.id;
                  final count = controller.menuItems.where((m) => m.menuCategoryId?.toString() == cat.id.toString()).length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onLongPress: () => showAddEditCategoryDialog(
                        context: context,
                        controller: controller,
                        categoryId: cat.id,
                        initialName: cat.name,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => controller.filterByCategory(cat.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : theme.dividerColor.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${cat.name} ($count)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => showAddEditCategoryDialog(
                                    context: context,
                                    controller: controller,
                                    categoryId: cat.id,
                                    initialName: cat.name,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // Quick Add Category Chip
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => showAddEditCategoryDialog(
                      context: context,
                      controller: controller,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 15, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'add_category'.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCatalogSection(BuildContext context, MyPropertyController controller, bool isDark) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: controller.updateSearch,
            decoration: InputDecoration(
              hintText: 'Search items in catalog...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Items List
        Obx(() {
          if (controller.isLoadingMenus.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final items = controller.filteredMenuItems;

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No items found',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.searchQuery.value.isNotEmpty
                          ? 'Try different search keywords'
                          : 'Tap "+ Add Item" to add your first menu product',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, index) {
              final item = items[index];
              return _buildMenuItemCard(context, controller, item, isDark);
            },
          );
        }),
      ],
    );
  }

  Widget _buildMenuItemCard(
    BuildContext context,
    MyPropertyController controller,
    MyMenuItemModel item,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.image.isNotEmpty
                ? AppNetworkImage(imageUrl: item.image, width: 68, height: 68, fit: BoxFit.cover)
                : const Icon(Icons.fastfood_outlined, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.specialOffer) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.discountPercent != null && item.discountPercent! > 0
                              ? '-${item.discountPercent!.toStringAsFixed(0)}%'
                              : 'Offer',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  item.formattedPrice,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Actions: Active Switch & Edit Pen
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: Colors.grey.shade600,
                tooltip: 'edit_menu_item'.tr,
                onPressed: () => showAddEditMenuItemSheet(
                  context: context,
                  controller: controller,
                  itemToEdit: item,
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: item.isActive,
                  activeTrackColor: AppColors.primary,
                  onChanged: (_) => controller.toggleMenuStatus(item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
