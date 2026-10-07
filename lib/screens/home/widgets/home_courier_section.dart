import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/pages.dart';
import '../../../core/theme/app_colors.dart';

/// The "Thinking of sending anything?" section on the Home Screen.
/// Displays an illustrated courier banner that navigates to the Courier delivery screen.
class HomeCourierSection extends StatelessWidget {
  const HomeCourierSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 22.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'thinking_of_sending'.tr,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Courier Interactive Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => Get.toNamed(AppRoutes.courier),
                borderRadius: BorderRadius.circular(20),
                splashColor: AppColors.primary.withValues(alpha: 0.1),
                highlightColor: AppColors.primary.withValues(alpha: 0.05),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 260;
                    final graphicWidth = isCompact ? 80.0 : 115.0;
                    final graphicHeight = isCompact ? 68.0 : 88.0;

                    return Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 104),
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 12 : 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOutlineVariant
                              : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Illustrated Courier Graphic
                          SizedBox(
                            width: graphicWidth,
                            height: graphicHeight,
                            child: const CourierIllustration(),
                          ),

                          SizedBox(width: isCompact ? 10 : 16),

                          // Text Block: COURIER & subtext
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'courier'.tr,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: isCompact ? 19 : 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: isCompact ? 1.1 : 1.6,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'send_receive_courier'.tr,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkOnSurfaceVariant
                                        : AppColors.onSurfaceVariant,
                                    fontSize: isCompact ? 10.5 : 11.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A crisp, lightweight vector illustration of a running courier with package and location pin.
class CourierIllustration extends StatelessWidget {
  const CourierIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CourierPainter(),
    );
  }
}

class _CourierPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Pastel Cloud Background
    final bgPaint = Paint()
      ..color = AppColors.primaryContainer.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final bgPath = Path()
      ..moveTo(w * 0.15, h * 0.5)
      ..quadraticBezierTo(w * 0.2, h * 0.15, w * 0.5, h * 0.2)
      ..quadraticBezierTo(w * 0.85, h * 0.25, w * 0.85, h * 0.6)
      ..quadraticBezierTo(w * 0.8, h * 0.9, w * 0.45, h * 0.88)
      ..quadraticBezierTo(w * 0.1, h * 0.85, w * 0.15, h * 0.5)
      ..close();
    canvas.drawPath(bgPath, bgPaint);

    // 2. Ground shadow under runner and pin
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.48, h * 0.86), width: w * 0.7, height: 10),
      shadowPaint,
    );

    // 3. Motion wind streaks behind runner
    final streakPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(w * 0.04, h * 0.42), Offset(w * 0.20, h * 0.42), streakPaint);
    canvas.drawLine(Offset(w * 0.08, h * 0.54), Offset(w * 0.25, h * 0.54), streakPaint);
    canvas.drawLine(Offset(w * 0.02, h * 0.66), Offset(w * 0.18, h * 0.66), streakPaint);

    // 4. Back Leg (Trailing Leg in running motion)
    final darkClothPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;

    final backLegPath = Path()
      ..moveTo(w * 0.40, h * 0.56)
      ..lineTo(w * 0.26, h * 0.72)
      ..lineTo(w * 0.29, h * 0.75)
      ..lineTo(w * 0.43, h * 0.60)
      ..close();
    canvas.drawPath(backLegPath, darkClothPaint);

    // Back Shoe
    final shoePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    final backShoe = Path()
      ..moveTo(w * 0.26, h * 0.72)
      ..lineTo(w * 0.21, h * 0.76)
      ..quadraticBezierTo(w * 0.20, h * 0.80, w * 0.24, h * 0.80)
      ..lineTo(w * 0.30, h * 0.76)
      ..close();
    canvas.drawPath(backShoe, shoePaint);

    // 5. Front Leg (Bent forward at knee in dynamic stride)
    final frontLegPath = Path()
      ..moveTo(w * 0.42, h * 0.56)
      ..lineTo(w * 0.52, h * 0.68)
      ..lineTo(w * 0.49, h * 0.80)
      ..lineTo(w * 0.44, h * 0.80)
      ..lineTo(w * 0.47, h * 0.67)
      ..lineTo(w * 0.38, h * 0.57)
      ..close();
    canvas.drawPath(frontLegPath, darkClothPaint);

    // Front Shoe
    final frontShoe = Path()
      ..moveTo(w * 0.44, h * 0.80)
      ..lineTo(w * 0.52, h * 0.80)
      ..quadraticBezierTo(w * 0.54, h * 0.83, w * 0.50, h * 0.84)
      ..lineTo(w * 0.42, h * 0.84)
      ..close();
    canvas.drawPath(frontShoe, shoePaint);

    // 6. Torso / Shirt (AppColors.primary Blue) leaning forward
    final shirtPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final torsoPath = Path()
      ..moveTo(w * 0.38, h * 0.35)
      ..lineTo(w * 0.48, h * 0.38)
      ..lineTo(w * 0.44, h * 0.58)
      ..lineTo(w * 0.37, h * 0.56)
      ..close();
    canvas.drawPath(torsoPath, shirtPaint);

    // 7. Head and Cap
    final skinPaint = Paint()
      ..color = const Color(0xFFF6C39D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.44, h * 0.28), 7, skinPaint);

    // Cap (Primary Blue)
    final capPath = Path()
      ..moveTo(w * 0.38, h * 0.27)
      ..quadraticBezierTo(w * 0.44, h * 0.18, w * 0.49, h * 0.25)
      ..lineTo(w * 0.55, h * 0.26) // Visor
      ..lineTo(w * 0.48, h * 0.28)
      ..close();
    canvas.drawPath(capPath, shirtPaint);

    // 8. Delivery Package / Parcel Box (Warm Cardboard Brown with tape)
    final boxPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;
    final boxRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.48, h * 0.38, 22, 18),
      const Radius.circular(3),
    );
    canvas.drawRRect(boxRRect, boxPaint);

    // Box tape
    final tapePaint = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.59, h * 0.38), Offset(w * 0.59, h * 0.56), tapePaint);

    // 9. Arms holding the box
    final armPath = Path()
      ..moveTo(w * 0.42, h * 0.40)
      ..lineTo(w * 0.51, h * 0.46)
      ..lineTo(w * 0.50, h * 0.50)
      ..lineTo(w * 0.40, h * 0.43)
      ..close();
    canvas.drawPath(armPath, shirtPaint);
    canvas.drawCircle(Offset(w * 0.51, h * 0.47), 3, skinPaint); // Hand

    // 10. Modern 3D Location Pin Marker in front
    final pinX = w * 0.78;
    final pinY = h * 0.60;

    // Pin shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pinX, pinY + 16), width: 14, height: 6),
      shadowPaint,
    );

    // Pin body (Soft white/light container with AppColors.primary accent)
    final pinPath = Path();
    pinPath.moveTo(pinX, pinY + 14);
    pinPath.cubicTo(
      pinX - 10, pinY + 4,
      pinX - 11, pinY - 8,
      pinX, pinY - 8,
    );
    pinPath.cubicTo(
      pinX + 11, pinY - 8,
      pinX + 10, pinY + 4,
      pinX, pinY + 14,
    );
    pinPath.close();

    final pinBodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, pinBodyPaint);

    final pinBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(pinPath, pinBorderPaint);

    // Pin center dot (AppColors.primary)
    final pinDotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(pinX, pinY - 1), 3.5, pinDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
