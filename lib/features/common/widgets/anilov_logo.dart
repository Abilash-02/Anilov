import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Reusable Anilov logo widget displaying the stylized play icon,
/// the wordmark "Anilov", and an optional tagline.
class AnilovLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool showTagline;
  final double? fontSize;
  final Color? textColor;
  final Axis direction;
  final CrossAxisAlignment crossAxisAlignment;

  const AnilovLogo({
    super.key,
    this.size = 36.0,
    this.showWordmark = true,
    this.showTagline = false,
    this.fontSize,
    this.textColor,
    this.direction = Axis.horizontal,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveTextColor = textColor ??
        (isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface);

    final iconWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.deepIndigo,
            AppTheme.violet,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violet.withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _AnilovIconPainter(),
      ),
    );

    if (!showWordmark) {
      return iconWidget;
    }

    final double effectiveFontSize = fontSize ?? (size * 0.6).clamp(16.0, 36.0);

    final textColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: direction == Axis.vertical
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Anilov',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: effectiveFontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: effectiveTextColor,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: effectiveFontSize * 0.25,
              height: effectiveFontSize * 0.25,
              decoration: const BoxDecoration(
                color: AppTheme.violetLight,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Discover anime. Track every episode.',
            textAlign: direction == Axis.vertical ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: (effectiveFontSize * 0.42).clamp(11.0, 15.0),
              fontWeight: FontWeight.w400,
              color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
            ),
          ),
        ],
      ],
    );

    if (direction == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconWidget,
          SizedBox(height: size * 0.3),
          textColumn,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        iconWidget,
        SizedBox(width: size * 0.32),
        textColumn,
      ],
    );
  }
}

class _AnilovIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Play triangle centered in the icon
    // (w * 0.41, h * 0.36) to (w * 0.65, h * 0.50) to (w * 0.41, h * 0.64)
    final triangle = Path();
    triangle.moveTo(w * 0.41, h * 0.36);
    triangle.lineTo(w * 0.65, h * 0.50);
    triangle.lineTo(w * 0.41, h * 0.64);
    triangle.close();
    canvas.drawPath(triangle, whitePaint);

    // Sparkle (4-point star) near the upper-right corner of triangle
    final sparkleCenter = Offset(w * 0.65, h * 0.37);
    final outerR = w * 0.08;
    final innerR = w * 0.022;

    final sparkle = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * (math.pi / 4.0) - (math.pi / 2.0);
      final r = (i % 2 == 0) ? outerR : innerR;
      final px = sparkleCenter.dx + r * math.cos(angle);
      final py = sparkleCenter.dy + r * math.sin(angle);
      if (i == 0) {
        sparkle.moveTo(px, py);
      } else {
        sparkle.lineTo(px, py);
      }
    }
    sparkle.close();
    canvas.drawPath(sparkle, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
