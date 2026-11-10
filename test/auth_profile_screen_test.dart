import 'dart:async';

import 'package:ecolens/app.dart';
import 'package:ecolens/controllers/auth_controller.dart';
import 'package:ecolens/core/theme/app_theme.dart';
import 'package:ecolens/data/auth_repository.dart';
import 'package:ecolens/screens/home/home_screen.dart';
import 'package:ecolens/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthController controller;
  late DateTime now;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    repository = FakeAuthRepository();
    now = DateTime(2026, 11, 4);
    controller = AuthController(repository: repository, now: () => now);
  });
  tearDown(() {
    controller.dispose();
  });

  /// Fecha o aviso de sucesso (diálogo com OK), se estiver aberto.
  Future<void> dismissNotice(WidgetTester tester) async {
    final ok = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('OK'),
    );
    if (ok.evaluate().isEmpty) return;
    await tester.tap(ok);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await dismissNotice(tester);
    final finder = find.text(text).last;
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String key, String value) async {
    await dismissNotice(tester);
    final finder = find.byKey(ValueKey('auth-$key'));
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.3);
    await tester.pumpAndSettle();
    await tester.enterText(finder, value);
    tester.testTextInput.hide();
    await tester.pump();
  }

  Future<void> show(
    WidgetTester tester, {
    bool dark = false,
    double scale = 1,
  }) async {
    await controller.initialize();
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: ProfileScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Home abre Perfil convidado e continuar sem conta retorna ao início',
    (tester) async {
      await tester.pumpWidget(
        EcoLensApp(
          authController: controller,
          fetchPublishedSpecies: () async => [],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Entrar com e-mail'), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);
      expect(find.text('Entrar com Google'), findsOneWidget);
      await tap(tester, 'Continuar sem conta');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(repository.calls, 0);
    },
  );

  testWidgets(
    'Cadastro valida confirmação, mostra pendência e bloqueia reenvio imediato',
    (tester) async {
      await show(tester);
      await tap(tester, 'Criar conta');
      await enter(tester, 'name', 'Pessoa');
      await enter(tester, 'email', 'pessoa@example.com');
      await enter(tester, 'password', 'Password12');
      await enter(tester, 'confirmation', 'other');
      await tap(tester, 'Cadastrar');
      expect(find.text('As senhas não coincidem.'), findsOneWidget);
      expect(repository.calls, 0);
      await enter(tester, 'confirmation', 'Password12');
      await tap(tester, 'Cadastrar');
      expect(controller.user, isNull);
      expect(find.textContaining('Confira seu e-mail'), findsOneWidget);
      final resend = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Reenviar confirmação'),
      );
      expect(resend.onPressed, isNull);
      expect(find.text('Sair da conta'), findsNothing);
      await tester.pump(const Duration(seconds: 61));
    },
  );

  testWidgets('Login falho é informado e campos de senha são ocultáveis', (
    tester,
  ) async {
    repository.failure = const AuthFailure('E-mail ou senha incorretos.');
    await show(tester);
    await tap(tester, 'Entrar com e-mail');
    await enter(tester, 'email', account.email);
    await enter(tester, 'password', 'Password12');
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const ValueKey('auth-password')),
              matching: find.byType(TextField),
            ),
          )
          .obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(find.byTooltip('Ocultar senha'), findsOneWidget);
    await tap(tester, 'Entrar');
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    expect(controller.user, isNull);
    repository.failure = null;
    await enter(tester, 'password', 'Password12');
    await tap(tester, 'Entrar');
    expect(find.text('Login realizado'), findsOneWidget);
    expect(find.text('Sua conta foi conectada com sucesso.'), findsOneWidget);
    await dismissNotice(tester);
    expect(find.text('Login realizado'), findsNothing);
    expect(controller.message, isNull);
    expect(find.text(account.email), findsOneWidget);
    expect(find.text('Salvar nome'), findsOneWidget);
    expect(find.textContaining('não são sincronizados'), findsOneWidget);
  });

  testWidgets(
    'Cadastro A e edição para B reenvia somente ao destinatário B visível',
    (tester) async {
      await show(tester);
      await tap(tester, 'Criar conta');
      await enter(tester, 'name', 'Pessoa');
      await enter(tester, 'email', 'cadastro-a@example.com');
      await enter(tester, 'password', 'Password12');
      await enter(tester, 'confirmation', 'Password12');
      await tap(tester, 'Cadastrar');
      expect(controller.pendingEmail, 'cadastro-a@example.com');
      expect(
        find.text('Destinatário da confirmação: cadastro-a@example.com'),
        findsOneWidget,
      );
      await enter(tester, 'email', 'cadastro-b@example.com');
      expect(
        find.text('Destinatário da confirmação: cadastro-b@example.com'),
        findsOneWidget,
      );
      expect(
        find.text('Destinatário da confirmação: cadastro-a@example.com'),
        findsNothing,
      );
      final resend = find.widgetWithText(
        OutlinedButton,
        'Reenviar confirmação',
      );
      expect(tester.widget<OutlinedButton>(resend).onPressed, isNull);
      now = now.add(const Duration(seconds: 61));
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
      await tap(tester, 'Reenviar confirmação');
      expect(repository.lastConfirmationEmail, 'cadastro-b@example.com');
      expect(repository.calls, 2); // Cadastro A e reenvio B.
      expect(controller.message, contains('cadastro-b@example.com'));
      expect(controller.message, isNot(contains('cadastro-a@example.com')));
      now = now.add(const Duration(seconds: 61));
      await tester.pump(const Duration(seconds: 61));
      await enter(tester, 'email', '');
      expect(tester.widget<OutlinedButton>(resend).onPressed, isNull);
      expect(
        find.textContaining('Informe um e-mail válido no formulário'),
        findsOneWidget,
      );
      expect(repository.lastConfirmationEmail, 'cadastro-b@example.com');
    },
  );

  testWidgets(
    'Falha temporária oferece repetir link e remove ação após sucesso',
    (tester) async {
      await show(tester);
      repository.events.add(
        const AccountEvent(
          AccountEventType.callbackError,
          message: 'Falha temporária ao validar o link.',
          canRetryCallback: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.user, isNull);
      repository.retryEvent = const AccountEvent(
        AccountEventType.recovery,
        user: account,
      );
      await tap(tester, 'Tentar novamente com este link');
      expect(repository.callbackRetries, 1);
      expect(find.text('Definir nova senha'), findsOneWidget);
      expect(find.text('Tentar novamente com este link'), findsNothing);
      expect(controller.canRetryCallback, isFalse);
    },
  );

  testWidgets(
    'Logout falho mantém perfil; nome e logout podem ser tentados novamente',
    (tester) async {
      repository.restored = account;
      await show(tester);
      await enter(tester, 'name', 'Novo nome');
      await tap(tester, 'Salvar nome');
      expect(find.text('Nome atualizado.'), findsOneWidget);
      repository.failure = const AuthFailure('Falha ao sair.');
      await tap(tester, 'Sair da conta');
      expect(find.text('Falha ao sair.'), findsOneWidget);
      expect(find.text(account.email), findsOneWidget);
      repository.failure = null;
      await tap(tester, 'Sair da conta');
      expect(find.textContaining('Você saiu da conta.'), findsOneWidget);
      expect(find.text('Sair da conta'), findsNothing);
    },
  );

  testWidgets('Recuperação vai do pedido neutro ao callback e nova senha', (
    tester,
  ) async {
    await show(tester);
    await tap(tester, 'Esqueci minha senha');
    await enter(tester, 'email', account.email);
    await tap(tester, 'Enviar recuperação');
    expect(find.textContaining('Se houver uma conta'), findsOneWidget);
    repository.events.add(
      const AccountEvent(AccountEventType.recovery, user: account),
    );
    await tester.pumpAndSettle();
    expect(find.text('Definir nova senha'), findsOneWidget);
    await enter(tester, 'password', 'NewPassword12');
    await enter(tester, 'confirmation', 'NewPassword12');
    await tap(tester, 'Salvar nova senha');
    expect(find.text('Senha atualizada com sucesso.'), findsOneWidget);
    expect(find.text('Salvar nome'), findsOneWidget);
  });

  testWidgets('Link expirado mostra erro e permite solicitar novo link', (
    tester,
  ) async {
    await show(tester);
    repository.events.add(
      const AccountEvent(
        AccountEventType.callbackError,
        message: 'Link inválido ou expirado.',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Link inválido ou expirado.'), findsOneWidget);
    expect(find.text('Tentar novamente com este link'), findsNothing);
    expect(find.text('Salvar nova senha'), findsNothing);
    await tap(tester, 'Solicitar novo link de recuperação');
    expect(find.text('Enviar recuperação'), findsOneWidget);
  });

  testWidgets('Google cancelado não mostra perfil autenticado', (tester) async {
    repository.googleLaunched = false;
    await show(tester);
    await tap(tester, 'Entrar com Google');
    expect(find.textContaining('cancelado'), findsOneWidget);
    expect(find.text('Sair da conta'), findsNothing);
  });

  testWidgets(
    'Senha com sessão expirada oferece um novo pedido de recuperação',
    (tester) async {
      await show(tester);
      repository.events.add(
        const AccountEvent(AccountEventType.recovery, user: account),
      );
      await tester.pumpAndSettle();
      repository.failure = const AuthFailure(
        'Link ou sessão inválida ou expirada. Solicite um novo link.',
      );
      await enter(tester, 'password', 'NewPassword12');
      await enter(tester, 'confirmation', 'NewPassword12');
      await tap(tester, 'Salvar nova senha');
      expect(
        find.textContaining('sessão inválida ou expirada'),
        findsOneWidget,
      );
      await tap(tester, 'Solicitar novo link de recuperação');
      expect(find.text('Enviar recuperação'), findsOneWidget);
      expect(find.text('Salvar nova senha'), findsNothing);
    },
  );

  testWidgets('Eventos de recuperação repetidos não empilham telas', (
    tester,
  ) async {
    await tester.pumpWidget(
      EcoLensApp(
        authController: controller,
        fetchPublishedSpecies: () async => [],
      ),
    );
    await tester.pumpAndSettle();
    repository.events.add(
      const AccountEvent(AccountEventType.recovery, user: account),
    );
    repository.events.add(
      const AccountEvent(AccountEventType.recovery, user: account),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen, skipOffstage: false), findsOneWidget);
    expect(find.text('Salvar nova senha'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Tela descartada durante login não atualiza widget removido', (
    tester,
  ) async {
    await show(tester);
    await tap(tester, 'Entrar com e-mail');
    await enter(tester, 'email', account.email);
    await enter(tester, 'password', 'Password12');
    repository.pending = Completer<void>();
    final button = find.widgetWithText(FilledButton, 'Entrar');
    await Scrollable.ensureVisible(tester.element(button));
    await tester.tap(button);
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
    repository.pending!.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    for (final mode in [
      'convidado',
      'entrar',
      'cadastro',
      'recuperar',
      'perfil',
      'nova senha',
    ]) {
      testWidgets('320x480 texto 2x ${dark ? 'escuro' : 'claro'}: $mode', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        if (mode == 'perfil') repository.restored = account;
        await show(tester, dark: dark, scale: 2);
        if (mode == 'entrar') await tap(tester, 'Entrar com e-mail');
        if (mode == 'cadastro') await tap(tester, 'Criar conta');
        if (mode == 'recuperar') await tap(tester, 'Esqueci minha senha');
        if (mode == 'nova senha') {
          repository.events.add(
            const AccountEvent(AccountEventType.recovery, user: account),
          );
          await tester.pumpAndSettle();
        }
        await tap(
          tester,
          mode == 'perfil' || mode == 'nova senha'
              ? 'Voltar ao início'
              : 'Continuar sem conta',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
