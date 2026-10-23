import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/models/gebeta_place_suggestion.dart';
import 'package:delivery_app/services/gebeta_location_service.dart';
import 'package:delivery_app/widgets/map/property_location_picker_screen.dart';

void main() {
  setUp(() {
    DioConfig.isTestMode = true;
    Get.testMode = true;
  });

  group('GebetaPlaceSuggestion Model Tests', () {
    test('parses JSON and formats displayText accurately', () {
      final json = {
        'name': 'Bole Medhane Alem',
        'latitude': 8.99797,
        'longitude': 38.786733,
        'City': 'Addis Ababa',
        'Country': 'Ethiopia',
        'type': 'neighborhood',
      };

      final suggestion = GebetaPlaceSuggestion.fromJson(json);
      expect(suggestion.name, 'Bole Medhane Alem');
      expect(suggestion.latitude, 8.99797);
      expect(suggestion.longitude, 38.786733);
      expect(suggestion.city, 'Addis Ababa');
      expect(suggestion.country, 'Ethiopia');
      expect(suggestion.type, 'neighborhood');
      expect(suggestion.displayText, 'Bole Medhane Alem, Addis Ababa, Ethiopia');
    });

    test('searches places via GebetaLocationService in test mode', () async {
      final results = await GebetaLocationService.searchPlaces('Bole');
      expect(results, isNotEmpty);
      expect(results.any((p) => p.name.contains('Bole')), isTrue);
    });
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
    testWidgets('renders fallback interactive canvas, search field, and controls in test mode', (tester) async {
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

      // Verify search field is displayed
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

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

    testWidgets('typing Bole triggers Gebeta search dropdown and selects a location', (tester) async {
      PropertyLocationResult? returnedResult;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  returnedResult = await Get.to<PropertyLocationResult>(
                    () => const PropertyLocationPickerScreen(
                      initialLatitude: 9.0209,
                      initialLongitude: 38.7469,
                      title: 'Select Pick-up Location',
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

      expect(find.text('Select Pick-up Location'), findsOneWidget);

      // Enter query "Bole" in search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Bole');
      // Advance debounce timer (300ms)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify dropdown suggestions appear with Bole locations
      expect(find.text('Bole Medhane Alem'), findsOneWidget);
      expect(find.text('Bole Brass'), findsOneWidget);

      // Tap on 'Bole Medhane Alem' from dropdown
      await tester.tap(find.text('Bole Medhane Alem'));
      await tester.pumpAndSettle();

      // Dropdown should close
      expect(find.text('Bole Brass'), findsNothing);

      // Verify coordinates updated to Bole Medhane Alem (8.997970, 38.786733)
      expect(find.textContaining('8.997970'), findsOneWidget);
      expect(find.textContaining('38.786733'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.text('Confirm Location'));
      await tester.pumpAndSettle();

      expect(returnedResult, isNotNull);
      expect(returnedResult!.latitude, closeTo(8.99797, 0.0001));
      expect(returnedResult!.longitude, closeTo(38.786733, 0.0001));
      expect(returnedResult!.address, contains('Bole Medhane Alem'));
    });

    testWidgets('clearing search field resets suggestions and dismisses dropdown', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: PropertyLocationPickerScreen(
            initialLatitude: 9.0209,
            initialLongitude: 38.7469,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Bole');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Bole Medhane Alem'), findsOneWidget);

      // Tap clear button (Icons.close_rounded)
      final clearButton = find.byIcon(Icons.close_rounded);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Suggestions should disappear
      expect(find.text('Bole Medhane Alem'), findsNothing);
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
