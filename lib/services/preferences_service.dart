import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _themeKey = 'ecolens_theme_mode';
  static const String _textScaleKey = 'ecolens_text_scale';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  // Recupera o tema salvo no dispositivo
  Future<String?> loadThemeMode() async {
    return await _preferences.getString(_themeKey);
  }

  // Salva a preferência escolhida pelo usuário
  Future<void> saveThemeMode(String themeMode) async {
    await _preferences.setString(_themeKey, themeMode);
  }

  /// Escala do texto escolhida no app; nulo segue o Android.
  Future<double?> loadTextScale() => _preferences.getDouble(_textScaleKey);

  Future<void> saveTextScale(double? scale) => scale == null
      ? _preferences.remove(_textScaleKey)
      : _preferences.setDouble(_textScaleKey, scale);
}
