import 'package:flutter/material.dart';

/// Exact design tokens extracted from Google Stitch Design System:
/// **Vibrant Fluid Commerce** (`assets/c9c7d96d910e4bfab63935cdaea1b2ba`).
abstract final class AppColors {
  // Brand Core Accents
  static const Color primary = Color(
    0xFF4F46E5,
  ); // Electric Indigo (Primary CTA)
  static const Color primaryDeep = Color(0xFF3525CD); // M3 Fidelity Primary
  static const Color primaryDark = Color(
    0xFF818CF8,
  ); // Dark Mode Primary Accent
  static const Color primaryFixed = Color(0xFFE2DFFF);
  static const Color onPrimaryFixed = Color(0xFF0F0069);

  static const Color secondary = Color(0xFF10B981); // Emerald Conversion Cue
  static const Color secondaryDeep = Color(0xFF006C49);
  static const Color secondaryContainer = Color(0xFF6CF8BB);
  static const Color onSecondaryContainer = Color(0xFF00714D);

  static const Color tertiary = Color(0xFFF59E0B); // Warm Amber (Stars / Deals)
  static const Color tertiaryDeep = Color(0xFF684000);
  static const Color tertiaryFixed = Color(0xFFFFDDB8);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color errorDark = Color(0xFFF87171);

  // Light Mode Surface Hierarchy
  static const Color lightBackground = Color(0xFFF8F9FF);
  static const Color lightSurfaceLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceLow = Color(0xFFEFF4FF);
  static const Color lightSurfaceContainer = Color(0xFFE5EEFF);
  static const Color lightSurfaceHigh = Color(0xFFDCE9FF);
  static const Color lightSurfaceHighest = Color(0xFFD3E4FE);
  static const Color lightOnSurface = Color(0xFF0B1C30);
  static const Color lightOnSurfaceVariant = Color(0xFF464555);
  static const Color lightOutline = Color(0xFF777587);
  static const Color lightOutlineVariant = Color(0xFFC7C4D8);
  static const Color lightSubtleBorder = Color(
    0x1464748B,
  ); // rgba(100,116,139,0.08)

  // Dark Mode Surface Hierarchy (Deep Obsidian / Slate — avoids pure pitch black)
  static const Color darkBackground = Color(0xFF0B0F17);
  static const Color darkSurfaceLowest = Color(0xFF0F172A);
  static const Color darkSurfaceLow = Color(0xFF151F33);
  static const Color darkSurfaceContainer = Color(0xFF1E293B);
  static const Color darkSurfaceHigh = Color(0xFF273449);
  static const Color darkSurfaceHighest = Color(0xFF334155);
  static const Color darkOnSurface = Color(0xFFF1F5F9);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color darkOutline = Color(0xFF64748B);
  static const Color darkOutlineVariant = Color(0xFF334155);
  static const Color darkSubtleBorder = Color(
    0x0FFFFFFF,
  ); // rgba(255,255,255,0.06)

  // Brand Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDeep, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Spacing & corner radius scale matching Stitch `Vibrant Fluid Commerce`.
abstract final class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0; // Buttons & Inputs (0.75rem)
  static const double radiusLg = 16.0; // Containers (1rem)
  static const double radiusXl = 24.0; // Squircle 2XL Cards & Sheets (1.5rem)
  static const double radiusFull = 9999.0; // Pill Chips & Floating Dock
}
