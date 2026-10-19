import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/restaurant_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/delivery_item.dart';
import '../../models/store.dart';
import '../../widgets/common/app_widgets.dart';

class ItemCustomizationModal extends StatefulWidget {
  final DeliveryItem item;

  const ItemCustomizationModal({super.key, required this.item});

  static Future<void> show(BuildContext context, DeliveryItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemCustomizationModal(item: item),
    );
  }

  @override
  State<ItemCustomizationModal> createState() => _ItemCustomizationModalState();
}

class _ItemCustomizationModalState extends State<ItemCustomizationModal> {
  int _quantity = 1;
  String? _selectedVariant;
  final Set<String> _selectedAddonIds = {};
  final Set<String> _removedOptions = {};
  final _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item.availableVariants.isNotEmpty) {
      _selectedVariant = widget.item.availableVariants.first;
    }
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  double get _currentUnitPrice {
    double price = widget.item.price;
    for (final addon in widget.item.availableAddons) {
      if (_selectedAddonIds.contains(addon.id)) {
        price += addon.price;
      }
    }
    return price;
  }

  double get _currentTotalPrice => _currentUnitPrice * _quantity;

  Store? get _store {
    if (Get.isRegistered<RestaurantController>()) {
      final rc = Get.find<RestaurantController>();
      return rc.getRestaurantById(widget.item.storeId);
    }
    return null;
  }

  bool get _isStoreClosed => _store?.isPastClosingTime ?? false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartController = Get.find<CartController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AppNetworkImage(
                      imageUrl: widget.item.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${widget.item.price.toStringAsFixed(2)} Br',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    widget.item.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dynamic Variants Radio Group (if applicable: color, size, meat temperature, etc.)
                  if (widget.item.availableVariants.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.item.variantTitle ?? 'options'.tr,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'required'.tr,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.item.availableVariants.map((variant) {
                      final isSelected = _selectedVariant == variant;
                      return InkWell(
                        onTap: () => setState(() => _selectedVariant = variant),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                variant,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.grey.shade400,
                                    width: isSelected ? 6 : 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const Divider(height: 32),
                  ],

                  // Add-ons & Extras (if applicable)
                  if (widget.item.availableAddons.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'add_ons_extras'.tr,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'optional'.tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.item.availableAddons.map((addon) {
                      final isChecked = _selectedAddonIds.contains(addon.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(addon.name, style: theme.textTheme.bodyMedium),
                        subtitle: Text(
                          '+ ${addon.price.toStringAsFixed(2)} Br',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12),
                        ),
                        activeColor: AppColors.primary,
                        value: isChecked,
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              _selectedAddonIds.add(addon.id);
                            } else {
                              _selectedAddonIds.remove(addon.id);
                            }
                          });
                        },
                      );
                    }),
                    const Divider(height: 32),
                  ],

                  // Preferences / Removable Options (if applicable)
                  if (widget.item.removableOptions.isNotEmpty) ...[
                    Text(
                      'preferences_exclusions'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.item.removableOptions.map((opt) {
                        final isRemoved = _removedOptions.contains(opt);
                        final displayLabel = opt.toLowerCase().startsWith('no ') ? opt : 'No $opt';
                        return FilterChip(
                          label: Text(displayLabel),
                          selected: isRemoved,
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isRemoved ? AppColors.primary : theme.colorScheme.onSurface,
                            fontWeight: isRemoved ? FontWeight.w600 : FontWeight.w500,
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _removedOptions.add(opt);
                              } else {
                                _removedOptions.remove(opt);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(height: 32),
                  ],

                  // Special Instructions
                  Text(
                    'special_instructions'.tr,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _instructionsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'instructions_hint'.tr,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceContainerLow
                          : AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Sticky Bottom Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isStoreClosed) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded, size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'closed_ordering_disabled'.tr,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Row(
                  children: [
                    // Quantity Stepper
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerLow
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded, size: 20),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              '$_quantity',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 20),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Add to Cart / Save for Later Button
                    Expanded(
                      child: AppButton(
                        text: _isStoreClosed
                            ? '${'save_order_for_later'.tr} • ${_currentTotalPrice.toStringAsFixed(2)} Br'
                            : '${'add_to_cart'.tr} • ${_currentTotalPrice.toStringAsFixed(2)} Br',
                        onPressed: () {
                          final selectedAddonsList = widget.item.availableAddons
                              .where((a) => _selectedAddonIds.contains(a.id))
                              .toList();

                          cartController.addItem(
                            item: widget.item,
                            quantity: _quantity,
                            selectedVariant: _selectedVariant,
                            selectedAddons: selectedAddonsList,
                            removedOptions: _removedOptions.toList(),
                            specialInstructions: _instructionsController.text.trim().isNotEmpty
                                ? _instructionsController.text.trim()
                                : null,
                          );

                          Get.back();
                          if (_isStoreClosed) {
                            final nextOpen = _store?.formattedNextOpenTime ?? '08:30 AM';
                            Get.snackbar(
                              'item_added'.tr,
                              '${widget.item.name} ${'added_store_closed_tip'.tr} $nextOpen',
                              backgroundColor: const Color(0xFFB45309),
                              colorText: Colors.white,
                              snackPosition: SnackPosition.TOP,
                              duration: const Duration(seconds: 4),
                              icon: const Icon(Icons.schedule_rounded, color: Colors.white),
                            );
                          } else {
                            Get.snackbar(
                              'add_to_cart'.tr,
                              '$_quantity x ${widget.item.name}',
                              backgroundColor: AppColors.primary,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.TOP,
                              duration: const Duration(seconds: 2),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
