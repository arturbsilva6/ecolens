import 'dart:async';
import 'dart:convert';

import 'package:ecolens/data/auth_repository.dart';
import 'package:ecolens/data/supabase_auth_repository.dart';
import 'package:ecolens/services/auth_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Links implements AuthLinks {
  final events = StreamController<Uri>.broadcast();
  Uri? first;
  @override
  Future<Uri?> initial() async => first;
  @override
  Stream<Uri> get stream => events.stream;
}

class _PkceStorage implements GotrueAsyncStorage {
  final _values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => _values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }
}

final _user = <String, dynamic>{
  'id': '00000000-0000-0000-0000-000000000001',
  'aud': 'authenticated',
  'email': 'pessoa@example.com',
  'created_at': '2026-11-04T00:00:00Z',
  'user_metadata': {'display_name': 'Pessoa'},
};
Map<String, dynamic> _session() => {
  'access_token': 'test-access-token',
  'refresh_token': 'test-refresh-token',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': _user,
};

void main() {
  test(
    'URL web de navegação não é confundida com callback de autenticação',
    () {
      expect(
        AuthRedirects.hasAuthParameters(
          Uri.parse('https://example.invalid/#/'),
        ),
        isFalse,
      );
      expect(
        AuthRedirects.hasAuthParameters(
          Uri.parse('https://example.invalid/?search=animal#/'),
        ),
        isFalse,
      );
      expect(
        AuthRedirects.hasAuthParameters(
          Uri.parse('https://example.invalid/?code=test-code#/'),
        ),
        isTrue,
      );
      expect(
        AuthRedirects.hasAuthParameters(
          Uri.parse('https://example.invalid/#error=access_denied'),
        ),
        isTrue,
      );
    },
  );
  late SupabaseClient client;
  late SupabaseAuthRepository repository;
  late _Links links;
  late List<AccountEvent> events;
  late List<http.Request> requests;
  FutureOr<http.Response> Function(http.Request)? handler;
  setUp(() {
    requests = [];
    handler = null;
    events = [];
    links = _Links();
    client = SupabaseClient(
      'https://example.invalid',
      'public-test-key',
      authOptions: AuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: false,
        pkceAsyncStorage: _PkceStorage(),
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        return handler?.call(request) ??
            http.Response(
              jsonEncode(_session()),
              200,
              headers: {'content-type': 'application/json'},
            );
      }),
    );
    repository = SupabaseAuthRepository(
      clientProvider: () async => client,
      links: links,
      redirect: () => AuthRedirects.android,
    );
    repository.changes.listen(events.add);
  });
  tearDown(() async {
    await repository.dispose();
    await links.events.close();
    await client.dispose();
  });

  test('Restaura sessão do SDK sem criar usuário anônimo', () async {
    await client.auth.setInitialSession(jsonEncode(_session()));
    final user = await repository.connect();
    expect(user!.email, 'pessoa@example.com');
    expect(user.displayName, 'Pessoa');
    expect(requests, isEmpty);
  });

  test(
    'Anonymous AI session and expired session are not registered profiles',
    () async {
      final anonymous = _session();
      anonymous['user'] = {..._user, 'is_anonymous': true};
      await client.auth.setInitialSession(jsonEncode(anonymous));
      expect(await repository.connect(), isNull);
      await client.auth.setInitialSession(jsonEncode(_session()));
      client.auth.currentSession!.expiresAt = 1;
      expect(await repository.connect(), isNull);
      expect(requests, isEmpty);
    },
  );
  test('Cadastro pendente envia nome e redirect sem inventar sessão', () async {
    handler = (_) => http.Response(jsonEncode(_user), 200);
    expect(
      await repository.signUp('pessoa@example.com', 'Password12', 'Pessoa'),
      isNull,
    );
    final body = jsonDecode(requests.single.body) as Map;
    expect(body['data'], {'display_name': 'Pessoa'});
    expect(
      requests.single.url.queryParameters['redirect_to'],
      AuthRedirects.android,
    );
    expect(client.auth.currentSession, isNull);
  });

  test(
    'Login usa sessão retornada e updateName envia só metadado de apresentação',
    () async {
      final signedIn = await repository.signIn(
        'pessoa@example.com',
        'Password12',
      );
      expect(signedIn.email, 'pessoa@example.com');
      handler = (_) => http.Response(
        jsonEncode({
          ..._user,
          'user_metadata': {'display_name': 'Novo nome'},
        }),
        200,
      );
      final updated = await repository.updateName('Novo nome');
      expect(updated.displayName, 'Novo nome');
      final body = jsonDecode(requests.last.body) as Map;
      expect(body.keys, ['data']);
      expect(body['data'], {'display_name': 'Novo nome'});
    },
  );

  test(
    'Recuperação PKCE completa valida callback e atualiza nova senha',
    () async {
      await repository.requestPasswordReset('pessoa@example.com');
      expect(requests.single.url.path, '/auth/v1/recover');
      expect(
        requests.single.url.queryParameters['redirect_to'],
        AuthRedirects.android,
      );
      await repository.processCallback(
        Uri.parse('${AuthRedirects.android}?code=test-code'),
      );
      expect(
        events.where((event) => event.type == AccountEventType.recovery),
        hasLength(1),
      );
      expect(client.auth.currentSession, isNotNull);
      handler = (_) => http.Response(jsonEncode(_user), 200);
      await repository.updatePassword('NewPassword12');
      expect(jsonDecode(requests.last.body)['password'], 'NewPassword12');
      expect(requests.last.method, 'PUT');
      expect(requests.last.url.path, '/auth/v1/user');
    },
  );

  test('Callback de confirmação cria sessão e callback repetido só troca código uma vez', () async {
    handler = (request) => http.Response(
      jsonEncode(request.url.path.endsWith('/signup') ? _user : _session()),
      200,
    );
    await repository.signUp('pessoa@example.com', 'Password12', 'Pessoa');
    final uri = Uri.parse('${AuthRedirects.android}?code=confirmation-code');
    await repository.processCallback(uri);
    await repository.processCallback(uri);
    expect(
      requests.where(
        (request) => request.url.queryParameters['grant_type'] == 'pkce',
      ),
      hasLength(1),
    );
    expect(events.last.type, AccountEventType.session);
    expect(events.last.user!.email, 'pessoa@example.com');
  });

  for (final query in [
    '',
    'error=access_denied&error_description=internal-secret',
    'error_code=otp_expired',
    'invalid=value',
    'access_token=do-not-import',
  ]) {
    test(
      'Callback inválido/cancelado é sanitizado: ${query.split('=').first}',
      () async {
        await repository.connect();
        await repository.processCallback(
          Uri.parse('${AuthRedirects.android}?$query'),
        );
        expect(client.auth.currentSession, isNull);
        expect(requests, isEmpty);
        expect(events.single.type, AccountEventType.callbackError);
        expect(events.single.message, isNot(contains('internal-secret')));
      },
    );
  }

  test('Callback expirado no servidor não permite recuperação', () async {
    await repository.requestPasswordReset('pessoa@example.com');
    handler = (_) => http.Response(
      jsonEncode({'code': 'flow_state_expired', 'msg': 'internal-secret'}),
      400,
    );
    await repository.processCallback(
      Uri.parse('${AuthRedirects.android}?code=expired-code'),
    );
    expect(events.last.type, AccountEventType.callbackError);
    expect(events.last.message, contains('expirado'));
    expect(client.auth.currentSession, isNull);
  });

  test('Falha PKCE transitória permite reabrir o mesmo link; sucesso não é repetido', () async {
    await repository.requestPasswordReset('pessoa@example.com');
    handler = (_) => http.Response(jsonEncode({'msg': 'internal-secret'}), 503);
    final uri = Uri.parse('${AuthRedirects.android}?code=transient-code');
    await repository.processCallback(uri);
    expect(client.auth.currentSession, isNull);
    expect(events.last.type, AccountEventType.callbackError);
    expect(events.last.canRetryCallback, isTrue);
    expect(events.last.message, contains('Falha temporária'));
    expect(events.last.message, isNot(contains('internal-secret')));
    handler = null;
    await repository.processCallback(uri);
    expect(client.auth.currentSession, isNotNull);
    expect(events.last.type, AccountEventType.recovery);
    final count = requests.length;
    final eventCount = events.length;
    await repository.processCallback(uri);
    expect(requests.length, count);
    expect(events.length, eventCount);
    expect(
      requests.where(
        (request) => request.url.queryParameters['grant_type'] == 'pkce',
      ),
      hasLength(2),
    );
  });

  test(
    'Retry explícito repete o link após falha de rede sem salvar sessão falsa',
    () async {
      await repository.requestPasswordReset('pessoa@example.com');
      handler = (_) => throw http.ClientException('internal-network-details');
      final uri = Uri.parse('${AuthRedirects.android}?code=network-retry-code');
      await repository.processCallback(uri);
      expect(events.last.canRetryCallback, isTrue);
      expect(client.auth.currentSession, isNull);
      handler = null;
      await repository.retryCallback();
      expect(events.last.type, AccountEventType.recovery);
      expect(client.auth.currentSession, isNotNull);
      final exchanges = requests
          .where(
            (request) => request.url.queryParameters['grant_type'] == 'pkce',
          )
          .toList();
      expect(exchanges, hasLength(2));
      expect(
        jsonDecode(exchanges.first.body)['auth_code'],
        jsonDecode(exchanges.last.body)['auth_code'],
      );
      await expectLater(
        repository.retryCallback(),
        throwsA(isA<AuthFailure>()),
      );
      expect(
        requests.where(
          (request) => request.url.queryParameters['grant_type'] == 'pkce',
        ),
        hasLength(2),
      );
    },
  );

  test(
    'Callback em andamento e callback já concluído não duplicam a troca PKCE',
    () async {
      await repository.requestPasswordReset('pessoa@example.com');
      final pending = Completer<http.Response>();
      final started = Completer<void>();
      handler = (_) {
        started.complete();
        return pending.future;
      };
      final uri = Uri.parse('${AuthRedirects.android}?code=concurrent-code');
      final inProgress = repository.processCallback(uri);
      await started.future;
      await repository.processCallback(uri);
      expect(
        requests.where(
          (request) => request.url.queryParameters['grant_type'] == 'pkce',
        ),
        hasLength(1),
      );
      pending.complete(http.Response(jsonEncode(_session()), 200));
      await inProgress;
      await repository.processCallback(uri);
      expect(
        requests.where(
          (request) => request.url.queryParameters['grant_type'] == 'pkce',
        ),
        hasLength(1),
      );
      expect(
        events.where((event) => event.type == AccountEventType.recovery),
        hasLength(1),
      );
      // O primeiro sucesso continua deduplicado mesmo depois de outro callback.
      handler = null;
      await client.auth.getOAuthSignInUrl(
        provider: OAuthProvider.google,
        redirectTo: AuthRedirects.android,
      );
      await repository.processCallback(
        Uri.parse('${AuthRedirects.android}?code=second-code'),
      );
      final count = requests.length;
      await repository.processCallback(uri);
      expect(requests.length, count);
      expect(events.last.type, AccountEventType.session);
    },
  );

  for (final code in [
    'flow_state_expired',
    'flow_state_not_found',
    'bad_code_verifier',
  ]) {
    test(
      'Código inválido, expirado ou consumido exige novo link: $code',
      () async {
        await repository.requestPasswordReset('pessoa@example.com');
        handler = (_) => http.Response(
          jsonEncode({'code': code, 'msg': 'internal-secret'}),
          400,
        );
        final uri = Uri.parse('${AuthRedirects.android}?code=invalid-code');
        await repository.processCallback(uri);
        expect(events.last.type, AccountEventType.callbackError);
        expect(events.last.canRetryCallback, isFalse);
        expect(events.last.message, contains('Solicite um novo link'));
        expect(client.auth.currentSession, isNull);
        final count = requests.length;
        await repository.processCallback(uri);
        await expectLater(
          repository.retryCallback(),
          throwsA(isA<AuthFailure>()),
        );
        expect(requests.length, count);
        expect(events.last.canRetryCallback, isFalse);
      },
    );
  }

  test(
    'Callback inicial é processado e origem/caminho incorretos são ignorados',
    () async {
      await client.auth.resetPasswordForEmail('pessoa@example.com');
      links.first = Uri.parse('${AuthRedirects.android}?code=initial-code');
      await repository.connect();
      expect(events.last.type, AccountEventType.recovery);
      final count = requests.length;
      await repository.processCallback(
        Uri.parse('other://auth/callback?code=other-code'),
      );
      await repository.processCallback(
        Uri.parse('br.com.ecolens://auth/wrong?code=other-code'),
      );
      expect(requests.length, count);
    },
  );

  test(
    'Google não configurado informa pendência sem abrir fluxo falso',
    () async {
      await expectLater(
        repository.signInWithGoogle(),
        throwsA(isA<AuthFailure>()),
      );
      expect(requests, isEmpty);
    },
  );

  test(
    'Callback Google PKCE só autentica após troca validada pelo SDK',
    () async {
      await repository.connect();
      final oauth = await client.auth.getOAuthSignInUrl(
        provider: OAuthProvider.google,
        redirectTo: AuthRedirects.android,
      );
      expect(Uri.parse(oauth.url).queryParameters['provider'], 'google');
      expect(client.auth.currentSession, isNull);
      await repository.processCallback(
        Uri.parse('${AuthRedirects.android}?code=google-test-code'),
      );
      expect(client.auth.currentSession, isNotNull);
      expect(events.last.type, AccountEventType.session);
      expect(events.last.user!.email, 'pessoa@example.com');
    },
  );

  test(
    'Logout remoto falho informa encerramento local sem falso sucesso',
    () async {
      await repository.signIn('pessoa@example.com', 'Password12');
      handler = (_) => http.Response(
        jsonEncode({'code': 'unexpected_failure', 'msg': 'internal-secret'}),
        400,
      );
      await expectLater(repository.signOut(), throwsA(isA<AuthFailure>()));
      expect(client.auth.currentSession, isNull);
      expect(events.last.type, AccountEventType.signedOut);
      handler = null;
      await repository.signIn('pessoa@example.com', 'Password12');
      handler = (_) => http.Response('', 204);
      await repository.signOut();
      expect(client.auth.currentSession, isNull);
    },
  );

  test('Mapeamento de erros cobre credenciais, confirmação, limites e indisponibilidade', () {
    expect(
      authErrorMessage(
        const AuthException('internal-secret', code: 'invalid_credentials'),
      ),
      'E-mail ou senha incorretos.',
    );
    expect(
      authErrorMessage(
        const AuthException('internal-secret', code: 'email_not_confirmed'),
      ),
      contains('Confirme'),
    );
    expect(
      authErrorMessage(
        const AuthException('internal-secret', statusCode: '429'),
      ),
      contains('Muitas tentativas'),
    );
    expect(
      authErrorMessage(
        const AuthException('internal-secret', code: 'provider_disabled'),
      ),
      contains('habilitar'),
    );
    expect(
      authErrorMessage(StateError('internal-secret')),
      contains('indisponível'),
    );
  });
}
