import 'package:flutter/material.dart';
import 'package:untitled/theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
  static const _buttonMinSize = Size(64, 50);
  static const _buttonPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 14,
  );

  static const _textTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    bodySmall: TextStyle(fontSize: 15, height: 1.5),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      height: 22 / 17,
    ),
  );

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.yellow,
      onPrimary: AppColors.charcoal,
      primaryContainer: AppColors.yellow,
      onPrimaryContainer: AppColors.charcoal,
      secondary: AppColors.teal,
      secondaryContainer: AppColors.tealSurface,
      onSecondaryContainer: AppColors.teal,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.charcoal,
      onSurfaceVariant: AppColors.gray,
      error: AppColors.error,
      onError: AppColors.white,
      outlineVariant: AppColors.border,
      outline: AppColors.charcoal,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: _textTheme.apply(
      bodyColor: AppColors.charcoal,
      displayColor: AppColors.charcoal,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.charcoal,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(_buttonMinSize),
        padding: const WidgetStatePropertyAll(_buttonPadding),
        shape: const WidgetStatePropertyAll(_buttonShape),
        textStyle: WidgetStatePropertyAll(_textTheme.labelLarge),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => switch (states) {
            _ when states.contains(WidgetState.disabled) => AppColors.lightGray,
            _ when states.contains(WidgetState.pressed) => AppColors.amber,
            _ => AppColors.yellow,
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.gray
              : AppColors.charcoal,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: _buttonMinSize,
        padding: _buttonPadding,
        shape: _buttonShape,
        textStyle: _textTheme.labelLarge,
        foregroundColor: AppColors.charcoal,
        side: const BorderSide(color: AppColors.charcoal, width: 2),
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.shadow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.charcoal,
        disabledForegroundColor: AppColors.gray,
        minimumSize: const Size(48, 48),
        shape: _buttonShape,
        textStyle: _textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.charcoal,
        minimumSize: const Size(48, 48),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.white,
      selectedColor: AppColors.yellow,
      checkmarkColor: AppColors.charcoal,
      labelStyle: _textTheme.bodyMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      side: const BorderSide(color: AppColors.border),
      shape: _buttonShape,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      modalBarrierColor: Color(0x99202020),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      selectedColor: AppColors.charcoal,
      selectedTileColor: AppColors.tealSurface,
      iconColor: AppColors.teal,
      minVerticalPadding: 16,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.teal,
      linearTrackColor: AppColors.tealBorder,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  // shortcut: the supplied design is light-only; add dark tokens with a dark design.
  static final dark = light;
}
