import 'package:ecolens/core/app_info.dart';
import 'package:ecolens/widgets/intro/app_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double opacityOf(WidgetTester tester, String word) => tester
    .widget<Opacity>(
      find.ancestor(of: find.text(word), matching: find.byType(Opacity)).first,
    )
    .opacity;

void main() {
  Future<int Function()> show(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(
            body: AppIntro(
              onFinished: () => finished++,
              startDelay: Duration.zero,
              waitForImages: false,
            ),
          ),
        ),
      ),
    );
    return () => finished;
  }

  testWidgets('Desenha o logo, mostra lema e versão e termina', (tester) async {
    final finished = await show(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(finished(), 0);

    // Primeiro vem "Identificar"; "e proteger" ainda está escondido.
    await tester.pump(const Duration(milliseconds: 2900));
    expect(opacityOf(tester, AppInfo.taglineFirst), greaterThan(0));
    expect(opacityOf(tester, AppInfo.taglineSecond), 0);

    await tester.pump(const Duration(milliseconds: 1300));
    expect(opacityOf(tester, AppInfo.taglineFirst), 1);
    expect(opacityOf(tester, AppInfo.taglineSecond), 1);
    expect(find.text('Versão ${AppInfo.version}'), findsOneWidget);
    expect(finished(), 0);

    await tester.pump(const Duration(milliseconds: 600));
    expect(finished(), 1);
  });

  testWidgets('Um toque pula a abertura', (tester) async {
    final finished = await show(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(AppIntro));
    await tester.pumpAndSettle();
    expect(finished(), 1);
  });

  testWidgets('Sem animações, mostra o logo pronto e fecha sozinha', (
    tester,
  ) async {
    final finished = await show(tester, reduceMotion: true);
    await tester.pump();
    expect(opacityOf(tester, AppInfo.taglineSecond), 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(finished(), 1);
  });

  test('Versão da abertura acompanha a do pubspec', () {
    expect(AppInfo.version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
  });
}
