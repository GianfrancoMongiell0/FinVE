// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import '../../core/utils/extensions.dart';
import '../theme/app_text_styles.dart';

// ─────────────────────────────────────────────
//  EmptyState widget
// ─────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.illustration,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Si se provee, reemplaza el círculo+ícono genérico.
  final EmptyIllustration? illustration;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ilustración o ícono genérico
            if (illustration != null)
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _IllustrationPainter(
                    illustration: illustration!,
                    colors: colors,
                  ),
                ),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon ?? Icons.inbox_outlined,
                    size: 36, color: colors.primary),
              ),

            const SizedBox(height: 20),

            Text(
              title,
              style: AppTextStyles.headingSmall.copyWith(
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Ilustraciones disponibles
// ─────────────────────────────────────────────
enum EmptyIllustration {
  wallets,
  transactions,
  goals,
  budget,
  recurring,
  categories,
}

// ─────────────────────────────────────────────
//  CustomPainter
// ─────────────────────────────────────────────
class _IllustrationPainter extends CustomPainter {
  const _IllustrationPainter({
    required this.illustration,
    required this.colors,
  });

  final EmptyIllustration illustration;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    switch (illustration) {
      case EmptyIllustration.wallets:
        _paintWallets(canvas, size);
      case EmptyIllustration.transactions:
        _paintTransactions(canvas, size);
      case EmptyIllustration.goals:
        _paintGoals(canvas, size);
      case EmptyIllustration.budget:
        _paintBudget(canvas, size);
      case EmptyIllustration.recurring:
        _paintRecurring(canvas, size);
      case EmptyIllustration.categories:
        _paintCategories(canvas, size);
    }
  }

  // ── Helpers ───────────────────────────────
  Paint _fill(Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.fill;

  Paint _stroke(Color c, {double width = 1.5}) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  RRect _rrect(double x, double y, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  void _drawText(Canvas canvas, String text, Offset center,
      {double size = 14,
      FontWeight weight = FontWeight.w700,
      required Color color}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: color, fontSize: size, fontWeight: weight, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  // ── Billeteras ────────────────────────────
  void _paintWallets(Canvas canvas, Size s) {
    final bg = colors.primaryContainer;
    final fg = colors.primary;
    final accent = colors.tertiary;
    final accentBg = colors.tertiaryContainer;

    // Tarjeta principal
    canvas.drawRRect(
        _rrect(
            s.width * 0.1, s.height * 0.28, s.width * 0.8, s.height * 0.52, 10),
        _fill(bg));
    canvas.drawRRect(
        _rrect(
            s.width * 0.1, s.height * 0.28, s.width * 0.8, s.height * 0.52, 10),
        _stroke(fg.withOpacity(0.3)));

    // Banda horizontal
    canvas.drawRRect(
        _rrect(
            s.width * 0.1, s.height * 0.4, s.width * 0.8, s.height * 0.11, 0),
        _fill(fg.withOpacity(0.12)));

    // Líneas de datos
    canvas.drawRRect(
        _rrect(
            s.width * 0.18, s.height * 0.6, s.width * 0.22, s.height * 0.07, 3),
        _fill(fg.withOpacity(0.3)));
    canvas.drawRRect(
        _rrect(s.width * 0.18, s.height * 0.71, s.width * 0.15, s.height * 0.07,
            3),
        _fill(fg.withOpacity(0.18)));

    // Moneda flotante
    canvas.drawCircle(Offset(s.width * 0.76, s.height * 0.22), s.width * 0.13,
        _fill(accentBg));
    canvas.drawCircle(Offset(s.width * 0.76, s.height * 0.22), s.width * 0.13,
        _stroke(accent.withOpacity(0.5)));
    _drawText(canvas, '\$', Offset(s.width * 0.76, s.height * 0.22),
        color: accent, size: 15);
  }

  // ── Transacciones ─────────────────────────
  void _paintTransactions(Canvas canvas, Size s) {
    final bg = colors.surfaceContainerHighest;
    final fg = colors.onSurfaceVariant;
    final incomeBg = colors.tertiaryContainer;
    final incomeColor = colors.tertiary;
    final expenseBg = colors.errorContainer;
    final expenseColor = colors.error;
    final warnBg = colors.secondaryContainer;
    final warnColor = colors.secondary;

    final dots = [
      (incomeBg, incomeColor),
      (expenseBg, expenseColor),
      (warnBg, warnColor),
    ];

    for (var i = 0; i < 3; i++) {
      final y = s.height * (0.18 + i * 0.26);
      // Fila
      canvas.drawRRect(
          _rrect(s.width * 0.08, y, s.width * 0.84, s.height * 0.2, 6),
          _fill(bg));
      canvas.drawRRect(
          _rrect(s.width * 0.08, y, s.width * 0.84, s.height * 0.2, 6),
          _stroke(fg.withOpacity(0.15), width: 0.5));
      // Círculo de color
      canvas.drawCircle(Offset(s.width * 0.2, y + s.height * 0.1),
          s.height * 0.065, _fill(dots[i].$1));
      // Línea de texto
      canvas.drawRRect(
          _rrect(s.width * 0.32, y + s.height * 0.07, s.width * 0.28,
              s.height * 0.06, 3),
          _fill(fg.withOpacity(0.25)));
    }

    // Punto rojo de "nuevo"
    canvas.drawCircle(Offset(s.width * 0.78, s.height * 0.08), s.width * 0.06,
        _fill(expenseBg));
    canvas.drawCircle(Offset(s.width * 0.78, s.height * 0.08), s.width * 0.06,
        _stroke(expenseColor.withOpacity(0.5)));
  }

  // ── Metas ─────────────────────────────────
  void _paintGoals(Canvas canvas, Size s) {
    final bg = colors.surfaceContainerHighest;
    final fg = colors.onSurfaceVariant;
    final primary = colors.primary;
    final successBg = colors.tertiaryContainer;
    final successFg = colors.tertiary;

    // Círculo reloj
    canvas.drawCircle(
        Offset(s.width * 0.46, s.height * 0.48), s.width * 0.3, _fill(bg));
    canvas.drawCircle(Offset(s.width * 0.46, s.height * 0.48), s.width * 0.3,
        _stroke(fg.withOpacity(0.25)));

    // Manecillas
    final cx = s.width * 0.46;
    final cy = s.height * 0.48;
    // Hora
    canvas.drawLine(Offset(cx, cy), Offset(cx, cy - s.height * 0.16),
        _stroke(primary, width: 2));
    // Minuto
    canvas.drawLine(Offset(cx, cy), Offset(cx + s.width * 0.14, cy),
        _stroke(primary, width: 1.5));
    // Centro
    canvas.drawCircle(Offset(cx, cy), 3, _fill(primary));

    // Línea punteada de objetivo
    final path = Path()
      ..moveTo(s.width * 0.18, s.height * 0.83)
      ..quadraticBezierTo(
          s.width * 0.46, s.height * 0.95, s.width * 0.76, s.height * 0.83);
    canvas.drawPath(
        path,
        _stroke(fg.withOpacity(0.2), width: 1)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke);

    // Check verde
    canvas.drawCircle(Offset(s.width * 0.76, s.height * 0.2), s.width * 0.1,
        _fill(successBg));
    canvas.drawCircle(Offset(s.width * 0.76, s.height * 0.2), s.width * 0.1,
        _stroke(successFg.withOpacity(0.5)));
    final checkPath = Path()
      ..moveTo(s.width * 0.71, s.height * 0.2)
      ..lineTo(s.width * 0.75, s.height * 0.24)
      ..lineTo(s.width * 0.82, s.height * 0.16);
    canvas.drawPath(checkPath, _stroke(successFg, width: 1.8));
  }

  // ── Presupuesto ───────────────────────────
  void _paintBudget(Canvas canvas, Size s) {
    final bg = colors.surfaceContainerHighest;
    final fg = colors.onSurfaceVariant;
    final primary = colors.primary;
    final primaryBg = colors.primaryContainer;

    // Documento
    canvas.drawRRect(
        _rrect(
            s.width * 0.16, s.height * 0.2, s.width * 0.68, s.height * 0.62, 8),
        _fill(bg));
    canvas.drawRRect(
        _rrect(
            s.width * 0.16, s.height * 0.2, s.width * 0.68, s.height * 0.62, 8),
        _stroke(fg.withOpacity(0.2)));

    // Líneas de contenido
    for (var i = 0; i < 3; i++) {
      final y = s.height * (0.38 + i * 0.14);
      final w = [0.4, 0.32, 0.22][i];
      canvas.drawRRect(
          _rrect(s.width * 0.26, y, s.width * w, s.height * 0.06, 3),
          _fill(fg.withOpacity(0.2)));
    }

    // Marcadores (clips) en la parte superior
    for (var i = 0; i < 2; i++) {
      final x = s.width * (0.3 + i * 0.22);
      canvas.drawRRect(
          _rrect(x, s.height * 0.1, s.width * 0.14, s.height * 0.22, 4),
          _fill(primaryBg));
      canvas.drawRRect(
          _rrect(x, s.height * 0.1, s.width * 0.14, s.height * 0.22, 4),
          _stroke(primary.withOpacity(0.4)));
    }
  }

  // ── Recurrentes ───────────────────────────
  void _paintRecurring(Canvas canvas, Size s) {
    final bg = colors.surfaceContainerHighest;
    final fg = colors.onSurfaceVariant;
    final primary = colors.primary;
    final primaryBg = colors.primaryContainer;
    final warnBg = colors.tertiaryContainer;
    final warnFg = colors.tertiary;

    // Casa
    final housePath = Path()
      ..moveTo(s.width * 0.28, s.height * 0.5)
      ..lineTo(s.width * 0.5, s.height * 0.28)
      ..lineTo(s.width * 0.72, s.height * 0.5)
      ..lineTo(s.width * 0.72, s.height * 0.78)
      ..lineTo(s.width * 0.28, s.height * 0.78)
      ..close();
    canvas.drawPath(housePath, _fill(primaryBg));
    canvas.drawPath(housePath, _stroke(primary.withOpacity(0.4)));

    // Puerta
    canvas.drawRRect(
        _rrect(
            s.width * 0.42, s.height * 0.6, s.width * 0.16, s.height * 0.18, 3),
        _fill(bg));

    // Ventana
    canvas.drawRRect(
        _rrect(
            s.width * 0.32, s.height * 0.55, s.width * 0.12, s.height * 0.1, 2),
        _fill(bg));

    // Ícono de recurrencia
    canvas.drawCircle(
        Offset(s.width * 0.75, s.height * 0.2), s.width * 0.1, _fill(warnBg));
    canvas.drawCircle(Offset(s.width * 0.75, s.height * 0.2), s.width * 0.1,
        _stroke(warnFg.withOpacity(0.5)));

    // Flecha circular (↻)
    final arcRect = Rect.fromCenter(
        center: Offset(s.width * 0.75, s.height * 0.2),
        width: s.width * 0.1,
        height: s.width * 0.1);
    canvas.drawArc(arcRect, 0.3, 4.8, false, _stroke(warnFg, width: 1.5));

    // Punta de la flecha
    canvas.drawLine(Offset(s.width * 0.795, s.height * 0.165),
        Offset(s.width * 0.81, s.height * 0.2), _stroke(warnFg, width: 1.5));
    canvas.drawLine(Offset(s.width * 0.765, s.height * 0.155),
        Offset(s.width * 0.81, s.height * 0.2), _stroke(warnFg, width: 1.5));
  }

  // ── Categorías ────────────────────────────
  void _paintCategories(Canvas canvas, Size s) {
    final bg = colors.surfaceContainerHighest;
    final fg = colors.onSurfaceVariant;
    final primary = colors.primary;

    // Ventana / pantalla
    canvas.drawRRect(
        _rrect(s.width * 0.08, s.height * 0.16, s.width * 0.84, s.height * 0.66,
            8),
        _fill(bg));
    canvas.drawRRect(
        _rrect(s.width * 0.08, s.height * 0.16, s.width * 0.84, s.height * 0.66,
            8),
        _stroke(fg.withOpacity(0.2)));

    // Barra de título
    canvas.drawRRect(
        _rrect(s.width * 0.08, s.height * 0.16, s.width * 0.84, s.height * 0.16,
            8),
        _fill(fg.withOpacity(0.07)));

    // Puntos de color (semáforo)
    final dotColors = [
      colors.error.withOpacity(0.6),
      colors.tertiary.withOpacity(0.6),
      colors.primary.withOpacity(0.6),
    ];
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(s.width * (0.18 + i * 0.09), s.height * 0.24),
          s.width * 0.035, _fill(dotColors[i]));
    }

    // Gráfico de línea
    final points = [
      Offset(s.width * 0.16, s.height * 0.66),
      Offset(s.width * 0.3, s.height * 0.5),
      Offset(s.width * 0.44, s.height * 0.57),
      Offset(s.width * 0.58, s.height * 0.43),
      Offset(s.width * 0.75, s.height * 0.52),
    ];
    final linePath = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, _stroke(primary, width: 2));

    // Puntos en la línea
    for (final p in points) {
      canvas.drawCircle(p, 3, _fill(primary));
    }
  }

  @override
  bool shouldRepaint(_IllustrationPainter old) =>
      old.illustration != illustration || old.colors != colors;
}
