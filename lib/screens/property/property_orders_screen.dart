import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/pages.dart';
import '../../controllers/my_property_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/my_property_model.dart';
import '../../models/property_order_model.dart';
import '../../services/property_service.dart';
import '../../widgets/common/app_widgets.dart';

class PropertyOrdersScreen extends StatefulWidget {
  const PropertyOrdersScreen({super.key});

  @override
  State<PropertyOrdersScreen> createState() => _PropertyOrdersScreenState();
}

class _PropertyOrdersScreenState extends State<PropertyOrdersScreen> {
  late final MyPropertyController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<MyPropertyController>()
        ? Get.find<MyPropertyController>()
        : Get.put(MyPropertyController());

    // If a property was passed as route argument, select it
    if (Get.arguments is MyPropertyModel) {
      final prop = Get.arguments as MyPropertyModel;
      _controller.selectProperty(prop);
    } else if (_controller.selectedProperty.value != null) {
      _controller.loadOrdersForProperty(_controller.selectedProperty.value!.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPropertySwitcherSheet(BuildContext context) {
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
                Text(
                  'switch_store'.tr.isNotEmpty && 'switch_store'.tr != 'switch_store'
                      ? 'switch_store'.tr
                      : 'Select Store',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Column(
                    children: _controller.properties.map((prop) {
                      final isSelected = _controller.selectedProperty.value?.id == prop.id;
                      return ListTile(
                        onTap: () {
                          _controller.selectProperty(prop);
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
                        subtitle: Text(
                          prop.friendlyLocation.isNotEmpty ? prop.friendlyLocation : 'Addis Ababa',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  void _showOrderDetailSheet(BuildContext context, PropertyOrderModel initialOrder) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyCode = _controller.getPropertyCurrencyCode(_controller.selectedProperty.value);

    Get.bottomSheet(
      FutureBuilder<PropertyOrderModel?>(
        future: PropertyService.fetchPropertyOrderDetail(initialOrder.id, initial: initialOrder),
        initialData: initialOrder,
        builder: (context, snapshot) {
          final order = snapshot.data ?? initialOrder;
          final isLoading = snapshot.connectionState == ConnectionState.waiting && snapshot.data == null;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header Handle & Close
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: order.statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(order.statusIcon, size: 14, color: order.statusColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      order.statusLabel,
                                      style: TextStyle(
                                        color: order.statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  order.orderCode,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Scrollable Body
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date & Order Time Banner
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded, size: 15, color: theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 8),
                                      Text(
                                        order.formattedDateTime,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Customer Information Section
                                Text(
                                  'Customer Information',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  order.customerFullName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                ),
                                                if (order.customerPhone != null && order.customerPhone!.trim().isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    order.customerPhone!.trim(),
                                                    style: TextStyle(
                                                      color: theme.colorScheme.onSurfaceVariant,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (order.customerPhone != null && order.customerPhone!.trim().isNotEmpty)
                                            IconButton.filledTonal(
                                              style: IconButton.styleFrom(
                                                backgroundColor: Colors.green.withValues(alpha: 0.15),
                                                foregroundColor: Colors.green.shade700,
                                              ),
                                              icon: const Icon(Icons.phone_rounded, size: 20),
                                              tooltip: 'Call Customer',
                                              onPressed: () async {
                                                final phoneUri = Uri(scheme: 'tel', path: order.customerPhone!.trim());
                                                if (await canLaunchUrl(phoneUri)) {
                                                  await launchUrl(phoneUri);
                                                }
                                              },
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              order.location.isNotEmpty ? order.location : 'Addis Ababa',
                                              style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Order Items (if loaded)
                                if (order.items.isNotEmpty) ...[
                                  Text(
                                    'Order Items (${order.items.length})',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: order.items.length,
                                      separatorBuilder: (_, _) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final item = order.items[index];
                                        return ListTile(
                                          leading: item.imageUrl.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: AppNetworkImage(
                                                    imageUrl: item.imageUrl,
                                                    width: 40,
                                                    height: 40,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(Icons.fastfood_rounded, size: 20, color: AppColors.primary),
                                                ),
                                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                          subtitle: Text('Qty: ${item.quantity}'),
                                          trailing: Text(
                                            '${item.price.toStringAsFixed(2)} $currencyCode',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Order Summary & Financials
                                Text(
                                  'Financial Summary',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildSummaryRow('Items Total', '${order.itemTotalPrice.toStringAsFixed(2)} $currencyCode', theme),
                                      if (order.totalKmPrice > 0) ...[
                                        const SizedBox(height: 8),
                                        _buildSummaryRow('Delivery Fee', '${order.totalKmPrice.toStringAsFixed(2)} $currencyCode', theme),
                                      ],
                                      const SizedBox(height: 8),
                                      _buildSummaryRow('Payment Method', order.paymentMethodLabel, theme),
                                      const SizedBox(height: 8),
                                      _buildSummaryRow(
                                        'Payment Status',
                                        order.paymentStatusLabel,
                                        theme,
                                        valueColor: order.paymentStatus == '1' ? Colors.green : Colors.orange.shade700,
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total Amount',
                                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                          ),
                                          Text(
                                            '${order.effectiveTotal.toStringAsFixed(2)} $currencyCode',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Action Buttons: Track live delivery
                                AppButton(
                                  text: 'Track Live Delivery',
                                  icon: const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                                  onPressed: () {
                                    Get.back();
                                    final currentStore = _controller.selectedProperty.value;
                                    final storeModel = currentStore != null
                                        ? PropertyService.getCachedProperty(currentStore.id.toString())
                                        : null;
                                    final orderModel = order.toOrderModel(
                                      store: storeModel,
                                      currencyCode: currencyCode,
                                    );
                                    Get.toNamed(AppRoutes.tracking, arguments: orderModel);
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: valueColor ?? theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Obx(() {
          final prop = _controller.selectedProperty.value;
          final propCount = _controller.properties.length;

          if (prop == null || propCount <= 1) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'store_orders'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (prop != null)
                  Text(
                    prop.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            );
          }

          // Switcher dropdown trigger
          return InkWell(
            onTap: () => _showPropertySwitcherSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'store_orders'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          prop.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down_rounded, size: 24),
                ],
              ),
            ),
          );
        }),
        actions: [
          IconButton(
            tooltip: 'Refresh Orders',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.refreshCurrentPropertyOrders(),
          ),
        ],
      ),
      body: Obx(() {
        final currentProperty = _controller.selectedProperty.value;
        if (currentProperty == null && _controller.properties.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'no_property_yet'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }

        final orders = _controller.filteredOrders;
        final currencyCode = _controller.getPropertyCurrencyCode(currentProperty);

        return RefreshIndicator(
          onRefresh: () => _controller.refreshCurrentPropertyOrders(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Metric Stat Summary Cards Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _buildMetricOverview(context, isDark, currencyCode),
                ),
              ),

              // 2. Search & Filter Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => _controller.ordersSearchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: 'Search by Order # or location...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _controller.ordersSearchQuery.value = '';
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter chips
                      _buildFilterChips(context, isDark),
                    ],
                  ),
                ),
              ),

              // 3. Orders List or Empty State
              if (_controller.isLoadingOrders.value)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (orders.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context, isDark),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final order = orders[index];
                        return _buildOrderCard(context, order, isDark, currencyCode);
                      },
                      childCount: orders.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMetricOverview(BuildContext context, bool isDark, String currencyCode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Orders',
                value: '${_controller.propertyOrders.length}',
                icon: Icons.receipt_long_rounded,
                color: Colors.blue,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: 'Active',
                value: '${_controller.activeOrdersCount}',
                icon: Icons.local_shipping_rounded,
                color: Colors.orange,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: 'Revenue',
                value: '${_controller.totalOrdersRevenue.toStringAsFixed(0)} $currencyCode',
                icon: Icons.monetization_on_rounded,
                color: Colors.green,
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, bool isDark) {
    final filters = [
      {'key': 'all', 'label': 'All (${_controller.propertyOrders.length})'},
      {'key': 'active', 'label': 'Active (${_controller.activeOrdersCount})'},
      {'key': 'delivered', 'label': 'Delivered (${_controller.deliveredOrdersCount})'},
      {'key': 'cancelled', 'label': 'Cancelled (${_controller.cancelledOrdersCount})'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(
        () => Row(
          children: filters.map((f) {
            final isSelected = _controller.ordersFilter.value == f['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(f['label']!),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
                backgroundColor: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                ),
                onSelected: (_) => _controller.ordersFilter.value = f['key']!,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    PropertyOrderModel order,
    bool isDark,
    String currencyCode,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.isActive
              ? AppColors.primary.withValues(alpha: 0.3)
              : theme.dividerColor.withValues(alpha: 0.1),
          width: order.isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: order.isActive
                ? AppColors.primary.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showOrderDetailSheet(context, order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Order code & Status Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.orderCode,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.formattedDateTime,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: order.statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(order.statusIcon, size: 12, color: order.statusColor),
                          const SizedBox(width: 4),
                          Text(
                            order.statusLabel,
                            style: TextStyle(
                              color: order.statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location / Delivery destination
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.location.isNotEmpty ? order.location : 'Addis Ababa',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Items summary
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${order.totalItem} items • ${order.totalQuantity} total qty',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Bottom row: Payment badge & Total Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              order.paymentType == '0' ? Icons.payments_outlined : Icons.account_balance_wallet_outlined,
                              size: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                order.paymentMethodLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${order.effectiveTotal.toStringAsFixed(2)} $currencyCode',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Orders Found',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.ordersFilter.value != 'all' || _controller.ordersSearchQuery.isNotEmpty
                  ? 'No orders match your current filter or search criteria.'
                  : 'Orders placed by customers for this store will appear here in real-time.',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (_controller.ordersFilter.value != 'all' || _controller.ordersSearchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: const Text('Reset Filters'),
                onPressed: () {
                  _searchController.clear();
                  _controller.ordersSearchQuery.value = '';
                  _controller.ordersFilter.value = 'all';
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
