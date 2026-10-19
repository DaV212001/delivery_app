class ApiEndpoints {
  // Auth endpoints (Driver)
  static const String driverLogin = '/driver-login';
  static const String driverRegister = '/driver-register';
  static const String driverForgetPassword = '/driver-forget-password';
  static const String driverSendOtp = '/driver-send-otp';
  static const String driverVerifyOtp = '/driver-verify-otp';
  static const String driverChangePassword = '/driver-change-password';
  static const String driverLogout = '/driver-logout';
  static const String driverChangeProfileImage = '/driver-change-profile-image';

  // Auth endpoints (Customer)
  static const String customerLogin = '/customer-login';
  static const String customerRegister = '/customer-register';
  static const String customerForgetPassword = '/customer-forget-password';
  static const String customerSendOtp = '/customer-send-otp';
  static const String customerVerifyOtp = '/customer-verify-otp';
  static const String customerChangePassword = '/customer-change-password';
  static const String customerLogout = '/customer-logout';
  static const String customerChangeProfileImage = '/customer-change-profile-image';
  static const String changeProfileImage = '/change-profile-image';

  // General & Discovery endpoints
  static const String categories = '/delivery-categroy';
  static const String deliveryTypes = '/delivery-type';
  static const String specialOffers = '/special-offer';
  static const String featureStores = '/feature-store';
  static const String promotionalImages = '/promotional-image';
  static String categoryStores(dynamic id) => '/delivery-categroy/$id';
  static String deliveryTypeStores(dynamic id) => '/delivery-type/$id';
  static String menuDetail(dynamic id) => '/menu/$id';

  // Property endpoints
  static const String properties = '/property';
  static String nearbyProperties(dynamic lat, dynamic lng, {int page = 1}) =>
      '/nearby-property/$lat/$lng?page=$page';
  static String propertyDetail(dynamic id) => '/property/$id';
  static const String searchGlobal = '/search';
  static String searchProperty(dynamic id) => '/property/$id/search';
  static String myProperty(dynamic customerId) => '/my-property/$customerId';
  static String myMenuCategory(dynamic propertyId) => '/my-menu-category/$propertyId';
  static const String menuCategory = '/menu-category';
  static String menuCategoryDetail(dynamic id) => '/menu-category/$id';
  static String myMenuByProperty(dynamic propertyId) => '/my-menu-by-property/$propertyId';
  static const String myMenu = '/my-menu';
  static String myMenuDetail(dynamic id) => '/my-menu/$id';
  static const String updateMenuStatus = '/update-menu-status';
  static String propertySchedules(dynamic propertyId) => '/property/$propertyId/schedules';
  static String propertySchedulesSync(dynamic propertyId) => '/property/$propertyId/schedules/sync';

  // Order endpoints
  static const String order = '/order';
  static String activeOrders(dynamic customerId) => '/my_active_order/$customerId';
  static String pastOrders(dynamic customerId) => '/my_past_order/$customerId';
  static String orderDetail(dynamic orderId) => '/my_order_detail/$orderId';
  static String propertyDeliveryOptions(dynamic propertyId) => '/property-delivery-option/$propertyId';

  // Payment & Wallet endpoints
  static const String walletPayment = '/wallet-payment';
  static const String payOnChapa = '/pay-on-chapa';
  static const String payOnWallet = '/pay-on-wallet';

  // Profile endpoints
  static String profile(dynamic customerId) => '/profile/$customerId';
  static String walletAmount(dynamic customerId) => '/my_wallet_amount/$customerId';
  static String walletTransactions(dynamic customerId) => '/my_wallet_transaction/$customerId';
  static String deliveryAddresses(dynamic customerId) => '/my-delivery-adress/$customerId';
  static const String deliveryAddress = '/delivery-adress';
  static String deliveryAddressDetail(dynamic id) => '/delivery-adress/$id';

  // Information endpoints
  static const String privacy = '/privacy';
  static const String termsAndConditions = '/term_and_condition';
  static const String faq = '/faq';

  // Corporate endpoints
  static String myCompany(dynamic companyId) => '/my-company/$companyId';
  static String branchByCompanyId(dynamic companyId) => '/branch-by-company-id/$companyId';
  static const String itemList = '/item-list';
  static String companyDeliveryOptions(dynamic companyId) => '/company-delivery-options-by-company-id/$companyId';
  static const String companyOrder = '/company-order';
  static String pendingCompanyOrders(dynamic userId) => '/pending-company-order/$userId';
  static String finishedCompanyOrders(dynamic userId) => '/finihsed-company-order/$userId';
  static String branchByUserId(dynamic userId) => '/branch-by-user-id/$userId';

  // Courier endpoints
  static const String courierOrder = '/courirer-order';
  static String activeCourierOrders(dynamic userId) => '/my_active_courirer_order/$userId';
  static String pastCourierOrders(dynamic userId) => '/my_past_courirer_order/$userId';

  // Real-Time Socket Server (Render)
  static const String socketServerUrl = 'https://amn-delivery-socket-server.onrender.com';
}
