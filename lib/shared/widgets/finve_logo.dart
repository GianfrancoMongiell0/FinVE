import 'package:flutter/material.dart';
import '../../core/providers/logo_provider.dart';

/// Renders the FinVe logo for the given [logoId].
/// [size] is the width/height of the square icon.
class FinveLogo extends StatelessWidget {
  const FinveLogo({
    super.key,
    required this.logoId,
    this.size = 80,
  });

  final AppLogoId logoId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(logoId: logoId, size: size),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.logoId, required this.size});

  final AppLogoId logoId;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final s = size;
    final r = s * 0.25; // corner radius

    // ── Background ──────────────────────────────
    final bgPaint = Paint()..style = PaintingStyle.fill;
    Color bgColor;
    Color? borderColor;

    switch (logoId) {
      case AppLogoId.v1:
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFE2E8F0);
      case AppLogoId.v4:
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFE2E8F0);
      case AppLogoId.v6:
        bgColor = const Color(0xFF1E3A5F);
      case AppLogoId.v7:
        bgColor = const Color(0xFF0C1445);
      case AppLogoId.v8:
        bgColor = const Color(0xFFFEF9F0);
        borderColor = const Color(0xFFFED7AA);
    }

    bgPaint.color = bgColor;
    final rrect =
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s, s), Radius.circular(r));
    canvas.drawRRect(rrect, bgPaint);

    if (borderColor != null) {
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = borderColor;
      canvas.drawRRect(rrect, borderPaint);
    }

    // ── Circle colors ────────────────────────────
    Color leftColor;
    Color rightColor;

    switch (logoId) {
      case AppLogoId.v1:
        leftColor = const Color(0xFFDC2626);
        rightColor = const Color(0xFF2563EB);
      case AppLogoId.v4:
        leftColor = const Color(0xFFDC2626);
        rightColor = const Color(0xFF2563EB);
      case AppLogoId.v6:
        leftColor = const Color(0xFFDC2626);
        rightColor = const Color(0xFFF59E0B);
      case AppLogoId.v7:
        leftColor = const Color(0xFFE11D48);
        rightColor = const Color(0xFFF59E0B);
      case AppLogoId.v8:
        leftColor = const Color(0xFFE11D48);
        rightColor = const Color(0xFFF59E0B);
    }

    final bool hasWordmark = logoId == AppLogoId.v4 || logoId == AppLogoId.v7;
    final cy = hasWordmark ? s * 0.46 : s * 0.5;
    final cr = s * 0.23; // circle radius
    final lx = s * 0.365;
    final rx = s * 0.635;

    // Right circle
    canvas.drawCircle(
      Offset(rx, cy),
      cr,
      Paint()
        ..color = rightColor
        ..style = PaintingStyle.fill,
    );

    // Left circle (full)
    canvas.drawCircle(
      Offset(lx, cy),
      cr,
      Paint()
        ..color = leftColor
        ..style = PaintingStyle.fill,
    );

    // Left circle overlay (blend effect)
    canvas.drawCircle(
      Offset(lx, cy),
      cr,
      Paint()
        ..color = leftColor.withOpacity(0.36)
        ..style = PaintingStyle.fill,
    );

    // ── Letters ──────────────────────────────────
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: s * 0.2,
      fontWeight: FontWeight.w900,
      height: 1,
    );

    _drawText(canvas, 'B', Offset(lx, cy), textStyle);
    _drawText(canvas, '\$', Offset(rx, cy), textStyle);

    // ── Wordmark (V4 and V7) ─────────────────────
    if (hasWordmark) {
      final dividerY = s * 0.73;
      final dividerPaint = Paint()
        ..color = (logoId == AppLogoId.v7)
            ? Colors.white.withOpacity(0.18)
            : const Color(0xFF94A3B8)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(s * 0.18, dividerY),
        Offset(s * 0.82, dividerY),
        dividerPaint,
      );

      final wordStyle = TextStyle(
        color: (logoId == AppLogoId.v7)
            ? Colors.white.withOpacity(0.75)
            : const Color(0xFF334155),
        fontSize: s * 0.09,
        fontWeight: FontWeight.w700,
        letterSpacing: s * 0.025,
        height: 1,
      );
      _drawText(canvas, 'FINVE', Offset(s * 0.5, s * 0.865), wordStyle);
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.logoId != logoId || old.size != size;
}