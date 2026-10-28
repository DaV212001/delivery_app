import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:get/get.dart';

import '../../config/dio_config.dart';
import '../../core/theme/app_colors.dart';
import '../../services/gebeta_location_service.dart';

/// A locked (non-interactive) map view centered on [latitude] and [longitude]
/// with a styled pin marker positioned directly on the selected coordinates.
class LockedMapPreview extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  final double height;
  final VoidCallback? onTap;

  const LockedMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.zoom = 15.5,
    this.height = 140.0,
    this.onTap,
  });

  @override
  State<LockedMapPreview> createState() => _LockedMapPreviewState();
}

class _LockedMapPreviewState extends State<LockedMapPreview> {
  static const String _gebetaStandardStyle =
      'https://tiles.gebeta.app/styles/standard/style.json';

  GebetaMapController? _mapController;

  bool get _canUseNativeMap {
    if (DioConfig.isTestMode) return false;
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void didUpdateWidget(covariant LockedMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      if (_mapController != null && _canUseNativeMap) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(widget.latitude, widget.longitude)),
        );
      }
    }
  }

  void _onMapCreated(GebetaMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Locked Map Canvas
          Positioned.fill(
            child: _canUseNativeMap
                ? IgnorePointer(
                    ignoring: true,
                    child: GebetaMap(
                      styleString: _gebetaStandardStyle,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(widget.latitude, widget.longitude),
                        zoom: widget.zoom,
                      ),
                      onMapCreated: _onMapCreated,
                      trackCameraPosition: false,
                      compassEnabled: false,
                      rotateGesturesEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      doubleClickZoomEnabled: false,
                      tiltGesturesEnabled: false,
                      myLocationEnabled: false,
                    ),
                  )
                : _buildFallbackCanvas(isDark),
          ),

          // 2. Center Marker Pin (Pointed directly at map center)
          Center(
            child: FractionalTranslation(
              translation: const Offset(0, -0.45),
              child: _buildPinMarker(),
            ),
          ),

          // 3. Tap Overlay (Allows user to tap map view to open map picker)
          if (widget.onTap != null)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  splashColor: AppColors.primary.withValues(alpha: 0.12),
                  highlightColor: AppColors.primary.withValues(alpha: 0.06),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPinMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pin Head
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        // Pin Tip Needle
        CustomPaint(
          size: const Size(10, 8),
          painter: _LockedPinTipPainter(color: AppColors.primary),
        ),
        // Ground Shadow
        const SizedBox(height: 2),
        Container(
          width: 10,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackCanvas(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E252B) : const Color(0xFFE9EEF4),
      child: CustomPaint(
        size: Size.infinite,
        painter: _LockedMapGridPainter(isDark: isDark),
      ),
    );
  }
}

class _LockedPinTipPainter extends CustomPainter {
  final Color color;
  const _LockedPinTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LockedMapGridPainter extends CustomPainter {
  final bool isDark;
  const _LockedMapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Stylized road lines for realistic locked map preview
    final roadPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final roadAccentPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final midY = size.height * 0.55;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY - 10), roadPaint);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.55, size.height), roadAccentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A complete card component that replaces raw coordinates in modals & bottomsheets.
/// Displays:
/// 1. Title row ("Pinned Location")
/// 2. Locked map view with marker on coordinates
/// 3. Reverse geocoded string underneath the map view
/// 4. "Pick on Map" button (plus optional extra actions)
class LockedLocationPickerCard extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? address;
  final String? buttonLabel;
  final VoidCallback onPickOnMap;
  final ValueChanged<String>? onAddressResolved;
  final List<Widget>? extraActions;

  const LockedLocationPickerCard({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
    this.buttonLabel,
    required this.onPickOnMap,
    this.onAddressResolved,
    this.extraActions,
  });

  @override
  State<LockedLocationPickerCard> createState() =>
      _LockedLocationPickerCardState();
}

class _LockedLocationPickerCardState extends State<LockedLocationPickerCard> {
  String _resolvedAddress = '';
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _initAddress();
  }

  @override
  void didUpdateWidget(covariant LockedLocationPickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.address != widget.address) {
      _initAddress();
    }
  }

  bool _isRawCoordinates(String str) {
    final trimmed = str.trim();
    final coordRegExp = RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$');
    return coordRegExp.hasMatch(trimmed);
  }

  void _initAddress() {
    final addr = widget.address?.trim() ?? '';
    if (addr.isNotEmpty && !_isRawCoordinates(addr) && addr != 'Home' && addr != 'Office' && addr != 'Other') {
      _resolvedAddress = addr;
    } else {
      _resolveReverseGeocode();
    }
  }

  Future<void> _resolveReverseGeocode() async {
    if (_isResolving) return;
    setState(() => _isResolving = true);
    try {
      final res = await GebetaLocationService.reverseGeocode(
        widget.latitude,
        widget.longitude,
      );
      if (mounted) {
        setState(() {
          _resolvedAddress = res;
          _isResolving = false;
        });
        widget.onAddressResolved?.call(res);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedAddress = '${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)} (Addis Ababa)';
          _isResolving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainerLow
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(
                Icons.pin_drop_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'pinned_location'.tr.isNotEmpty && 'pinned_location'.tr != 'pinned_location'
                    ? 'pinned_location'.tr
                    : 'Pinned Location',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 1. Locked Map View with Marker
          LockedMapPreview(
            latitude: widget.latitude,
            longitude: widget.longitude,
            height: 135,
            onTap: widget.onPickOnMap,
          ),
          const SizedBox(height: 10),

          // 2. Reverse Geocoded String Underneath Map View
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.place_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _isResolving && _resolvedAddress.isEmpty
                      ? Row(
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Resolving address...',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _resolvedAddress.isNotEmpty
                              ? _resolvedAddress
                              : 'Location selected',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.grey.shade200
                                : Colors.grey.shade800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. "Pick on Map" Button
          if (widget.extraActions == null || widget.extraActions!.isEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.map_outlined, size: 16),
                label: Text(
                  widget.buttonLabel ??
                      ('select_location_on_map'.tr.isNotEmpty &&
                              'select_location_on_map'.tr != 'select_location_on_map'
                          ? 'select_location_on_map'.tr
                          : 'Pick on Map'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: widget.onPickOnMap,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: Text(
                      widget.buttonLabel ??
                          ('select_location_on_map'.tr.isNotEmpty &&
                                  'select_location_on_map'.tr != 'select_location_on_map'
                              ? 'select_location_on_map'.tr
                              : 'Pick on Map'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    onPressed: widget.onPickOnMap,
                  ),
                ),
                const SizedBox(width: 8),
                ...widget.extraActions!,
              ],
            ),
        ],
      ),
    );
  }
}
