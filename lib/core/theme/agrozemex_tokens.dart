import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AgroZemex Design Tokens - Google Stitches / Material Design Tokens
/// Centralized visual foundation for all screens across the AgroZemex app.
abstract class AgroZemexTokens {
  AgroZemexTokens._();

  // ---------------------------------------------------------------------------
  // 🎨 COLOR PALETTE
  // ---------------------------------------------------------------------------
  /// Primary (Forest Green) - Used for CTAs, brand logo, and active navigation states.
  static const Color primary = Color(0xFF2D4F1E);

  /// Surface (Warm White) - Primary background color for a spacious, clean feel.
  static const Color surface = Color(0xFFF9F9F9);

  /// Surface Container Lowest - Used for floating cards and secondary sections.
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  /// Surface Container Low - Used for secondary sections and subtle backgrounds.
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);

  /// Secondary (Warm Terracotta / Gold-Brown) - Used for highlights and secondary pills.
  static const Color secondary = Color(0xFF6B5C4C);

  /// On-Surface Variant - Used for secondary text and icons.
  static const Color onSurfaceVariant = Color(0xFF5D5D5D);

  /// Standard On-Surface text color for high contrast primary text.
  static const Color onSurface = Color(0xFF1C1D1B);

  /// On-Primary text color (text/icons on primary Forest Green background).
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onErrorContainer = Color(0xFF410E0B);
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);

  // ---------------------------------------------------------------------------
  // ✍️ TYPOGRAPHY (Inter)
  // ---------------------------------------------------------------------------
  /// Display Large: 32px / Leading 1.1 / -0.02em tracking
  /// For hero greetings and brand headlines.
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 32.0,
        height: 1.1,
        letterSpacing: 32.0 * -0.02,
        fontWeight: FontWeight.bold,
        color: onSurface,
      );

  /// Headline Medium: 20px / Leading 1.2
  /// For section titles (e.g., "Prime Acquisitions").
  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 20.0,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: onSurface,
      );

  /// Body Large: 16px / Leading 1.5
  /// Primary readable content.
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16.0,
        height: 1.5,
        fontWeight: FontWeight.normal,
        color: onSurface,
      );

  /// Body Medium: 14px / Leading 1.4
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14.0,
        height: 1.4,
        fontWeight: FontWeight.normal,
        color: onSurface,
      );

  /// Label Caps: 10px / Tracking 0.05em / Uppercase
  /// For categories and utility labels (e.g., "ARABLE").
  static TextStyle get labelCaps => GoogleFonts.inter(
        fontSize: 10.0,
        letterSpacing: 10.0 * 0.05,
        fontWeight: FontWeight.w700,
        color: onSurfaceVariant,
      );

  // ---------------------------------------------------------------------------
  // 📐 LAYOUT & SPACING
  // ---------------------------------------------------------------------------
  /// Base Roundness (8px base) - Applied to buttons and inputs.
  static const double roundnessEight = 8.0;
  static final BorderRadius radiusEight = BorderRadius.circular(roundnessEight);

  /// Soft Premium Roundness (24px) - Applied to large cards and floating panels.
  static const double roundnessLargeCard = 24.0;
  static final BorderRadius radiusLargeCard = BorderRadius.circular(roundnessLargeCard);

  static const double roundnessTwelve = 12.0;
  static final BorderRadius radiusTwelve = BorderRadius.circular(roundnessTwelve);
  static const double roundnessPill = 20.0;
  static final BorderRadius radiusPill = BorderRadius.circular(roundnessPill);

  /// Margins
  static const double marginMobile = 20.0;
  static const double marginDesktop = 40.0;

  /// Gaps
  static const double gapSmall = 12.0;
  static const double gapMedium = 24.0;
  static const double gapLarge = 48.0;

  // ---------------------------------------------------------------------------
  // ☁️ ELEVATION & EFFECTS
  // ---------------------------------------------------------------------------
  /// Soft Shadows: 0 4px 20px rgba(0,0,0,0.04)
  /// Used to lift floating search pills and property cards.
  static const List<BoxShadow> softShadows = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.04),
      blurRadius: 20.0,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 12.0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 24.0,
      offset: Offset(0, 8),
    ),
  ];

  /// Glassmorphism preset properties
  static const double glassOpacity = 0.80; // 80% opacity
  static const double glassBlurSigma = 20.0; // blur-xl

  /// Background decoration helper for Glassmorphism containers
  static BoxDecoration glassDecoration({
    Color color = surface,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: glassOpacity),
      borderRadius: borderRadius ?? radiusLargeCard,
      border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.2)),
      boxShadow: softShadows,
    );
  }

  /// BackdropFilter ImageFilter helper for Glassmorphism
  static ImageFilter get glassBlurFilter => ImageFilter.blur(
        sigmaX: glassBlurSigma,
        sigmaY: glassBlurSigma,
      );

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;
}

/// Centralized asset path constants for the AgroZemex app.
abstract class AppAssets {
  AppAssets._();

  static const String defaultAvatar = 'assets/images/default_avatar.png';
  static const String loginHero = 'assets/images/login_hero.png';
  static const String defaultLand = 'assets/images/default_land.png';
}
