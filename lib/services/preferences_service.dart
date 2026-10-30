import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _themeKey = 'ecolens_theme_mode';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  // Recupera o tema salvo no dispositivo
  Future<String?> loadThemeMode() async {
    return await _preferences.getString(_themeKey);
  }

  // Salva a preferência escolhida pelo usuário
  Future<void> saveThemeMode(String themeMode) async {
    await _preferences.setString(_themeKey, themeMode);
  }
}
