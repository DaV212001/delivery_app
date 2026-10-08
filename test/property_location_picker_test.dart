import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/widgets/map/property_location_picker_screen.dart';

void main() {
  setUp(() {
    DioConfig.isTestMode = true;
    Get.testMode = true;
  });

  group('PropertyLocationResult Tests', () {
    test('instantiates and formats toString accurately', () {
      const result = PropertyLocationResult(
        latitude: 9.0209,
        longitude: 38.7469,
        address: 'Bole, Addis Ababa',
      );

      expect(result.latitude, 9.0209);
      expect(result.longitude, 38.7469);
      expect(result.address, 'Bole, Addis Ababa');
      expect(result.toString(), contains('9.0209'));
      expect(result.toString(), contains('38.7469'));
    });
  });

  group('PropertyLocationPickerScreen Widget Tests', () {
    testWidgets('renders fallback interactive canvas and controls in test mode', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: PropertyLocationPickerScreen(
            initialLatitude: 9.0209,
            initialLongitude: 38.7469,
            initialAddress: 'Bole Medhanialem',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('Pin Store Location'), findsOneWidget);

      // Verify coordinate text badge
      expect(find.textContaining('9.020900'), findsOneWidget);
      expect(find.textContaining('38.746900'), findsOneWidget);

      // Verify initial address is shown
      expect(find.text('Bole Medhanialem'), findsOneWidget);

      // Verify action buttons and fallback guidance
      expect(find.text('Confirm Location'), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      expect(find.text('Tap or drag to reposition location pin'), findsOneWidget);
    });

    testWidgets('confirm button triggers return callback', (tester) async {
      PropertyLocationResult? returnedResult;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  returnedResult = await Get.to<PropertyLocationResult>(
                    () => const PropertyLocationPickerScreen(
                      initialLatitude: 9.05,
                      initialLongitude: 38.75,
                      initialAddress: 'Kazanchis',
                    ),
                  );
                },
                child: const Text('Open Picker'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open screen
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Pin Store Location'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.text('Confirm Location'));
      await tester.pumpAndSettle();

      expect(returnedResult, isNotNull);
      expect(returnedResult!.latitude, closeTo(9.05, 0.0001));
      expect(returnedResult!.longitude, closeTo(38.75, 0.0001));
    });
  });
}
