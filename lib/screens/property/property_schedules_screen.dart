import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/property_schedule_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/my_property_model.dart';
import '../../models/property_schedule.dart';
import 'widgets/select_time_modal.dart';

class PropertySchedulesScreen extends StatefulWidget {
  final dynamic propertyId;
  final String? propertyName;

  const PropertySchedulesScreen({
    super.key,
    this.propertyId,
    this.propertyName,
  });

  @override
  State<PropertySchedulesScreen> createState() => _PropertySchedulesScreenState();
}

class _PropertySchedulesScreenState extends State<PropertySchedulesScreen> {
  late final PropertyScheduleController _controller;

  @override
  void initState() {
    super.initState();

    dynamic pid = widget.propertyId;
    String? pname = widget.propertyName;

    if (pid == null && Get.arguments != null) {
      if (Get.arguments is MyPropertyModel) {
        final p = Get.arguments as MyPropertyModel;
        pid = p.id;
        pname = p.name;
      } else if (Get.arguments is Map) {
        final map = Get.arguments as Map;
        pid = map['id'] ?? map['propertyId'];
        pname = map['name'] ?? map['propertyName'];
      } else {
        pid = Get.arguments;
      }
    }

    // Default fallback to 3 (as in user example) if somehow null
    pid ??= 3;

    final tag = 'property_schedule_$pid';
    if (Get.isRegistered<PropertyScheduleController>(tag: tag)) {
      _controller = Get.find<PropertyScheduleController>(tag: tag);
    } else {
      _controller = Get.put(
        PropertyScheduleController(propertyId: pid),
        tag: tag,
      );
    }

    if (pname != null && pname.isNotEmpty) {
      _controller.propertyName.value = pname;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'schedules'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(context, isDark),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Open 24 Hours Card
              _buildOpen24HoursCard(context, isDark),
              const SizedBox(height: 16),

              // 2. Open All Week Card
              _buildOpenAllWeekCard(context, isDark),
              const SizedBox(height: 24),

              // 3. Working Days Section Title
              Text(
                'working_days'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Days List (Monday to Sunday)
              ..._controller.days.map((day) => _buildDayCard(context, day, isDark)),

              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  /// Card 1: Open 24 Hours & default Starting/Closing Time
  Widget _buildOpen24HoursCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Open 24 Hours & Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'open_24_hours'.tr,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Obx(
                () => Switch.adaptive(
                  value: _controller.isOpen24Hours.value,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) => _controller.toggle24Hours(val),
                ),
              ),
            ],
          ),

