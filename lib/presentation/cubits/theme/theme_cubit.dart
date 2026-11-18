import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';

/// Manages Light/Dark [ThemeMode] with instant local persistence in Hive `settings_box`.
class ThemeCubit extends Cubit<ThemeMode> {
  final Box<String> _settingsBox;

  ThemeCubit({required Box<String> settingsBox})
    : _settingsBox = settingsBox,
      super(_readSavedTheme(settingsBox));

  bool get isDarkMode => state == ThemeMode.dark;

  static ThemeMode _readSavedTheme(Box<String> box) {
    final stored = box.get(AppConstants.themeModeKey);
    if (stored == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final nextMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setTheme(nextMode);
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(mode);
    await _settingsBox.put(
      AppConstants.themeModeKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}
