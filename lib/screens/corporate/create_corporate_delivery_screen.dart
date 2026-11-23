import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/corporate_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/corporate_model.dart';

class CreateCorporateDeliveryScreen extends StatefulWidget {
  const CreateCorporateDeliveryScreen({super.key});

  @override
  State<CreateCorporateDeliveryScreen> createState() =>
      _CreateCorporateDeliveryScreenState();
}

class _CreateCorporateDeliveryScreenState
    extends State<CreateCorporateDeliveryScreen> {
  final CorporateController _controller = Get.find<CorporateController>();
  late final TextEditingController _remarkController;

  @override
  void initState() {
    super.initState();
    _remarkController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadOrderFormDependencies();
    });
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'New Corporate Delivery',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
      ),
      body: Obx(() {
        final senderBranch = _controller.senderBranch;
        final receiverBranches = _controller.availableReceiverBranches;
        final items = _controller.items;
        final vehicles = _controller.deliveryOptions;
        final selectedReceiver = _controller.selectedReceiverBranch.value;
        final selectedItem = _controller.selectedItem.value;
        final selectedVehicle = _controller.selectedDeliveryOption.value;
        final distanceKm = _controller.calculatedDistanceKm.value;
        final totalPrice = _controller.calculatedTotalPrice.value;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            // 1. Origin (Sender Branch - Locked)
            Text(
              'ORIGIN (SENDER BRANCH)',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLow
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trip_origin_rounded,
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
                          senderBranch?.branchName ?? 'Your Assigned Branch',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (senderBranch?.friendlyLocation != null)
                          Text(
                            senderBranch!.friendlyLocation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LOCKED',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Destination (Receiver Branch - Dropdown)
            Text(
              'DESTINATION (RECEIVER BRANCH)',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CompanyBranchModel>(
                  isExpanded: true,
                  value: receiverBranches.contains(selectedReceiver)
                      ? selectedReceiver
                      : (receiverBranches.isNotEmpty
                          ? receiverBranches.first
                          : null),
                  hint: const Text('Select destination branch'),
                  icon: const Icon(Icons.arrow_drop_down_rounded, size: 28),
                  items: receiverBranches.map((b) {
                    return DropdownMenuItem<CompanyBranchModel>(
                      value: b,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              b.branchName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (b) => _controller.onReceiverBranchChanged(b),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Item Selection
            Text(
              'ITEM TO DISPATCH',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items.map((item) {
                  final isSelected = selectedItem?.id == item.id;
                  return ChoiceChip(
                    label: Text(item.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (_) => _controller.onItemChanged(item),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            // 4. Delivery Vehicle / Options
            Text(
              'DELIVERY OPTION / VEHICLE',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            if (vehicles.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Column(
                children: vehicles.map((v) {
                  final isSelected = selectedVehicle?.id == v.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _controller.onDeliveryOptionChanged(v),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : (isDark
                                    ? AppColors.darkSurface
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkOutlineVariant
                                      : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.primary
                                          .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.two_wheeler_rounded,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v.carName,
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${v.kmPrice.toStringAsFixed(2)} ${v.displayCurrency} / km',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),

            // 5. Remark / Instructions
            Text(
              'REMARKS / SPECIAL INSTRUCTIONS (OPTIONAL)',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _remarkController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText:
                    'e.g. Fragile documents, handle with care, deliver to HR Dept.',
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkOutlineVariant
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkOutlineVariant
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 6. Distance & Price Calculation Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLow
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Distance (Haversine)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${distanceKm.toStringAsFixed(1)} km',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rate per km',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${selectedVehicle?.kmPrice.toStringAsFixed(2) ?? "0.00"} ${selectedVehicle?.displayCurrency ?? "ETB"}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Total',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${totalPrice.toStringAsFixed(2)} ${selectedVehicle?.displayCurrency ?? "ETB"}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Billed to company account on file',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.darkOutlineVariant
                  : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: Obx(() {
              final isSubmitting = _controller.isSubmitting.value;

              return ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () {
                        _controller.placeOrder(
                          remark: _remarkController.text.trim(),
                          onSuccess: () => Get.back(),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Confirm & Dispatch Delivery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