          // When not 24 hours, display the default starting and closing time inputs
          Obx(() {
            if (_controller.isOpen24Hours.value) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'starting_time'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey.shade300 : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickTopDefaultTime(isStart: true),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerLow : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade700 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      _controller.defaultStartTime.value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'closing_time'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey.shade300 : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickTopDefaultTime(isStart: false),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerLow : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade700 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      _controller.defaultEndTime.value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Future<void> _pickTopDefaultTime({required bool isStart}) async {
    SelectTimeModal.show(
      context: context,
      initialStartTime: _controller.defaultStartTime.value,
      initialEndTime: _controller.defaultEndTime.value,
      onSelected: (start, end) {
        _controller.defaultStartTime.value = start;
        _controller.defaultEndTime.value = end;
        // Optionally update all open days with 1 interval
        for (final day in _controller.days) {
          if (!day.isClosed.value && day.intervals.length == 1) {
            day.intervals[0].startTime.value = start;
            day.intervals[0].endTime.value = end;
          }
        }
      },
    );
  }

  /// Card 2: Open All Week toggle with calendar icon
  Widget _buildOpenAllWeekCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'open_all_week'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Obx(
            () => Switch.adaptive(
              value: _controller.isOpenAllWeek.value,
              activeTrackColor: AppColors.primary,
              onChanged: (val) => _controller.toggleAllWeek(val),
            ),
          ),
        ],
      ),
    );
  }

  /// Day Card: Accordion with Checkbox, Day Name, Shifts, and Add Another Schedule
  Widget _buildDayCard(BuildContext context, DayScheduleState day, bool isDark) {
    return Obx(() {
      final isOpen = !day.isClosed.value;
      final isExpanded = day.isExpanded.value;

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOpen
                ? (isDark ? Colors.grey.shade700 : const Color(0xFFE2E8F0))
                : (isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Checkbox, Day Name, Chevron
            InkWell(
              onTap: () => _controller.toggleDayExpansion(day.dayOfWeek),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Green Checkbox
                    InkWell(
                      onTap: () => _controller.toggleDay(day.dayOfWeek, !isOpen),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isOpen ? const Color(0xFF22C55E) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isOpen ? const Color(0xFF22C55E) : Colors.grey.shade400,
                            width: 1.8,
                          ),
                        ),
                        child: isOpen
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Day Name
                    Expanded(
                      child: Text(
                        day.dayKey.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isOpen
                              ? (isDark ? Colors.white : const Color(0xFF1E293B))
                              : Colors.grey,
                        ),
                      ),
                    ),

                    // Chevron Down / Up
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade500,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

            // Expanded Shifts List (only when day is open and expanded)
            if (isOpen && isExpanded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    // List of shifts
                    ...day.intervals.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final interval = entry.value;
                      return _buildShiftRow(
                        context: context,
                        day: day,
                        index: idx,
                        interval: interval,
                        isDark: isDark,
                        showDelete: day.intervals.length > 1,
                      );
                    }),
                    const SizedBox(height: 12),

                    // "+ Add Another Schedule" Button
                    InkWell(
                      onTap: () => _controller.addShift(day.dayOfWeek),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'add_another_schedule'.tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// Single shift row with Starting Time box & Closing Time box
  Widget _buildShiftRow({
    required BuildContext context,
    required DayScheduleState day,
    required int index,
    required ScheduleInterval interval,
    required bool isDark,
    required bool showDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'starting_time'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'closing_time'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
              if (showDelete) const SizedBox(width: 32),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // Starting Time Pill Box
              Expanded(
                child: InkWell(
                  onTap: () => _openTimePickerForShift(day.dayOfWeek, index, interval),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainerLow
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          interval.startTime.value,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Icon(
                          PropertyScheduleItem.isTimeDay(interval.startTime.value)
                              ? Icons.wb_sunny_rounded
                              : Icons.nightlight_round,
                          size: 16,
                          color: PropertyScheduleItem.isTimeDay(interval.startTime.value)
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF1E293B),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Closing Time Pill Box
              Expanded(
                child: InkWell(
                  onTap: () => _openTimePickerForShift(day.dayOfWeek, index, interval),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainerLow
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          interval.endTime.value,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Icon(
                          PropertyScheduleItem.isTimeDay(interval.endTime.value)
                              ? Icons.wb_sunny_rounded
                              : Icons.nightlight_round,
                          size: 16,
                          color: PropertyScheduleItem.isTimeDay(interval.endTime.value)
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF1E293B),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Delete Shift Button (if multiple shifts)
              if (showDelete) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  onPressed: () => _controller.removeShift(day.dayOfWeek, index),
                  tooltip: 'Remove',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _openTimePickerForShift(int dayOfWeek, int index, ScheduleInterval interval) {
    SelectTimeModal.show(
      context: context,
      initialStartTime: interval.startTime.value,
      initialEndTime: interval.endTime.value,
      onSelected: (start, end) {
        _controller.updateShift(dayOfWeek, index, start, end);
      },
    );
  }

  /// Bottom Fixed Action Bar: Cancel & Save Buttons
  Widget _buildBottomActionBar(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Get.back(),
                child: Text(
                  'cancel'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Save Button
          Expanded(
            child: SizedBox(
              height: 52,
              child: Obx(
                () => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _controller.isSaving.value
                      ? null
                      : () async {
                          final ok = await _controller.saveSchedules();
                          if (ok) {
                            Get.back(result: true);
                          }
                        },
                  child: _controller.isSaving.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'save'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
