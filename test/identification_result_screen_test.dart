import 'dart:convert';

import 'package:ecolens/models/ai_identification_result.dart';
import 'package:ecolens/models/species_model.dart';
import 'package:ecolens/screens/identification/identification_result_screen.dart';
import 'package:ecolens/screens/species/species_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final photoBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/pL8AAAAASUVORK5CYII=',
  );

  const suggestion = AiIdentificationResult(
    identified: true,
    commonName: 'Jararaca',
    scientificName: 'Bothrops jararaca',
    explanation: 'Padrões visuais encontrados na fotografia.',
  );

  const jararaca = SpeciesModel(
    commonName: 'Jararaca',
    scientificName: 'Bothrops jararaca',
    status: SpeciesStatus.danger,
    description: 'Ficha publicada no catálogo.',
  );

  testWidgets('Exibe fotografia, sugestão e aviso sem confiança inventada', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IdentificationResultScreen(
          imageBytes: photoBytes,
          result: suggestion,
          matchedSpecies: jararaca,
        ),
      ),
    );

    expect(find.text('Resultado da análise'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Ver ficha da espécie'), findsOneWidget);

    // A imagem ocupa grande parte da viewport padrão dos testes.
    // O título é criado pelo ListView somente após a rolagem.
    await tester.scrollUntilVisible(
      find.text('Espécie sugerida'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Espécie sugerida'), findsOneWidget);
    expect(find.text('Jararaca'), findsOneWidget);
    expect(find.text('Bothrops jararaca'), findsOneWidget);
    expect(find.textContaining('não confirmada'), findsWidgets);
    expect(find.textContaining('95%'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Abre ficha do catálogo sem tratá-la como demonstração', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IdentificationResultScreen(
          imageBytes: photoBytes,
          result: suggestion,
          matchedSpecies: jararaca,
        ),
      ),
    );

    await tester.tap(find.text('Ver ficha da espécie'));
    await tester.pumpAndSettle();

    expect(find.byType(SpeciesDetailScreen), findsOneWidget);
    expect(find.text('Ficha da espécie'), findsOneWidget);
    final detail = tester.widget<SpeciesDetailScreen>(
      find.byType(SpeciesDetailScreen),
    );
    expect(detail.species, same(jararaca));
    expect(detail.isDemonstration, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sem correspondência, não oferece abrir ficha', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IdentificationResultScreen(
          imageBytes: photoBytes,
          result: suggestion,
        ),
      ),
    );

    expect(find.text('Ver ficha da espécie'), findsNothing);
    expect(find.text('Nova identificação'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Análise inconclusiva não oferece abrir ficha', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IdentificationResultScreen(
          imageBytes: photoBytes,
          result: const AiIdentificationResult(
            identified: false,
            commonName: null,
            scientificName: null,
            explanation: 'Foto insuficiente para identificar a espécie.',
          ),
        ),
      ),
    );

    expect(find.text('Ver ficha da espécie'), findsNothing);
    expect(find.text('Nova identificação'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Resultado inconclusivo'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Resultado inconclusivo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Explicação longa pode ser expandida e recolhida', (
    tester,
  ) async {
    final longExplanation = List.filled(
      8,
      'A análise é experimental e descreve apenas traços visuais.',
    ).join(' ');

    await tester.pumpWidget(
      MaterialApp(
        home: IdentificationResultScreen(
          imageBytes: photoBytes,
          result: AiIdentificationResult(
            identified: true,
            commonName: 'Jararaca',
            scientificName: 'Bothrops jararaca',
            explanation: longExplanation,
          ),
          matchedSpecies: jararaca,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Ler explicação completa'),
      160,
      scrollable: find.byType(Scrollable).first,
    );

    final explanation = find.text(longExplanation);
    expect(tester.widget<Text>(explanation).maxLines, 3);

    await tester.tap(find.text('Ler explicação completa'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(explanation).maxLines, isNull);
    expect(find.text('Recolher explicação'), findsOneWidget);

    await tester.tap(find.text('Recolher explicação'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(explanation).maxLines, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nova identificação devolve sinal para limpar foto anterior', (
    tester,
  ) async {
    bool? startAgain;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  startAgain = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (context) => IdentificationResultScreen(
                        imageBytes: photoBytes,
                        result: suggestion,
                      ),
                    ),
                  );
                },
                child: const Text('Mostrar resultado'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mostrar resultado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova identificação'));
    await tester.pumpAndSettle();

    expect(startAgain, isTrue);
    expect(find.text('Mostrar resultado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
