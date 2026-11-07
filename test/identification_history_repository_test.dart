import 'dart:convert';

import 'package:ecolens/data/identification_history_repository.dart';
import 'package:ecolens/models/ai_identification_result.dart';
import 'package:ecolens/models/identification_history_entry.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements IdentificationHistoryStore {
  List<String> values = <String>[];

  @override
  Future<List<String>?> read() async => List<String>.from(values);

  @override
  Future<void> write(List<String> updated) async {
    values = List<String>.from(updated);
  }
}

void main() {
  late _MemoryStore store;
  late IdentificationHistoryRepository repository;

  const jararaca = AiIdentificationResult(
    identified: true,
    commonName: 'Jararaca',
    scientificName: 'Bothrops jararaca',
    explanation: 'A IA encontrou padrões de coloração.',
  );

  setUp(() {
    store = _MemoryStore();
    var tick = 0;
    repository = IdentificationHistoryRepository(
      store: store,
      now: () => DateTime.utc(2026, 11, 3).add(
        Duration(seconds: tick++),
      ),
    );
  });

  test('Histórico só é salvo após a ação explícita', () async {
    expect(await repository.load(), isEmpty);
    final entry = await repository.save(jararaca, matchedCatalog: true);
    final list = await repository.load();
    expect(list, hasLength(1));
    expect(list.single.id, entry.id);
    expect(list.single.scientificName, 'Bothrops jararaca');
    expect(list.single.matchedCatalog, isTrue);
    expect(list.single.createdAt.isUtc, isTrue);
  });

  test('Não guarda fotografias, segredos nem dados pessoais de sessão', () async {
    await repository.save(jararaca, matchedCatalog: false);
    final json = jsonDecode(store.values.single) as Map<String, dynamic>;
    expect(
      json.keys.toSet(),
      {
        'id',
        'createdAt',
        'identified',
        'commonName',
        'scientificName',
        'explanation',
        'matchedCatalog',
      },
    );
    expect(store.values.single, isNot(contains('imageBase64')));
    expect(store.values.single, isNot(contains('GEMINI_API_KEY')));
  });

  test('Registros permanecem legíveis em outra instância do repositório', () async {
    await repository.save(jararaca, matchedCatalog: true);
    final reopened = IdentificationHistoryRepository(store: store);
    expect((await reopened.load()).single.commonName, 'Jararaca');
  });

  test('Análise inconclusiva pode ser salva sem inventar espécie', () async {
    const result = AiIdentificationResult(
      identified: false,
      commonName: null,
      scientificName: null,
      explanation: 'A fotografia está desfocada.',
    );
    await repository.save(result, matchedCatalog: false);
    final entry = (await repository.load()).single;
    expect(entry.displayName, 'Análise inconclusiva');
    expect(entry.scientificName, isNull);
    expect(entry.identified, isFalse);
  });

  test('Exclusão individual e limpeza completa funcionam', () async {
    final first = await repository.save(jararaca, matchedCatalog: true);
    await repository.save(
      const AiIdentificationResult(
        identified: true,
        commonName: 'Capivara',
        scientificName: 'Hydrochoerus hydrochaeris',
        explanation: 'Animal semiaquático.',
      ),
      matchedCatalog: true,
    );
    await repository.delete(first.id);
    expect(await repository.load(), hasLength(1));
    expect((await repository.load()).single.commonName, 'Capivara');
    await repository.clear();
    expect(await repository.load(), isEmpty);
  });

  test('Ignora item corrompido sem perder os demais', () async {
    final good = IdentificationHistoryEntry.fromResult(
      jararaca,
      createdAt: DateTime.utc(2026, 11, 3),
      matchedCatalog: true,
    );
    store.values = <String>['not valid json', jsonEncode(good.toJson())];
    expect((await repository.load()).single.commonName, 'Jararaca');
  });

  test('Limita armazenamento aos 50 registros mais recentes', () async {
    for (var i = 0; i < 55; i++) {
      await repository.save(
        AiIdentificationResult(
          identified: true,
          commonName: 'Espécie $i',
          scientificName: 'Genus species',
          explanation: 'Descrição de teste $i',
        ),
        matchedCatalog: false,
      );
    }
    final records = await repository.load();
    expect(records, hasLength(50));
    expect(records.first.commonName, 'Espécie 54');
    expect(records.last.commonName, 'Espécie 5');
  });
}
