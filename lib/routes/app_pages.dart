import 'package:get/get.dart';
import '../config/storage_config.dart';
import '../constants/pages.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/checkout/cart_screen.dart';
import '../screens/corporate/corporate_dashboard_screen.dart';
import '../screens/corporate/create_corporate_delivery_screen.dart';
import '../screens/courier/courier_history_screen.dart';
import '../screens/courier/courier_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/main_navigation.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/faq_screen.dart';
import '../screens/profile/privacy_policy_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/saved_addresses_screen.dart';
import '../screens/profile/terms_and_conditions_screen.dart';
import '../screens/property/my_properties_list_screen.dart';
import '../screens/property/my_property_screen.dart';
import '../screens/property/property_orders_screen.dart';
import '../screens/property/property_schedules_screen.dart';
import '../screens/property/register_property_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/tracking/order_tracking_screen.dart';
import '../screens/wallet/wallet_screen.dart';

class AppPages {
  static String get initial {
    try {
      final token = ConfigPreference.getAccessToken();
      final isExpired = ConfigPreference.isAccessTokenExpired();
      if (token != null && !isExpired) {
        return AppRoutes.mainNav;
      }
      final pendingReg = ConfigPreference.getPendingRegistration();
      if (pendingReg != null &&
          (pendingReg['phone']?.toString().isNotEmpty ?? false)) {
        return AppRoutes.otp;
      }
    } catch (_) {}
    return AppRoutes.splash;
  }

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.mainNav,
      page: () => const MainNavigationScreen(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchScreen(),
    ),
    GetPage(
      name: AppRoutes.cart,
      page: () => const CartScreen(),
    ),
    GetPage(
      name: AppRoutes.tracking,
      page: () => const OrderTrackingScreen(),
    ),
    GetPage(
      name: AppRoutes.orderDetail,
      page: () => const OrderTrackingScreen(),
    ),
    GetPage(
      name: AppRoutes.orderHistory,
      page: () => const OrderHistoryScreen(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileScreen(),
    ),
    GetPage(
      name: AppRoutes.savedAddresses,
      page: () => const SavedAddressesScreen(),
    ),
    GetPage(
      name: AppRoutes.wallet,
      page: () => const WalletScreen(),
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpScreen(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.courier,
      page: () => const CourierScreen(),
    ),
    GetPage(
      name: AppRoutes.courierHistory,
      page: () => const CourierHistoryScreen(),
    ),
    GetPage(
      name: AppRoutes.myProperty,
      page: () => const MyPropertiesListScreen(),
    ),
    GetPage(
      name: AppRoutes.manageProperty,
      page: () => const MyPropertyScreen(),
    ),
    GetPage(
      name: AppRoutes.registerProperty,
      page: () => const RegisterPropertyScreen(),
    ),
    GetPage(
      name: AppRoutes.editProperty,
      page: () => const RegisterPropertyScreen(),
    ),
    GetPage(
      name: AppRoutes.propertySchedules,
      page: () => const PropertySchedulesScreen(),
    ),
    GetPage(
      name: AppRoutes.propertyOrders,
      page: () => const PropertyOrdersScreen(),
    ),
    GetPage(
      name: AppRoutes.corporateDashboard,
      page: () => const CorporateDashboardScreen(),
    ),
    GetPage(
      name: AppRoutes.createCorporateOrder,
      page: () => const CreateCorporateDeliveryScreen(),
    ),
    GetPage(
      name: AppRoutes.faq,
      page: () => const FaqScreen(),
    ),
    GetPage(
      name: AppRoutes.privacyPolicy,
      page: () => const PrivacyPolicyScreen(),
    ),
    GetPage(
      name: AppRoutes.termsAndConditions,
      page: () => const TermsAndConditionsScreen(),
    ),
  ];
}
