import 'dart:async';

import 'package:ecolens/controllers/auth_controller.dart';
import 'package:ecolens/data/auth_repository.dart';
import 'package:ecolens/data/favorites_repository.dart';
import 'package:ecolens/data/identification_history_repository.dart';
import 'package:ecolens/models/ai_identification_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthController controller;
  var now = DateTime(2026, 11, 4);
  setUp(() {
    repository = FakeAuthRepository();
    now = DateTime(2026, 11, 4);
    controller = AuthController(repository: repository, now: () => now);
  });
  tearDown(() {
    controller.dispose();
  });

  test('Convidado restaura ausência de sessão sem criar usuário', () async {
    await controller.initialize();
    await controller.initialize();
    expect(controller.user, isNull);
    expect(repository.calls, 0);
    expect(repository.connects, 1);
  });
  test('Sessão restaurada e mudanças do SDK atualizam perfil', () async {
    repository.restored = account;
    await controller.initialize();
    expect(controller.user, same(account));
    repository.events.add(const AccountEvent(AccountEventType.signedOut));
    expect(controller.user, isNull);
    repository.events.add(
      const AccountEvent(AccountEventType.session, user: account),
    );
    expect(controller.user, same(account));
  });
  test(
    'Cadastro pendente não autentica e reenvios têm intervalo e limite',
    () async {
      await controller.signUp(
        'pessoa@example.com',
        'Password12',
        'Password12',
        'Pessoa',
      );
      expect(controller.user, isNull);
      expect(controller.pendingEmail, 'pessoa@example.com');
      expect(controller.message, contains('link de confirmação'));
      await controller.resend('pessoa@example.com');
      expect(repository.calls, 1);
      for (var i = 0; i < 3; i++) {
        now = now.add(const Duration(seconds: 61));
        await controller.resend('pessoa@example.com');
      }
      expect(repository.calls, 4);
      now = now.add(const Duration(seconds: 61));
      expect(controller.canResend, isFalse);
      await controller.resend('pessoa@example.com');
      expect(repository.calls, 4);
    },
  );
  test(
    'Cadastro sem confirmação obrigatória usa somente sessão real retornada',
    () async {
      repository.registered = account;
      await controller.signUp(
        account.email,
        'Password12',
        'Password12',
        'Pessoa',
      );
      expect(controller.user, same(account));
    },
  );
  test('Valida e-mail, tamanho/conteúdo do nome, senha e confirmação antes de envio', () async {
    await controller.signUp('invalid', 'Password12', 'Password12', 'Pessoa');
    await controller.signUp(
      account.email,
      'Password12',
      'Password12',
      '<script>',
    );
    await controller.signUp(account.email, 'short', 'short', 'Pessoa');
    await controller.signUp(account.email, 'Password12', 'different', 'Pessoa');
    expect(repository.calls, 0);
    expect(AuthController.nameError('a' * 61), isNotNull);
    expect(AuthController.nameError('Nome\nTeste'), isNotNull);
    expect(AuthController.nameError('  Maria da Silva  '), isNull);
  });
  test('Login sucesso e falha não criam sessão falsa', () async {
    repository.failure = const AuthFailure('E-mail ou senha incorretos.');
    await controller.signIn(account.email, 'wrong');
    expect(controller.user, isNull);
    expect(controller.message, 'E-mail ou senha incorretos.');
    repository.failure = null;
    await controller.signIn(account.email, 'Password12');
    expect(controller.user, same(account));
  });
  test('Envio duplicado é bloqueado durante operação pendente', () async {
    repository.pending = Completer<void>();
    final first = controller.signUp(
      account.email,
      'Password12',
      'Password12',
      'Pessoa',
    );
    await controller.signUp(
      account.email,
      'Password12',
      'Password12',
      'Pessoa',
    );
    expect(controller.busy, isTrue);
    expect(repository.calls, 1);
    repository.pending!.complete();
    await first;
    expect(controller.busy, isFalse);
  });
  test('Logout só confirma após concluir; falha mantém usuário', () async {
    repository.restored = account;
    await controller.initialize();
    repository.failure = const AuthFailure('Serviço indisponível.');
    await controller.signOut();
    expect(controller.user, same(account));
    expect(controller.message, 'Serviço indisponível.');
    repository.failure = null;
    repository.pending = Completer<void>();
    final logout = controller.signOut();
    expect(controller.user, same(account));
    expect(controller.message, isNull);
    repository.pending!.complete();
    await logout;
    expect(controller.user, isNull);
    expect(controller.message, contains('Você saiu'));
  });
  test('Edita apenas nome válido e preserva estado após falha', () async {
    repository.restored = account;
    await controller.initialize();
    await controller.saveName('x');
    expect(repository.calls, 0);
    repository.failure = const AuthFailure('Falha ao salvar.');
    await controller.saveName('Outro nome');
    expect(controller.user, same(account));
    repository.failure = null;
    await controller.saveName('  Outro nome  ');
    expect(controller.user!.displayName, 'Outro nome');
    expect(controller.user!.email, account.email);
  });
  test(
    'Recuperação só atualiza após callback validado; erro permite repetir',
    () async {
      await controller.initialize();
      await controller.requestReset(account.email);
      expect(controller.message, startsWith('Se houver uma conta'));
      await controller.resetPassword('Password12', 'Password12');
      expect(repository.calls, 1);
      repository.events.add(
        const AccountEvent(AccountEventType.recovery, user: account),
      );
      expect(controller.recoveryRequired, isTrue);
      repository.failure = const AuthFailure(
        'Link ou sessão inválida ou expirada. Solicite um novo link.',
      );
      await controller.resetPassword('Password12', 'Password12');
      expect(controller.recoveryRequired, isTrue);
      expect(controller.message, contains('expirada'));
      repository.failure = null;
      await controller.resetPassword('Password12', 'Password12');
      expect(controller.recoveryRequired, isFalse);
      expect(controller.message, 'Senha atualizada com sucesso.');
    },
  );
  test('Callback inválido impede recuperação e eventos repetidos não duplicam rota', () async {
    await controller.initialize();
    repository.events.add(
      const AccountEvent(AccountEventType.recovery, user: account),
    );
    repository.events.add(
      const AccountEvent(AccountEventType.recovery, user: account),
    );
    expect(controller.callbackRevision, 1);
    repository.events.add(
      const AccountEvent(
        AccountEventType.callbackError,
        message: 'Link expirado.',
      ),
    );
    expect(controller.recoveryRequired, isFalse);
    await controller.resetPassword('Password12', 'Password12');
    expect(repository.calls, 0);
  });
  test(
    'Google lançado, cancelado e falha nunca simulam autenticação',
    () async {
      await controller.initialize();
      await controller.google();
      expect(controller.user, isNull);
      expect(controller.message, contains('sessão válida'));
      repository.googleLaunched = false;
      await controller.google();
      expect(controller.user, isNull);
      expect(controller.message, contains('cancelado'));
      repository.failure = const AuthFailure('Provedor não configurado.');
      await controller.google();
      expect(controller.message, 'Provedor não configurado.');
      repository.events.add(
        const AccountEvent(AccountEventType.session, user: account),
      );
      expect(controller.user, same(account));
    },
  );
  test('Erros inesperados não expõem exceções internas', () async {
    repository.failure = StateError('sensitive-internal-details');
    await controller.signIn(account.email, 'Password12');
    expect(controller.message, isNot(contains('sensitive')));
  });

  test(
    'Retry só é permitido para callback transitório e termina após validação',
    () async {
      await controller.initialize();
      repository.events.add(
        const AccountEvent(
          AccountEventType.callbackError,
          canRetryCallback: true,
        ),
      );
      repository.retryEvent = const AccountEvent(
        AccountEventType.recovery,
        user: account,
      );
      await controller.retryCallback();
      expect(repository.callbackRetries, 1);
      expect(controller.recoveryRequired, isTrue);
      expect(controller.canRetryCallback, isFalse);
      repository.events.add(
        const AccountEvent(
          AccountEventType.callbackError,
          message: 'Link já utilizado.',
        ),
      );
      await controller.retryCallback();
      expect(repository.callbackRetries, 1);
      expect(controller.message, contains('Solicite um novo link'));
      expect(controller.recoveryRequired, isFalse);
    },
  );

  test(
    'Erro de refresh não força navegação nem invalida a sessão local',
    () async {
      repository.restored = account;
      await controller.initialize();
      repository.events.add(
        const AccountEvent(
          AccountEventType.serviceError,
          message: 'Serviço indisponível.',
        ),
      );
      expect(controller.user, same(account));
      expect(controller.callbackRevision, 0);
      expect(controller.message, 'Serviço indisponível.');
    },
  );
  test('Login, nome e logout preservam favoritos e histórico locais', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final preferences = SharedPreferencesAsync();
    final favorites = FavoritesRepository();
    final history = IdentificationHistoryRepository();
    await favorites.setFavorite('Bothrops jararaca', true);
    await history.save(
      const AiIdentificationResult(
        identified: true,
        commonName: 'Jararaca',
        scientificName: 'Bothrops jararaca',
        explanation: 'Teste',
      ),
      matchedCatalog: true,
    );
    final before = await preferences.getStringList(
      SharedPreferencesHistoryStore.storageKey,
    );
    await controller.signIn(account.email, 'Password12');
    await controller.saveName('Outro nome');
    await controller.signOut();
    expect(await favorites.load(), {'bothrops jararaca'});
    expect(
      await preferences.getStringList(SharedPreferencesHistoryStore.storageKey),
      before,
    );
  });

  test(
    'Dispose cancela subscription e ignora operação concluída depois',
    () async {
      await controller.initialize();
      var notifications = 0;
      controller.addListener(() {
        notifications++;
      });
      repository.pending = Completer<void>();
      final result = controller.signIn(account.email, 'Password12');
      final before = notifications;
      controller.dispose();
      repository.pending!.complete();
      await result;
      expect(notifications, before);
      expect(repository.disposed, isTrue);
      // Evita segundo dispose no tearDown.
      controller = AuthController(repository: FakeAuthRepository());
    },
  );
}
