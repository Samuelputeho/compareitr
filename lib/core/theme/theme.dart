import 'package:flutter/material.dart';

import 'app_pallete.dart';

class AppTheme {
  static _border([Color color = AppPallete.lightGreyColor]) =>
      OutlineInputBorder(
        borderSide: BorderSide(
          color: color,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      );

  static _borderDark([Color color = AppPallete.borderColorDark]) =>
      OutlineInputBorder(
        borderSide: BorderSide(
          color: color,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      );

  static final lightThemeMode = ThemeData.light().copyWith(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppPallete.backgroundColor,
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPallete.backgroundColor,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    chipTheme: const ChipThemeData(
      color: WidgetStatePropertyAll(
        AppPallete.backgroundColor,
      ),
      side: BorderSide.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppPallete.lightGreyColor,
      filled: true,
      contentPadding: const EdgeInsets.all(15),
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(AppPallete.primaryColor),
      errorBorder: _border(AppPallete.primaryColor),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppPallete.primaryColor,
      unselectedItemColor: AppPallete.secondaryColor,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.black54),
    ),
  );

  static final darkThemeMode = ThemeData.dark().copyWith(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppPallete.backgroundColorDark,
    cardColor: AppPallete.cardColorDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPallete.cardColorDark,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    chipTheme: const ChipThemeData(
      color: WidgetStatePropertyAll(
        AppPallete.cardColorDark,
      ),
      side: BorderSide.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppPallete.lightGreyColorDark,
      filled: true,
      contentPadding: const EdgeInsets.all(15),
      border: _borderDark(),
      enabledBorder: _borderDark(),
      focusedBorder: _borderDark(AppPallete.primaryColorDark),
      errorBorder: _borderDark(Colors.red),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppPallete.cardColorDark,
      selectedItemColor: AppPallete.primaryColorDark,
      unselectedItemColor: AppPallete.secondaryColorDark,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppPallete.textColorDark),
      bodyMedium: TextStyle(color: AppPallete.textColorDark),
      bodySmall: TextStyle(color: AppPallete.secondaryColorDark),
    ),
  );
}
