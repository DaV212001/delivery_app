import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/property_schedule.dart';
import '../services/property_service.dart';

class ScheduleInterval {
  final RxString startTime;
  final RxString endTime;

  ScheduleInterval({
    required String startTime,
    required String endTime,
  })  : startTime = startTime.obs,
        endTime = endTime.obs;
}

class DayScheduleState {
  final int dayOfWeek; // 0 = Sun, 1 = Mon, 2 = Tue, 3 = Wed, 4 = Thu, 5 = Fri, 6 = Sat
  final String dayName;
  final String dayKey;
  final RxBool isClosed;
  final RxBool isExpanded;
  final RxList<ScheduleInterval> intervals;

  DayScheduleState({
    required this.dayOfWeek,
    required this.dayName,
    required this.dayKey,
    required bool isClosed,
    bool isExpanded = true,
    List<ScheduleInterval>? intervals,
  })  : isClosed = isClosed.obs,
        isExpanded = isExpanded.obs,
        intervals = (intervals ?? <ScheduleInterval>[]).obs;
}

class PropertyScheduleController extends GetxController {
  final dynamic propertyId;
  final propertyName = ''.obs;

  PropertyScheduleController({this.propertyId}) {
    _initializeDayStructure();
  }

  final isLoading = false.obs;
  final isSaving = false.obs;

  final isOpen24Hours = false.obs;
  final isOpenAllWeek = false.obs;

  final defaultStartTime = '08:00'.obs;
  final defaultEndTime = '22:00'.obs;

  final days = <DayScheduleState>[].obs;

  @override
  void onInit() {
    super.onInit();
    if (days.isEmpty) {
      _initializeDayStructure();
    }
    if (propertyId != null) {
      loadSchedules();
    }
  }

  void _initializeDayStructure() {
    days.assignAll([
      DayScheduleState(
        dayOfWeek: 0,
        dayName: 'Sunday',
        dayKey: 'sunday',
        isClosed: true,
        intervals: [ScheduleInterval(startTime: '09:00', endTime: '17:00')],
      ),
      DayScheduleState(
        dayOfWeek: 1,
        dayName: 'Monday',
        dayKey: 'monday',
        isClosed: false,
        intervals: [ScheduleInterval(startTime: '08:30', endTime: '17:30')],
      ),
      DayScheduleState(
        dayOfWeek: 2,
        dayName: 'Tuesday',
        dayKey: 'tuesday',
        isClosed: false,
        intervals: [ScheduleInterval(startTime: '08:30', endTime: '17:30')],
      ),
      DayScheduleState(
        dayOfWeek: 3,
        dayName: 'Wednesday',
        dayKey: 'wednesday',
        isClosed: false,
        intervals: [ScheduleInterval(startTime: '08:30', endTime: '17:30')],
      ),
      DayScheduleState(
        dayOfWeek: 4,
        dayName: 'Thursday',
        dayKey: 'thursday',
        isClosed: false,
        intervals: [ScheduleInterval(startTime: '08:30', endTime: '17:30')],
      ),
      DayScheduleState(
        dayOfWeek: 5,
        dayName: 'Friday',
        dayKey: 'friday',
        isClosed: false,
        intervals: [ScheduleInterval(startTime: '08:30', endTime: '17:30')],
      ),
      DayScheduleState(
        dayOfWeek: 6,
        dayName: 'Saturday',
        dayKey: 'saturday',
        isClosed: true,
        intervals: [ScheduleInterval(startTime: '09:00', endTime: '17:00')],
      ),
    ]);
  }

