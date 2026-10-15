import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFFD93B68);
  static const primaryHover = Color(0xFFBE2B57);
  static const primarySoft = Color(0xFFFDF0F4);
  static const primaryBorder = Color(0xFFF8C8D7);
  static const secondary = Color(0xFF28242E);
  static const secondarySoft = Color(0xFFF4EFEA);
  static const foreground = Color(0xFF17151A);
  static const muted = Color(0xFF6E6475);
  static const surface = Color(0xFFFFFBF7);
  static const border = Color(0xFFEAE4DE);

  static const roseShadow = Color(0x40D93B68);
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFE94A7A), Color(0xFFD93B68), Color(0xFFBE2B57)],
  );
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFFDF0F4), Color(0xFFFFFBF7)],
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
    brightness: Brightness.light,
  );
  final baseText = GoogleFonts.interTextTheme();
  final displayText = GoogleFonts.fraunces(fontWeight: FontWeight.w700);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.surface,
    textTheme: baseText.copyWith(
      displayLarge: displayText.copyWith(fontSize: 32, color: AppColors.foreground),
      displayMedium: displayText.copyWith(fontSize: 28, color: AppColors.foreground),
      displaySmall: displayText.copyWith(fontSize: 24, color: AppColors.foreground),
      headlineLarge: displayText.copyWith(fontSize: 22, color: AppColors.foreground),
      headlineMedium: displayText.copyWith(fontSize: 20, color: AppColors.foreground),
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.foreground),
      bodyLarge: baseText.bodyLarge?.copyWith(color: AppColors.foreground),
      bodyMedium: baseText.bodyMedium?.copyWith(color: AppColors.foreground),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.foreground,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.foreground),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(color: AppColors.muted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.foreground,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.secondarySoft,
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    dividerColor: AppColors.border,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primarySoft,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
      iconTheme: const WidgetStatePropertyAll(IconThemeData(color: AppColors.muted, size: 24)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.foreground,
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.muted,
      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
      indicator: const UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.primary, width: 3)),
    ),
  );
}
