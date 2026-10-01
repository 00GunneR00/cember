import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/brand_profile.dart';

@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.scrim,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryGradientStart,
    required this.secondaryGradientEnd,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiaryContainer,
    required this.tertiaryFixedDim,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.outline,
    required this.outlineVariant,
    required this.logoBackground,
    required this.logoRing,
    required this.logoAccent,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color scrim;

  final Color secondary;
  final Color onSecondary;
  final Color secondaryGradientStart;
  final Color secondaryGradientEnd;
  final Color secondaryContainer;
  final Color onSecondaryContainer;

  final Color tertiary;
  final Color onTertiaryContainer;
  final Color tertiaryFixedDim;

  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;

  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;

  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;

  final Color outline;
  final Color outlineVariant;

  final Color logoBackground;
  final Color logoRing;
  final Color logoAccent;

  // "Gün Batımı" — magentadan mandalinaya, oradan güneş sarısına akan sıcak bir parti gradyanı.
  // Zeminler sıcak ama sakin kalır ki fotoğraflar öne çıksın; renk butonlarda, + tuşunda ve kapaklarda.
  // Zümrüt yeşili yalnızca canlı/aktif sinyali. Butonlardaki beyaz yazı gradyanın her noktasında WCAG AA (≥4.5).
  static const light = AppColorTokens(
    primary: Color(0xFF1E1216),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF2A1A22),
    onPrimaryContainer: Color(0xFFFFE8F2),
    scrim: Color(0xFF0E080B),
    secondary: Color(0xFFD6197E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryGradientStart: Color(0xFFD6197E),
    secondaryGradientEnd: Color(0xFFD93A1F),
    secondaryContainer: Color(0xFFFFE0EE),
    onSecondaryContainer: Color(0xFF7A0C45),
    tertiary: Color(0xFF065F46),
    onTertiaryContainer: Color(0xFF0E9F6E),
    tertiaryFixedDim: Color(0xFFA7F3D0),
    error: Color(0xFFD92D20),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE4E2),
    onErrorContainer: Color(0xFF7A1A12),
    background: Color(0xFFFFF7F2),
    onBackground: Color(0xFF1E1216),
    surface: Color(0xFFFFF7F2),
    onSurface: Color(0xFF1E1216),
    onSurfaceVariant: Color(0xFF7A5F68),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFF6F1),
    surfaceContainer: Color(0xFFF8E7E0),
    surfaceContainerHigh: Color(0xFFF1DBD3),
    surfaceContainerHighest: Color(0xFFE8CEC5),
    outline: Color(0xFF9C8189),
    outlineVariant: Color(0xFFEBDAD3),
    logoBackground: Color(0xFF1E1216),
    logoRing: Color(0xFFFF8A3D),
    logoAccent: Color(0xFFFFC53D),
  );

  static const dark = AppColorTokens(
    primary: Color(0xFFFBF1F4),
    onPrimary: Color(0xFF141014),
    primaryContainer: Color(0xFF3A2531),
    onPrimaryContainer: Color(0xFFFFE8F2),
    scrim: Color(0xFF000000),
    secondary: Color(0xFFFF4FA8),
    onSecondary: Color(0xFF1E0712),
    secondaryGradientStart: Color(0xFFFF4FA8),
    secondaryGradientEnd: Color(0xFFFF8A3D),
    secondaryContainer: Color(0xFF5C1638),
    onSecondaryContainer: Color(0xFFFFD9EA),
    tertiary: Color(0xFF065F46),
    onTertiaryContainer: Color(0xFF3DDC97),
    tertiaryFixedDim: Color(0xFF6EE7B7),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF2A0606),
    errorContainer: Color(0xFF5B1616),
    onErrorContainer: Color(0xFFFFD5D5),
    background: Color(0xFF141014),
    onBackground: Color(0xFFFBF1F4),
    surface: Color(0xFF141014),
    onSurface: Color(0xFFFBF1F4),
    onSurfaceVariant: Color(0xFFB9A3AC),
    surfaceContainerLowest: Color(0xFF1C161B),
    surfaceContainerLow: Color(0xFF221B21),
    surfaceContainer: Color(0xFF2A2229),
    surfaceContainerHigh: Color(0xFF332A31),
    surfaceContainerHighest: Color(0xFF3D333B),
    outline: Color(0xFF7E6B74),
    outlineVariant: Color(0xFF3A3037),
    logoBackground: Color(0xFF221B21),
    logoRing: Color(0xFFFF8A3D),
    logoAccent: Color(0xFFFFC53D),
  );

  /// The main call-to-action gradient (QR ile Katıl, the + button, the recap card).
  /// Both ends keep AA contrast with [onSecondary].
  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [secondaryGradientStart, secondaryGradientEnd],
      );

  /// The full sunset — magenta, tangerine, sun — for covers without a photo. Decorative only:
  /// text over it always sits on a scrim.
  List<Color> get coverGradientColors => [secondaryGradientStart, logoRing, logoAccent];

  /// Layers a brand's colors on top of [base] for a branded circle's screens.
  /// Only the primary/secondary/logo tokens shift — surfaces, text, and error
  /// tokens stay as-is so contrast/readability aren't affected by brand colors.
  factory AppColorTokens.brandOverlay(AppColorTokens base, BrandProfile brand) {
    final secondary = brand.secondaryColor ?? base.secondary;
    return base.copyWith(
      primary: brand.primaryColor,
      secondary: secondary,
      logoBackground: brand.primaryColor,
      logoRing: secondary,
      logoAccent: brand.primaryColor,
    );
  }

  @override
  AppColorTokens copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? scrim,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryGradientStart,
    Color? secondaryGradientEnd,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiaryContainer,
    Color? tertiaryFixedDim,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? background,
    Color? onBackground,
    Color? surface,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? outline,
    Color? outlineVariant,
    Color? logoBackground,
    Color? logoRing,
    Color? logoAccent,
  }) {
    return AppColorTokens(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      scrim: scrim ?? this.scrim,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryGradientStart: secondaryGradientStart ?? this.secondaryGradientStart,
      secondaryGradientEnd: secondaryGradientEnd ?? this.secondaryGradientEnd,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      tertiary: tertiary ?? this.tertiary,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      tertiaryFixedDim: tertiaryFixedDim ?? this.tertiaryFixedDim,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      surfaceContainerLowest: surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest ?? this.surfaceContainerHighest,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      logoBackground: logoBackground ?? this.logoBackground,
      logoRing: logoRing ?? this.logoRing,
      logoAccent: logoAccent ?? this.logoAccent,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColorTokens(
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      primaryContainer: c(primaryContainer, other.primaryContainer),
      onPrimaryContainer: c(onPrimaryContainer, other.onPrimaryContainer),
      scrim: c(scrim, other.scrim),
      secondary: c(secondary, other.secondary),
      onSecondary: c(onSecondary, other.onSecondary),
      secondaryGradientStart: c(secondaryGradientStart, other.secondaryGradientStart),
      secondaryGradientEnd: c(secondaryGradientEnd, other.secondaryGradientEnd),
      secondaryContainer: c(secondaryContainer, other.secondaryContainer),
      onSecondaryContainer: c(onSecondaryContainer, other.onSecondaryContainer),
      tertiary: c(tertiary, other.tertiary),
      onTertiaryContainer: c(onTertiaryContainer, other.onTertiaryContainer),
      tertiaryFixedDim: c(tertiaryFixedDim, other.tertiaryFixedDim),
      error: c(error, other.error),
      onError: c(onError, other.onError),
      errorContainer: c(errorContainer, other.errorContainer),
      onErrorContainer: c(onErrorContainer, other.onErrorContainer),
      background: c(background, other.background),
      onBackground: c(onBackground, other.onBackground),
      surface: c(surface, other.surface),
      onSurface: c(onSurface, other.onSurface),
      onSurfaceVariant: c(onSurfaceVariant, other.onSurfaceVariant),
      surfaceContainerLowest: c(surfaceContainerLowest, other.surfaceContainerLowest),
      surfaceContainerLow: c(surfaceContainerLow, other.surfaceContainerLow),
      surfaceContainer: c(surfaceContainer, other.surfaceContainer),
      surfaceContainerHigh: c(surfaceContainerHigh, other.surfaceContainerHigh),
      surfaceContainerHighest: c(surfaceContainerHighest, other.surfaceContainerHighest),
      outline: c(outline, other.outline),
      outlineVariant: c(outlineVariant, other.outlineVariant),
      logoBackground: c(logoBackground, other.logoBackground),
      logoRing: c(logoRing, other.logoRing),
      logoAccent: c(logoAccent, other.logoAccent),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColorTokens get colors => Theme.of(this).extension<AppColorTokens>()!;
}

class AppSpacing {
  AppSpacing._();

  static const xs2 = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xl2 = 32.0;
  static const xl3 = 40.0;
  static const marginMobile = 16.0;
  static const gutterMobile = 12.0;
}

class AppRadius {
  AppRadius._();

  static const card = 16.0;
  static const cardLarge = 24.0;
  static const pill = 999.0;
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle display = GoogleFonts.plusJakartaSans(
    fontSize: 36,
    height: 44 / 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.03 * 36,
  );

  static TextStyle headlineLgMobile = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 24,
  );

  static TextStyle headlineMd = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.015 * 20,
  );

  static TextStyle headlineSm = GoogleFonts.plusJakartaSans(
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.01 * 17,
  );

  static TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodySm = GoogleFonts.inter(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );

  static TextStyle labelLg = GoogleFonts.inter(
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle labelMd = GoogleFonts.inter(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
  );

  static TextStyle labelSm = GoogleFonts.inter(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData _build(AppColorTokens tokens, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: tokens.background,
      extensions: [tokens],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: tokens.primary,
        onPrimary: tokens.onPrimary,
        primaryContainer: tokens.primaryContainer,
        onPrimaryContainer: tokens.onPrimaryContainer,
        secondary: tokens.secondary,
        onSecondary: tokens.onSecondary,
        secondaryContainer: tokens.secondaryContainer,
        onSecondaryContainer: tokens.onSecondaryContainer,
        tertiary: tokens.tertiary,
        onTertiary: Colors.white,
        error: tokens.error,
        onError: tokens.onError,
        errorContainer: tokens.errorContainer,
        onErrorContainer: tokens.onErrorContainer,
        surface: tokens.surface,
        onSurface: tokens.onSurface,
        onSurfaceVariant: tokens.onSurfaceVariant,
        outline: tokens.outline,
        outlineVariant: tokens.outlineVariant,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(color: tokens.onSurface),
        headlineLarge: AppTextStyles.headlineLgMobile.copyWith(color: tokens.onSurface),
        headlineMedium: AppTextStyles.headlineMd.copyWith(color: tokens.onSurface),
        headlineSmall: AppTextStyles.headlineSm.copyWith(color: tokens.onSurface),
        bodyLarge: AppTextStyles.bodyLg.copyWith(color: tokens.onSurface),
        bodyMedium: AppTextStyles.bodyMd.copyWith(color: tokens.onSurface),
        bodySmall: AppTextStyles.bodySm.copyWith(color: tokens.onSurfaceVariant),
        labelLarge: AppTextStyles.labelLg.copyWith(color: tokens.onSurface),
        labelMedium: AppTextStyles.labelMd.copyWith(color: tokens.onSurface),
        labelSmall: AppTextStyles.labelSm.copyWith(color: tokens.onSurfaceVariant),
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
    );
  }

  static ThemeData light = _build(AppColorTokens.light, Brightness.light);
  static ThemeData dark = _build(AppColorTokens.dark, Brightness.dark);
}
