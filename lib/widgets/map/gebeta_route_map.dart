import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';

import '../../config/dio_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/gebeta_route.dart';
import '../../models/order.dart';
import '../../services/gebeta_location_service.dart';

/// Interactive Map Widget powered by Gebeta Maps.
/// Displays the real road route between restaurant/store and delivery destination,
/// with courier live position, interactive gestures, and beautiful route styling.
class GebetaRouteMap extends StatefulWidget {
  final OrderModel order;
  final double? height;
  final bool allowExpand;
  final double? liveDriverLatitude;
  final double? liveDriverLongitude;
  final double? liveDriverHeading;
  final bool isLiveDriverOnline;
  final EdgeInsets contentPadding;

  const GebetaRouteMap({
    super.key,
    required this.order,
    this.height,
    this.allowExpand = false,
    this.liveDriverLatitude,
    this.liveDriverLongitude,
    this.liveDriverHeading,
    this.isLiveDriverOnline = false,
    this.contentPadding = EdgeInsets.zero,
  });

  @override
  State<GebetaRouteMap> createState() => _GebetaRouteMapState();
}

class _GebetaRouteMapState extends State<GebetaRouteMap> with SingleTickerProviderStateMixin {
  GebetaRoute? _route;
  bool _isLoading = true;
  GebetaMapController? _mapController;
  Circle? _driverCircle;
  late AnimationController _pulseController;
  Circle? _userLocationCircle;
  LatLng? _userLocation;
  bool _isLocatingUser = false;
  bool _showingUserLocation = false;


