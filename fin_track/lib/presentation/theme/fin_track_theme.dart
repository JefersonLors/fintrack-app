import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

part 'fin_track_color_scheme.dart';

class FinTrackTheme {
  const FinTrackTheme._();

  static ThemeData dark() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final baseTextTheme = GoogleFonts.config.allowRuntimeFetching
        ? GoogleFonts.manropeTextTheme(base.textTheme)
        : base.textTheme;
    final textTheme = baseTextTheme.apply(
      bodyColor: FinTrackColors.textSecondary,
      displayColor: FinTrackColors.textPrimary,
    );
    final scheme =
        const ColorScheme.dark(
          primary: FinTrackColors.primary,
          onPrimary: Color(0xFF101827),
          secondary: FinTrackColors.info,
          onSecondary: Color(0xFF101827),
          surface: FinTrackColors.surface,
          onSurface: FinTrackColors.textPrimary,
          error: FinTrackColors.danger,
          onError: FinTrackColors.textPrimary,
        ).copyWith(
          primaryContainer: FinTrackColors.surfaceAlt,
          onPrimaryContainer: FinTrackColors.textPrimary,
          surfaceContainerHighest: FinTrackColors.surfaceAlt,
          onSurfaceVariant: FinTrackColors.textMuted,
          outline: FinTrackColors.border,
          outlineVariant: FinTrackColors.border,
        );

    return base.copyWith(
      colorScheme: scheme,
      extensions: const [FinTrackColorScheme.dark],
      canvasColor: FinTrackColors.surfaceAlt,
      scaffoldBackgroundColor: FinTrackColors.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: FinTrackColors.background,
        foregroundColor: FinTrackColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: FinTrackColors.surface,
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: FinTrackColors.border),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: FinTrackColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: FinTrackColors.border),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: FinTrackColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: FinTrackColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: FinTrackColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: FinTrackColors.primary),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FinTrackColors.primary,
          foregroundColor: const Color(0xFF101827),
          disabledBackgroundColor: FinTrackColors.surfaceAlt,
          disabledForegroundColor: FinTrackColors.textMuted,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FinTrackColors.textSecondary,
          side: const BorderSide(color: FinTrackColors.border),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: FinTrackColors.border),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FinTrackColors.primary,
        linearTrackColor: FinTrackColors.border,
      ),
      dividerTheme: const DividerThemeData(color: FinTrackColors.border),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FinTrackColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: FinTrackColors.surfaceAlt,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: FinTrackColors.border),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(FinTrackColors.surfaceAlt),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.all(
            const BorderSide(color: FinTrackColors.border),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FinTrackColors.surfaceAlt,
        selectedColor: FinTrackColors.primary.withValues(alpha: 0.14),
        disabledColor: FinTrackColors.surface,
        side: const BorderSide(color: FinTrackColors.border),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: FinTrackColors.textSecondary,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: FinTrackColors.textPrimary,
        ),
        brightness: Brightness.dark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: FinTrackColors.textMuted,
        textColor: FinTrackColors.textPrimary,
        subtitleTextStyle: TextStyle(color: FinTrackColors.textMuted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: FinTrackColors.surface,
        selectedItemColor: FinTrackColors.primary,
        unselectedItemColor: FinTrackColors.textMuted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: FinTrackColors.surface,
        indicatorColor: FinTrackColors.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? FinTrackColors.textPrimary
                : FinTrackColors.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? FinTrackColors.primary : FinTrackColors.textMuted,
          );
        }),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: FinTrackColors.surfaceAlt,
        contentTextStyle: TextStyle(color: FinTrackColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        insetPadding: EdgeInsets.fromLTRB(16, 0, 16, 40),
      ),
    );
  }

  static ThemeData light() {
    const background = Color(0xFFF6F8FB);
    const surface = Color(0xFFFFFFFF);
    const surfaceAlt = Color(0xFFE8EDF4);
    const border = Color(0xFFD4DCE8);
    const borderStrong = Color(0xFFB8C5D6);
    const primary = Color(0xFF456F82);
    const info = Color(0xFF58798D);
    const danger = Color(0xFFB84F4F);
    const textPrimary = Color(0xFF243647);
    const textSecondary = Color(0xFF344154);
    const textMuted = Color(0xFF647184);

    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final baseTextTheme = GoogleFonts.config.allowRuntimeFetching
        ? GoogleFonts.manropeTextTheme(base.textTheme)
        : base.textTheme;
    final textTheme = baseTextTheme.apply(
      bodyColor: textSecondary,
      displayColor: textPrimary,
    );
    final scheme =
        const ColorScheme.light(
          primary: primary,
          onPrimary: Colors.white,
          secondary: info,
          onSecondary: Colors.white,
          surface: surface,
          onSurface: textPrimary,
          error: danger,
          onError: Colors.white,
        ).copyWith(
          primaryContainer: surfaceAlt,
          onPrimaryContainer: textPrimary,
          surfaceContainerHighest: surfaceAlt,
          onSurfaceVariant: textMuted,
          outline: border,
          outlineVariant: borderStrong,
        );

    return base.copyWith(
      colorScheme: scheme,
      extensions: const [FinTrackColorScheme.light],
      canvasColor: surfaceAlt,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: borderStrong),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: borderStrong),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: primary),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: surfaceAlt,
          disabledForegroundColor: textMuted,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textSecondary,
          side: const BorderSide(color: borderStrong),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: borderStrong),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: borderStrong,
      ),
      dividerTheme: const DividerThemeData(color: borderStrong),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: borderStrong),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.all(const BorderSide(color: borderStrong)),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        selectedColor: primary.withValues(alpha: 0.14),
        disabledColor: surface,
        side: const BorderSide(color: borderStrong),
        labelStyle: textTheme.labelLarge?.copyWith(color: textSecondary),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: textPrimary),
        brightness: Brightness.light,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textMuted,
        textColor: textPrimary,
        subtitleTextStyle: TextStyle(color: textMuted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? textPrimary : textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primary : textMuted);
        }),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        insetPadding: EdgeInsets.fromLTRB(16, 0, 16, 40),
      ),
    );
  }
}
