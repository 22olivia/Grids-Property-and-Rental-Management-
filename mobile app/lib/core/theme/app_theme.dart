import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: RC.teal,
      primary: RC.teal,
      onPrimary: Colors.white,
      secondary: RC.navy,
      onSecondary: Colors.white,
      surface: RC.surface,
      onSurface: RC.textPrimary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: RC.bg,
      fontFamily: 'Roboto',
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: RC.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: RT.h2,
        iconTheme: IconThemeData(color: RC.navy, size: 22),
      ),
      dividerTheme: const DividerThemeData(
        color: RC.border,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displaySmall: RT.display,
        headlineSmall: RT.h1,
        titleLarge: RT.h2,
        titleMedium: RT.title,
        bodyMedium: RT.body,
        bodySmall: RT.caption,
        labelSmall: RT.label,
      ),
      iconTheme: const IconThemeData(color: RC.navy, size: 22),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? RC.teal : RC.borderStrong,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: RC.navy,
        contentTextStyle: RT.bodyStrong.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: RR.button),
        insetPadding: const EdgeInsets.all(RS.x16),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: RC.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
