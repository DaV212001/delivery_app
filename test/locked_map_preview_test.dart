import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/widgets/map/locked_map_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DioConfig.isTestMode = true;
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('LockedMapPreview Widget Tests', () {
    testWidgets('renders fallback canvas, center pin marker, and locked pill badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LockedMapPreview(
              latitude: 9.0209,
              longitude: 38.7469,
              height: 140,
            ),
          ),
        ),
      );

      // Verify container renders center pin marker without Locked Map badge
      expect(find.byType(LockedMapPreview), findsOneWidget);
      expect(find.text('Locked Map'), findsNothing);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
    });

    testWidgets('calls onTap callback when user taps on map preview', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockedMapPreview(
              latitude: 9.0209,
              longitude: 38.7469,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LockedMapPreview));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('LockedLocationPickerCard Widget Tests', () {
    testWidgets('renders pinned location header, locked map view, reverse geocoded address, and Pick on Map button without raw coordinates', (tester) async {
      bool pickOnMapTapped = false;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: LockedLocationPickerCard(
                latitude: 9.0209,
                longitude: 38.7469,
                address: 'Bole Medhanialem, Addis Ababa',
                buttonLabel: 'Pick on Map',
                onPickOnMap: () {
                  pickOnMapTapped = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header is rendered
      expect(find.text('Pinned Location'), findsOneWidget);

      // 2. Locked map preview is rendered without badge
      expect(find.byType(LockedMapPreview), findsOneWidget);
      expect(find.text('Locked Map'), findsNothing);

      // 3. Reverse geocoded address is rendered underneath the map view
      expect(find.text('Bole Medhanialem, Addis Ababa'), findsOneWidget);

      // 4. Raw coordinates are NOT rendered above button
      expect(find.text('9.02090, 38.74690'), findsNothing);
      expect(find.text('9.0209, 38.7469'), findsNothing);

      // 5. Button is rendered with Pick on Map
      expect(find.text('Pick on Map'), findsOneWidget);

      // 6. Tapping the button fires onPickOnMap
      await tester.tap(find.text('Pick on Map'));
      await tester.pump();
      expect(pickOnMapTapped, isTrue);
    });

    testWidgets('tapping on the locked map preview also triggers onPickOnMap', (tester) async {
      bool pickOnMapTapped = false;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: LockedLocationPickerCard(
                latitude: 9.0209,
                longitude: 38.7469,
                address: 'Sarbet, Addis Ababa',
                buttonLabel: 'Pick on Map',
                onPickOnMap: () {
                  pickOnMapTapped = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LockedMapPreview));
      await tester.pump();
      expect(pickOnMapTapped, isTrue);
    });

    testWidgets('renders extraActions when provided (e.g. GPS Position button)', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: LockedLocationPickerCard(
                latitude: 9.0209,
                longitude: 38.7469,
                address: 'Bole Rwanda',
                buttonLabel: 'Pick on Map',
                onPickOnMap: () {},
                extraActions: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                    label: const Text('GPS Position'),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pick on Map'), findsOneWidget);
      expect(find.text('GPS Position'), findsOneWidget);
      expect(find.byIcon(Icons.gps_fixed_rounded), findsOneWidget);
    });

    testWidgets('renders inside AlertDialog without RenderFlex overflow', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Add Address'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const TextField(
                                decoration: InputDecoration(labelText: 'Name'),
                              ),
                              const SizedBox(height: 14),
                              LockedLocationPickerCard(
                                latitude: 9.0209,
                                longitude: 38.7469,
                                address: 'Bole Atlas, Addis Ababa',
                                buttonLabel: 'Pick on Map',
                                onPickOnMap: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(LockedLocationPickerCard), findsOneWidget);
      expect(find.text('Bole Atlas, Addis Ababa'), findsOneWidget);
      expect(find.text('Pick on Map'), findsOneWidget);
    });
  });
}
