import 'package:flutter/material.dart';

/// Design system matching AlertaCBBA Dashboard CSS tokens exactly.
/// Source: dashboard/styles.css :root variables
class AppTheme {
  AppTheme._();

  // ── Background Colors ──
  static const Color bgPrimary = Color(0xFF06080F);
  static const Color bgSecondary = Color(0xFF0C1120);
  static const Color bgPanel = Color(0xD90C1120); // rgba(12, 17, 32, 0.85)
  static const Color bgCard = Color(0xB312192D); // rgba(18, 25, 45, 0.7)
  static const Color bgHover = Color(0x801E2846); // rgba(30, 40, 70, 0.5)
  static const Color bgGlass = Color(0x990F1428); // rgba(15, 20, 40, 0.6)

  // ── Alert Colors ──
  static const Color colorCritical = Color(0xFFFF3D3D);
  static const Color colorCriticalGlow = Color(0x66FF3D3D);
  static const Color colorCriticalBg = Color(0x1AFF3D3D);
  static const Color colorWarning = Color(0xFFFF8C00);
  static const Color colorWarningGlow = Color(0x59FF8C00);
  static const Color colorWarningBg = Color(0x1AFF8C00);
  static const Color colorInfo = Color(0xFF4FC3F7);
  static const Color colorSuccess = Color(0xFF00E676);
  static const Color colorSuccessBg = Color(0x1400E676);

  // ── Text Colors ──
  static const Color textPrimary = Color(0xFFE8ECF4);
  static const Color textSecondary = Color(0xFF8892A8);
  static const Color textMuted = Color(0xFF4A5568);
  static const Color textAccent = Color(0xFF7EB8FF);

  // ── Brand ──
  static const Color brandPrimary = Color(0xFFFF6B35);
  static const Color brandSecondary = Color(0xFFFF9F1C);
  static const Color brandTertiary = Color(0xFFFFCE44);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF9F1C), Color(0xFFFFCE44)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradientSubtle = LinearGradient(
    colors: [Color(0x26FF6B35), Color(0x14FF9F1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Borders ──
  static const Color borderColor = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color borderGlow = Color(0x4DFF6B35);

  // ── Radius ──
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  // ── Shadows ──
  static List<BoxShadow> glowCritical = [
    BoxShadow(color: colorCriticalGlow.withOpacity(0.3), blurRadius: 20),
    BoxShadow(color: colorCriticalGlow.withOpacity(0.1), blurRadius: 60),
  ];

  static List<BoxShadow> glowWarning = [
    BoxShadow(color: colorWarningGlow.withOpacity(0.25), blurRadius: 20),
    BoxShadow(color: colorWarningGlow.withOpacity(0.08), blurRadius: 60),
  ];

  static List<BoxShadow> glowBrand = [
    BoxShadow(color: brandPrimary.withOpacity(0.3), blurRadius: 20),
    BoxShadow(color: brandPrimary.withOpacity(0.1), blurRadius: 60),
  ];

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      fontFamily: 'Inter',
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: brandPrimary,
        secondary: brandSecondary,
        surface: bgSecondary,
        error: colorCritical,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgPanel,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: borderColor),
        ),
        elevation: 0,
      ),
    );
  }
}
