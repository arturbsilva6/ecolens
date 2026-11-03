import 'dart:async';

import 'package:ecolens/app.dart';
import 'package:ecolens/screens/home/home_screen.dart';
import 'package:ecolens/screens/sos/sos_screen.dart';
import 'package:ecolens/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> openSos(WidgetTester tester, SupabaseService service) async {
    await tester.pumpWidget(EcoLensApp(supabaseService: service));
    expect(find.byType(HomeScreen), findsOneWidget);

    final sos = find.byTooltip('Abrir SOS ambiental');
    final button = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(button.backgroundColor, const Color(0xFFD9292F));
    expect(button.onPressed, isNotNull);

    await tester.tap(sos);
    await tester.pumpAndSettle();

    expect(find.byType(SosScreen), findsOneWidget);
    expect(find.text('SAMU · 192'), findsOneWidget);
    expect(find.text('Corpo de Bombeiros · 193'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  testWidgets('Home e SOS abrem sem configuração do Supabase', (tester) async {
    await openSos(tester, SupabaseService(url: '', publishableKey: ''));
  });

  testWidgets('Home e SOS abrem enquanto o SDK ainda está inicializando', (
    tester,
  ) async {
    final pending = Completer<SupabaseClient>();
    var started = false;
    final service = SupabaseService(
      url: 'https://example.invalid',
      publishableKey: 'test-publishable-key',
      initializer: (_, _) {
        // O SDK é acionado somente depois de a Home ter sido construída.
        expect(find.byType(HomeScreen), findsOneWidget);
        started = true;
        return pending.future;
      },
    );

    await openSos(tester, service);
    expect(started, isTrue);
    expect(pending.isCompleted, isFalse);

    pending.completeError(http.ClientException('Sem conexão.'));
    await tester.pump();
    expect(find.byType(SosScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Falha de rede na inicialização não bloqueia Home ou SOS', (
    tester,
  ) async {
    await openSos(
      tester,
      SupabaseService(
        url: 'https://example.invalid',
        publishableKey: 'test-publishable-key',
        initializer: (_, _) async => throw http.ClientException('Sem conexão.'),
      ),
    );
  });

  testWidgets('Erro síncrono do SDK não bloqueia Home ou SOS', (tester) async {
    await openSos(
      tester,
      SupabaseService(
        url: 'https://example.invalid',
        publishableKey: 'test-publishable-key',
        initializer: (_, _) => throw StateError('Falha do SDK.'),
      ),
    );
  });
}
