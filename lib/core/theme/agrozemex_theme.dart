import 'package:flutter/material.dart';
import 'agrozemex_tokens.dart';

/// Central AgroZemex Flutter ThemeData configuration using AgroZemexTokens.
abstract class AgroZemexTheme {
  AgroZemexTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AgroZemexTokens.primary,
      scaffoldBackgroundColor: AgroZemexTokens.surface,
      colorScheme: ColorScheme.light(
        primary: AgroZemexTokens.primary,
        onPrimary: AgroZemexTokens.onPrimary,
        surface: AgroZemexTokens.surface,
        onSurface: AgroZemexTokens.onSurface,
        onSurfaceVariant: AgroZemexTokens.onSurfaceVariant,
        surfaceContainerLowest: AgroZemexTokens.surfaceContainerLowest,
        surfaceContainerLow: AgroZemexTokens.surfaceContainerLow,
      ),
      textTheme: TextTheme(
        displayLarge: AgroZemexTokens.displayLarge,
        headlineMedium: AgroZemexTokens.headlineMedium,
        bodyLarge: AgroZemexTokens.bodyLarge,
        labelSmall: AgroZemexTokens.labelCaps,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AgroZemexTokens.primary,
          foregroundColor: AgroZemexTokens.onPrimary,
          textStyle: AgroZemexTokens.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: AgroZemexTokens.radiusEight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AgroZemexTokens.gapMedium,
            vertical: AgroZemexTokens.gapSmall,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AgroZemexTokens.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AgroZemexTokens.gapMedium,
          vertical: AgroZemexTokens.gapSmall,
        ),
        border: OutlineInputBorder(
          borderRadius: AgroZemexTokens.radiusEight,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AgroZemexTokens.radiusEight,
          borderSide: BorderSide(color: AgroZemexTokens.surfaceContainerLow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AgroZemexTokens.radiusEight,
          borderSide: const BorderSide(color: AgroZemexTokens.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: AgroZemexTokens.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AgroZemexTokens.radiusLargeCard,
        ),
      ),
    );
  }
}
