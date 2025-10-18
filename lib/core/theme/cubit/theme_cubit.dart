import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState(themeMode: ThemeMode.light)) {
    _loadThemePreference();
  }

  static const String _themePreferenceKey = 'isDarkMode';

  // Load saved theme preference
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themePreferenceKey) ?? false;
      emit(ThemeState(
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      ));
    } catch (e) {
      print('Error loading theme preference: $e');
      // Default to light mode on error
      emit(ThemeState(themeMode: ThemeMode.light));
    }
  }

  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    emit(ThemeState(themeMode: newMode));

    // Save preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePreferenceKey, newMode == ThemeMode.dark);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  // Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    emit(ThemeState(themeMode: mode));

    // Save preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePreferenceKey, mode == ThemeMode.dark);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  // Check if current theme is dark
  bool get isDarkMode => state.themeMode == ThemeMode.dark;
}






