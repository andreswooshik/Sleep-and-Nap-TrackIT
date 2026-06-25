import 'dart:ui';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Colors
// ---------------------------------------------------------------------------
abstract final class LullabyColors {
  // Surfaces
  static const surface = Color(0xFF0E0F34);
  static const surfaceContainer = Color(0xFF1A1C40);
  static const surfaceContainerLow = Color(0xFF16173C);
  static const surfaceContainerHigh = Color(0xFF25264B);
  static const surfaceContainerHighest = Color(0xFF303157);

  // Primary
  static const primary = Color(0xFFBEC2FF);
  static const primaryContainer = Color(0xFF8B93FF);
  static const onPrimary = Color(0xFF181E8B);
  static const onPrimaryContainer = Color(0xFF1D238F);

  // Secondary
  static const secondary = Color(0xFFC1C1FF);
  static const secondaryContainer = Color(0xFF2A1CD7);
  static const onSecondaryContainer = Color(0xFFADAEFF);

  // Tertiary
  static const tertiary = Color(0xFFFFB3B3);
  static const tertiaryContainer = Color(0xFFD28A8A);

  // On-surface
  static const onSurface = Color(0xFFE1E0FF);
  static const onSurfaceVariant = Color(0xFFC6C5D5);

  // Outline
  static const outline = Color(0xFF908F9E);
  static const outlineVariant = Color(0xFF464652);

  // Error
  static const error = Color(0xFFFFB4AB);

  // Glass
  static const glassBackground = Color(0x66303157);
  static const glassBorder = Color(0x19908F9E);
}

// ---------------------------------------------------------------------------
// Decorations
// ---------------------------------------------------------------------------
abstract final class LullabyDecorations {
  static BoxDecoration glassCard({double borderRadius = 16}) => BoxDecoration(
        color: LullabyColors.glassBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: LullabyColors.glassBorder),
      );

  static BoxDecoration gradientButton({double borderRadius = 14}) =>
      BoxDecoration(
        gradient: const LinearGradient(
          colors: [LullabyColors.secondaryContainer, LullabyColors.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: LullabyColors.secondaryContainer.withValues(alpha: 0.3),
            blurRadius: 40,
          ),
        ],
      );

  static InputDecoration inputDecoration({
    required String label,
    String? errorText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: LullabyColors.primary)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: LullabyColors.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LullabyColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LullabyColors.primaryContainer, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: LullabyColors.error.withValues(alpha: 0.6)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LullabyColors.error, width: 2),
      ),
      labelStyle: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 14),
      errorStyle: const TextStyle(color: LullabyColors.error, fontSize: 12),
    );
  }
}

// ---------------------------------------------------------------------------
// GlassCard widget
// ---------------------------------------------------------------------------
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: LullabyDecorations.glassCard(borderRadius: borderRadius),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AmbientGlow widget
// ---------------------------------------------------------------------------
class AmbientGlow extends StatelessWidget {
  const AmbientGlow({
    super.key,
    required this.color,
    required this.alignment,
    this.radius = 300,
  });

  final Color color;
  final Alignment alignment;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Container(
            width: radius,
            height: radius,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ThemeData
// ---------------------------------------------------------------------------
ThemeData buildLullabyTheme() {
  final colorScheme = const ColorScheme.dark().copyWith(
    surface: LullabyColors.surface,
    primary: LullabyColors.primary,
    primaryContainer: LullabyColors.primaryContainer,
    onPrimary: LullabyColors.onPrimary,
    onPrimaryContainer: LullabyColors.onPrimaryContainer,
    secondary: LullabyColors.secondary,
    secondaryContainer: LullabyColors.secondaryContainer,
    onSecondaryContainer: LullabyColors.onSecondaryContainer,
    tertiary: LullabyColors.tertiary,
    tertiaryContainer: LullabyColors.tertiaryContainer,
    error: LullabyColors.error,
    onSurface: LullabyColors.onSurface,
    onSurfaceVariant: LullabyColors.onSurfaceVariant,
    outline: LullabyColors.outline,
    outlineVariant: LullabyColors.outlineVariant,
    surfaceContainerHighest: LullabyColors.surfaceContainerHighest,
  );

  const headlineStyle = TextStyle(fontWeight: FontWeight.w800, color: LullabyColors.onSurface);
  const bodyStyle = TextStyle(fontWeight: FontWeight.w400, color: LullabyColors.onSurfaceVariant);

  final textTheme = ThemeData.dark().textTheme.copyWith(
    displayLarge: headlineStyle.copyWith(fontSize: 57),
    displayMedium: headlineStyle.copyWith(fontSize: 45),
    displaySmall: headlineStyle.copyWith(fontSize: 36, fontWeight: FontWeight.w900),
    headlineLarge: headlineStyle.copyWith(fontSize: 32, letterSpacing: -0.5),
    headlineMedium: headlineStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
    headlineSmall: headlineStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
    titleLarge: headlineStyle.copyWith(fontSize: 22),
    titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: LullabyColors.onSurface),
    titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LullabyColors.onSurface),
    bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: LullabyColors.onSurface),
    bodyMedium: bodyStyle.copyWith(fontSize: 14),
    bodySmall: bodyStyle.copyWith(fontSize: 12),
    labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LullabyColors.onSurface),
    labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: LullabyColors.onSurfaceVariant),
    labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: LullabyColors.onSurfaceVariant),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: LullabyColors.surface,
    textTheme: textTheme,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LullabyColors.primaryContainer,
        foregroundColor: LullabyColors.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LullabyColors.primary,
        side: const BorderSide(color: LullabyColors.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: LullabyColors.primaryContainer,
      inactiveTrackColor: LullabyColors.surfaceContainerHighest,
      thumbColor: LullabyColors.primary,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: LullabyColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: LullabyColors.surfaceContainer,
      headerBackgroundColor: LullabyColors.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: LullabyColors.surfaceContainer,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(LullabyColors.surfaceContainerHigh),
      ),
    ),
  );
}
