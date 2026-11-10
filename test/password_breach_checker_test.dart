import 'package:ecolens/controllers/auth_controller.dart';
import 'package:ecolens/services/password_breach_checker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_auth_repository.dart';

void main() {
  // SHA-1 de "password" = 5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8.
  const prefix = '5BAA6';
  const suffix = '1E4C9B93F3F0682250B6CF8331B7EE68FD8';

  test('Envia só o começo do hash e reconhece senha vazada', () async {
    Uri? asked;
    final checker = PasswordBreachChecker(
      client: MockClient((request) async {
        asked = request.url;
        expect(request.headers['Add-Padding'], 'true');
        return http.Response(
          '0000000000000000000000000000000000A:3\r\n$suffix:9545824\r\n',
          200,
        );
      }),
    );
    expect(await checker.isLeaked('password'), isTrue);
    expect(asked?.path, '/range/$prefix');
    // O resto do hash (e a senha) nunca vai na requisição.
    expect(asked.toString(), isNot(contains(suffix)));
  });

  test('Linha de preenchimento (contagem 0) não conta como vazada', () async {
    final checker = PasswordBreachChecker(
      client: MockClient((_) async => http.Response('$suffix:0\r\n', 200)),
    );
    expect(await checker.isLeaked('password'), isFalse);
  });

  test('Sem internet, não bloqueia o cadastro', () async {
    final checker = PasswordBreachChecker(
      client: MockClient((_) async => throw Exception('offline')),
    );
    expect(await checker.isLeaked('password'), isFalse);
  });

  test(
    'Cadastro com senha vazada é recusado antes de chegar ao servidor',
    () async {
      final repository = FakeAuthRepository();
      final controller = AuthController(
        repository: repository,
        isLeakedPassword: (_) async => true,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.signUp(
        'pessoa@example.com',
        'senha12345',
        'senha12345',
        'Pessoa',
      );
      expect(controller.message, contains('vazamentos'));
      expect(repository.calls, 0);
    },
  );
}