  bool get _canUseNativeMap {
    if (DioConfig.isTestMode) return false;
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Official standard Gebeta Maps style JSON
  static const String gebetaStandardStyle =
      'https://tiles.gebeta.app/styles/standard/style.json';

  double get _progressFraction {
    switch (widget.order.status) {
      case OrderProgressStatus.preparing:
        return 0.0;
      case OrderProgressStatus.pickedUp:
        return 0.10;
      case OrderProgressStatus.onTheWay:
        return 0.65;
      case OrderProgressStatus.delivered:
        return 1.0;
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _configureGebetaHeaders();
    _loadRoute();
  }

  Future<void> _configureGebetaHeaders() async {
    if (!_canUseNativeMap) return;
    try {
      await setHttpHeaders({
        'Origin': 'https://gebeta.app',
        'Authorization': 'Bearer ${GebetaLocationService.apiKey}',
      });
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant GebetaRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.orderId != widget.order.orderId ||
        oldWidget.order.status != widget.order.status) {
      _loadRoute();
    } else if (widget.liveDriverLatitude != oldWidget.liveDriverLatitude ||
        widget.liveDriverLongitude != oldWidget.liveDriverLongitude) {
      _updateDriverPosition();
    }
  }

  void _updateDriverPosition() {
    if (_mapController == null || _driverCircle == null) return;
    if (widget.liveDriverLatitude != null && widget.liveDriverLongitude != null) {
      try {
        _mapController!.updateCircle(
          _driverCircle!,
          CircleOptions(
            geometry: LatLng(widget.liveDriverLatitude!, widget.liveDriverLongitude!),
            circleColor: widget.isLiveDriverOnline ? '#2E7D32' : '#1976D2',
          ),
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    setState(() => _isLoading = true);
    try {
      final route = await GebetaLocationService.getRoute(
        originLat: widget.order.effectiveStoreLatitude,
        originLng: widget.order.effectiveStoreLongitude,
        destLat: widget.order.effectiveDeliveryLatitude,
        destLng: widget.order.effectiveDeliveryLongitude,
      );
      if (mounted) {
        setState(() {
          _route = route;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _route = GebetaRoute.generateFallbackRoute(
            originLat: widget.order.effectiveStoreLatitude,
            originLng: widget.order.effectiveStoreLongitude,
            destLat: widget.order.effectiveDeliveryLatitude,
            destLng: widget.order.effectiveDeliveryLongitude,
          );
          _isLoading = false;
        });
      }
    }
  }

  void _onMapCreated(GebetaMapController controller) {
    _mapController = controller;
    _configureGebetaHeaders();
  }

  Future<void> _onStyleLoaded() async {
    if (_mapController == null || _route == null) return;
    try {
      // Draw road route line
      await _mapController!.addLine(
        LineOptions(
          geometry: _route!.points,
          lineColor: '#FF5722',
          lineWidth: 5.0,
          lineOpacity: 0.95,
          lineJoin: 'round',
        ),
      );

      // Origin (Store) Marker
      await _mapController!.addCircle(
        CircleOptions(
          geometry: _route!.points.first,
          circleColor: '#FF5722',
          circleRadius: 8.0,
          circleStrokeWidth: 3.0,
          circleStrokeColor: '#FFFFFF',
        ),
      );

      // Destination (User delivery address) Marker
      await _mapController!.addCircle(
        CircleOptions(
          geometry: _route!.points.last,
          circleColor: '#2E7D32',
          circleRadius: 8.0,
          circleStrokeWidth: 3.0,
          circleStrokeColor: '#FFFFFF',
        ),
      );

      // Driver position along route or live GPS coordinates (only when picked up or on the way)
      if (widget.order.status != OrderProgressStatus.preparing || widget.liveDriverLatitude != null) {
        final LatLng driverPos = (widget.liveDriverLatitude != null && widget.liveDriverLongitude != null)
            ? LatLng(widget.liveDriverLatitude!, widget.liveDriverLongitude!)
            : _route!.positionAtProgress(_progressFraction);

        _driverCircle = await _mapController!.addCircle(
          CircleOptions(
            geometry: driverPos,
            circleColor: widget.isLiveDriverOnline ? '#2E7D32' : '#1976D2',
            circleRadius: 9.0,
            circleStrokeWidth: 3.5,
            circleStrokeColor: '#FFFFFF',
          ),
        );
      }

      _recenterMap();
    } catch (_) {}
  }

  void _recenterMap() {
    if (_mapController == null || _route == null) return;
    try {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          _route!.bounds,
          left: 48 + widget.contentPadding.left,
          right: 48 + widget.contentPadding.right,
          top: 48 + widget.contentPadding.top,
          bottom: 48 + widget.contentPadding.bottom,
        ),
      );
    } catch (_) {}
  }

  Future<void> _handleLocationButtonPress() async {
    // If currently centered on user location, toggle back to route overview
    if (_showingUserLocation && _route != null) {
      _recenterMap();
      if (mounted) {
        setState(() => _showingUserLocation = false);
      }
      return;
    }

    setState(() => _isLocatingUser = true);
    try {
      // Actively prompt the user (triggers native OS / Play Services prompt if disabled)
      final pos = await GebetaLocationService.getCurrentPosition(
        promptIfDeniedForever: true,
      );

      if (pos != null && mounted) {
        final userLatLng = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _userLocation = userLatLng;
          _showingUserLocation = true;
        });

        if (_mapController != null && _canUseNativeMap) {
          // Center camera on user's location
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: userLatLng,
                zoom: 15.5,
              ),
            ),
          );

          // Add or update blue user location pin
          if (_userLocationCircle != null) {
            await _mapController!.updateCircle(
              _userLocationCircle!,
              CircleOptions(geometry: userLatLng),
            );
          } else {
            _userLocationCircle = await _mapController!.addCircle(
              CircleOptions(
                geometry: userLatLng,
                circleColor: '#2196F3',
                circleRadius: 8.5,
                circleStrokeWidth: 3.0,
                circleStrokeColor: '#FFFFFF',
              ),
            );
          }
        }
      } else {
        // If unable to get user location, re-center route
        _recenterMap();
      }
    } catch (_) {
      _recenterMap();
    } finally {
      if (mounted) {
        setState(() => _isLocatingUser = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mapContent = Stack(
      children: [
        // 1. Base Map View (Native GebetaMap with Gebeta Vector Tiles or Interactive Canvas View)
        Positioned.fill(
          child: _canUseNativeMap && _route != null
              ? GebetaMap(
                  styleString: gebetaStandardStyle,
                  initialCameraPosition: CameraPosition(
                    target: _route!.center,
                    zoom: 13.2,
                  ),
                  onMapCreated: _onMapCreated,
                  onStyleLoadedCallback: _onStyleLoaded,
                  compassEnabled: true,
                  rotateGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  doubleClickZoomEnabled: true,
                  tiltGesturesEnabled: true,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                )
              : InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: _GebetaRouteCanvasView(
                    route: _route,
                    order: widget.order,
                    progress: _progressFraction,
                    pulseAnimation: _pulseController,
                    isDark: isDark,
                    liveDriverLatitude: widget.liveDriverLatitude,
                    liveDriverLongitude: widget.liveDriverLongitude,
                    isLiveDriverOnline: widget.isLiveDriverOnline,
                    userLocation: _userLocation,
                  ),
                ),
        ),

        // 2. Loading State Overlay
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.65),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

        // 3. Top Info: LIVE GPS Status & Route Stats (Without Gebeta Maps brand pill)
        Positioned(
          top: widget.contentPadding.top > 0 ? widget.contentPadding.top : 14,
          left: 14 + widget.contentPadding.left,
          right: 14 + widget.contentPadding.right,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Live GPS Badge
              if (widget.isLiveDriverOnline)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sensors_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'LIVE GPS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),

              // Distance & Duration chip
              if (_route != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.two_wheeler_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            '${_route!.formattedDistance} • ${_route!.formattedDuration}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 4. Floating Action Control: Re-center map (Without fullscreen button)
        Positioned(
          top: (widget.contentPadding.top > 0 ? widget.contentPadding.top : 14) + 42,
          right: 14 + widget.contentPadding.right,
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xDD1E1E1E) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 22,
              icon: _isLocatingUser
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      _showingUserLocation ? Icons.alt_route_rounded : Icons.my_location_rounded,
                      color: AppColors.primary,
                    ),
              onPressed: _handleLocationButtonPress,
            ),
          ),
        ),
      ],
    );

    if (widget.height != null) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: mapContent,
      );
    }

    return SizedBox.expand(child: mapContent);
  }
}

