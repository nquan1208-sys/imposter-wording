import 'package:untitled/constants/app_radii.dart';
import 'package:flutter/material.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/theme/app_effects.dart';

class AppTheme {
  AppTheme._();

  static const _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.control)),
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
      height: 1.4,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    labelMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    labelSmall: TextStyle(fontSize: 15, height: 1.5),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    bodySmall: TextStyle(fontSize: 15, height: 1.5),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
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
      height: 1.4,
    ),
  );

  static final light = ThemeData(
    useMaterial3: true,
    fontFamily: 'BeVietnamPro',
    materialTapTargetSize: MaterialTapTargetSize.padded,
    focusColor: AppColors.tealBorder,
    hoverColor: AppColors.lightGray,
    disabledColor: AppColors.gray,
    colorScheme: const ColorScheme.light(
      primary: AppColors.yellow,
      onPrimary: AppColors.charcoal,
      primaryContainer: AppColors.cream,
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
      errorContainer: AppColors.errorSurface,
      onErrorContainer: AppColors.error,
      outlineVariant: AppColors.border,
      outline: AppColors.charcoal,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: _textTheme.apply(
      fontFamily: 'BeVietnamPro',
      bodyColor: AppColors.charcoal,
      displayColor: AppColors.charcoal,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.charcoal,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontFamily: 'BeVietnamPro',
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.charcoal,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(_buttonMinSize),
        padding: const WidgetStatePropertyAll(_buttonPadding),
        shape: const WidgetStatePropertyAll(_buttonShape),
        textStyle: WidgetStatePropertyAll(_textTheme.labelLarge),
        animationDuration: AppEffects.quick,
        backgroundBuilder: (context, states, child) => Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.control),
            gradient:
                states.contains(WidgetState.disabled) ||
                    states.contains(WidgetState.pressed)
                ? null
                : AppEffects.heroGradient,
            color: states.contains(WidgetState.disabled)
                ? AppColors.lightGray
                : AppColors.amber,
          ),
          child: child,
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? const BorderSide(color: AppColors.charcoal, width: 2)
              : BorderSide.none,
        ),
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
        disabledForegroundColor: AppColors.gray,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.shadow,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style:
          TextButton.styleFrom(
            foregroundColor: AppColors.charcoal,
            disabledForegroundColor: AppColors.gray,
            minimumSize: const Size(48, 48),
            shape: _buttonShape,
            textStyle: _textTheme.labelLarge,
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? const BorderSide(color: AppColors.charcoal, width: 2)
                  : BorderSide.none,
            ),
          ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style:
          IconButton.styleFrom(
            foregroundColor: AppColors.charcoal,
            minimumSize: const Size(48, 48),
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? const BorderSide(color: AppColors.charcoal, width: 2)
                  : BorderSide.none,
            ),
          ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.white,
      selectedColor: AppColors.tealSurface,
      checkmarkColor: AppColors.teal,
      labelStyle: _textTheme.bodyMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      side: const BorderSide(color: AppColors.border),
      shape: const StadiumBorder(),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      modalBarrierColor: Color(0x99202020),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.hero),
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.hero)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      selectedColor: AppColors.charcoal,
      selectedTileColor: AppColors.tealSurface,
      iconColor: AppColors.teal,
      minVerticalPadding: 16,
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      titleTextStyle: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontWeight: FontWeight.w500,
        fontSize: 17,
        height: 1.4,
        color: AppColors.charcoal,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 15,
        height: 1.5,
        color: AppColors.gray,
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.lightGray,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      constraints: const BoxConstraints(minHeight: 48),
      labelStyle: _textTheme.bodyMedium?.copyWith(color: AppColors.gray),
      hintStyle: _textTheme.bodyMedium?.copyWith(color: AppColors.gray),
      floatingLabelStyle: _textTheme.bodyMedium?.copyWith(
        color: AppColors.charcoal,
      ),
      errorStyle: _textTheme.bodySmall?.copyWith(color: AppColors.error),
      errorMaxLines: 4,
      helperMaxLines: 4,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.gray
            : states.contains(WidgetState.selected)
            ? AppColors.charcoal
            : AppColors.gray,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.yellow
            : AppColors.lightGray,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.charcoal
            : AppColors.gray,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.teal
            : AppColors.white,
      ),
      checkColor: const WidgetStatePropertyAll(AppColors.white),
      side: const BorderSide(color: AppColors.gray, width: 2),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    ),
    radioTheme: const RadioThemeData(
      fillColor: WidgetStatePropertyAll(AppColors.teal),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.charcoal,
      unselectedLabelColor: AppColors.gray,
      labelStyle: _textTheme.titleMedium,
      unselectedLabelStyle: _textTheme.titleMedium,
      indicator: BoxDecoration(
        gradient: AppEffects.selectedGradient,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.tealBorder),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelPadding: const EdgeInsets.symmetric(horizontal: 24),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.teal,
      linearTrackColor: AppColors.tealBorder,
      linearMinHeight: 6,
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.charcoal,
      contentTextStyle: _textTheme.bodyMedium?.copyWith(color: AppColors.white),
      behavior: SnackBarBehavior.floating,
      shape: _buttonShape,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  // shortcut: this palette is light-only; add dark tokens with a dark design.
  static final dark = light;
}
