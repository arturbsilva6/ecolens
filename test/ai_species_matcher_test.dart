import 'package:ecolens/models/ai_identification_result.dart';
import 'package:ecolens/models/species_model.dart';
import 'package:ecolens/utils/ai_species_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const jararaca = SpeciesModel(
    commonName: 'Jararaca',
    scientificName: 'Bothrops jararaca',
    status: SpeciesStatus.danger,
  );

  const other = SpeciesModel(
    commonName: 'Jararaca-ilhoa',
    scientificName: 'Bothrops insularis',
    status: SpeciesStatus.danger,
  );

  const catalog = <SpeciesModel>[jararaca, other];

  AiIdentificationResult suggestion({
    bool identified = true,
    String? common = 'Jararaca',
    String? scientific = 'Bothrops jararaca',
  }) =>
      AiIdentificationResult(
        identified: identified,
        commonName: common,
        scientificName: scientific,
        explanation: 'Sugestão experimental.',
      );

  test('Liga sugestão ao nome científico exato publicado', () {
    expect(
      matchAiSuggestionToPublishedSpecies(suggestion(), catalog),
      same(jararaca),
    );
  });

  test('Ignora maiúsculas e espaços extras no nome científico', () {
    expect(
      matchAiSuggestionToPublishedSpecies(
        suggestion(scientific: '  BOTHROPS   JARARACA  '),
        catalog,
      ),
      same(jararaca),
    );
  });

  test('Não confunde espécies do mesmo gênero', () {
    expect(
      matchAiSuggestionToPublishedSpecies(
        suggestion(scientific: 'Bothrops atrox'),
        catalog,
      ),
      isNull,
    );
  });

  test('Nome popular sem nome científico não abre ficha', () {
    expect(
      matchAiSuggestionToPublishedSpecies(
        suggestion(scientific: null),
        catalog,
      ),
      isNull,
    );
  });

  test('Análise inconclusiva não abre ficha', () {
    expect(
      matchAiSuggestionToPublishedSpecies(
        suggestion(identified: false),
        catalog,
      ),
      isNull,
    );
  });

  test('Sugestão genérica de gênero não abre ficha', () {
    expect(
      matchAiSuggestionToPublishedSpecies(
        suggestion(scientific: 'Bothrops sp.'),
        catalog,
      ),
      isNull,
    );
  });

  test('Catálogo vazio não abre ficha', () {
    expect(
      matchAiSuggestionToPublishedSpecies(suggestion(), const []),
      isNull,
    );
  });
}
