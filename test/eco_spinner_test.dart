import 'package:ecolens/widgets/eco_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> show(WidgetTester tester, Widget child, {bool still = false}) =>
      tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: still),
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      );

  double start(WidgetTester tester) => (tester
          .widget<ClipPath>(
            find.descendant(
              of: find.byType(EcoSpinner),
              matching: find.byType(ClipPath),
            ),
          )
          .clipper! as EcoArcClipper)
      .from;

  testWidgets('Sem valor, o símbolo gira enquanto carrega', (tester) async {
    await show(tester, const EcoSpinner());
    expect(find.bySemanticsLabel('Carregando'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    final first = start(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(start(tester), greaterThan(first));
  });

  testWidgets('Com valor, informa o progresso e fica parado', (tester) async {
    await show(tester, const EcoSpinner(value: .4, semanticsLabel: 'Baixando'));
    final node = tester.getSemantics(find.bySemanticsLabel('Baixando'));
    expect(node.value, '40%');
    await tester.pumpAndSettle();
  });

  testWidgets('Remover animações deixa o símbolo parado', (tester) async {
    await show(tester, const EcoSpinner(), still: true);
    await tester.pumpAndSettle();
    expect(find.byType(EcoSpinner), findsOneWidget);
  });
}
