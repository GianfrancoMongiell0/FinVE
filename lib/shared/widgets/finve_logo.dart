// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import '../../core/providers/logo_provider.dart';

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
    final r = s * 0.22;

    // ── Fondo ────────────────────────────────────
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s),
      Radius.circular(r),
    );

    final bgColor = logoId == AppLogoId.v1
        ? Colors.white
        : Colors.white;

    canvas.drawRRect(rrect, Paint()..color = bgColor);

    // Borde sutil
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFFE0E0E0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Círculos ─────────────────────────────────
    const leftColor  = Color(0xFFEB001B);
    const rightColor = Color(0xFF0099DF);

    final hasWordmark = logoId == AppLogoId.v4;
    final cy = hasWordmark ? s * 0.46 : s * 0.50;
    final cr = s * 0.30;
    final lx = s * 0.36;
    final rx = s * 0.64;

    // Sombra detrás de los círculos
    canvas.drawCircle(
      Offset(lx, cy), cr,
      Paint()..color = const Color(0x22000000),
    );

    // Círculo derecho
    canvas.drawCircle(Offset(rx, cy), cr, Paint()..color = rightColor);

    // Círculo izquierdo
    canvas.drawCircle(Offset(lx, cy), cr, Paint()..color = leftColor);

    // Overlap real con clipPath
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(rx, cy), radius: cr));
    canvas.save();
    canvas.clipPath(path);
    canvas.drawCircle(Offset(lx, cy), cr, Paint()..color = rightColor);
    canvas.restore();

    // ── Wordmark (solo v4) ────────────────────────
    if (hasWordmark) {
      final dividerPaint = Paint()
        ..color = const Color(0xFFE0E0E0)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(s * 0.18, s * 0.73),
        Offset(s * 0.82, s * 0.73),
        dividerPaint,
      );

      final wordStyle = TextStyle(
        color: const Color(0xFF1A1A1A),
        fontSize: s * 0.09,
        fontWeight: FontWeight.w700,
        letterSpacing: s * 0.025,
        height: 1,
      );

      final tp = TextPainter(
        text: TextSpan(text: 'FINVE', style: wordStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(s * 0.5 - tp.width / 2, s * 0.865 - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.logoId != logoId || old.size != size;
}