import 'dart:convert';
import 'dart:typed_data';

import 'package:ecolens/data/community_repository.dart';
import 'package:ecolens/data/supabase_community_repository.dart';
import 'package:ecolens/models/sighting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/community_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SupabaseCommunityRepository repository;
  late List<http.Request> requests;
  late http.Response Function(http.Request) handler;
  final draft = SightingDraft(
    observedOn: DateTime(2026, 10, 1),
    municipalityId: '3550605',
  );
  Future<void> session({bool anonymous = false}) async {
    await client.auth.setInitialSession(
      jsonEncode({
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': '10000000-0000-4000-8000-000000000001',
          'aud': 'authenticated',
          'created_at': '2026-11-04T00:00:00Z',
          'is_anonymous': anonymous,
        },
      }),
    );
  }

  setUp(() {
    requests = [];
    handler = (_) =>
        http.Response('[]', 200, headers: {'content-type': 'application/json'});
    client = SupabaseClient(
      'https://example.invalid',
      'test-public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((r) async {
        requests.add(r);
        final response = handler(r);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: r,
        );
      }),
    );
    repository = SupabaseCommunityRepository(
      clientProvider: () async => client,
    );
  });
  tearDown(() async {
    await client.dispose();
  });
  test('visitor and anonymous session cannot publish or mutate', () async {
    for (final anonymous in [false, true]) {
      if (anonymous) await session(anonymous: true);
      expect(await repository.accountId(), isNull);
      await expectLater(
        repository.create(draft, Uint8List(1)),
        throwsA(isA<CommunityFailure>()),
      );
      await expectLater(
        repository.update(fixture(), draft),
        throwsA(isA<CommunityFailure>()),
      );
      await expectLater(
        repository.delete(fixture()),
        throwsA(isA<CommunityFailure>()),
      );
    }
    expect(requests, isEmpty);
  });
  test('expired SDK session is rejected before any write or upload', () async {
    await session();
    client.auth.currentSession!.expiresAt = 1;
    expect(await repository.accountId(), isNull);
    await expectLater(
      repository.create(draft, Uint8List(1)),
      throwsA(isA<CommunityFailure>()),
    );
    expect(requests, isEmpty);
  });
  test(
    'query restricts published rows, municipality, filter and pagination',
    () async {
      await repository.page(
        offset: 20,
        municipalityId: '3550605',
        species: 'a%b',
      );
      final query = requests.single.url.queryParameters;
      expect(query['status'], 'eq.published');
      expect(query['municipality_id'], 'eq.3550605');
      expect(query['species_label'], r'ilike.%a\%b%');
      expect(query['offset'], '20');
      expect(query['limit'], '20');
    },
  );
  test('missing migration is explicit and leaks no raw server data', () async {
    handler = (_) => http.Response(
      jsonEncode({'code': 'PGRST205', 'message': 'internal sensitive detail'}),
      404,
    );
    await expectLater(
      repository.page(),
      throwsA(
        isA<CommunityFailure>().having(
          (e) => e.message,
          'message',
          allOf(contains('não configurada'), isNot(contains('sensitive'))),
        ),
      ),
    );
  });
  test(
    'upload failure retains recoverable draft and never announces publication',
    () async {
      await session();
      handler = (r) => r.url.path.startsWith('/storage/')
          ? http.Response('{"message":"upload failed"}', 400)
          : http.Response('', 201);
      await expectLater(
        repository.create(draft, Uint8List(1)),
        throwsA(
          isA<CommunityFailure>().having(
            (e) => e.message,
            'message',
            contains('Meus registros'),
          ),
        ),
      );
      expect(requests.map((r) => r.method).toList(), ['POST', 'POST']);
      final inserted = jsonDecode(requests.first.body) as Map;
      expect(inserted['status'], 'draft');
      expect(inserted.containsKey('latitude'), false);
      expect(inserted['photo_path'], endsWith('/photo.png'));
    },
  );
  test(
    'uncertain publication retains image and row for reconciliation',
    () async {
      await session();
      handler = (r) {
        if (r.method == 'PATCH') {
          return http.Response('{"message":"unavailable"}', 400);
        }
        return http.Response(
          '{"Key":"community-photos/test.png"}',
          201,
          headers: {'content-type': 'application/json'},
        );
      };
      await expectLater(
        repository.create(draft, Uint8List(1)),
        throwsA(isA<CommunityFailure>()),
      );
      expect(requests.map((r) => r.method), ['POST', 'POST', 'PATCH']);
      expect(jsonDecode(requests.last.body), {'status': 'published'});
    },
  );
  test(
    'confirmed publication creates draft, uploads PNG and publishes once',
    () async {
      await session();
      handler = (r) {
        if (r.url.path.startsWith('/storage/')) {
          expect(r.headers['content-type'], startsWith('multipart/form-data'));
          expect(r.body, contains('content-type: image/png'));
          expect(r.headers['x-upsert'], 'false');
          return http.Response('{"Key":"community-photos/test.png"}', 200);
        }
        if (r.method == 'PATCH') {
          return http.Response(
            jsonEncode({
              'id': 'test',
              'owner_id': '10000000-0000-4000-8000-000000000001',
              'municipality_id': '3550605',
              'photo_path': 'test.png',
              'observed_on': '2026-10-01',
              'species_label': null,
              'identification_origin': 'unknown',
              'notes': '',
              'status': 'published',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('', 201);
      };
      final published = await repository.create(
        draft,
        Uint8List.fromList([1, 2, 3]),
      );
      expect(published.id, 'test');
      expect(published.status, 'published');
      expect(requests.map((r) => r.method), ['POST', 'POST', 'PATCH']);
      expect(requests[1].bodyBytes, containsAllInOrder([1, 2, 3]));
      expect(jsonDecode(requests.last.body), {'status': 'published'});
    },
  );
  test(
    'lost draft insertion response requires reconciliation before retry',
    () async {
      await session();
      handler = (_) => http.Response('{"message":"unavailable"}', 400);
      await expectLater(
        repository.create(draft, Uint8List(1)),
        throwsA(isA<CommunityPublicationUncertain>()),
      );
      expect(requests.length, 1);
    },
  );
  test(
    'missing public configuration is clear and never exposes internals',
    () async {
      final unavailable = SupabaseCommunityRepository(
        clientProvider: () async => throw StateError('internal detail'),
      );
      await expectLater(
        unavailable.page(),
        throwsA(
          isA<CommunityFailure>().having(
            (e) => e.message,
            'message',
            allOf(contains('SUPABASE_URL'), isNot(contains('internal detail'))),
          ),
        ),
      );
    },
  );
  test('storage deletion failure hides row but does not delete row', () async {
    await session();
    handler = (r) {
      if (r.url.path.startsWith('/storage/')) {
        return http.Response('{"message":"unavailable"}', 400);
      }
      return http.Response(
        '[{"id":"one"}]',
        200,
        headers: {'content-type': 'application/json'},
      );
    };
    await expectLater(
      repository.delete(fixture()),
      throwsA(
        isA<CommunityFailure>().having(
          (e) => e.message,
          'message',
          contains('limpeza pendente'),
        ),
      ),
    );
    expect(requests.length, 2);
    expect(jsonDecode(requests.first.body), {'status': 'deleting'});
    expect(requests.last.url.path, contains('/storage/'));
  });
  test(
    'deletion hides then removes object then row; retry permits absent object',
    () async {
      await session();
      handler = (r) => http.Response(
        r.method == 'PATCH' ? '[{"id":"one"}]' : '[]',
        200,
        headers: {'content-type': 'application/json'},
      );
      await repository.delete(fixture());
      expect(requests.map((r) => r.method), ['PATCH', 'DELETE', 'DELETE']);
      expect(requests[1].url.path, contains('/storage/'));
      expect(requests[2].url.path, contains('/rest/'));
    },
  );
}
