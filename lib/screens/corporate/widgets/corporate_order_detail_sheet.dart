import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/pages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/corporate_model.dart';
import 'package:url_launcher/url_launcher.dart';

class CorporateOrderDetailSheet extends StatelessWidget {
  final CompanyOrderModel order;

  const CorporateOrderDetailSheet({super.key, required this.order});

  static void show(BuildContext context, CompanyOrderModel order) {
    Get.bottomSheet(
      CorporateOrderDetailSheet(order: order),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isPending = order.isPending;
    final statusColor = isPending ? const Color(0xFFD97706) : const Color(0xFF16A34A);
    final statusBg = isPending
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFDCFCE7);
    final statusText = isPending ? 'Pending Dispatch' : 'Finished / Delivered';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Corporate Order #${order.id}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    if (order.dateTime != null && order.dateTime!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        order.dateTime!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Body
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                // Route Card
                Container(
                  padding: const EdgeInsets.all(16),
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
                      _BranchRouteRow(
                        icon: Icons.trip_origin_rounded,
                        iconColor: AppColors.primary,
                        title: 'Origin (Sender Branch)',
                        branchName: order.fromBranch ?? 'Assigned Branch',
                        personName: order.senderFullName,
                        phone: order.senderPhone,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 2,
                            height: 24,
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      _BranchRouteRow(
                        icon: Icons.location_on_rounded,
                        iconColor: AppColors.secondary,
                        title: 'Destination (Receiver Branch)',
                        branchName: order.toBranch ?? 'Destination Branch',
                        personName: order.receiverFullName,
                        phone: order.receiverPhone,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Package & Vehicle Info
                Container(
                  padding: const EdgeInsets.all(16),
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
                      _DetailRow(
                        label: 'Dispatched Item',
                        value: order.item ?? 'Official Package',
                        icon: Icons.inventory_2_outlined,
                      ),
                      if (order.carType != null && order.carType!.isNotEmpty) ...[
                        const Divider(height: 18),
                        _DetailRow(
                          label: 'Delivery Vehicle',
                          value: order.carType!,
                          icon: Icons.two_wheeler_rounded,
                        ),
                      ],
                      const Divider(height: 18),
                      _DetailRow(
                        label: 'Distance',
                        value: '${order.totalKm.toStringAsFixed(1)} km',
                        icon: Icons.straighten_rounded,
                      ),
                      const Divider(height: 18),
                      _DetailRow(
                        label: 'Rate',
                        value: '${order.kmPrice.toStringAsFixed(2)} ${order.displayCurrency} / km',
                        icon: Icons.price_change_outlined,
                      ),
                      const Divider(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Price',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${order.totalPrice.toStringAsFixed(2)} ${order.displayCurrency}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Direct corporate monthly billing invoice',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Driver Contact Card (if assigned)
                if (order.hasDriver) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: const Icon(
                            Icons.directions_bike_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.driverFullName!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (order.driverPhone != null)
                                Text(
                                  order.driverPhone!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (order.driverPhone != null &&
                            order.driverPhone!.isNotEmpty)
                          IconButton(
                            onPressed: () => _makePhoneCall(order.driverPhone!),
                            icon: const Icon(
                              Icons.phone_in_talk_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainerLow
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkOutlineVariant
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isPending
                                ? 'Driver assignment in progress by AMN Dispatch'
                                : 'Completed delivery',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.toNamed(AppRoutes.tracking, arguments: order.toOrderModel());
                    },
                    icon: const Icon(Icons.location_searching_rounded, size: 20),
                    label: const Text(
                      'Track Driver Progress',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchRouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String branchName;
  final String personName;
  final String? phone;

  const _BranchRouteRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.branchName,
    required this.personName,
    this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                branchName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                phone != null && phone!.isNotEmpty
                    ? '$personName ($phone)'
                    : personName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
