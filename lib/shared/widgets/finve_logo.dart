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

    // ── Background ────────────────────────────────
    const bgColor = Color(0xFF1A1A1A);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s),
      Radius.circular(r),
    );
    canvas.drawRRect(rrect, Paint()..color = bgColor);

    // ── Circles ───────────────────────────────────
    const leftColor = Color(0xFFEB001B); // rojo
    const rightColor = Color(0xFF0099DF); // azul

    final cy = s * 0.50;
    final cr = s * 0.30;
    final lx = s * 0.36;
    final rx = s * 0.64;

    // Círculo derecho
    canvas.drawCircle(
      Offset(rx, cy),
      cr,
      Paint()..color = rightColor,
    );

    // Círculo izquierdo — encima, sin blend
    canvas.drawCircle(
      Offset(lx, cy),
      cr,
      Paint()..color = leftColor,
    );

    // ── Clip overlap para que el azul tape el rojo ─
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(rx, cy), radius: cr));
    canvas.save();
    canvas.clipPath(path);
    canvas.drawCircle(
      Offset(lx, cy),
      cr,
      Paint()..color = rightColor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.logoId != logoId || old.size != size;
}
