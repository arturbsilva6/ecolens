import 'package:shared_preferences/shared_preferences.dart';

/// Autores bloqueados neste aparelho: os registros deles deixam de aparecer
/// na Comunidade. Fica só no celular; o autor não é avisado.
class BlockedAuthorsRepository {
  BlockedAuthorsRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'community_blocked_authors';
  final SharedPreferencesAsync _preferences;

  Future<Set<String>> load() async =>
      (await _preferences.getStringList(_key) ?? const <String>[]).toSet();

  Future<void> block(String ownerId) async {
    final all = await load()..add(ownerId);
    await _preferences.setStringList(_key, all.toList()..sort());
  }

  Future<void> clear() => _preferences.remove(_key);
}
