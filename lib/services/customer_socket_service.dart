import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/storage_config.dart';
import '../constants/api_endpoints.dart';
import '../controllers/order_controller.dart';
import '../models/order.dart';


class CustomerSocketService extends GetxService {
  static CustomerSocketService get to => Get.find<CustomerSocketService>();

  IO.Socket? _socket;
  IO.Socket? get socket => _socket;

  final RxBool isConnected = false.obs;
  final RxBool isDriverOnline = false.obs;
  final RxString currentOrderId = ''.obs;
  final Rxn<double> driverLatitude = Rxn<double>();
  final Rxn<double> driverLongitude = Rxn<double>();
  final Rxn<double> driverHeading = Rxn<double>();
  final Rxn<double> driverSpeed = Rxn<double>();
  final Rxn<int> estimatedMinutes = Rxn<int>();
  final RxString liveOrderStatus = ''.obs;
  final RxString lastError = ''.obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  final Logger _logger = Logger();
  bool isTestMode = false;

  static bool get isInTest =>
      Get.testMode || Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void onInit() {
    super.onInit();
    if (!isInTest && ConfigPreference.getUserId() != null) {
      connect();
    }
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  /// Initialize and connect to Render Socket.IO server as customer
  void connect({String? serverUrl}) {
    if (isTestMode || isInTest) {
      isConnected.value = true;
      return;
    }

    if (_socket != null && _socket!.connected) {
      return;
    }

    final userId = ConfigPreference.getUserId()?.toString() ?? '';
    final token = ConfigPreference.getAccessToken() ?? '';
    final url = serverUrl ?? ApiEndpoints.socketServerUrl;

    try {
      _logger.i('🔌 Connecting Customer Socket to: $url (customerId: $userId)');

      _socket = IO.io(
        url,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({
              'userId': userId,
              'role': 'customer',
              'token': token,
            })
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket!.onConnect((_) {
        isConnected.value = true;
        _logger.i('✅ Customer Socket connected to Render! [ID: ${_socket?.id}]');

        // Rejoin active tracking room if reconnected
        if (currentOrderId.value.isNotEmpty) {
          joinOrder(currentOrderId.value);
        }
      });

      _socket!.onDisconnect((reason) {
        isConnected.value = false;
        isDriverOnline.value = false;
        _logger.w('❌ Customer Socket disconnected: $reason');
      });

      _socket!.onConnectError((err) {
        isConnected.value = false;
        _logger.e('Customer Socket connect_error: $err');
      });

      // Driver live GPS coordinate packet
      _socket!.on('driver:location:update', (data) {
        if (data is Map) {
          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();
          final heading = (data['heading'] as num?)?.toDouble() ?? 0.0;
          final speed = (data['speed'] as num?)?.toDouble() ?? 0.0;

          if (lat != null && lng != null) {
            driverLatitude.value = lat;
            driverLongitude.value = lng;
            driverHeading.value = heading;
            driverSpeed.value = speed;
            isDriverOnline.value = true;
            _logger.d('📍 Received live driver location: [$lat, $lng], heading: $heading°');

            if (Get.isRegistered<OrderController>()) {
              Get.find<OrderController>().updateActiveOrderLocation(
                latitude: lat,
                longitude: lng,
              );
            }
          }
        }
      });

      // Driver ETA update
      _socket!.on('driver:eta:update', (data) {
        if (data is Map) {
          final mins = (data['estimatedMinutes'] as num?)?.toInt();
          if (mins != null) {
            estimatedMinutes.value = mins;
            _logger.i('⏱️ Updated driver ETA: $mins mins');
          }
        }
      });

      // Order status transition
      _socket!.on('order:status:update', (data) {
        if (data is Map) {
          final status = data['status']?.toString();
          final statusName = data['statusName']?.toString();
          if (status != null) {
            liveOrderStatus.value = status;
            _syncOrderStatus(status);
            _showNotification(
              'Order Update',
              statusName ?? 'Your order is in transit: $status',
              Colors.orange.shade700,
            );
          }
        }
      });

      // Order completed
      _socket!.on('order:completed', (data) {
        liveOrderStatus.value = 'delivered';
        _syncOrderStatus('delivered');
        _showNotification(
          'Order Delivered! 🎉',
          'Your meal has been delivered. Enjoy!',
          Colors.green.shade700,
        );
      });

      // Driver presence events
      _socket!.on('order:peer:joined', (data) {
        if (data is Map && data['role'] == 'driver') {
          isDriverOnline.value = true;
          _logger.i('🚗 Assigned driver joined live tracking room');
          _showNotification(
            'Driver Online',
            'Your delivery driver is now broadcasting live location.',
            Colors.green.shade700,
          );
        }
      });

      _socket!.on('order:peer:left', (data) {
        if (data is Map && data['role'] == 'driver') {
          isDriverOnline.value = false;
          _logger.w('Driver went offline from tracking room');
        }
      });

      // In-delivery chat messages
      _socket!.on('order:message:received', (data) {
        if (data is Map) {
          messages.add(Map<String, dynamic>.from(data));
          final senderName = data['senderName']?.toString() ?? 'Driver';
          final message = data['message']?.toString() ?? '';
          if (data['senderRole'] == 'driver') {
            _showNotification('Message from $senderName', message, Colors.indigo.shade700);
          }
        }
      });

      // Server error handling
      _socket!.on('order:error', (error) {
        final code = error['code']?.toString() ?? 'ERROR';
        final message = error['message']?.toString() ?? 'Socket tracking error';
        lastError.value = message;
        _logger.e('⛔ Socket Server Error [$code]: $message');
      });
    } catch (e, stack) {
      _logger.e('Failed to initialize Customer Socket', error: e, stackTrace: stack);
    }
  }

  /// Authenticate and join order tracking room
  void joinOrder(String orderId, {Function(bool success, dynamic data)? onResult}) {
    currentOrderId.value = orderId;

    if (isTestMode || isInTest) {
      isDriverOnline.value = true;
      driverLatitude.value = 9.0082;
      driverLongitude.value = 38.7845;
      driverHeading.value = 45.0;
      estimatedMinutes.value = 12;
      onResult?.call(true, null);
      return;
    }

    if (_socket == null || !_socket!.connected) {
      connect();
    }

    final userId = ConfigPreference.getUserId()?.toString() ?? '';
    final token = ConfigPreference.getAccessToken() ?? '';

    _logger.i('Requesting tracking join for Order #$orderId (customer: $userId)...');

    _socket?.emitWithAck(
      'order:join',
      {
        'orderId': orderId,
        'userId': userId,
        'role': 'customer',
        'token': token,
      },
      ack: (response) {
        if (response is Map && response['success'] == true) {
          final data = response['data'] as Map?;
          final peerConnected = data?['peerConnected'] == true;
          isDriverOnline.value = peerConnected;

          // Hydrate last known location immediately
          final lastLoc = data?['lastKnownLocation'] as Map?;
          if (lastLoc != null) {
            final lat = (lastLoc['latitude'] as num?)?.toDouble();
            final lng = (lastLoc['longitude'] as num?)?.toDouble();
            final heading = (lastLoc['heading'] as num?)?.toDouble() ?? 0.0;
            if (lat != null && lng != null) {
              driverLatitude.value = lat;
              driverLongitude.value = lng;
              driverHeading.value = heading;

              if (Get.isRegistered<OrderController>()) {
                Get.find<OrderController>().updateActiveOrderLocation(
                  latitude: lat,
                  longitude: lng,
                );
              }
            }
          }

          // Hydrate last ETA
          final lastEta = data?['lastEta'] as Map?;
          if (lastEta != null) {
            estimatedMinutes.value = (lastEta['estimatedMinutes'] as num?)?.toInt();
          }

          _logger.i('✅ Customer joined tracking for Order #$orderId [driverOnline: $peerConnected]');
          onResult?.call(true, data);
        } else {
          final errorMsg = response is Map && response['error'] is Map
              ? response['error']['message']?.toString()
              : 'Failed to join tracking room';
          lastError.value = errorMsg ?? '';
          _logger.w('Customer join rejected: $errorMsg');
          onResult?.call(false, null);
        }
      },
    );
  }

  /// Send chat message to driver
  void sendChatMessage(String orderId, String message) {
    if (isTestMode || isInTest) return;

    if (_socket != null && _socket!.connected) {
      final userId = ConfigPreference.getUserId()?.toString() ?? '';
      final userName = ConfigPreference.getUserName() ?? 'Customer';

      _socket!.emit('order:message:send', {
        'orderId': orderId,
        'senderId': userId,
        'senderRole': 'customer',
        'senderName': userName,
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  /// Leave order tracking room
  void leaveOrder(String orderId) {
    if (_socket != null && _socket!.connected) {
      final userId = ConfigPreference.getUserId()?.toString() ?? '15';
      _socket!.emit('order:leave', {
        'orderId': orderId,
        'userId': userId,
      });
    }
    if (currentOrderId.value == orderId) {
      currentOrderId.value = '';
      isDriverOnline.value = false;
      driverLatitude.value = null;
      driverLongitude.value = null;
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
    isDriverOnline.value = false;
  }

  void _syncOrderStatus(String status) {
    if (!Get.isRegistered<OrderController>()) return;
    final orderCtrl = Get.find<OrderController>();
    if (status == 'at_store') {
      orderCtrl.updateActiveOrderStatus(OrderProgressStatus.preparing);
    } else if (status == 'order_picked_up' || status == 'picked_up') {
      orderCtrl.updateActiveOrderStatus(OrderProgressStatus.pickedUp);
    } else if (status == 'in_transit' || status == 'on_the_way') {
      orderCtrl.updateActiveOrderStatus(OrderProgressStatus.onTheWay);
    } else if (status == 'delivered') {
      orderCtrl.updateActiveOrderStatus(OrderProgressStatus.delivered);
    }
  }

  void _showNotification(String title, String message, Color color) {
    if (Get.testMode) return;
    if (Get.context != null && Get.overlayContext != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: color,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
      );
    }
  }
}
