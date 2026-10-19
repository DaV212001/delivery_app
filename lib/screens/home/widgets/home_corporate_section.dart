import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/pages.dart';
import '../../../controllers/corporate_controller.dart';
import '../../../core/theme/app_colors.dart';

/// The "Corporate Service" section on the Home Screen.
/// Displayed under the courier service card for eligible corporate users.
class HomeCorporateSection extends StatelessWidget {
  const HomeCorporateSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final corp = Get.isRegistered<CorporateController>()
        ? Get.find<CorporateController>()
        : Get.put(CorporateController());

    return Padding(
      padding: const EdgeInsets.only(top: 14.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'corporate_service'.tr.isNotEmpty
                        ? 'corporate_service'.tr
                        : 'Corporate Service',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'BUSINESS',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Corporate Interactive Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => Get.toNamed(AppRoutes.corporateDashboard),
                borderRadius: BorderRadius.circular(20),
                splashColor: AppColors.primary.withValues(alpha: 0.1),
                highlightColor: AppColors.primary.withValues(alpha: 0.05),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 280;
                    final graphicWidth = isCompact ? 72.0 : 88.0;
                    final graphicHeight = isCompact ? 64.0 : 78.0;

                    return Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 114),
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 14 : 18,
                        vertical: isCompact ? 12 : 16,
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
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.3 : 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Illustrated Corporate Office Graphic
                          SizedBox(
                            width: graphicWidth,
                            height: graphicHeight,
                            child: const CorporateIllustration(),
                          ),

                          SizedBox(width: isCompact ? 12 : 16),

                          // Text Block: Company info & Subtitle
                          Expanded(
                            child: Obx(() {
                              final companyName =
                                  corp.company.value?.name.trim();
                              final hasCompany = companyName != null &&
                                  companyName.isNotEmpty;
                              final branch = corp.senderBranch?.branchName ??
                                  corp.branches.firstOrNull?.branchName ??
                                  '';
                              final subtext = branch.isNotEmpty
                                  ? '$branch • Inter-branch dispatch'
                                  : 'Inter-branch business package dispatch';

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'CORPORATE DELIVERY',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: isCompact ? 14 : 15.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: isCompact ? 0.6 : 0.8,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (hasCompany) ...[
                                    Text(
                                      companyName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: isCompact ? 12.5 : 13.5,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    subtext,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkOnSurfaceVariant
                                          : AppColors.onSurfaceVariant,
                                      fontSize: isCompact ? 10.5 : 11.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),

                          const SizedBox(width: 8),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: isDark ? 0.08 : 0.04),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: isDark
                                  ? AppColors.darkOnSurfaceVariant
                                  : const Color(0xFF64748B),
                              size: 18,
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

/// A crisp vector illustration representing corporate headquarters, documents, and business logistics.
class CorporateIllustration extends StatelessWidget {
  const CorporateIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CorporatePainter(),
    );
  }
}

class _CorporatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Pastel Glow Background
    final bgPaint = Paint()
      ..color = AppColors.primaryContainer.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final bgPath = Path()
      ..moveTo(w * 0.15, h * 0.45)
      ..quadraticBezierTo(w * 0.2, h * 0.12, w * 0.5, h * 0.18)
      ..quadraticBezierTo(w * 0.88, h * 0.22, w * 0.86, h * 0.65)
      ..quadraticBezierTo(w * 0.8, h * 0.92, w * 0.45, h * 0.88)
      ..quadraticBezierTo(w * 0.1, h * 0.82, w * 0.15, h * 0.45)
      ..close();
    canvas.drawPath(bgPath, bgPaint);

    // 2. Base Ground Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.86),
        width: w * 0.75,
        height: 10,
      ),
      shadowPaint,
    );

    // 3. Tall Corporate Tower Building (Dark Slate Blue)
    final bldg1Paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final bldg1RRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.24, w * 0.30, h * 0.60),
      const Radius.circular(5),
    );
    canvas.drawRRect(bldg1RRect, bldg1Paint);

    // Windows on Tower 1
    final winPaint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    for (double row = 0; row < 4; row++) {
      for (double col = 0; col < 2; col++) {
        final wx = w * 0.26 + col * (w * 0.12);
        final wy = h * 0.30 + row * (h * 0.10);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(wx, wy, w * 0.08, h * 0.06),
            const Radius.circular(1.5),
          ),
          winPaint,
        );
      }
    }

    // 4. Secondary Corporate Office (AppColors.primary)
    final bldg2Paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final bldg2RRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.46, h * 0.38, w * 0.32, h * 0.46),
      const Radius.circular(5),
    );
    canvas.drawRRect(bldg2RRect, bldg2Paint);

    // Windows on Tower 2
    final win2Paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    for (double row = 0; row < 3; row++) {
      for (double col = 0; col < 2; col++) {
        final wx = w * 0.51 + col * (w * 0.12);
        final wy = h * 0.44 + row * (h * 0.10);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(wx, wy, w * 0.08, h * 0.06),
            const Radius.circular(1.5),
          ),
          win2Paint,
        );
      }
    }

    // 5. Executive Briefcase / Dispatch Icon in Foreground
    final casePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;
    final caseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.65, h * 0.62, w * 0.24, h * 0.20),
      const Radius.circular(3),
    );
    canvas.drawRRect(caseRect, casePaint);

    // Briefcase handle
    final handlePaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final handlePath = Path()
      ..moveTo(w * 0.72, h * 0.62)
      ..lineTo(w * 0.72, h * 0.56)
      ..lineTo(w * 0.82, h * 0.56)
      ..lineTo(w * 0.82, h * 0.62);
    canvas.drawPath(handlePath, handlePaint);

    // Briefcase lock/strap accent
    final lockPaint = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.75, h * 0.70, w * 0.04, h * 0.04),
      lockPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
