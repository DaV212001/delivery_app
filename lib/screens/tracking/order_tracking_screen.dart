import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/order_controller.dart';
import '../../constants/app_assets.dart';
import '../../constants/pages.dart';
import '../../core/theme/app_colors.dart';
import '../../models/order.dart';
import '../../widgets/common/app_widgets.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orderController = Get.find<OrderController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.offAllNamed(AppRoutes.mainNav),
        ),
        title: Text(
          'track_order'.tr,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Obx(() {
        final order = orderController.activeOrder.value;
        if (order == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'no_active_order'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                AppButton(
                  width: 200,
                  text: 'back_to_home'.tr,
                  onPressed: () => Get.offAllNamed(AppRoutes.mainNav),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Stylized Map Background Simulation with Animated Scooter Pin
              SStackMap(driverName: order.driver?.name ?? 'Alex'),

              // Order ETA Card (Floating above content)
              Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delivery_dining_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'estimated_arrival'.tr,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.estimatedArrival,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.orderId,
                          style: const TextStyle(
                            color: AppColors.onPrimaryFixed,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4-Stage Stepper
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  children: [
                    _ProgressStep(
                      title: 'order_confirmed'.tr,
                      subtitle: 'order_confirmed_sub'.tr,
                      isCompleted: true,
                      isCurrent: false,
                      icon: Icons.check_circle_rounded,
                    ),
                    _ProgressLine(isCompleted: true),
                    _ProgressStep(
                      title: 'preparing_order'.tr,
                      subtitle: 'preparing_order_sub'.tr,
                      isCompleted: order.status != OrderProgressStatus.preparing,
                      isCurrent: order.status == OrderProgressStatus.preparing,
                      icon: Icons.inventory_2_rounded,
                    ),
                    _ProgressLine(isCompleted: order.status == OrderProgressStatus.onTheWay || order.status == OrderProgressStatus.delivered),
                    _ProgressStep(
                      title: 'on_the_way'.tr,
                      subtitle: 'on_the_way_sub'.tr,
                      isCompleted: order.status == OrderProgressStatus.delivered,
                      isCurrent: order.status == OrderProgressStatus.onTheWay,
                      icon: Icons.two_wheeler_rounded,
                    ),
                    _ProgressLine(isCompleted: order.status == OrderProgressStatus.delivered),
                    _ProgressStep(
                      title: 'delivered'.tr,
                      subtitle: 'delivered_sub'.tr,
                      isCompleted: order.status == OrderProgressStatus.delivered,
                      isCurrent: false,
                      icon: Icons.home_rounded,
                    ),
                  ],
                ),
              ),

              // Courier Card
              if (order.driver != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AppNetworkImage(
                            imageUrl: order.driver!.photoUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.driver!.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${order.driver!.vehicle} • ${order.driver!.plateNumber}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RatingBadge(rating: order.driver!.rating),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          child: IconButton(
                            icon: const Icon(Icons.call_rounded, color: AppColors.primary, size: 20),
                            onPressed: () {
                              Get.snackbar(
                                'calling_driver'.tr,
                                '${'calling'.tr} ${order.driver!.name} at ${order.driver!.phone}...',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Order Summary Snippet
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'order_details'.tr,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 2,
                            child: Text(
                              'store'.tr,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 3,
                            child: Text(
                              order.restaurantName,
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 2,
                            child: Text(
                              'delivery_address'.tr,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 3,
                            child: Text(
                              order.deliveryAddress,
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'total'.tr,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${order.total.toStringAsFixed(2)} Br',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class SStackMap extends StatelessWidget {
  final String driverName;

  const SStackMap({super.key, required this.driverName});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: AppNetworkImage(
              imageUrl: AppAssets.trackingMap,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.15),
            ),
          ),
          // Animated Scooter Pin
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isCurrent;
  final IconData icon;

  const _ProgressStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isCurrent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = isCompleted || isCurrent ? AppColors.primary : Colors.grey.shade400;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isCompleted || isCurrent
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: activeColor,
              width: isCurrent ? 2 : 1.5,
            ),
          ),
          child: Icon(icon, size: 20, color: activeColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: isCurrent ? AppColors.primary : theme.colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final bool isCompleted;

  const _ProgressLine({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(left: 18),
      height: 20,
      child: VerticalDivider(
        color: isCompleted ? AppColors.primary : Colors.grey.shade300,
        thickness: 2,
      ),
    );
  }
}