  Future<void> loadSchedules() async {
    if (propertyId == null) return;
    isLoading.value = true;
    try {
      final list = await PropertyService.fetchPropertySchedules(propertyId);
      if (list.isNotEmpty) {
        // Group items by day_of_week
        final Map<int, List<PropertyScheduleItem>> grouped = {};
        for (final item in list) {
          final normalizedDay = (item.dayOfWeek == 7) ? 0 : item.dayOfWeek;
          grouped.putIfAbsent(normalizedDay, () => []).add(item);
        }

        for (final dayState in days) {
          final dayItems = grouped[dayState.dayOfWeek];
          if (dayItems != null && dayItems.isNotEmpty) {
            // Check if any open intervals exist
            final openIntervals = dayItems.where((i) => !i.isClosed && i.openTime != null && i.closeTime != null).toList();
            if (openIntervals.isNotEmpty) {
              dayState.isClosed.value = false;
              dayState.intervals.assignAll(
                openIntervals.map((i) => ScheduleInterval(
                  startTime: i.openTime!,
                  endTime: i.closeTime!,
                )),
              );
            } else {
              dayState.isClosed.value = true;
            }
          } else {
            // Not in response -> closed
            dayState.isClosed.value = true;
          }
        }

        _recalculateToggles();
      }
    } catch (e) {
      debugPrint('Failed to load property schedules: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _recalculateToggles() {
    isOpenAllWeek.value = days.every((d) => !d.isClosed.value);

    // Check if open 24 hours
    final allOpen = days.every((d) => !d.isClosed.value);
    if (allOpen) {
      final is24 = days.every((d) => d.intervals.any((i) =>
          (i.startTime.value == '00:00' && (i.endTime.value == '23:59' || i.endTime.value == '24:00' || i.endTime.value == '00:00'))));
      isOpen24Hours.value = is24;
    } else {
      isOpen24Hours.value = false;
    }
  }

  void toggle24Hours(bool value) {
    isOpen24Hours.value = value;
    if (value) {
      isOpenAllWeek.value = true;
      for (final day in days) {
        day.isClosed.value = false;
        day.intervals.assignAll([
          ScheduleInterval(startTime: '00:00', endTime: '23:59'),
        ]);
      }
    } else {
      for (final day in days) {
        day.intervals.assignAll([
          ScheduleInterval(
            startTime: defaultStartTime.value,
            endTime: defaultEndTime.value,
          ),
        ]);
      }
      _recalculateToggles();
    }
  }

  void toggleAllWeek(bool value) {
    isOpenAllWeek.value = value;
    for (final day in days) {
      day.isClosed.value = !value;
      if (value && day.intervals.isEmpty) {
        day.intervals.add(
          ScheduleInterval(
            startTime: defaultStartTime.value,
            endTime: defaultEndTime.value,
          ),
        );
      }
    }
    if (!value) {
      isOpen24Hours.value = false;
    }
  }

  void toggleDay(int dayOfWeek, bool isOpen) {
    final day = days.firstWhereOrNull((d) => d.dayOfWeek == dayOfWeek);
    if (day == null) return;

    day.isClosed.value = !isOpen;
    if (isOpen && day.intervals.isEmpty) {
      day.intervals.add(
        ScheduleInterval(
          startTime: defaultStartTime.value,
          endTime: defaultEndTime.value,
        ),
      );
    }

    _recalculateToggles();
  }

  void toggleDayExpansion(int dayOfWeek) {
    final day = days.firstWhereOrNull((d) => d.dayOfWeek == dayOfWeek);
    if (day != null) {
      day.isExpanded.toggle();
    }
  }

  void addShift(int dayOfWeek) {
    final day = days.firstWhereOrNull((d) => d.dayOfWeek == dayOfWeek);
    if (day == null) return;

    day.isClosed.value = false;
    // Default afternoon/evening interval for second shift
    String nextStart = '13:00';
    String nextEnd = '18:00';
    if (day.intervals.isNotEmpty) {
      final last = day.intervals.last;
      final parts = last.endTime.value.split(':');
      final h = int.tryParse(parts[0]) ?? 12;
      final newH = (h + 1).clamp(0, 22);
      nextStart = '${newH.toString().padLeft(2, '0')}:00';
      nextEnd = '${(newH + 4).clamp(1, 23).toString().padLeft(2, '0')}:00';
    }

    day.intervals.add(
      ScheduleInterval(startTime: nextStart, endTime: nextEnd),
    );
  }

  void removeShift(int dayOfWeek, int index) {
    final day = days.firstWhereOrNull((d) => d.dayOfWeek == dayOfWeek);
    if (day == null) return;

    if (day.intervals.length > 1) {
      day.intervals.removeAt(index);
    } else {
      // If only 1 interval and user removes it, mark day closed
      day.isClosed.value = true;
    }
    _recalculateToggles();
  }

  void updateShift(int dayOfWeek, int index, String start, String end) {
    final day = days.firstWhereOrNull((d) => d.dayOfWeek == dayOfWeek);
    if (day == null || index < 0 || index >= day.intervals.length) return;

    day.intervals[index].startTime.value = start;
    day.intervals[index].endTime.value = end;
  }

  List<PropertyScheduleItem> buildSyncPayload() {
    final payloadList = <PropertyScheduleItem>[];

    for (final day in days) {
      if (day.isClosed.value || day.intervals.isEmpty) {
        payloadList.add(
          PropertyScheduleItem(
            dayOfWeek: day.dayOfWeek,
            isClosed: true,
            openTime: null,
            closeTime: null,
          ),
        );
      } else {
        for (final interval in day.intervals) {
          payloadList.add(
            PropertyScheduleItem(
              dayOfWeek: day.dayOfWeek,
              isClosed: false,
              openTime: interval.startTime.value,
              closeTime: interval.endTime.value,
            ),
          );
        }
      }
    }

    return payloadList;
  }

  Future<bool> saveSchedules() async {
    if (propertyId == null) {
      Get.snackbar('error'.tr, 'Property ID is required');
      return false;
    }

    isSaving.value = true;
    try {
      final payload = buildSyncPayload();
      final success = await PropertyService.syncPropertySchedules(propertyId, payload);
      if (success) {
        Get.snackbar(
          'success'.tr,
          'schedules_updated_success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_to_update_schedules'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