/// Fallback / Responsive vector map canvas rendering the Gebeta road route,
/// origin/store pin, destination pin, and moving delivery scooter pin.
class _GebetaRouteCanvasView extends StatelessWidget {
  final GebetaRoute? route;
  final OrderModel order;
  final double progress;
  final Animation<double> pulseAnimation;
  final bool isDark;
  final double? liveDriverLatitude;
  final double? liveDriverLongitude;
  final bool isLiveDriverOnline;
  final LatLng? userLocation;

  const _GebetaRouteCanvasView({
    required this.route,
    required this.order,
    required this.progress,
    required this.pulseAnimation,
    required this.isDark,
    this.liveDriverLatitude,
    this.liveDriverLongitude,
    this.isLiveDriverOnline = false,
    this.userLocation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return ClipRect(
          child: CustomPaint(
            size: Size.infinite,
            painter: _GebetaRoutePainter(
              route: route,
              order: order,
              progress: progress,
              pulseValue: pulseAnimation.value,
              isDark: isDark,
              liveDriverLatitude: liveDriverLatitude,
              liveDriverLongitude: liveDriverLongitude,
              isLiveDriverOnline: isLiveDriverOnline,
              userLocation: userLocation,
            ),
          ),
        );
      },
    );
  }
}

class _GebetaRoutePainter extends CustomPainter {
  final GebetaRoute? route;
  final OrderModel order;
  final double progress;
  final double pulseValue;
  final bool isDark;
  final double? liveDriverLatitude;
  final double? liveDriverLongitude;
  final bool isLiveDriverOnline;
  final LatLng? userLocation;

