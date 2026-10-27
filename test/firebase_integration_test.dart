import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/firebase_options.dart';
import 'package:delivery_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Options & Configuration Tests', () {
    test('DefaultFirebaseOptions has correct Android config matching amn-driver-app project', () {
      final android = DefaultFirebaseOptions.android;
      expect(android.projectId, 'amn-driver-app');
      expect(android.appId, '1:368083384192:android:5c76d2862fc8f200493365');
      expect(android.messagingSenderId, '368083384192');
      expect(android.storageBucket, 'amn-driver-app.firebasestorage.app');
    });

    test('DefaultFirebaseOptions has correct iOS config matching amn-driver-app project', () {
      final ios = DefaultFirebaseOptions.ios;
      expect(ios.projectId, 'amn-driver-app');
      expect(ios.appId, '1:368083384192:ios:b6c2f617b54ddb73493365');
      expect(ios.messagingSenderId, '368083384192');
      expect(ios.iosBundleId, 'com.freshbite.deliveryApp');
    });

    test('NotificationService singleton initializes safely in test environment', () async {
      final service = NotificationService.instance;
      expect(service, isNotNull);
      expect(NotificationService.isInTest, isTrue);

      // In test mode, initialize should be a safe no-op without throwing
      await service.initialize();
      expect(service.fcmToken.value, isNull);
    });
  });
}
