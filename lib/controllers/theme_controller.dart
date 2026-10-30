import 'package:flutter/material.dart';

import '../services/preferences_service.dart';

class ThemeController extends ChangeNotifier {
  final PreferencesService _preferencesService;

  ThemeController({PreferencesService? preferencesService})
    : _preferencesService = preferencesService ?? PreferencesService();

  // Tema atual do aplicativo
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // Recupera a preferência salva
  Future<void> loadTheme() async {
    final savedTheme = await _preferencesService.loadThemeMode();

    final mode = switch (savedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();
  }

  // Altera e salva o tema escolhido
  Future<void> changeTheme(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    await _preferencesService.saveThemeMode(mode.name);
  }
}
