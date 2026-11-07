import 'dart:async';
import 'dart:typed_data';

import 'package:ecolens/data/supabase_species_repository.dart';
import 'package:ecolens/services/ai_service.dart';
import 'package:ecolens/services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  SupabaseClient createClient({http.Client? httpClient}) {
    final client = SupabaseClient(
      'https://example.invalid',
      'test-publishable-key',
      httpClient: httpClient,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(client.dispose);
    return client;
  }

  for (final configuration in [
    (url: '', key: ''),
    (url: 'https://example.invalid', key: ''),
    (url: '', key: 'test-publishable-key'),
    (url: 'invalid-url', key: 'test-publishable-key'),
    (url: 'ftp://example.invalid', key: 'test-publishable-key'),
  ]) {
    test(
      'Configuração ausente ou inválida não chama o SDK: $configuration',
      () async {
        var calls = 0;
        final service = SupabaseService(
          url: configuration.url,
          publishableKey: configuration.key,
          initializer: (_, _) async {
            calls++;
            throw StateError('O SDK não deveria ser chamado.');
          },
        );

        expect(await service.initialize(), isNull);
        await expectLater(service.requireClient(), throwsStateError);
        expect(calls, 0);
      },
    );
  }

  test('Chamadas concorrentes aguardam uma única inicialização', () async {
    final pending = Completer<SupabaseClient>();
    final client = createClient();
    var calls = 0;
    final service = SupabaseService(
      url: 'https://example.invalid',
      publishableKey: 'test-publishable-key',
      initializer: (_, _) {
        calls++;
        return pending.future;
      },
    );

    final initialization = service.initialize();
    final requestedClient = service.requireClient();
    expect(calls, 1);
    pending.complete(client);

    expect(await initialization, same(client));
    expect(await requestedClient, same(client));
    expect(await service.initialize(), same(client));
    expect(client.auth.currentSession, isNull);
    expect(calls, 1);
  });

  test('Falha síncrona é tratada e permite nova tentativa', () async {
    final client = createClient();
    var calls = 0;
    final service = SupabaseService(
      url: 'https://example.invalid',
      publishableKey: 'test-publishable-key',
      initializer: (_, _) {
        calls++;
        if (calls == 1) throw StateError('Falha de inicialização.');
        return Future.value(client);
      },
    );

    expect(await service.initialize(), isNull);
    expect(await service.requireClient(), same(client));
    expect(calls, 2);
  });

  test('Falha assíncrona não escapa e permite nova tentativa', () async {
    final client = createClient();
    var calls = 0;
    final service = SupabaseService(
      url: 'https://example.invalid',
      publishableKey: 'test-publishable-key',
      initializer: (_, _) async {
        calls++;
        if (calls == 1) throw http.ClientException('Sem conexão.');
        return client;
      },
    );

    await expectLater(service.requireClient(), throwsStateError);
    expect(await service.requireClient(), same(client));
    expect(calls, 2);
  });

  testWidgets('Espera online tem limite sem duplicar a inicialização lenta', (
    tester,
  ) async {
    final pending = Completer<SupabaseClient>();
    var calls = 0;
    final service = SupabaseService(
      url: 'https://example.invalid',
      publishableKey: 'test-publishable-key',
      initializer: (_, _) {
        calls++;
        return pending.future;
      },
    );

    final failure = expectLater(service.requireClient(), throwsStateError);
    await tester.pump(const Duration(seconds: 11));
    await failure;

    final nextFailure = expectLater(service.requireClient(), throwsStateError);
    expect(calls, 1);
    pending.completeError(StateError('Falha tardia de inicialização.'));
    await tester.pump();
    await nextFailure;
  });

  test(
    'Catálogo só consulta após inicialização, sem sessão de login',
    () async {
      final pending = Completer<SupabaseClient>();
      var requests = 0;
      final transport = MockClient((request) async {
        requests++;
        expect(request.url.path, '/rest/v1/species');
        expect(request.url.queryParameters['is_published'], 'eq.true');
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      });
      addTearDown(transport.close);
      final client = createClient(httpClient: transport);
      final service = SupabaseService(
        url: 'https://example.invalid',
        publishableKey: 'test-publishable-key',
        initializer: (_, _) => pending.future,
      );
      final repository = SupabaseSpeciesRepository(supabaseService: service);

      final result = repository.fetchPublishedSpecies();
      expect(requests, 0);
      pending.complete(client);

      expect(await result, isEmpty);
      expect(client.auth.currentSession, isNull);
      expect(requests, 1);
    },
  );

  test('Catálogo e IA sem configuração retornam erro controlado', () async {
    final service = SupabaseService(url: '', publishableKey: '');
    final repository = SupabaseSpeciesRepository(supabaseService: service);
    final ai = AiService(supabaseService: service);

    await expectLater(repository.fetchPublishedSpecies(), throwsStateError);
    await expectLater(
      ai.suggestSpecies(Uint8List.fromList([0xFF, 0xD8, 0xFF])),
      throwsStateError,
    );
  });

  test(
    'Cliente injetado continua funcionando sem configuração global',
    () async {
      final transport = MockClient((request) async {
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      });
      addTearDown(transport.close);
      final client = createClient(httpClient: transport);
      final repository = SupabaseSpeciesRepository(
        client: client,
        supabaseService: SupabaseService(url: '', publishableKey: ''),
      );

      expect(await repository.fetchPublishedSpecies(), isEmpty);
    },
  );
}
