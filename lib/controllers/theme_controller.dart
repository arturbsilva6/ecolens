import 'package:flutter/material.dart';

import '../services/preferences_service.dart';

class ThemeController extends ChangeNotifier {
  final PreferencesService _preferencesService;

  ThemeController({PreferencesService? preferencesService})
    : _preferencesService = preferencesService ?? PreferencesService();

  // Tema atual do aplicativo
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Tamanhos de texto oferecidos em Acessibilidade.
  static const textScales = <double>[1.15, 1.3];

  // Nulo: só o tamanho de fonte do Android; os demais o ampliam.
  double? _textScale;

  double? get textScale => _textScale;

  // Recupera a preferência salva
  Future<void> loadTheme() async {
    final savedTheme = await _preferencesService.loadThemeMode();

    final mode = switch (savedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    double? scale;
    try {
      final saved = await _preferencesService.loadTextScale();
      if (saved != null && textScales.contains(saved)) scale = saved;
    } catch (_) {
      // Sem preferência salva, o app segue o Android.
    }

    if (_themeMode == mode && _textScale == scale) return;

    _themeMode = mode;
    _textScale = scale;
    notifyListeners();
  }

  Future<void> changeTextScale(double? scale) async {
    if (scale != null && !textScales.contains(scale)) return;
    if (_textScale == scale) return;

    _textScale = scale;
    notifyListeners();

    await _preferencesService.saveTextScale(scale);
  }

  // Altera e salva o tema escolhido
  Future<void> changeTheme(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    await _preferencesService.saveThemeMode(mode.name);
  }
}
