import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecolens/screens/sos/sos_screen.dart';

void main() {
  const launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcherChannel, (call) async {
          calls.add(call);
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcherChannel, null);
  });

  testWidgets('SOS apresenta contatos de emergência sem ligar sozinho', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SosScreen()));

    expect(find.text('SOS ambiental'), findsOneWidget);
    expect(find.text('SAMU · 192'), findsOneWidget);
    expect(find.text('Corpo de Bombeiros · 193'), findsOneWidget);
    expect(find.textContaining('Priorize sua segurança'), findsOneWidget);

    // Sem tocar em um botão, o teste não aciona aplicativos externos.
    expect(find.byIcon(Icons.phone_outlined), findsWidgets);
    expect(calls, isEmpty);
  });

  testWidgets('SOS solicita apenas o discador após toque explícito', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SosScreen()));
    expect(calls, isEmpty);

    await tester.tap(find.text('Abrir discador · 192'));
    await tester.pumpAndSettle();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'launch');
    expect((calls.single.arguments as Map)['url'], 'tel:192');
    expect((calls.single.arguments as Map)['useWebView'], isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final throwsError in [false, true]) {
    testWidgets(
      'SOS continua disponível se o discador falhar (exceção: $throwsError)',
      (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(launcherChannel, (_) async {
              if (throwsError) throw PlatformException(code: 'unavailable');
              return false;
            });
        await tester.pumpWidget(const MaterialApp(home: SosScreen()));

        await tester.tap(find.text('Abrir discador · 192'));
        await tester.pumpAndSettle();

        expect(find.byType(SosScreen), findsOneWidget);
        expect(find.text('SAMU · 192'), findsOneWidget);
        expect(
          find.text('Não foi possível abrir o aplicativo solicitado.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
