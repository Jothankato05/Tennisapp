import 'package:flutter/material.dart';

/// Brand colours taken from the VUNA Racqueteers badge.
class VeritasColors {
  static const navy = Color(0xFF021E34);
  static const navyLight = Color(0xFF0B3354);
  static const court = Color(0xFF1C8A4C); // racquet green
  static const ball = Color(0xFFDFAD16); // badge gold
  static const gold = ball;
  static const cream = Color(0xFFF5E6C5);
  static const win = Color(0xFF1C8A4C);
  static const loss = Color(0xFFD14343);

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF021E34), Color(0xFF0B3354)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

const _font = 'PlusJakartaSans';

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final background = dark ? const Color(0xFF01111F) : const Color(0xFFF5F6F8);
  final surface = dark ? const Color(0xFF0A2236) : Colors.white;
  final outline = dark ? const Color(0xFF173452) : const Color(0xFFE9ECF0);

  final scheme = ColorScheme.fromSeed(seedColor: VeritasColors.navy, brightness: brightness).copyWith(
    primary: dark ? VeritasColors.ball : VeritasColors.navy,
    onPrimary: dark ? VeritasColors.navy : Colors.white,
    secondary: VeritasColors.court,
    onSecondary: Colors.white,
    tertiary: VeritasColors.ball,
    surface: surface,
    surfaceContainerHighest: dark ? const Color(0xFF122C45) : const Color(0xFFEFF1F4),
    outlineVariant: outline,
    error: VeritasColors.loss,
  );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: brightness, fontFamily: _font);
  final text = base.textTheme.apply(
    fontFamily: _font,
    bodyColor: dark ? const Color(0xFFE8EDF3) : const Color(0xFF0E1B2A),
    displayColor: dark ? Colors.white : VeritasColors.navy,
  );

  return base.copyWith(
    scaffoldBackgroundColor: background,
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 24,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: outline),
      ),
    ),
    dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(52, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(52, 52),
        side: BorderSide(color: outline, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w700),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: outline)),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontFamily: _font, fontWeight: FontWeight.w600)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      indicatorColor: dark ? VeritasColors.ball.withValues(alpha: 0.18) : VeritasColors.navy.withValues(alpha: 0.08),
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? (dark ? VeritasColors.ball : VeritasColors.navy)
              : (dark ? const Color(0xFF7F93A8) : const Color(0xFF8A97A6)),
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: _font,
          fontSize: 11.5,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected)
              ? (dark ? VeritasColors.ball : VeritasColors.navy)
              : (dark ? const Color(0xFF7F93A8) : const Color(0xFF8A97A6)),
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.primary,
      unselectedLabelColor: dark ? const Color(0xFF7F93A8) : const Color(0xFF8A97A6),
      indicatorColor: VeritasColors.ball,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w700, fontSize: 14),
      unselectedLabelStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w600, fontSize: 14),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: outline),
      labelStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w600),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: dark ? VeritasColors.ball : VeritasColors.navy,
      foregroundColor: dark ? VeritasColors.navy : Colors.white,
      elevation: 2,
      shape: const StadiumBorder(),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: VeritasColors.navy,
      contentTextStyle: const TextStyle(fontFamily: _font, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: VeritasColors.court, linearTrackColor: outline),
    sliderTheme: base.sliderTheme.copyWith(activeTrackColor: VeritasColors.court, thumbColor: VeritasColors.court),
  );
}
