import 'dart:convert';

import 'package:ecolens/data/share_identification_draft_store.dart';
import 'package:ecolens/models/community_share_draft.dart';
import 'package:ecolens/models/sighting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final photo = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/pL8AAAAASUVORK5CYII=',
);
const municipality = Municipality('test-city', 'São Roque', 'SP', -23.5, -47.1);
CommunityShareDraft draft(IdentificationOrigin origin) => CommunityShareDraft(
  photo: photo,
  hypothesis: 'Hipótese revisada',
  origin: origin,
  observedOn: DateTime(2026, 11, 5),
  municipalityId: municipality.id,
  municipalities: const [municipality],
  notes: 'Observações mantidas',
);

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  for (final origin in IdentificationOrigin.values) {
    test(
      'new store restores every field and photo for origin ${origin.name}',
      () async {
        await ShareIdentificationDraftStore().save(draft(origin));
        final restored = (await ShareIdentificationDraftStore().load())!;
        expect(restored.photo, photo);
        expect(restored.hypothesis, 'Hipótese revisada');
        expect(restored.origin, origin);
        expect(restored.observedOn, DateTime(2026, 11, 5));
        expect(restored.municipalityId, municipality.id);
        expect(restored.municipalities.single.label, 'São Roque/SP');
        expect(restored.notes, 'Observações mantidas');
        await ShareIdentificationDraftStore().clear();
        expect(await ShareIdentificationDraftStore().load(), isNull);
      },
    );
  }

  test(
    'checkpoint expires after 24 hours and removes only its own key',
    () async {
      var now = DateTime.utc(2026, 11, 6);
      final store = ShareIdentificationDraftStore(now: () => now);
      final prefs = SharedPreferencesAsync();
      await prefs.setString('unrelated-history', 'kept');
      await store.save(draft(IdentificationOrigin.ai));
      now = now.add(const Duration(hours: 25));
      expect(await store.load(), isNull);
      expect(
        await prefs.getString(ShareIdentificationDraftStore.storageKey),
        isNull,
      );
      expect(await prefs.getString('unrelated-history'), 'kept');
    },
  );

  test('corruption, incompatible version and invalid fields cannot restore or publish', () async {
    final prefs = SharedPreferencesAsync();
    final valid = {
      'version': 1,
      'saved_at': DateTime.now().toIso8601String(),
      'draft': draft(IdentificationOrigin.ai).toJson(),
    };
    final invalids = <String>[
      'not-json',
      'null',
      '[]',
      jsonEncode({...valid, 'version': 2}),
      jsonEncode({
        ...valid,
        'draft': {
          ...draft(IdentificationOrigin.ai).toJson(),
          'photo': 'broken',
        },
      }),
      jsonEncode({
        ...valid,
        'draft': {
          ...draft(IdentificationOrigin.ai).toJson(),
          'origin': 'invalid',
        },
      }),
      jsonEncode({
        ...valid,
        'draft': {
          ...draft(IdentificationOrigin.ai).toJson(),
          'municipality_id': 'unknown',
        },
      }),
      jsonEncode({
        ...valid,
        'draft': {
          ...draft(IdentificationOrigin.ai).toJson(),
          'notes': 'x' * 2001,
        },
      }),
    ];
    for (final encoded in invalids) {
      await prefs.setString(ShareIdentificationDraftStore.storageKey, encoded);
      expect(await ShareIdentificationDraftStore().load(), isNull);
      expect(
        await prefs.getString(ShareIdentificationDraftStore.storageKey),
        isNull,
      );
    }
  });

  test(
    'checkpoint contains no authentication or navigation callback data',
    () async {
      await ShareIdentificationDraftStore().save(
        draft(IdentificationOrigin.ai),
      );
      final encoded = (await SharedPreferencesAsync().getString(
        ShareIdentificationDraftStore.storageKey,
      ))!;
      final json = jsonDecode(encoded) as Map;
      expect(json.keys, unorderedEquals(['version', 'saved_at', 'draft']));
      expect(encoded, isNot(contains('access_token')));
      expect(encoded, isNot(contains('refresh_token')));
      expect(encoded, isNot(contains('auth/callback')));
    },
  );
}
