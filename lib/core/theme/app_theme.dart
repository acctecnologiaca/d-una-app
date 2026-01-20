import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const seedColor = Color(0xFF263547);

  static final lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: const Color(0xFF36618E),
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFFD1E4FF),
    onPrimaryContainer: const Color(0xFF194975),
    secondary: const Color(0xFF8E4D2F),
    onSecondary: const Color(0xFFFFFFFF),
    secondaryContainer: const Color(0xFFFFDBCD),
    onSecondaryContainer: const Color(0xFF71361A),
    tertiary: const Color(0xFF266489),
    onTertiary: const Color(0xFFFFFFFF),
    tertiaryContainer: const Color(0xFFC9E6FF),
    onTertiaryContainer: const Color(0xFF004B6F),
    error: const Color(0xFFBA1A1A),
    onError: const Color(0xFFFFFFFF),
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF93000A),
    surface: const Color(0xFFF8F9FF),
    surfaceContainer: const Color(0xFFECEEF4),
    onSurface: const Color(0xFF191C20),
    surfaceContainerHigh: const Color(0xFFEBEDF5),
    surfaceContainerHighest: const Color(0xFFE1E2E8),
    onSurfaceVariant: const Color(0xFF43474E),
    outline: const Color(0xFF73777F),
    outlineVariant: const Color(0xFFC3C6CF),
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
    inverseSurface: const Color(0xFF2E3135),
    onInverseSurface: const Color(0xFFEFF0F7),
    inversePrimary: const Color(0xFFA0CAFD),
  );

  static final darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFFA0CAFD),
    onPrimary: const Color(0xFF003258),
    primaryContainer: const Color(0xFF194975),
    onPrimaryContainer: const Color(0xFFD1E4FF),
    secondary: const Color(0xFFFFB596),
    onSecondary: const Color(0xFF542106),
    secondaryContainer: const Color(0xFF71361A),
    onSecondaryContainer: const Color(0xFFFFDBCD),
    tertiary: const Color(0xFF95CDF7),
    onTertiary: const Color(0xFF00344E),
    tertiaryContainer: const Color(0xFF004B6F),
    onTertiaryContainer: const Color(0xFFC9E6FF),
    error: const Color(0xFFFFB4AB),
    onError: const Color(0xFF690005),
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),
    surface: const Color(0xFF111418),
    onSurface: const Color(0xFFE1E2E8),
    surfaceContainerHigh: const Color(0xFF25282D),
    surfaceContainerHighest: const Color(0xFF32353A),
    onSurfaceVariant: const Color(0xFFC3C6CF),
    outline: const Color(0xFF8D9199),
    outlineVariant: const Color(0xFF43474E),
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
    inverseSurface: const Color(0xFFE1E2E8),
    onInverseSurface: const Color(0xFF2E3135),
    inversePrimary: const Color(0xFF36618E),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: lightColorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.primary,
        foregroundColor: lightColorScheme.onPrimary,
        centerTitle: true,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: darkColorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.surfaceContainerHighest,
        foregroundColor: darkColorScheme.onSurface,
        centerTitle: true,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
        ),
      ),
    );
  }
}
