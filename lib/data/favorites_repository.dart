import 'package:shared_preferences/shared_preferences.dart';

abstract class FavoritesStore {
  Future<List<String>?> read();
  Future<void> write(List<String> values);
}

class SharedPreferencesFavoritesStore implements FavoritesStore {
  static const storageKey = 'ecolens_species_favorites_v1';
  final SharedPreferencesAsync? preferences;
  SharedPreferencesAsync get _preferences =>
      preferences ?? SharedPreferencesAsync();

  SharedPreferencesFavoritesStore({this.preferences});

  @override
  Future<List<String>?> read() async {
    try {
      return await _preferences.getStringList(storageKey);
    } on TypeError {
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(List<String> values) =>
      _preferences.setStringList(storageKey, values);
}

/// Guarda somente nomes científicos; não armazena fichas nem fotografias.
class FavoritesRepository {
  final FavoritesStore _store;
  // Serializa alterações também entre instâncias usadas por rotas diferentes.
  static final _pending = Expando<Future<void>>();
  static final FavoritesStore _defaultStore = SharedPreferencesFavoritesStore();

  FavoritesRepository({FavoritesStore? store})
    : _store = store ?? _defaultStore;

  static String normalize(String name) => name.trim().toLowerCase();

  static bool _valid(String name) =>
      RegExp(r'^[a-z][a-z-]*(?: [a-z][a-z.-]*)+$').hasMatch(name);

  Future<Set<String>> load() async => {
    for (final value in await _store.read() ?? <String>[])
      if (_valid(normalize(value))) normalize(value),
  };

  Future<void> setFavorite(String scientificName, bool favorite) {
    final name = normalize(scientificName);
    if (!_valid(name)) {
      return Future<void>.error(ArgumentError.value(scientificName));
    }
    final operation = (_pending[_store] ?? Future<void>.value()).then((
      _,
    ) async {
      final names = await load();
      if (favorite) {
        names.add(name);
      } else {
        names.remove(name);
      }
      await _store.write(names.toList()..sort());
    });
    _pending[_store] = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
