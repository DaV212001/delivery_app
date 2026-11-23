import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/corporate_controller.dart';
import '../controllers/courier_controller.dart';
import '../controllers/localization_controller.dart';
import '../controllers/my_property_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../core/theme/theme_controller.dart';
import '../services/customer_socket_service.dart';
import '../services/property_service.dart';
import '../services/user_location_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Core global state (theme, language, authentication, in-memory cart, live location)
    Get.put(ThemeController(), permanent: true);
    Get.put(LocalizationController(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(CartController(), permanent: true);
    Get.put(UserLocationService(), permanent: true);

    // Preload & register supported currencies globally
    PropertyService.fetchCurrencies();

    // 2. Domain controllers lazily initialized via onInit on the screens that need them
    Get.lazyPut<RestaurantController>(() => RestaurantController(), fenix: true);
    Get.lazyPut<OrderController>(() => OrderController(), fenix: true);
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
    Get.lazyPut<CourierController>(() => CourierController(), fenix: true);
    Get.lazyPut<CorporateController>(() => CorporateController(), fenix: true);
    Get.lazyPut<MyPropertyController>(() => MyPropertyController(), fenix: true);
    Get.lazyPut<CustomerSocketService>(() => CustomerSocketService(), fenix: true);
  }
}

