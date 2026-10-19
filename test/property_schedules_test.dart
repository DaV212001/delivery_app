import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/constants/api_endpoints.dart';
import 'package:delivery_app/controllers/property_schedule_controller.dart';
import 'package:delivery_app/models/property_schedule.dart';
import 'package:delivery_app/services/property_service.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/screens/property/widgets/select_time_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioAdapter dioAdapter;

  setUp(() async {
    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    final dio = await DioConfig.dio();
    dioAdapter = DioAdapter(dio: dio);
  });

  tearDown(() {
    DioConfig.resetDio();
    DioConfig.isTestMode = false;
  });

  group('PropertyScheduleItem Model Tests', () {
    test('parses API response with string/int day_of_week and string/bool is_closed', () {
      final json1 = {
        'id': 121,
        'day_of_week': '1',
        'is_closed': '0',
        'open_time': '08:30:00',
        'close_time': '17:30:00',
      };

      final item1 = PropertyScheduleItem.fromJson(json1);
      expect(item1.id, 121);
      expect(item1.dayOfWeek, 1);
      expect(item1.isClosed, isFalse);
      expect(item1.openTime, '08:30');
      expect(item1.closeTime, '17:30');
      expect(item1.dayName, 'Monday');

      final json2 = {
        'id': 128,
        'day_of_week': 6,
        'is_closed': '1',
        'open_time': null,
        'close_time': null,
      };

      final item2 = PropertyScheduleItem.fromJson(json2);
      expect(item2.dayOfWeek, 6);
      expect(item2.isClosed, isTrue);
      expect(item2.openTime, isNull);
      expect(item2.closeTime, isNull);
      expect(item2.dayName, 'Saturday');
    });

    test('toJson produces expected sync format for both open and closed schedules', () {
      const openItem = PropertyScheduleItem(
        dayOfWeek: 2,
        isClosed: false,
        openTime: '09:00',
        closeTime: '12:00',
      );

      final openJson = openItem.toJson();
      expect(openJson['day_of_week'], 2);
      expect(openJson['is_closed'], isFalse);
      expect(openJson['open_time'], '09:00');
      expect(openJson['close_time'], '12:00');

      const closedItem = PropertyScheduleItem(
        dayOfWeek: 0,
        isClosed: true,
        openTime: '08:00',
        closeTime: '20:00',
      );

      final closedJson = closedItem.toJson();
      expect(closedJson['day_of_week'], 0);
      expect(closedJson['is_closed'], isTrue);
      expect(closedJson['open_time'], isNull);
      expect(closedJson['close_time'], isNull);
    });

    test('isTimeDay accurately distinguishes day (06:00-17:59) from night (18:00-05:59)', () {
      expect(PropertyScheduleItem.isTimeDay('08:30'), isTrue);
      expect(PropertyScheduleItem.isTimeDay('12:00'), isTrue);
      expect(PropertyScheduleItem.isTimeDay('17:59'), isTrue);
      expect(PropertyScheduleItem.isTimeDay('18:00'), isFalse);
      expect(PropertyScheduleItem.isTimeDay('22:00'), isFalse);
      expect(PropertyScheduleItem.isTimeDay('02:30'), isFalse);
    });
  });

  group('PropertyScheduleController Logic Tests', () {
    test('initializes 7 days in order Monday to Sunday', () {
      final controller = PropertyScheduleController();
      expect(controller.days.length, 7);
      expect(controller.days[0].dayOfWeek, 1); // Mon
      expect(controller.days[0].dayName, 'Monday');
      expect(controller.days[5].dayOfWeek, 6); // Sat
      expect(controller.days[6].dayOfWeek, 0); // Sun
    });

    test('toggle24Hours sets all days to open and 00:00 - 23:59', () {
      final controller = PropertyScheduleController();
      controller.toggle24Hours(true);

      expect(controller.isOpen24Hours.value, isTrue);
      expect(controller.isOpenAllWeek.value, isTrue);
      for (final day in controller.days) {
        expect(day.isClosed.value, isFalse);
        expect(day.intervals.length, 1);
        expect(day.intervals.first.startTime.value, '00:00');
        expect(day.intervals.first.endTime.value, '23:59');
      }
    });

    test('toggleAllWeek toggles isClosed across all 7 days', () {
      final controller = PropertyScheduleController();
      controller.toggleAllWeek(true);
      expect(controller.isOpenAllWeek.value, isTrue);
      for (final day in controller.days) {
        expect(day.isClosed.value, isFalse);
      }

      controller.toggleAllWeek(false);
      expect(controller.isOpenAllWeek.value, isFalse);
      for (final day in controller.days) {
        expect(day.isClosed.value, isTrue);
      }
    });

    test('addShift adds multiple intervals for split schedules (e.g., day 2 with morning and afternoon shifts)', () {
      final controller = PropertyScheduleController();
      final tue = controller.days.firstWhere((d) => d.dayOfWeek == 2);
      expect(tue.intervals.length, 1);

      tue.intervals[0].startTime.value = '09:00';
      tue.intervals[0].endTime.value = '12:00';

      controller.addShift(2);
      expect(tue.intervals.length, 2);

      tue.intervals[1].startTime.value = '13:00';
      tue.intervals[1].endTime.value = '18:00';

      final payload = controller.buildSyncPayload();
      final tuesdayPayloads = payload.where((p) => p.dayOfWeek == 2).toList();
      expect(tuesdayPayloads.length, 2);
      expect(tuesdayPayloads[0].openTime, '09:00');
      expect(tuesdayPayloads[0].closeTime, '12:00');
      expect(tuesdayPayloads[1].openTime, '13:00');
      expect(tuesdayPayloads[1].closeTime, '18:00');
    });

    test('buildSyncPayload formats closed days with is_closed: true and null times', () {
      final controller = PropertyScheduleController();
      controller.toggleDay(6, false); // Close Saturday
      controller.toggleDay(0, false); // Close Sunday

      final payload = controller.buildSyncPayload();
      final sat = payload.firstWhere((p) => p.dayOfWeek == 6);
      expect(sat.isClosed, isTrue);
      expect(sat.openTime, isNull);
      expect(sat.closeTime, isNull);

      final sun = payload.firstWhere((p) => p.dayOfWeek == 0);
      expect(sun.isClosed, isTrue);
      expect(sun.openTime, isNull);
      expect(sun.closeTime, isNull);
    });
  });

  group('PropertyService Schedules Integration Tests', () {
    test('fetchPropertySchedules calls GET /property/{id}/schedules and parses list', () async {
      dioAdapter.onGet(
        ApiEndpoints.propertySchedules(3),
        (server) => server.reply(200, {
          'data': [
            {
              'id': 127,
              'day_of_week': '0',
              'is_closed': '0',
              'open_time': '08:30',
              'close_time': '17:30',
            },
            {
              'id': 121,
              'day_of_week': '1',
              'is_closed': '0',
              'open_time': '08:30',
              'close_time': '17:30',
            },
            {
              'id': 122,
              'day_of_week': '2',
              'is_closed': '0',
              'open_time': '09:00',
              'close_time': '12:00',
            },
            {
              'id': 123,
              'day_of_week': '2',
              'is_closed': '0',
              'open_time': '13:00',
              'close_time': '18:00',
            },
          ],
        }),
      );

      final result = await PropertyService.fetchPropertySchedules(3);
      expect(result.length, 4);
      expect(result[0].dayOfWeek, 0);
      expect(result[1].dayOfWeek, 1);
      expect(result[2].openTime, '09:00');
      expect(result[3].closeTime, '18:00');
    });

    test('syncPropertySchedules calls POST /property/{id}/schedules/sync with schedules array', () async {
      dioAdapter.onPost(
        ApiEndpoints.propertySchedulesSync(3),
        (server) => server.reply(200, {
          'message': 'Schedules synced successfully',
          'data': [],
        }),
        data: {
          'schedules': [
            {
              'day_of_week': 1,
              'is_closed': false,
              'open_time': '08:30',
              'close_time': '17:30',
            },
            {
              'day_of_week': 6,
              'is_closed': true,
              'open_time': null,
              'close_time': null,
            },
          ],
        },
      );

      final schedules = [
        const PropertyScheduleItem(
          dayOfWeek: 1,
          isClosed: false,
          openTime: '08:30',
          closeTime: '17:30',
        ),
        const PropertyScheduleItem(
          dayOfWeek: 6,
          isClosed: true,
          openTime: null,
          closeTime: null,
        ),
      ];

      final success = await PropertyService.syncPropertySchedules(3, schedules);
      expect(success, isTrue);
    });
  });

  group('SelectTimeModal Widget Tests', () {
    testWidgets('SelectTimeModal renders Day/Night toggle pills and buttons', (tester) async {
      String? selectedStart;
      String? selectedEnd;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SelectTimeModal.show(
                      context: context,
                      initialStartTime: '08:30',
                      initialEndTime: '17:30',
                      onSelected: (start, end) {
                        selectedStart = start;
                        selectedEnd = end;
                      },
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Select Time'), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
      expect(find.text('Day'), findsWidgets);
      expect(find.text('Night'), findsWidgets);
      expect(find.text('08:30'), findsOneWidget);
      expect(find.text('17:30'), findsOneWidget);
      expect(find.text('Select Times'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Select Times
      await tester.tap(find.text('Select Times'));
      await tester.pumpAndSettle();

      expect(selectedStart, '08:30');
      expect(selectedEnd, '17:30');
    });
  });
}
