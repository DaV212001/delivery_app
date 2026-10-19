import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';

class SelectTimeModal extends StatefulWidget {
  final String initialStartTime;
  final String initialEndTime;
  final Function(String startTime, String endTime) onSelected;

  const SelectTimeModal({
    super.key,
    required this.initialStartTime,
    required this.initialEndTime,
    required this.onSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialStartTime,
    required String initialEndTime,
    required Function(String startTime, String endTime) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SelectTimeModal(
        initialStartTime: initialStartTime,
        initialEndTime: initialEndTime,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<SelectTimeModal> createState() => _SelectTimeModalState();
}

class _SelectTimeModalState extends State<SelectTimeModal> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isStartDay;
  late bool _isEndDay;

  @override
  void initState() {
    super.initState();
    _startTime = _parseTime(widget.initialStartTime, const TimeOfDay(hour: 8, minute: 30));
    _endTime = _parseTime(widget.initialEndTime, const TimeOfDay(hour: 17, minute: 30));
    _isStartDay = _isDaytime(_startTime);
    _isEndDay = _isDaytime(_endTime);
  }

  TimeOfDay _parseTime(String timeStr, TimeOfDay fallback) {
    if (!timeStr.contains(':')) return fallback;
    final parts = timeStr.split(':');
    final h = int.tryParse(parts[0]) ?? fallback.hour;
    final m = int.tryParse(parts[1]) ?? fallback.minute;
    return TimeOfDay(hour: h, minute: m);
  }

  bool _isDaytime(TimeOfDay time) {
    return time.hour >= 6 && time.hour < 18;
  }

  String _formatTime24(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
        _isStartDay = _isDaytime(picked);
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
        _isEndDay = _isDaytime(picked);
      });
    }
  }

  void _toggleStartDayNight(bool day) {
    setState(() {
      _isStartDay = day;
      if (day && !_isDaytime(_startTime)) {
        // Switch from night to day
        final newH = (_startTime.hour - 12).clamp(6, 17);
        _startTime = TimeOfDay(hour: newH, minute: _startTime.minute);
      } else if (!day && _isDaytime(_startTime)) {
        // Switch from day to night
        final newH = (_startTime.hour + 12).clamp(18, 23);
        _startTime = TimeOfDay(hour: newH, minute: _startTime.minute);
      }
    });
  }

  void _toggleEndDayNight(bool day) {
    setState(() {
      _isEndDay = day;
      if (day && !_isDaytime(_endTime)) {
        // Switch from night to day
        final newH = (_endTime.hour - 12).clamp(6, 17);
        _endTime = TimeOfDay(hour: newH, minute: _endTime.minute);
      } else if (!day && _isDaytime(_endTime)) {
        // Switch from day to night
        final newH = (_endTime.hour + 12).clamp(18, 23);
        _endTime = TimeOfDay(hour: newH, minute: _endTime.minute);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'select_time'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 24, color: AppColors.primary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Subtitle instructions
            Text(
              'select_part_of_day_help'.tr,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'example_time_help'.tr,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Start Time and End Time Side-by-Side
            Row(
              children: [
                // Start Time Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'starting_time'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          children: const [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Day / Night Pill selector
                      _buildDayNightPills(
                        isDay: _isStartDay,
                        onChanged: _toggleStartDayNight,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Large Time Display Card
                      InkWell(
                        onTap: _pickStartTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 72,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainerLow
                                : const Color(0xFFF6F7F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            _formatTime24(_startTime),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // End Time Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'closing_time'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          children: const [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Day / Night Pill selector
                      _buildDayNightPills(
                        isDay: _isEndDay,
                        onChanged: _toggleEndDayNight,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Large Time Display Card
                      InkWell(
                        onTap: _pickEndTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 72,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainerLow
                                : const Color(0xFFF6F7F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            _formatTime24(_endTime),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Select Times Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  final s = _formatTime24(_startTime);
                  final e = _formatTime24(_endTime);
                  widget.onSelected(s, e);
                  Navigator.of(context).pop();
                },
                child: Text(
                  'select_times'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'cancel'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayNightPills({
    required bool isDay,
    required Function(bool isDay) onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLowest : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // Day Pill
          Expanded(
            child: InkWell(
              onTap: () => onChanged(true),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isDay ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDay
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wb_sunny_rounded,
                      size: 14,
                      color: isDay ? const Color(0xFFF59E0B) : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'day'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isDay ? FontWeight.w700 : FontWeight.w500,
                        color: isDay ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Night Pill
          Expanded(
            child: InkWell(
              onTap: () => onChanged(false),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: !isDay ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: !isDay
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.nightlight_round,
                      size: 14,
                      color: !isDay ? const Color(0xFF1E293B) : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'night'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: !isDay ? FontWeight.w700 : FontWeight.w500,
                        color: !isDay ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
