import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../config/storage_config.dart';
import '../constants/api_endpoints.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in background isolate
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {}

  final logger = Logger();
  logger.i('🌙 FCM Background Message: [ID: ${message.messageId}]');
  logger.d('Title: ${message.notification?.title}');
  logger.d('Body: ${message.notification?.body}');
  logger.d('Data: ${message.data}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final Logger _logger = Logger();
  final Rx<String?> fcmToken = Rx<String?>(null);
  final RxBool isFetchingToken = false.obs;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  Dio? _customDio;
  Dio get _dioClient => _customDio ?? _dio;

  @visibleForTesting
  set dioClient(Dio? client) => _customDio = client;

  String get platformName {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return Platform.operatingSystem.toLowerCase();
  }

  static bool get isInTest =>
      Get.testMode || Platform.environment.containsKey('FLUTTER_TEST');

  FirebaseMessaging get _fcm {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase has not been initialized');
    }
    return FirebaseMessaging.instance;
  }

  /// Initialize Firebase Messaging handlers and permissions
  Future<void> initialize() async {
    if (isInTest) return;

    try {
      if (Firebase.apps.isEmpty) {
        _logger.w('⚠️ Firebase is not initialized, skipping notification setup');
        return;
      }

      // 1. Set background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Request user permissions
      await requestPermissions();

      // 3. Setup foreground notification listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _logger.i('🔔 FCM Foreground Message: ${message.messageId}');
        _handleIncomingMessage(message);
      });

      // 4. Background / Inactive app opened via FCM notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _logger.i('📱 FCM Message Opened App: ${message.data}');
        _handleNotificationTap(message);
      });

      // 5. Cold start from terminated state via FCM notification tap
      _fcm.getInitialMessage().then((RemoteMessage? initialMessage) {
        if (initialMessage != null) {
          _logger.i('🚀 App cold-started from FCM notification: ${initialMessage.data}');
          _handleNotificationTap(initialMessage);
        }
      });

      // 6. Monitor token refresh
      // ignore: deprecated_member_use
      _fcm.onTokenRefresh.listen((newToken) {
        _logger.i('🔄 FCM Device Token Refreshed: $newToken');
        fcmToken.value = newToken;
        final uid = ConfigPreference.getUserId();
        if (uid != null && newToken.isNotEmpty) {
          registerDeviceToken(customerId: uid, token: newToken);
        }
      });

      // 7. Initial device token fetch
      final initialToken = await refreshDeviceToken();
      final uid = ConfigPreference.getUserId();
      if (initialToken != null && uid != null) {
        await registerDeviceToken(customerId: uid, token: initialToken);
      }

      // 8. Subscribe to general broadcast topics if desired
      try {
        await _fcm.subscribeToTopic('customers');
        await _fcm.subscribeToTopic('delivery_updates');
      } catch (e) {
        _logger.d('FCM topic subscription note: $e');
      }
    } catch (e, stack) {
      _logger.e('Failed to initialize NotificationService', error: e, stackTrace: stack);
    }
  }

  /// Register customer FCM token on push notification backend service
  Future<bool> registerDeviceToken({
    required dynamic customerId,
    String? token,
  }) async {
    final parsedId = customerId is int
        ? customerId
        : int.tryParse(customerId?.toString() ?? '') ?? 0;
    if (parsedId <= 0) {
      _logger.w('⚠️ Cannot register FCM token: invalid customerId ($customerId)');
      return false;
    }

    final targetToken = token ?? await getDeviceToken();
    if (targetToken == null || targetToken.isEmpty) {
      _logger.w('⚠️ Cannot register FCM token: no FCM device token available');
      return false;
    }

    try {
      _logger.i('📤 Registering customer FCM token on ${ApiEndpoints.customerTokens} for customer $parsedId...');
      final response = await _dioClient.post(
        ApiEndpoints.customerTokens,
        data: {
          'customer_id': parsedId,
          'fcm_token': targetToken,
          'platform': platformName,
        },
      );

      final isSuccess = response.statusCode == 200 || response.statusCode == 201;
      if (isSuccess) {
        _logger.i('✅ Customer FCM token registered successfully [HTTP ${response.statusCode}]');
        return true;
      } else {
        _logger.w('⚠️ Customer FCM token registration returned status: ${response.statusCode}');
        return false;
      }
    } catch (e, stack) {
      _logger.w('⚠️ Failed to register customer FCM token: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Delete / unregister customer FCM token on logout
  Future<bool> unregisterDeviceToken({String? token}) async {
    final targetToken = token ?? fcmToken.value ?? await getDeviceToken();
    if (targetToken == null || targetToken.isEmpty) {
      _logger.d('ℹ️ No FCM token found to delete on logout');
      return true;
    }

    try {
      final deleteUrl = ApiEndpoints.deleteCustomerToken(targetToken);
      _logger.i('🗑️ Deleting customer FCM token via DELETE $deleteUrl...');
      final response = await _dioClient.delete(
        deleteUrl,
        options: Options(
          headers: {'Accept': 'application/json'},
        ),
      );

      final isSuccess = response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 404; // 404 means already deleted
      _logger.i('✅ Customer FCM token deleted successfully [HTTP ${response.statusCode}]');
      return isSuccess;
    } catch (e, stack) {
      _logger.w('⚠️ Error deleting customer FCM token on logout: $e', error: e, stackTrace: stack);
      // Return true so logout flow does not halt on network errors
      return true;
    } finally {
      try {
        if (!isInTest && Firebase.apps.isNotEmpty) {
          // ignore: deprecated_member_use
          await _fcm.deleteToken();
        }
      } catch (e) {
        _logger.d('Local FCM deleteToken note: $e');
      }
      fcmToken.value = null;
    }
  }

  /// Request permissions for iOS and Android 13+
  Future<void> requestPermissions() async {
    if (isInTest) return;

    try {
      if (Firebase.apps.isNotEmpty) {
        final settings = await _fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        _logger.i('FCM Permission Status: ${settings.authorizationStatus}');

        if (Platform.isIOS) {
          final apnsToken = await _fcm.getAPNSToken();
          _logger.d('APNs Token: $apnsToken');
        }
      }
    } catch (e) {
      _logger.w('Error requesting FCM permissions: $e');
    }
  }

  /// Explicitly query and update the FCM device registration token
  Future<String?> refreshDeviceToken() async {
    if (isInTest) return null;

    try {
      isFetchingToken.value = true;
      if (Firebase.apps.isEmpty) return null;

      // ignore: deprecated_member_use
      final token = await _fcm.getToken();
      _logger.i('📲 FCM Device Token: $token');
      fcmToken.value = token;
      return token;
    } catch (e, stack) {
      _logger.e('Failed to get FCM device token', error: e, stackTrace: stack);
      return null;
    } finally {
      isFetchingToken.value = false;
    }
  }

  /// Get current cached or refreshed FCM registration token
  Future<String?> getDeviceToken() async {
    if (fcmToken.value != null && fcmToken.value!.isNotEmpty) {
      return fcmToken.value;
    }
    return await refreshDeviceToken();
  }

  void _handleIncomingMessage(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title']?.toString() ?? 'AMN Delivery Update';
    final body = message.notification?.body ?? message.data['body']?.toString() ?? 'You have a new update for your order.';

    if (!isInTest && Get.context != null) {
      Get.snackbar(
        title,
        body,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        icon: const Icon(Icons.notifications_active, color: Colors.orangeAccent),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigate or route based on message.data if order_id is present
    final orderId = message.data['order_id'] ?? message.data['orderId'];
    if (orderId != null) {
      _logger.i('Notification tapped with orderId: $orderId');
    }
  }
}
