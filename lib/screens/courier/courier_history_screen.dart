import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/pages.dart';
import '../../controllers/courier_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/courier_model.dart';

class CourierHistoryScreen extends StatefulWidget {
  final int initialTabIndex;
  const CourierHistoryScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CourierHistoryScreen> createState() => _CourierHistoryScreenState();
}

class _CourierHistoryScreenState extends State<CourierHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final CourierController _courierController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _courierController = Get.isRegistered<CourierController>()
        ? Get.find<CourierController>()
        : Get.put(CourierController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _courierController.loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Deliveries',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainerLow
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
              tabs: [
                Obx(() {
                  final count = _courierController.activeOrders.length;
                  return Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Active'),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const Tab(text: 'Past Deliveries'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Active Orders
          _buildOrdersList(
            isDark: isDark,
            theme: theme,
            isActiveTab: true,
          ),
          // Tab 2: Past Orders
          _buildOrdersList(
            isDark: isDark,
            theme: theme,
            isActiveTab: false,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList({
    required bool isDark,
    required ThemeData theme,
    required bool isActiveTab,
  }) {
    return Obx(() {
      final isLoading = _courierController.ordersLoading.value;
      final orders = isActiveTab
          ? _courierController.activeOrders
          : _courierController.pastOrders;

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => await _courierController.loadOrders(),
        child: isLoading && orders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : orders.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 60),
                      Icon(
                        isActiveTab
                            ? Icons.delivery_dining_outlined
                            : Icons.history_rounded,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isActiveTab
                            ? 'No active deliveries'
                            : 'No past deliveries yet',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isActiveTab
                            ? 'Your ongoing courier requests will appear here in real time.'
                            : 'Delivered or completed courier orders will be listed here.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return CourierOrderCard(
                        order: orders[index],
                        isDark: isDark,
                      );
                    },
                  ),
      );
    });
  }
}

/// Order card representing a courier delivery with human-readable normalized date
class CourierOrderCard extends StatelessWidget {
  final CourierOrderModel order;
  final bool isDark;

  const CourierOrderCard({
    super.key,
    required this.order,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkOutlineVariant : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header: ID + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delivery_dining_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#CR-${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: order.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.statusTitle,
                  style: TextStyle(
                    color: order.statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route Details: Origin to Destination
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.trip_origin_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  Container(
                    width: 2,
                    height: 22,
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  ),
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.fromAddress ??
                          '${order.fromLatitude.toStringAsFixed(4)}, ${order.fromLongitude.toStringAsFixed(4)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      order.toAddress ??
                          '${order.toLatitude.toStringAsFixed(4)}, ${order.toLongitude.toStringAsFixed(4)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Footer: Receiver, Human-Readable Normalized Date, and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To: ${order.receiverName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (order.formattedDateTime.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.formattedDateTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${order.totalPrice.toStringAsFixed(2)} ${order.displayCurrency}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (order.status != '4' && order.status != '5' && order.status != '-1') ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton.icon(
                        onPressed: () => Get.toNamed(AppRoutes.tracking, arguments: order.toOrderModel()),
                        icon: const Icon(Icons.location_searching_rounded, size: 14),
                        label: const Text('Track Live', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
