import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/localization_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../core/theme/theme_controller.dart';
import '../services/customer_socket_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ThemeController(), permanent: true);
    Get.put(LocalizationController(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(RestaurantController(), permanent: true);
    Get.put(CartController(), permanent: true);
    Get.put(OrderController(), permanent: true);
    Get.put(ProfileController(), permanent: true);
    Get.put(CustomerSocketService(), permanent: true);
  }
}

