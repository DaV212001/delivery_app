import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
import '../../constants/pages.dart';
import '../../core/theme/app_colors.dart';
import '../../models/order.dart';
import '../../services/customer_socket_service.dart';
import '../../services/order_service.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/map/gebeta_route_map.dart';
import '../checkout/widgets/different_property_batch_sheet.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  String? _joinedOrderId;
  OrderModel? _orderDetail;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    final OrderModel? orderArg = Get.arguments is OrderModel ? Get.arguments as OrderModel : null;
    if (orderArg != null) {
      _orderDetail = orderArg;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinActiveOrder();
      _fetchFullOrderDetail();
    });
  }

  void _joinActiveOrder() {
    final OrderModel? orderArg = Get.arguments is OrderModel ? Get.arguments as OrderModel : null;
    final order = _orderDetail ?? orderArg ??
        (Get.isRegistered<OrderController>()
            ? Get.find<OrderController>().activeOrder.value
            : null);
    if (order != null) {
      final cleanId = order.orderId.replaceAll(RegExp(r'[^0-9]'), '');
      final targetId = cleanId.isNotEmpty ? cleanId : order.orderId;
      _joinedOrderId = targetId;
      if (Get.isRegistered<CustomerSocketService>()) {
        CustomerSocketService.to.joinOrder(targetId);
      }
    }
  }

  Future<void> _fetchFullOrderDetail() async {
    final OrderModel? orderArg = Get.arguments is OrderModel ? Get.arguments as OrderModel : null;
    final order = _orderDetail ?? orderArg ??
        (Get.isRegistered<OrderController>()
            ? Get.find<OrderController>().activeOrder.value
            : null);

    String targetId = '';
    if (order != null) {
      final cleanId = order.orderId.replaceAll(RegExp(r'[^0-9]'), '');
      targetId = cleanId.isNotEmpty ? cleanId : order.orderId;
    } else if (Get.arguments is String) {
      final cleanId = (Get.arguments as String).replaceAll(RegExp(r'[^0-9]'), '');
      targetId = cleanId.isNotEmpty ? cleanId : (Get.arguments as String);
    } else if (Get.arguments is Map && Get.arguments['id'] != null) {
      final cleanId = Get.arguments['id'].toString().replaceAll(RegExp(r'[^0-9]'), '');
      targetId = cleanId.isNotEmpty ? cleanId : Get.arguments['id'].toString();
    }

    if (targetId.isEmpty) return;

    if (mounted) setState(() => _isLoadingDetail = true);
    try {
      final detail = await OrderService.fetchOrderDetail(targetId);
      if (detail != null && mounted) {
        setState(() {
          _orderDetail = detail;
        });
        if (Get.isRegistered<OrderController>()) {
          final oc = Get.find<OrderController>();
          if (oc.activeOrder.value == null ||
              oc.activeOrder.value!.orderId == detail.orderId ||
              oc.activeOrder.value!.orderId.replaceAll(RegExp(r'[^0-9]'), '') == targetId) {
            oc.activeOrder.value = detail;
          }
        }
      }
    } catch (_) {
      // Keep existing data on error
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  @override
  void dispose() {
    if (_joinedOrderId != null && Get.isRegistered<CustomerSocketService>()) {
      CustomerSocketService.to.leaveOrder(_joinedOrderId!);
    }
    super.dispose();
  }

  void _showQuickChatSheet(BuildContext context, String rawOrderId, String driverName) {
    final cleanId = rawOrderId.replaceAll(RegExp(r'[^0-9]'), '');
    final orderId = cleanId.isNotEmpty ? cleanId : rawOrderId;
    final textController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Message $driverName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                "I'm at the main gate",
                "Please call when outside",
                "Leave at door",
                "Take your time!",
              ].map((msg) {
                return ActionChip(
                  label: Text(msg, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    if (Get.isRegistered<CustomerSocketService>()) {
                      CustomerSocketService.to.sendChatMessage(orderId, msg);
                      Get.back();
                      Get.snackbar('Sent to $driverName', msg, snackPosition: SnackPosition.TOP);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: () {
                    final text = textController.text.trim();
                    if (text.isNotEmpty && Get.isRegistered<CustomerSocketService>()) {
                      CustomerSocketService.to.sendChatMessage(orderId, text);
                      Get.back();
                      Get.snackbar('Sent to $driverName', text, snackPosition: SnackPosition.TOP);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orderController = Get.isRegistered<OrderController>()
        ? Get.find<OrderController>()
        : Get.put(OrderController());
    final cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController());

    return Obx(() {
      final active = orderController.activeOrder.value;
      final currentOrder = _orderDetail ?? active;

      return _buildScaffold(
        context: context,
        theme: theme,
        isDark: isDark,
        order: currentOrder,
        orderArg: _orderDetail,
        cartController: cartController,
      );
    });
  }

  Widget _buildFloatingIconButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xEE1E1E1E) : Colors.white).withValues(alpha: 0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildScaffold({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required OrderModel? order,
    required OrderModel? orderArg,
    required CartController cartController,
  }) {
    final socket = Get.isRegistered<CustomerSocketService>()
        ? CustomerSocketService.to
        : Get.put(CustomerSocketService());
    final isDelivered = order?.status == OrderProgressStatus.delivered;
    final isCancelled = order?.status == OrderProgressStatus.cancelled;
    final titleText = isCancelled
        ? 'order_cancelled'.tr
        : (isDelivered ? 'order_details'.tr : 'track_order'.tr);

    if (order == null) {
      if (_isLoadingDetail) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(titleText.isNotEmpty ? titleText : 'Order Details'),
            centerTitle: true,
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (orderArg != null || Navigator.of(context).canPop()) {
                Get.back();
              } else {
                Get.offAllNamed(AppRoutes.mainNav);
              }
            },
          ),
          title: Text(
            titleText.isNotEmpty ? titleText : (isDelivered ? 'Order Details' : 'Track Order'),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
        ),
        body: Center(
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Full-screen Gebeta Route Map in background (Edge-to-edge, always visible)
          Positioned.fill(
            child: Obx(() {
              final liveLat = socket.driverLatitude.value;
              final liveLng = socket.driverLongitude.value;
              final liveHeading = socket.driverHeading.value;
              final isDriverOnline = socket.isDriverOnline.value;

              return GebetaRouteMap(
                order: order,
                contentPadding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 64,
                  bottom: 220,
                ),
                liveDriverLatitude: liveLat,
                liveDriverLongitude: liveLng,
                liveDriverHeading: liveHeading,
                isLiveDriverOnline: isDriverOnline,
              );
            }),
          ),

          // 2. Floating Top Header: Back button, Title pill, Help button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFloatingIconButton(
                      icon: Icons.arrow_back_rounded,
                      isDark: isDark,
                      onPressed: () {
                        if (orderArg != null || Navigator.of(context).canPop()) {
                          Get.back();
                        } else {
                          Get.offAllNamed(AppRoutes.mainNav);
                        }
                      },
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xEE1E1E1E) : Colors.white).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            titleText.isNotEmpty ? titleText : (isDelivered ? 'Order Details' : 'Track Order'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Draggable Scrollable Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.16,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.16, 0.38, 0.88],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag Handle Bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Order ETA / Status Banner
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Obx(() {
                            final isDriverOnline = socket.isDriverOnline.value;
                            final liveMins = socket.estimatedMinutes.value;
                            final isAccepted = order.status == OrderProgressStatus.accepted;
                            final isDriverToShop = order.status == OrderProgressStatus.driverToShop;
                            final isDriverToYou = order.status == OrderProgressStatus.driverToYou;
                            final isDelivered = order.status == OrderProgressStatus.delivered;
                            final isCancelled = order.status == OrderProgressStatus.cancelled;

                            String arrivalText;
                            if (isCancelled) {
                              arrivalText = 'order_cancelled'.tr;
                            } else if (isDelivered) {
                              arrivalText = 'delivered'.tr;
                            } else if (isAccepted) {
                              arrivalText = '${'order_accepted'.tr} (~${order.estimatedArrival})';
                            } else if (isDriverToShop) {
                              arrivalText = liveMins != null
                                  ? '$liveMins mins • ${'driver_to_shop'.tr}'
                                  : 'driver_to_shop'.tr;
                            } else if (isDriverToYou) {
                              arrivalText = liveMins != null
                                  ? '$liveMins mins • ${'driver_to_you'.tr}'
                                  : 'driver_to_you'.tr;
                            } else {
                              arrivalText = order.estimatedArrival;
                            }

                            final Color statusColor = isCancelled
                                ? Colors.red
                                : (isDelivered
                                    ? Colors.green
                                    : (isDriverOnline ? Colors.green.shade700 : AppColors.primary));

                            final IconData statusIcon = isCancelled
                                ? Icons.cancel_rounded
                                : (isDelivered
                                    ? Icons.check_circle_rounded
                                    : (isDriverToYou
                                        ? Icons.two_wheeler_rounded
                                        : (isDriverToShop
                                            ? Icons.storefront_rounded
                                            : Icons.receipt_long_rounded)));

                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.storeName,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        arrivalText,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCancelled
                                        ? Colors.red.withValues(alpha: 0.12)
                                        : (isDelivered
                                            ? Colors.green.withValues(alpha: 0.12)
                                            : AppColors.primaryFixed),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    order.orderId,
                                    style: TextStyle(
                                      color: isCancelled
                                          ? Colors.red
                                          : (isDelivered
                                              ? Colors.green
                                              : AppColors.onPrimaryFixed),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),

                    // Progress Stepper:
                    // 1: Accepted
                    // 2: Driver on the way to shop
                    // 3: Driver on the way to you
                    // 4: Delivered
                    // 5: Cancelled
                    if (order.status == OrderProgressStatus.cancelled)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cancel_rounded, color: Colors.red, size: 30),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'order_cancelled'.tr,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'order_cancelled_sub'.tr,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: Column(
                          children: [
                            _ProgressStep(
                              title: 'order_accepted'.tr,
                              subtitle: 'order_accepted_sub'.tr,
                              isCompleted: order.status.code >= 1,
                              isCurrent: order.status == OrderProgressStatus.accepted,
                              icon: Icons.receipt_long_rounded,
                            ),
                            _ProgressLine(
                              isCompleted: order.status.code >= 2,
                            ),
                            _ProgressStep(
                              title: 'driver_to_shop'.tr,
                              subtitle: 'driver_to_shop_sub'.tr,
                              isCompleted: order.status.code >= 2,
                              isCurrent: order.status == OrderProgressStatus.driverToShop,
                              icon: Icons.storefront_rounded,
                            ),
                            _ProgressLine(
                              isCompleted: order.status.code >= 3,
                            ),
                            _ProgressStep(
                              title: 'driver_to_you'.tr,
                              subtitle: 'driver_to_you_sub'.tr,
                              isCompleted: order.status.code >= 3,
                              isCurrent: order.status == OrderProgressStatus.driverToYou,
                              icon: Icons.two_wheeler_rounded,
                            ),
                            _ProgressLine(
                              isCompleted: order.status == OrderProgressStatus.delivered,
                            ),
                            _ProgressStep(
                              title: 'delivered'.tr,
                              subtitle: 'delivered_sub'.tr,
                              isCompleted: order.status == OrderProgressStatus.delivered,
                              isCurrent: order.status == OrderProgressStatus.delivered,
                              icon: Icons.home_rounded,
                            ),
                          ],
                        ),
                      ),

                    // Courier Card (If available)
                    if (order.driver != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: AppNetworkImage(
                                  imageUrl: order.driver!.photoUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            order.driver!.name,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Obx(() {
                                          if (!socket.isDriverOnline.value) {
                                            return const SizedBox.shrink();
                                          }
                                          return Container(
                                            margin: const EdgeInsets.only(left: 4),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'LIVE',
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${order.driver!.vehicle} • ${order.driver!.plateNumber}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    RatingBadge(rating: order.driver!.rating),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Chat with Driver button
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 16,
                                  icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () => _showQuickChatSheet(
                                    context,
                                    order.orderId,
                                    order.driver!.name,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Call Driver button
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 16,
                                  icon: const Icon(
                                    Icons.call_rounded,
                                    color: AppColors.primary,
                                  ),
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

                    // Order Details & Items Card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'order_details'.tr,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_isLoadingDetail)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
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
                                    order.storeName,
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

                            // Items breakdown if available
                            if (order.items.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Divider(),
                              const SizedBox(height: 6),
                              Text(
                                'items'.tr.isNotEmpty ? 'items'.tr : 'Items',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...order.items.map(
                                (cartItem) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${cartItem.quantity}x ${cartItem.item.name}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${(cartItem.item.price * cartItem.quantity).toStringAsFixed(2)} Br',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),
                            const Divider(),
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

                            // Reorder button for delivered orders
                            if (isDelivered) ...[
                              const SizedBox(height: 16),
                              AppButton(
                                text: 'reorder'.tr,
                                isSecondary: false,
                                onPressed: () {
                                  if (order.items.isEmpty) return;
                                  final firstItem = order.items.first.item;
                                  if (cartController.isDifferentProperty(firstItem)) {
                                    DifferentPropertyBatchSheet.show(
                                      context,
                                      currentStoreName: cartController.activePropertyName,
                                      newStoreName: order.restaurantName,
                                      newItem: firstItem,
                                      onFinishCurrentBatch: () {
                                        Get.back();
                                        Get.toNamed(AppRoutes.cart);
                                      },
                                      onSaveForNextBatch: () {
                                        cartController.saveCurrentBatch();
                                        for (final item in order.items) {
                                          cartController.addItem(
                                            item: item.item,
                                            quantity: item.quantity,
                                          );
                                        }
                                        Get.back();
                                        Get.toNamed(AppRoutes.cart);
                                        Get.snackbar(
                                          'batch_saved'.tr,
                                          'previous_batch_saved'.tr,
                                          backgroundColor: AppColors.primary,
                                          colorText: Colors.white,
                                        );
                                      },
                                    );
                                    return;
                                  }

                                  for (final item in order.items) {
                                    cartController.addItem(
                                      item: item.item,
                                      quantity: item.quantity,
                                    );
                                  }
                                  Get.toNamed(AppRoutes.cart);
                                  Get.snackbar(
                                    'reorder'.tr,
                                    'reorder_added'.tr,
                                    backgroundColor: AppColors.primary,
                                    colorText: Colors.white,
                                  );
                                },
                              ),
                            ],
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
