import 'package:ecolens/widgets/home/header_vine.dart';
import 'package:ecolens/widgets/intro/intro_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(HeaderVine.resetForTest);

  Widget header(ValueNotifier<bool> done, {bool still = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: still),
      child: IntroStatus(
        done: done,
        child: const Scaffold(
          body: SizedBox(width: 400, height: 64, child: HeaderVine()),
        ),
      ),
    ),
  );

  testWidgets('Galho só cresce depois da abertura e toca uma vez', (
    tester,
  ) async {
    final done = ValueNotifier(false);
    addTearDown(done.dispose);
    await tester.pumpWidget(header(done));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isFalse);

    done.value = true;
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();

    // Reconstruir a Home não repete a animação.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(header(done));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('Com "Remover animações", o galho não aparece', (tester) async {
    final done = ValueNotifier(true);
    addTearDown(done.dispose);
    await tester.pumpWidget(header(done, still: true));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
