import 'dart:convert';

import 'package:ecolens/data/identification_history_repository.dart';
import 'package:ecolens/models/ai_identification_result.dart';
import 'package:ecolens/screens/identification/identification_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements IdentificationHistoryStore {
  List<String> values = [];

  @override
  Future<List<String>?> read() async => List<String>.from(values);

  @override
  Future<void> write(List<String> updated) async {
    values = List<String>.from(updated);
  }
}

void main() {
  testWidgets('Resultado só entra no histórico após tocar em Salvar', (
    tester,
  ) async {
    final repository = IdentificationHistoryRepository(store: _MemoryStore());
    final imageBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/pL8AAAAASUVORK5CYII=',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: IdentificationResultScreen(
          imageBytes: imageBytes,
          result: const AiIdentificationResult(
            identified: true,
            commonName: 'Jararaca',
            scientificName: 'Bothrops jararaca',
            explanation: 'Características visuais observadas.',
          ),
          historyRepository: repository,
        ),
      ),
    );

    expect(await repository.load(), isEmpty);
    await tester.scrollUntilVisible(
      find.text('Salvar no histórico'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar no histórico'));
    await tester.pumpAndSettle();

    expect((await repository.load()).single.commonName, 'Jararaca');
    expect(find.text('Salvo no histórico'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
