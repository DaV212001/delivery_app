import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../constants/pages.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/profile_controller.dart';
import '../../../controllers/restaurant_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/address_model.dart';
import '../../../models/promotion.dart';
import '../../../widgets/common/app_widgets.dart';
import '../../restaurant/restaurant_detail_screen.dart';

class PromotionalCarouselSection extends StatefulWidget {
  final List<Promotion> promotions;
  final bool isLoading;

  const PromotionalCarouselSection({
    super.key,
    required this.promotions,
    this.isLoading = false,
  });

  @override
  State<PromotionalCarouselSection> createState() =>
      _PromotionalCarouselSectionState();
}

class _PromotionalCarouselSectionState
    extends State<PromotionalCarouselSection> {
  int _currentIndex = 0;
  final GlobalKey _pillKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const _PromotionalCarouselSkeleton();
    }

    final authController = Get.find<AuthController>();
    final restaurantController = Get.find<RestaurantController>();

    if (widget.promotions.isEmpty) {
      return SizedBox(
        height: 180,
        width: double.infinity,
        child: Stack(
          children: [
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            _buildTopBar(context, authController),
          ],
        ),
      );
    }

    return SizedBox(
      height: 290,
      width: double.infinity,
      child: Stack(
        children: [
          // 1. Edge-to-edge Carousel Slider
          CarouselSlider.builder(
            itemCount: widget.promotions.length,
            itemBuilder: (context, index, realIndex) {
              final promo = widget.promotions[index];
              return GestureDetector(
                onTap: () {
                  if (promo.storeId != null) {
                    final store = restaurantController.restaurants
                        .firstWhereOrNull((s) => s.id == promo.storeId);
                    if (store != null) {
                      Get.to(() => RestaurantDetailScreen(restaurant: store));
                    }
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Slide Hero Background Image
                    AppNetworkImage(
                      imageUrl: promo.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 0,
                    ),

                    // Layered Gradient Overlay for Text and Top Pill Contrast
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.85),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Promotional Copy (Badge, Title, Subtitle)
                    Positioned(
                      left: 20,
                      right: 90,
                      bottom: 42,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (promo.badge != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                promo.badge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            promo.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            promo.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              shadows: const [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            options: CarouselOptions(
              height: 290,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 700),
              autoPlayCurve: Curves.easeInOutCubic,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),

          // 2. Floating Translucent Address & Profile Pill (User selected design)
          _buildTopBar(context, authController),

          // 3. Bottom-Right Animated Pill Dots Indicator (yenetena_mobile pattern)
          Positioned(
            bottom: 38,
            right: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: widget.promotions.asMap().entries.map((entry) {
                final isActive = _currentIndex == entry.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: isActive ? 22.0 : 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressDropdown(BuildContext context) async {
    final RenderBox? button = _pillKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset buttonTopLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final Size buttonSize = button.size;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        buttonTopLeft.translate(0, buttonSize.height + 6),
        buttonTopLeft.translate(buttonSize.width, buttonSize.height + 6),
      ),
      Offset.zero & overlay.size,
    );

    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    final authController = Get.find<AuthController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (profileController.isAuthenticated && profileController.addresses.isEmpty) {
      await profileController.loadAddresses();
    }

    if (!context.mounted) return;

    final result = await showMenu<dynamic>(
      context: context,
      position: position,
      elevation: 10,
      color: isDark ? AppColors.darkSurfaceContainer : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'saved_addresses'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        if (profileController.addresses.isEmpty)
          PopupMenuItem<String>(
            enabled: false,
            child: Text(
              'no_saved_addresses'.tr,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54),
            ),
          )
        else
          ...profileController.addresses.map((addr) {
            final isSelected = profileController.selectedAddress.value?.id == addr.id ||
                profileController.selectedAddress.value?.name == addr.name;
            return PopupMenuItem<AddressModel>(
              value: addr,
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.location_on_outlined,
                    size: 18,
                    color: isSelected ? AppColors.primary : (isDark ? Colors.white60 : Colors.black54),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      addr.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : null,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: '__add_new__',
          child: Row(
            children: [
              const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'add_new_address'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (result is AddressModel) {
      profileController.selectAddress(result);
    } else if (result == '__add_new__') {
      if (!authController.isLoggedIn) {
        Get.toNamed(AppRoutes.login);
      } else {
        if (!context.mounted) return;
        _showAddAddressDialog(context, profileController);
      }
    }
  }

  void _showAddAddressDialog(BuildContext context, ProfileController profileController) {
    final nameCtrl = TextEditingController(text: '');
    final latCtrl = TextEditingController(text: '9.0209');
    final lngCtrl = TextEditingController(text: '38.7469');

    Get.dialog(
      AlertDialog(
        title: Text('add_address'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'address_name'.tr)),
            const SizedBox(height: 8),
            TextField(controller: latCtrl, decoration: InputDecoration(labelText: 'latitude'.tr)),
            const SizedBox(height: 8),
            TextField(controller: lngCtrl, decoration: InputDecoration(labelText: 'longitude'.tr)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(latCtrl.text) ?? 9.0209;
              final lng = double.tryParse(lngCtrl.text) ?? 38.7469;
              final label = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Home';
              profileController.addAddress(label, lat, lng);
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AuthController authController) {
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              // Translucent Frosted Glass Address Pill (Selectable Dropdown)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: _pillKey,
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _showAddressDropdown(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'delivering_to'.tr,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Obx(() {
                                            final currentAddr = profileController.selectedAddress.value?.name ??
                                                (authController.user.defaultAddress.isNotEmpty
                                                    ? authController.user.defaultAddress
                                                    : 'Addis Ababa, Ethiopia');
                                            return Text(
                                              currentAddr,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            );
                                          }),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ],
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

              const SizedBox(width: 10),

              // Profile Avatar with translucent border & subtle drop shadow
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.profile),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.65),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: AppNetworkImage(
                      imageUrl: authController.user.avatarUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotionalCarouselSkeleton extends StatelessWidget {
  const _PromotionalCarouselSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 290,
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: isDark ? AppColors.darkSurfaceContainer : const Color(0xFFE2E8F0),
        highlightColor:
            isDark ? AppColors.darkSurfaceContainerHigh : const Color(0xFFF1F5F9),
        child: Container(
          color: isDark ? AppColors.darkSurface : Colors.white,
        ),
      ),
    );
  }
}
