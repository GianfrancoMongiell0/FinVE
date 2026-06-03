// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  App theme identifiers
// ─────────────────────────────────────────────
enum AppThemeId { oceanBlue, slateAmber, emeraldGold, roseNight, violetSunset }

// ─────────────────────────────────────────────
//  Ocean Blue — primary palette
// ─────────────────────────────────────────────
class OceanBlueColors {
  OceanBlueColors._();
  static const Color primary900 = Color(0xFF042C53);
  static const Color primary800 = Color(0xFF0C447C);
  static const Color primary600 = Color(0xFF185FA5);
  static const Color primary400 = Color(0xFF378ADD);
  static const Color primary200 = Color(0xFF85B7EB);
  static const Color primary100 = Color(0xFFB5D4F4);
  static const Color primary50  = Color(0xFFE6F1FB);
  static const Color accent900  = Color(0xFF04342C);
  static const Color accent800  = Color(0xFF085041);
  static const Color accent600  = Color(0xFF0F6E56);
  static const Color accent400  = Color(0xFF1D9E75);
  static const Color accent200  = Color(0xFF5DCAA5);
  static const Color accent100  = Color(0xFF9FE1CB);
  static const Color accent50   = Color(0xFFE1F5EE);
  static const Color error      = Color(0xFFE24B4A);
  static const Color warning    = Color(0xFFEF9F27);
  static const Color success    = Color(0xFF1D9E75);
  static const Color seed       = primary600;
}

// ─────────────────────────────────────────────
//  Slate & Amber
// ─────────────────────────────────────────────
class SlateAmberColors {
  SlateAmberColors._();
  static const Color primary900 = Color(0xFF2C2C2A);
  static const Color primary800 = Color(0xFF444441);
  static const Color primary600 = Color(0xFF5F5E5A);
  static const Color primary400 = Color(0xFF888780);
  static const Color primary200 = Color(0xFFB4B2A9);
  static const Color primary100 = Color(0xFFD3D1C7);
  static const Color primary50  = Color(0xFFF1EFE8);
  static const Color accent900  = Color(0xFF412402);
  static const Color accent800  = Color(0xFF633806);
  static const Color accent600  = Color(0xFF854F0B);
  static const Color accent400  = Color(0xFFBA7517);
  static const Color accent200  = Color(0xFFEF9F27);
  static const Color accent100  = Color(0xFFFAC775);
  static const Color accent50   = Color(0xFFFAEEDA);
  static const Color error      = Color(0xFFE24B4A);
  static const Color warning    = Color(0xFFEF9F27);
  static const Color success    = Color(0xFF1D9E75);
  static const Color seed       = Color(0xFF5F5E5A);
}

// ─────────────────────────────────────────────
//  Emerald & Gold — verde esmeralda + dorado
// ─────────────────────────────────────────────
class EmeraldGoldColors {
  EmeraldGoldColors._();
  static const Color primary900 = Color(0xFF064E3B);
  static const Color primary800 = Color(0xFF065F46);
  static const Color primary600 = Color(0xFF059669);
  static const Color primary400 = Color(0xFF34D399);
  static const Color primary200 = Color(0xFF6EE7B7);
  static const Color primary100 = Color(0xFFA7F3D0);
  static const Color primary50  = Color(0xFFECFDF5);
  static const Color accent900  = Color(0xFF78350F);
  static const Color accent800  = Color(0xFF92400E);
  static const Color accent600  = Color(0xFFD97706);
  static const Color accent400  = Color(0xFFF59E0B);
  static const Color accent200  = Color(0xFFFBBF24);
  static const Color accent100  = Color(0xFFFDE68A);
  static const Color accent50   = Color(0xFFFFFBEB);
  static const Color error      = Color(0xFFE24B4A);
  static const Color success    = Color(0xFF059669);
  static const Color seed       = primary600;
}

