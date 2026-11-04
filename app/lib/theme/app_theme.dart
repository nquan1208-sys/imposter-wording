import 'package:untitled/constants/app_radii.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    labelSmall: TextStyle(fontSize: 14, height: 1.5),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    bodySmall: TextStyle(fontSize: 14, height: 1.5),
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
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
  );

  static final dark = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'BeVietnamPro',
    materialTapTargetSize: MaterialTapTargetSize.padded,
    focusColor: AppColors.secondaryAction,
    hoverColor: AppColors.secondaryAction,
    disabledColor: AppColors.disabledText,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.selection,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.accentText,
      secondaryContainer: AppColors.selection,
      onSecondaryContainer: AppColors.accentText,
      onSecondary: AppColors.canvas,
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceRaised,
      surfaceContainerLow: AppColors.canvas,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textMuted,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorSurface,
      onErrorContainer: AppColors.error,
      outlineVariant: AppColors.border,
      outline: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: _textTheme.apply(
      fontFamily: 'BeVietnamPro',
      bodyColor: AppColors.textBody,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.textPrimary,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.canvas,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontFamily: 'BeVietnamPro',
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(_buttonMinSize),
        padding: const WidgetStatePropertyAll(_buttonPadding),
        shape: const WidgetStatePropertyAll(_buttonShape),
        textStyle: WidgetStatePropertyAll(_textTheme.labelLarge),
        animationDuration: AppEffects.quick,
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? const BorderSide(color: AppColors.onPrimary, width: 2)
              : BorderSide.none,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => switch (states) {
            _ when states.contains(WidgetState.disabled) =>
              AppColors.disabledSurface,
            _ when states.contains(WidgetState.pressed) =>
              AppColors.primaryPressed,
            _ => AppColors.primary,
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.disabledText
              : AppColors.onPrimary,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            minimumSize: _buttonMinSize,
            padding: _buttonPadding,
            shape: _buttonShape,
            textStyle: _textTheme.labelLarge,
            foregroundColor: AppColors.textPrimary,
            backgroundColor: AppColors.secondaryAction,
            disabledForegroundColor: AppColors.disabledText,
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.focused)
                    ? AppColors.focus
                    : AppColors.border,
                width: states.contains(WidgetState.focused) ? 2 : 1,
              ),
            ),
          ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
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
            foregroundColor: AppColors.textPrimary,
            disabledForegroundColor: AppColors.disabledText,
            minimumSize: const Size(48, 48),
            shape: _buttonShape,
            textStyle: _textTheme.labelLarge,
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? const BorderSide(color: AppColors.focus, width: 2)
                  : BorderSide.none,
            ),
          ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style:
          IconButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(48, 48),
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? const BorderSide(color: AppColors.focus, width: 2)
                  : BorderSide.none,
            ),
          ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.selection,
      checkmarkColor: AppColors.accentText,
      labelStyle: _textTheme.bodyMedium?.copyWith(color: AppColors.textBody),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      side: const BorderSide(color: AppColors.border),
      shape: const StadiumBorder(),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      modalBarrierColor: AppColors.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.hero),
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.hero)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      selectedColor: AppColors.textPrimary,
      selectedTileColor: AppColors.selection,
      iconColor: AppColors.accentText,
      minVerticalPadding: 16,
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      titleTextStyle: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontWeight: FontWeight.w500,
        fontSize: 18,
        height: 1.4,
        color: AppColors.textPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 14,
        height: 1.5,
        color: AppColors.textMuted,
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.surfaceRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      constraints: const BoxConstraints(minHeight: 48),
      labelStyle: _textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      hintStyle: _textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      floatingLabelStyle: _textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
      ),
      errorStyle: _textTheme.bodySmall?.copyWith(color: AppColors.error),
      errorMaxLines: 4,
      helperMaxLines: 4,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        borderSide: const BorderSide(color: AppColors.focus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.textMuted
            : states.contains(WidgetState.selected)
            ? AppColors.onPrimary
            : AppColors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.disabledSurface
            : states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.surfaceRaised,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.onPrimary
            : AppColors.textMuted,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.disabledSurface
            : states.contains(WidgetState.selected)
            ? AppColors.accentText
            : AppColors.surface,
      ),
      checkColor: const WidgetStatePropertyAll(AppColors.canvas),
      side: const BorderSide(color: AppColors.textMuted, width: 2),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.disabledText
            : AppColors.accentText,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.textPrimary,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle: _textTheme.titleMedium,
      unselectedLabelStyle: _textTheme.titleMedium,
      indicator: BoxDecoration(
        color: AppColors.selection,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.selectionBorder),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelPadding: const EdgeInsets.symmetric(horizontal: 24),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accentText,
      linearTrackColor: AppColors.selection,
      linearMinHeight: 6,
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceRaised,
      contentTextStyle: _textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
      ),
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
}
