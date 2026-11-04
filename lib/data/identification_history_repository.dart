import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_identification_result.dart';
import '../models/identification_history_entry.dart';

/// Armazenamento local. Não sincroniza com Supabase ou serviços externos.
abstract class IdentificationHistoryStore {
  Future<List<String>?> read();
  Future<void> write(List<String> values);
}

class SharedPreferencesHistoryStore implements IdentificationHistoryStore {
  static const storageKey = 'ecolens_history_v1';
  final SharedPreferencesAsync preferences;

  SharedPreferencesHistoryStore({SharedPreferencesAsync? preferences})
    : preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<List<String>?> read() => preferences.getStringList(storageKey);

  @override
  Future<void> write(List<String> values) =>
      preferences.setStringList(storageKey, values);
}

class IdentificationHistoryRepository {
  static const maxEntries = 50;

  final IdentificationHistoryStore _store;
  final DateTime Function() _now;

  IdentificationHistoryRepository({
    IdentificationHistoryStore? store,
    DateTime Function()? now,
  }) : _store = store ?? SharedPreferencesHistoryStore(),
       _now = now ?? DateTime.now;

  Future<List<IdentificationHistoryEntry>> load() async {
    final values = await _store.read() ?? <String>[];
    final entries = <IdentificationHistoryEntry>[];
    for (final encoded in values) {
      try {
        final value = jsonDecode(encoded);
        if (value is! Map<String, dynamic>) continue;
        entries.add(IdentificationHistoryEntry.fromJson(value));
      } on FormatException {
        // Um item corrompido não impede a leitura dos demais.
      } on TypeError {
        // Ignora registros com tipos incompatíveis.
      }
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries.take(maxEntries).toList(growable: false);
  }

  Future<IdentificationHistoryEntry> save(
    AiIdentificationResult result, {
    required bool matchedCatalog,
  }) async {
    final entry = IdentificationHistoryEntry.fromResult(
      result,
      createdAt: _now(),
      matchedCatalog: matchedCatalog,
    );
    final existing = await load();
    await _store.write([
      entry,
      ...existing.where((item) => item.id != entry.id),
    ].take(maxEntries).map((item) => jsonEncode(item.toJson())).toList());
    return entry;
  }

  Future<void> delete(String id) async {
    final existing = await load();
    await _store.write(
      existing
          .where((entry) => entry.id != id)
          .map((entry) => jsonEncode(entry.toJson()))
          .toList(),
    );
  }

  Future<void> clear() => _store.write(<String>[]);
}
