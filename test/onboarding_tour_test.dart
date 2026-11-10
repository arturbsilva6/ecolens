import 'package:ecolens/widgets/onboarding/onboarding_tour.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  final first = GlobalKey();
  final second = GlobalKey();
  final missing = GlobalKey();

  Future<BuildContext> mount(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return Scaffold(
              body: Column(
                children: [
                  SizedBox(key: first, width: 200, height: 80),
                  const Spacer(),
                  SizedBox(key: second, width: 60, height: 60),
                ],
              ),
            );
          },
        ),
      ),
    );
    return context;
  }

  List<TourStep> steps() => [
    TourStep(target: first, title: 'Primeiro', text: 'Explica o primeiro.'),
    TourStep(target: missing, title: 'Sumido', text: 'Não está na tela.'),
    TourStep(target: second, title: 'Segundo', text: 'Explica o segundo.'),
  ];

  testWidgets('Percorre os passos, pula alvo ausente e marca como visto', (
    tester,
  ) async {
    final context = await mount(tester);
    expect(await OnboardingTour.seen(), isFalse);
    final done = OnboardingTour.show(context, steps());
    await tester.pumpAndSettle();

    expect(find.text('Passo 1 de 3'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Passo 1 de 3. Primeiro')),
      findsOneWidget,
    );
    expect(find.text('Voltar'), findsNothing);
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    // O passo sem alvo na tela é pulado sozinho.
    expect(find.text('Sumido'), findsNothing);
    expect(find.text('Passo 3 de 3'), findsOneWidget);
    expect(find.text('Pular'), findsNothing);
    await tester.tap(find.text('Começar a usar'));
    await tester.pumpAndSettle();
    await done;

    expect(find.text('Segundo'), findsNothing);
    expect(await OnboardingTour.seen(), isTrue);
  });

  testWidgets('Pular encerra o tour e não mostra de novo', (tester) async {
    final context = await mount(tester);
    final done = OnboardingTour.show(context, steps());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();
    await done;
    expect(find.text('Primeiro'), findsNothing);
    expect(
      await SharedPreferencesAsync().getBool('onboarding_tour_seen_v1'),
      isTrue,
    );
  });
}