  _GebetaRoutePainter({
    required this.route,
    required this.order,
    required this.progress,
    required this.pulseValue,
    required this.isDark,
    this.liveDriverLatitude,
    this.liveDriverLongitude,
    this.isLiveDriverOnline = false,
    this.userLocation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Stylized Map Background
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E222A) : const Color(0xFFF3F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Subtle background street grid simulation
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.035)
      ..strokeWidth = 1.0;

    const spacing = 36.0;
    for (double x = 0; x < w; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Secondary road diagonal lines
    final secondaryRoadPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)
      ..strokeWidth = 4.0;
    canvas.drawLine(Offset(0, h * 0.7), Offset(w, h * 0.2), secondaryRoadPaint);
    canvas.drawLine(Offset(0, h * 0.35), Offset(w, h * 0.85), secondaryRoadPaint);

    final effectiveRoute = route ??
        GebetaRoute.generateFallbackRoute(
          originLat: order.effectiveStoreLatitude,
          originLng: order.effectiveStoreLongitude,
          destLat: order.effectiveDeliveryLatitude,
          destLng: order.effectiveDeliveryLongitude,
        );

    final points = effectiveRoute.points;
    if (points.isEmpty) return;

    // Determine driver coordinate: live GPS if available, else route progress position
    final LatLng driverCoord;
    if (liveDriverLatitude != null && liveDriverLongitude != null) {
      driverCoord = LatLng(liveDriverLatitude!, liveDriverLongitude!);
    } else if (order.driverLatitude != null && order.driverLongitude != null) {
      driverCoord = LatLng(order.driverLatitude!, order.driverLongitude!);
    } else {
      driverCoord = effectiveRoute.positionAtProgress(progress);
    }

    // 2. Coordinate Transformation to Canvas Rect (with padding)
    final bounds = effectiveRoute.bounds;
    final minLat = math.min(
      math.min(bounds.southwest.latitude, driverCoord.latitude),
      userLocation?.latitude ?? bounds.southwest.latitude,
    );
    final maxLat = math.max(
      math.max(bounds.northeast.latitude, driverCoord.latitude),
      userLocation?.latitude ?? bounds.northeast.latitude,
    );
    final minLng = math.min(
      math.min(bounds.southwest.longitude, driverCoord.longitude),
      userLocation?.longitude ?? bounds.southwest.longitude,
    );
    final maxLng = math.max(
      math.max(bounds.northeast.longitude, driverCoord.longitude),
      userLocation?.longitude ?? bounds.northeast.longitude,
    );

    const padX = 54.0;
    const padY = 54.0;
    final drawW = math.max(w - padX * 2, 20.0);
    final drawH = math.max(h - padY * 2, 20.0);

    Offset toCanvas(LatLng ll) {
      final normX = (maxLng - minLng) > 0 ? (ll.longitude - minLng) / (maxLng - minLng) : 0.5;
      final normY = (maxLat - minLat) > 0 ? (maxLat - ll.latitude) / (maxLat - minLat) : 0.5;
      return Offset(padX + normX * drawW, padY + normY * drawH);
    }

    // 3. Draw Route Path (Drop Shadow + Outline + Main Line)
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final pt = toCanvas(points[i]);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }

    // Shadow
    final shadowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawPath(path, shadowPaint);

