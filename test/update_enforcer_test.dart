import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/constants/api_endpoints.dart';
import 'package:delivery_app/utils/update_enforcer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateChecker Tests', () {
    final checker = UpdateChecker();

    test('UpdateChecker is a singleton', () {
      final checker2 = UpdateChecker();
      expect(identical(checker, checker2), isTrue);
    });

    test('ApiEndpoints.appVersion points to /app_version', () {
      expect(ApiEndpoints.appVersion, '/app_version');
    });

    test('Version comparison handles semver correctly', () {
      expect(checker.compareVersions('1.0.8', '1.3.10'), lessThan(0));
      expect(checker.compareVersions('1.3.10', '1.0.8'), greaterThan(0));
      expect(checker.compareVersions('1.3.10', '1.3.10'), equals(0));
    });

    test('Version comparison ignores build numbers (+suffix)', () {
      expect(checker.compareVersions('1.0.8+13', '1.3.10'), lessThan(0));
      expect(checker.compareVersions('1.3.10+20', '1.3.10+30'), equals(0));
    });

    test('Version comparison decomposes 2-digit patch like 1.39 into 1.3.9', () {
      expect(checker.compareVersions('1.3.9', '1.39'), equals(0));
      expect(checker.compareVersions('1.3.8', '1.39'), lessThan(0));
      expect(checker.compareVersions('1.4.0', '1.39'), greaterThan(0));
    });

    test('isUpdateAvailable returns true when installed version is older', () {
      expect(checker.isUpdateAvailable('1.0.8', '1.3.10'), isTrue);
      expect(checker.isUpdateAvailable('1.3.10', '1.3.10'), isFalse);
      expect(checker.isUpdateAvailable('1.3.11', '1.3.10'), isFalse);
    });
  });
}
