class ApiEndpoints {
  // Auth endpoints (Customer)
  static const String customerLogin = '/customer-login';
  static const String customerRegister = '/customer-register';
  static const String customerForgetPassword = '/customer-forget-password';
  static const String customerSendOtp = '/customer-send-otp';
  static const String customerVerifyOtp = '/customer-verify-otp';
  static const String customerChangePassword = '/customer-change-password';
  static const String customerLogout = '/customer-logout';
  static const String customerChangeProfileImage = '/customer-change-profile-image';

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
  static String propertyDetail(dynamic id) => '/property/$id';
  static const String searchGlobal = '/search';
  static String searchProperty(dynamic id) => '/property/$id/search';

  // Order endpoints
  static const String order = '/order';
  static String activeOrders(dynamic customerId) => '/my_active_order/$customerId';
  static String pastOrders(dynamic customerId) => '/my_past_order/$customerId';
  static String orderDetail(dynamic orderId) => '/my_order_detail/$orderId';

  // Payment & Wallet endpoints
  static const String walletPayment = '/wallet-payment';

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
}