    // Border casing
    final casingPaint = Paint()
      ..color = isDark ? const Color(0xFF121212) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, casingPaint);

    // Primary route line
    final routePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, routePaint);

    // 4. Origin (Store) Pin
    final originPt = toCanvas(points.first);
    _drawMarkerPin(
      canvas: canvas,
      position: originPt,
      color: AppColors.primary,
      icon: Icons.storefront_rounded,
      label: order.restaurantName,
      isDark: isDark,
    );

    // 5. Destination (Delivery Address) Pin
    final destPt = toCanvas(points.last);
    _drawMarkerPin(
      canvas: canvas,
      position: destPt,
      color: const Color(0xFF2E7D32),
      icon: Icons.home_rounded,
      label: order.deliveryAddress,
      isDark: isDark,
    );

    // 6. Courier Scooter Pin with Pulse Effect (Only if order is picked up/on the way, or live driver available)
    if (order.status != OrderProgressStatus.preparing || liveDriverLatitude != null) {
      final driverPt = toCanvas(driverCoord);
      final markerColor = isLiveDriverOnline ? const Color(0xFF2E7D32) : const Color(0xFF1976D2);

      // Radar pulse wave
      final wavePaint = Paint()
        ..color = (isLiveDriverOnline ? const Color(0xFF2E7D32) : AppColors.primary)
            .withValues(alpha: (1.0 - pulseValue) * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(driverPt, 12.0 + pulseValue * 18.0, wavePaint);

      // Scooter badge
      final driverBgPaint = Paint()..color = markerColor;
      final driverBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawCircle(driverPt, 14.0, driverBgPaint);
      canvas.drawCircle(driverPt, 14.0, driverBorderPaint);

      // Draw scooter icon
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.two_wheeler_rounded.codePoint),
          style: TextStyle(
            fontSize: 16.0,
            fontFamily: Icons.two_wheeler_rounded.fontFamily,
            package: Icons.two_wheeler_rounded.fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(driverPt.dx - textPainter.width / 2, driverPt.dy - textPainter.height / 2),
      );

      // Pin Callout Label for Live Driver
      if (isLiveDriverOnline) {
        final labelSpan = const TextSpan(
          text: 'LIVE',
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        );
        final labelPainter = TextPainter(
          text: labelSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final bubbleRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(driverPt.dx, driverPt.dy + 19),
            width: labelPainter.width + 8,
            height: labelPainter.height + 3,
          ),
          const Radius.circular(4),
        );

        final bubblePaint = Paint()..color = const Color(0xFF2E7D32);
        canvas.drawRRect(bubbleRect, bubblePaint);
        labelPainter.paint(
          canvas,
          Offset(driverPt.dx - labelPainter.width / 2, driverPt.dy + 19 - labelPainter.height / 2),
        );
      }
    }

    // 7. User Location Pin (when user taps location button)
    if (userLocation != null) {
      final userPt = toCanvas(userLocation!);
      final userWavePaint = Paint()
        ..color = const Color(0xFF2196F3).withValues(alpha: (1.0 - pulseValue) * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(userPt, 8.0 + pulseValue * 12.0, userWavePaint);

      final userBgPaint = Paint()..color = const Color(0xFF2196F3);
      final userBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(userPt, 8.0, userBgPaint);
      canvas.drawCircle(userPt, 8.0, userBorderPaint);
    }
  }

  void _drawMarkerPin({
    required Canvas canvas,
    required Offset position,
    required Color color,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    // Circle base
    final fillPaint = Paint()..color = color;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(position, 12.0, fillPaint);
    canvas.drawCircle(position, 12.0, strokePaint);

    // Icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 14.0,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(position.dx - iconPainter.width / 2, position.dy - iconPainter.height / 2),
    );

    // Pin Callout Label
    final cleanLabel = label.split(',').first.trim();
    if (cleanLabel.isNotEmpty) {
      final labelSpan = TextSpan(
        text: cleanLabel.length > 18 ? '${cleanLabel.substring(0, 16)}...' : cleanLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(position.dx, position.dy + 20),
          width: labelPainter.width + 10,
          height: labelPainter.height + 4,
        ),
        const Radius.circular(6),
      );

      final bubblePaint = Paint()
        ..color = isDark ? const Color(0xEE2A2A2A) : const Color(0xEEFFFFFF);
      canvas.drawRRect(bubbleRect, bubblePaint);
      labelPainter.paint(
        canvas,
        Offset(position.dx - labelPainter.width / 2, position.dy + 20 - labelPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GebetaRoutePainter oldDelegate) => true;
}
