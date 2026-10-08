import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:get/get.dart';

import '../../config/dio_config.dart';
import '../../core/theme/app_colors.dart';
import '../../services/gebeta_location_service.dart';
import '../common/app_widgets.dart';

/// Result object returned by [PropertyLocationPickerScreen]
class PropertyLocationResult {
  final double latitude;
  final double longitude;
  final String address;

  const PropertyLocationResult({
    required this.latitude,
    required this.longitude,
    this.address = '',
  });

  @override
  String toString() =>
      'PropertyLocationResult(lat: $latitude, lng: $longitude, address: $address)';
}

/// Interactive Full-Featured Map Selector powered by Gebeta Maps.
/// Allows business owners to accurately pin their property / store location on a map
/// with real-time reverse geocoding, current GPS centering, and intuitive pin-drop interaction.
class PropertyLocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final String? title;

  const PropertyLocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.title,
  });

  @override
  State<PropertyLocationPickerScreen> createState() =>
      _PropertyLocationPickerScreenState();
}

class _PropertyLocationPickerScreenState
    extends State<PropertyLocationPickerScreen>
    with SingleTickerProviderStateMixin {
  static const String _gebetaStandardStyle =
      'https://tiles.gebeta.app/styles/standard/style.json';

  // Default to Addis Ababa (Bole area) if null
  late double _selectedLat;
  late double _selectedLng;
  String _resolvedAddress = '';
  bool _isResolvingAddress = false;
  bool _isLocatingUser = false;
  bool _isCameraMoving = false;

  GebetaMapController? _mapController;
  late AnimationController _pinAnimController;
  late Animation<double> _pinJumpAnimation;

  bool get _canUseNativeMap {
    if (DioConfig.isTestMode) return false;
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLatitude ?? 9.0209;
    _selectedLng = widget.initialLongitude ?? 38.7469;
    _resolvedAddress = widget.initialAddress ?? '';

    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _pinJumpAnimation = Tween<double>(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(
        parent: _pinAnimController,
        curve: Curves.easeOutQuad,
      ),
    );

    _initHeadersAndAddress();
  }

  Future<void> _initHeadersAndAddress() async {
    await GebetaLocationService.configureMapHeaders();
    if (_resolvedAddress.isEmpty) {
      _resolveAddress(_selectedLat, _selectedLng);
    }
  }

  @override
  void dispose() {
    _pinAnimController.dispose();
    super.dispose();
  }

  void _onMapCreated(GebetaMapController controller) {
    _mapController = controller;
  }

  Future<void> _onCameraIdle() async {
    if (!mounted) return;
    _pinAnimController.reverse();

    if (_mapController != null) {
      final pos = _mapController!.cameraPosition;
      if (pos != null) {
        final target = pos.target;
        setState(() {
          _selectedLat = target.latitude;
          _selectedLng = target.longitude;
          _isCameraMoving = false;
        });
        _resolveAddress(target.latitude, target.longitude);
      }
    } else {
      if (mounted) {
        setState(() => _isCameraMoving = false);
      }
    }
  }

  void _onMapClick(LatLng latLng) {
    setState(() {
      _selectedLat = latLng.latitude;
      _selectedLng = latLng.longitude;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(latLng),
    );

    _resolveAddress(latLng.latitude, latLng.longitude);
  }

  Future<void> _resolveAddress(double lat, double lng) async {
    setState(() => _isResolvingAddress = true);
    try {
      final address = await GebetaLocationService.reverseGeocode(lat, lng);
      if (mounted) {
        setState(() {
          _resolvedAddress = address;
          _isResolvingAddress = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isResolvingAddress = false);
      }
    }
  }

  Future<void> _handleLocateMe() async {
    setState(() => _isLocatingUser = true);
    try {
      final pos = await GebetaLocationService.getCurrentPosition(
        promptIfDeniedForever: true,
      );

      if (pos != null && mounted) {
        final latLng = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _selectedLat = pos.latitude;
          _selectedLng = pos.longitude;
        });

        if (_mapController != null && _canUseNativeMap) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: latLng,
                zoom: 16.5,
              ),
            ),
          );
        }

        await _resolveAddress(pos.latitude, pos.longitude);
      }
    } finally {
      if (mounted) {
        setState(() => _isLocatingUser = false);
      }
    }
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _confirmSelection() {
    final result = PropertyLocationResult(
      latitude: _selectedLat,
      longitude: _selectedLng,
      address: _resolvedAddress,
    );
    Get.back(result: result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Interactive Map Area
          Positioned.fill(
            child: _canUseNativeMap
                ? GebetaMap(
                    styleString: _gebetaStandardStyle,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_selectedLat, _selectedLng),
                      zoom: 16.0,
                    ),
                    onMapCreated: _onMapCreated,
                    onCameraIdle: _onCameraIdle,
                    onMapClick: (_, latLng) => _onMapClick(latLng),
                    trackCameraPosition: true,
                    compassEnabled: true,
                    rotateGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    doubleClickZoomEnabled: true,
                    tiltGesturesEnabled: false,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                  )
                : _buildFallbackCanvas(isDark),
          ),

          // 2. Center Animated Drop Pin
          Center(
            child: AnimatedBuilder(
              animation: _pinJumpAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _pinJumpAnimation.value - 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pin Head
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      // Pin Tip Needle
                      CustomPaint(
                        size: const Size(12, 10),
                        painter: _PinTipPainter(color: AppColors.primary),
                      ),
                      // Shadow on ground
                      const SizedBox(height: 2),
                      Container(
                        width: _isCameraMoving ? 6 : 14,
                        height: _isCameraMoving ? 3 : 5,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: _isCameraMoving ? 0.2 : 0.45,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 3. Top Floating App Bar Pill
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xEE1E1E1E) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Get.back(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title Pill
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xEE1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.title ?? 'Pin Store Location',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Map Control Buttons (Zoom & Locate Me)
          Positioned(
            right: 16,
            bottom: 240,
            child: Column(
              children: [
                // Locate Me Button
                FloatingActionButton.small(
                  heroTag: 'btn_locate_me_property',
                  backgroundColor: isDark ? const Color(0xEE2A2A2A) : Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 4,
                  onPressed: _isLocatingUser ? null : _handleLocateMe,
                  child: _isLocatingUser
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 10),
                // Zoom In
                if (_canUseNativeMap) ...[
                  FloatingActionButton.small(
                    heroTag: 'btn_zoom_in_property',
                    backgroundColor: isDark ? const Color(0xEE2A2A2A) : Colors.white,
                    foregroundColor: theme.colorScheme.onSurface,
                    elevation: 4,
                    onPressed: _zoomIn,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 6),
                  // Zoom Out
                  FloatingActionButton.small(
                    heroTag: 'btn_zoom_out_property',
                    backgroundColor: isDark ? const Color(0xEE2A2A2A) : Colors.white,
                    foregroundColor: theme.colorScheme.onSurface,
                    elevation: 4,
                    onPressed: _zoomOut,
                    child: const Icon(Icons.remove),
                  ),
                ],
              ],
            ),
          ),

          // 5. Bottom Sheet Confirmation Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag pill indicator
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Coordinates & Location Name Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Store Location',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              if (_isResolvingAddress)
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Resolving address...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  _resolvedAddress.isNotEmpty
                                      ? _resolvedAddress
                                      : 'Drag map to choose location',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Coordinates badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerLow
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.gps_fixed_rounded,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_selectedLat.toStringAsFixed(6)}, ${_selectedLng.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Confirm Button
                    AppButton(
                      text: 'Confirm Location',
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: _confirmSelection,
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

  /// Interactive Fallback View for Desktop/Web or Flutter Tests
  Widget _buildFallbackCanvas(bool isDark) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          // Adjust coordinate scale proportional to drag gestures
          _selectedLat -= details.delta.dy * 0.0001;
          _selectedLng += details.delta.dx * 0.0001;
        });
      },
      onTapUp: (details) {
        final size = MediaQuery.of(context).size;
        final dx = details.localPosition.dx - (size.width / 2);
        final dy = details.localPosition.dy - (size.height / 2);
        setState(() {
          _selectedLat -= dy * 0.0001;
          _selectedLng += dx * 0.0001;
        });
        _resolveAddress(_selectedLat, _selectedLng);
      },
      child: Container(
        color: isDark ? const Color(0xFF1B232A) : const Color(0xFFE8EEF5),
        child: Stack(
          children: [
            // Grid background pattern
            CustomPaint(
              size: Size.infinite,
              painter: _MapGridPainter(isDark: isDark),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 80),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xEE1E1E1E)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Tap or drag to reposition location pin',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTipPainter extends CustomPainter {
  final Color color;
  const _PinTipPainter({required this.color});

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

class _MapGridPainter extends CustomPainter {
  final bool isDark;
  const _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
