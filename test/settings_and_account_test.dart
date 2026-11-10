import 'package:ecolens/controllers/auth_controller.dart';
import 'package:ecolens/controllers/theme_controller.dart';
import 'package:ecolens/data/auth_repository.dart';
import 'package:ecolens/data/favorites_repository.dart';
import 'package:ecolens/data/identification_history_repository.dart';
import 'package:ecolens/models/user_model.dart';
import 'package:ecolens/screens/settings/about_screen.dart';
import 'package:ecolens/screens/settings/accessibility_screen.dart';
import 'package:ecolens/screens/settings/privacy_policy_screen.dart';
import 'package:ecolens/screens/settings/privacy_screen.dart';
import 'package:ecolens/screens/settings/settings_screen.dart';
import 'package:ecolens/widgets/auth/account_navigation_scope.dart';
import 'package:ecolens/widgets/auth/account_security_section.dart';
import 'package:ecolens/widgets/camera_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/fake_auth_repository.dart';

class _Store implements FavoritesStore, IdentificationHistoryStore {
  List<String>? values;
  _Store(this.values);

  @override
  Future<List<String>?> read() async => values;

  @override
  Future<void> write(List<String> values) async => this.values = values;
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Configurações não têm itens "em desenvolvimento"', (
    tester,
  ) async {
    var accountOpened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AccountNavigationScope(
          openAccount: ({String? returnLabel}) async => accountOpened++,
          child: SettingsScreen(themeController: ThemeController()),
        ),
      ),
    );

    for (final title in [
      'Aparência',
      'Acessibilidade',
      'Uso offline',
      'Conta e segurança',
      'Privacidade e dados',
      'Sobre o EcoLens',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Notificações'), findsNothing);

    await tester.tap(find.text('Conta e segurança'));
    expect(accountOpened, 1);

    await tester.tap(find.text('Sobre o EcoLens'));
    await tester.pumpAndSettle();
    expect(find.text('Versão ${AboutScreen.version}'), findsOneWidget);
    expect(find.text('Funcionalidade em desenvolvimento'), findsNothing);
  });

  testWidgets('Tamanho do texto é salvo e restaurado', (tester) async {
    final theme = ThemeController();
    await tester.pumpWidget(
      MaterialApp(home: AccessibilityScreen(themeController: theme)),
    );

    await tester.tap(find.text('Muito grande'));
    await tester.pumpAndSettle();
    expect(theme.textScale, 1.3);

    final restored = ThemeController();
    await restored.loadTheme();
    expect(restored.textScale, 1.3);

    await theme.changeTextScale(null);
    final again = ThemeController();
    await again.loadTheme();
    expect(again.textScale, isNull);
  });

  testWidgets('Privacidade apaga histórico e favoritos após confirmar', (
    tester,
  ) async {
    final history = _Store(['{"id":"1"}']);
    final favorites = _Store(['bothrops jararaca']);
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyScreen(
          historyRepository: IdentificationHistoryRepository(store: history),
          favoritesRepository: FavoritesRepository(store: favorites),
        ),
      ),
    );

    Future<void> tapItem(String text) async {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(text));
    }

    await tapItem('Apagar histórico de identificações');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(history.values, isNotEmpty);

    await tapItem('Apagar histórico de identificações');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    expect(history.values, isEmpty);
    expect(find.text('Histórico apagado.'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico apagado.'), findsNothing);

    await tapItem('Apagar favoritos');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    expect(favorites.values, isEmpty);
    expect(find.text('Favoritos apagados.'), findsOneWidget);
  });

  testWidgets('Política de privacidade lista as seções', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));
    expect(find.text('Dados que coletamos'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Seus direitos'), 200);
    expect(find.text('Seus direitos'), findsOneWidget);
  });

  testWidgets('Aviso da câmera aparece só na primeira vez', (tester) async {
    final results = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                results.add(await const CameraNotice().confirm(context)),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Usar a câmera'), findsOneWidget);
    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();
    expect(results, [false]);

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(results, [false, true]);

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Usar a câmera'), findsNothing);
    expect(results, [false, true, true]);
    expect(
      await SharedPreferencesAsync().getBool(CameraNotice.storageKey),
      isTrue,
    );
  });

  group('Conta', () {
    late FakeAuthRepository repository;
    late AuthController controller;

    setUp(() async {
      repository = FakeAuthRepository()..restored = account;
      controller = AuthController(repository: repository);
      await controller.initialize();
    });
    tearDown(() => controller.dispose());

    test('Alterar senha pede a senha atual e valida a nova', () async {
      await controller.changePassword('', 'senhaforte1', 'senhaforte1');
      expect(controller.message, 'Informe a senha atual.');
      await controller.changePassword('senha-atual', 'curta', 'curta');
      expect(controller.message, contains('8 a 128'));
      await controller.changePassword(
        'senha-atual',
        'senhaforte1',
        'senhaforte2',
      );
      expect(controller.message, 'As senhas não coincidem.');
      expect(repository.calls, 0);

      await controller.changePassword('errada', 'senhaforte1', 'senhaforte1');
      expect(controller.message, 'Senha atual incorreta.');
      expect(repository.calls, 0);

      await controller.changePassword(
        'senha-atual',
        'senhaforte1',
        'senhaforte1',
      );
      expect(controller.message, 'Senha alterada.');
      expect(repository.calls, 1);
    });

    test('Excluir conta com senha exige informar a senha', () async {
      await controller.deleteAccount();
      expect(controller.message, 'Informe sua senha para excluir a conta.');
      expect(repository.deleteAccountCalls, 0);
    });

    test('Conta do Google exclui sem senha (servidor pede login recente)', () async {
      final google = FakeAuthRepository()
        ..restored = const UserModel(
          id: 'g',
          email: 'g@example.com',
          displayName: 'G',
          hasPassword: false,
        );
      final googleController = AuthController(repository: google);
      addTearDown(googleController.dispose);
      await googleController.initialize();
      await googleController.deleteAccount();
      expect(google.deleteAccountCalls, 1);
      expect(google.lastDeletePassword, isNull);
    });

    test('Sair de todos os aparelhos encerra a sessão local', () async {
      await controller.signOutEverywhere();
      expect(repository.signOutEverywhereCalls, 1);
      expect(controller.user, isNull);
    });

    test('Falha ao excluir mantém a conta e mostra a mensagem', () async {
      repository.failure = const AuthFailure('Sem conexão.');
      await controller.deleteAccount(password: 'senha-atual');
      expect(controller.user, isNotNull);
      expect(controller.message, 'Sem conexão.');
    });

    testWidgets('Excluir conta pede dois avisos e digitar EXCLUIR', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) =>
                    AccountSecuritySection(controller: controller),
              ),
            ),
          ),
        ),
      );

      // Primeiro aviso: desistir não apaga nada.
      await tester.tap(find.text('Excluir minha conta'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir sua conta?'), findsOneWidget);
      expect(find.text('Conta: ${account.email}'), findsOneWidget);
      await tester.tap(find.text('Manter minha conta'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir sua conta?'), findsNothing);
      expect(repository.deleteAccountCalls, 0);

      // Segundo aviso: só libera depois de digitar EXCLUIR.
      await tester.tap(find.text('Excluir minha conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Tem certeza?'), findsOneWidget);
      final button = find.widgetWithText(
        FilledButton,
        'Excluir definitivamente',
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, 'excluir');
      await tester.pump();
      // Conta com senha: também precisa informar a senha.
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.enterText(find.byType(TextField).last, 'senha-atual');
      await tester.pump();
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(repository.deleteAccountCalls, 1);
      expect(repository.lastDeletePassword, 'senha-atual');
      expect(controller.user, isNull);
      expect(controller.message, startsWith('Conta excluída.'));
    });
  });
}