// ─────────────────────────────────────────────
//  Rose Night — rosa oscuro + negro elegante
// ─────────────────────────────────────────────
class RoseNightColors {
  RoseNightColors._();
  static const Color primary900 = Color(0xFF1A0A0F);
  static const Color primary800 = Color(0xFF3D1A26);
  static const Color primary600 = Color(0xFF9F1239);
  static const Color primary400 = Color(0xFFE11D48);
  static const Color primary200 = Color(0xFFFB7185);
  static const Color primary100 = Color(0xFFFDA4AF);
  static const Color primary50  = Color(0xFFFFF1F2);
  static const Color accent900  = Color(0xFF1C1917);
  static const Color accent800  = Color(0xFF292524);
  static const Color accent600  = Color(0xFF44403C);
  static const Color accent400  = Color(0xFF78716C);
  static const Color accent200  = Color(0xFFA8A29E);
  static const Color accent100  = Color(0xFFD6D3D1);
  static const Color accent50   = Color(0xFFFAFAF9);
  static const Color error      = Color(0xFFE24B4A);
  static const Color success    = Color(0xFF1D9E75);
  static const Color seed       = primary600;
}

// ─────────────────────────────────────────────
//  Violet Sunset — púrpura + naranja vibrante
// ─────────────────────────────────────────────
class VioletSunsetColors {
  VioletSunsetColors._();
  static const Color primary900 = Color(0xFF2E1065);
  static const Color primary800 = Color(0xFF4C1D95);
  static const Color primary600 = Color(0xFF7C3AED);
  static const Color primary400 = Color(0xFFA78BFA);
  static const Color primary200 = Color(0xFFC4B5FD);
  static const Color primary100 = Color(0xFFDDD6FE);
  static const Color primary50  = Color(0xFFF5F3FF);
  static const Color accent900  = Color(0xFF7C2D12);
  static const Color accent800  = Color(0xFF9A3412);
  static const Color accent600  = Color(0xFFEA580C);
  static const Color accent400  = Color(0xFFFB923C);
  static const Color accent200  = Color(0xFFFDBA74);
  static const Color accent100  = Color(0xFFFED7AA);
  static const Color accent50   = Color(0xFFFFF7ED);
  static const Color error      = Color(0xFFE24B4A);
  static const Color success    = Color(0xFF1D9E75);
  static const Color seed       = primary600;
}

// ─────────────────────────────────────────────
//  Currency & Payment colors
// ─────────────────────────────────────────────
class CurrencyColors {
  CurrencyColors._();
  static const Map<String, Color> background = {
    'USD': Color(0xFFE6F1FB),
    'VES': Color(0xFFEAF3DE),
    'BTC': Color(0xFFFAEEDA),
    'ETH': Color(0xFFEEEDFE),
    'SOL': Color(0xFFE1F5EE),
  };
  static const Map<String, Color> foreground = {
    'USD': Color(0xFF0C447C),
    'VES': Color(0xFF27500A),
    'BTC': Color(0xFF633806),
    'ETH': Color(0xFF3C3489),
    'SOL': Color(0xFF085041),
  };
}

class PaymentColors {
  PaymentColors._();
  static const Map<String, Color> background = {
    'cash':       Color(0xFFEAF3DE),
    'pago_movil': Color(0xFFE6F1FB),
    'transfer':   Color(0xFFEEEDFE),
    'zelle':      Color(0xFFE1F5EE),
    'other':      Color(0xFFF1EFE8),
  };
  static const Map<String, Color> foreground = {
    'cash':       Color(0xFF27500A),
    'pago_movil': Color(0xFF0C447C),
    'transfer':   Color(0xFF3C3489),
    'zelle':      Color(0xFF085041),
    'other':      Color(0xFF444441),
  };
}

// ─────────────────────────────────────────────
//  Color picker palette — for category colors
// ─────────────────────────────────────────────
class CategoryColorPalette {
  CategoryColorPalette._();

  static const List<Color> colors = [
    Color(0xFFE24B4A), // Red
    Color(0xFFE11D48), // Rose
    Color(0xFFEA580C), // Orange
    Color(0xFFD97706), // Amber
    Color(0xFFEAB308), // Yellow
    Color(0xFF84CC16), // Lime
    Color(0xFF16A34A), // Green
    Color(0xFF059669), // Emerald
    Color(0xFF0D9488), // Teal
    Color(0xFF0284C7), // Sky
    Color(0xFF185FA5), // Blue
    Color(0xFF4F46E5), // Indigo
    Color(0xFF7C3AED), // Violet
    Color(0xFF9F1239), // Rose dark
    Color(0xFF854F0B), // Amber dark
    Color(0xFF166534), // Green dark
    Color(0xFF155E75), // Cyan dark
    Color(0xFF1E3A5F), // Blue dark
    Color(0xFF44403C), // Stone
    Color(0xFF374151), // Gray
  ];

  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  static Color fromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return colors.first;
    }
  }
}
