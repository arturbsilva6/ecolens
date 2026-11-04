import 'package:ecolens/data/identification_history_repository.dart';
import 'package:ecolens/models/ai_identification_result.dart';
import 'package:ecolens/screens/identification/identification_history_screen.dart';
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
  late IdentificationHistoryRepository repository;

  setUp(() {
    repository = IdentificationHistoryRepository(store: _MemoryStore());
  });

  testWidgets('Histórico vazio oferece instrução sem foto', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: IdentificationHistoryScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Meus registros'), findsOneWidget);
    expect(find.textContaining('Nenhum registro salvo ainda'), findsOneWidget);
    expect(find.textContaining('Fotografias não são armazenadas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Registro salvo pode ser consultado e excluído', (tester) async {
    await repository.save(
      const AiIdentificationResult(
        identified: true,
        commonName: 'Jararaca',
        scientificName: 'Bothrops jararaca',
        explanation: 'Padrões visuais descritos pela IA.',
      ),
      matchedCatalog: true,
    );
    await tester.pumpWidget(
      MaterialApp(home: IdentificationHistoryScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jararaca'), findsOneWidget);
    await tester.tap(find.text('Jararaca'));
    await tester.pumpAndSettle();
    expect(find.text('Registro de identificação'), findsOneWidget);
    expect(find.text('Padrões visuais descritos pela IA.'), findsOneWidget);
    await tester.ensureVisible(find.text('Excluir este registro'));
    await tester.tap(find.text('Excluir este registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nenhum registro salvo ainda'), findsOneWidget);
    expect(await repository.load(), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
