import 'package:flutter/material.dart';

class VeritasColors {
  static const navy = Color(0xFF0F2A4A);
  static const gold = Color(0xFFC9A227);
  static const ball = Color(0xFFD9E84A);
  static const court = Color(0xFF2F7A52);
  static const clay = Color(0xFFC1652F);
  static const win = Color(0xFF2E7D32);
  static const loss = Color(0xFFC62828);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: VeritasColors.navy,
    brightness: brightness,
    primary: dark ? const Color(0xFF9DC2F0) : VeritasColors.navy,
    secondary: dark ? VeritasColors.ball : VeritasColors.court,
    tertiary: VeritasColors.gold,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: brightness);
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xFF0D1520) : const Color(0xFFF4F6F9),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF0D1520) : const Color(0xFFF4F6F9),
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: dark ? const Color(0xFF152131) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dark ? const Color(0xFF2A3A50) : const Color(0xFFE1E6ED)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: dark ? const Color(0xFF152131) : Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: dark ? const Color(0xFF2B4466) : VeritasColors.ball,
      backgroundColor: dark ? const Color(0xFF111C2A) : Colors.white,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ),
    chipTheme: base.chipTheme.copyWith(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: dark ? VeritasColors.ball : VeritasColors.navy,
      foregroundColor: dark ? VeritasColors.navy : Colors.white,
    ),
  );
}
