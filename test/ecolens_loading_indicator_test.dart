import 'package:ecolens/widgets/ecolens_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Carregamento mostra o símbolo e a mensagem', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EcoLensLoadingIndicator(message: 'Identificando espécie...'),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/branding/ecolens_logo_loader.png',
    );
    expect(find.text('Identificando espécie...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Desativa o movimento quando solicitado pelo sistema',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: EcoLensLoadingIndicator()),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('Carregando...'), findsOneWidget);
  });

  testWidgets('Diálogo usa a marca em vez do spinner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => const EcoLensLoadingDialog(
                  message: 'Buscando espécies...',
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(EcoLensLoadingDialog), findsOneWidget);
    expect(find.text('Buscando espécies...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
