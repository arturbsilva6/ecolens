import 'package:flutter_test/flutter_test.dart';
import 'package:ecolens/models/species_model.dart';
import 'package:ecolens/utils/species_catalog_filter.dart';

void main() {
  const species = <SpeciesModel>[
    SpeciesModel(
      commonName: 'Jararaca',
      scientificName: 'Bothrops jararaca',
      status: SpeciesStatus.danger,
    ),
    SpeciesModel(
      commonName: 'Cambará',
      scientificName: 'Lantana camara',
      status: SpeciesStatus.invasive,
    ),
    SpeciesModel(
      commonName: 'Sagui',
      scientificName: 'Callithrix sp.',
      status: SpeciesStatus.unverified,
    ),
  ];

  test('Todas inclui as espécies recebidas', () {
    final result = filterSpeciesCatalog(species);
    expect(result.length, 3);
  });

  test('Perigosas mostra somente o status danger', () {
    final result = filterSpeciesCatalog(
      species,
      filter: SpeciesCatalogFilter.danger,
    );
    expect(result.map((s) => s.commonName), ['Jararaca']);
  });

  test('Invasoras mostra somente o status invasive', () {
    final result = filterSpeciesCatalog(
      species,
      filter: SpeciesCatalogFilter.invasive,
    );
    expect(result.map((s) => s.commonName), ['Cambará']);
  });

  test('A verificar mostra somente o status unverified', () {
    final result = filterSpeciesCatalog(
      species,
      filter: SpeciesCatalogFilter.unverified,
    );
    expect(result.map((s) => s.commonName), ['Sagui']);
  });

  test('Busca ignora maiúsculas e acentos', () {
    final result = filterSpeciesCatalog(species, query: 'CAMBARA');
    expect(result.map((s) => s.commonName), ['Cambará']);
  });

  test('Busca pelo nome científico combina com o filtro', () {
    final result = filterSpeciesCatalog(
      species,
      query: 'bothrops',
      filter: SpeciesCatalogFilter.danger,
    );
    expect(result.map((s) => s.commonName), ['Jararaca']);
  });

  test('Combinação incompatível não retorna espécies', () {
    final result = filterSpeciesCatalog(
      species,
      query: 'bothrops',
      filter: SpeciesCatalogFilter.invasive,
    );
    expect(result, isEmpty);
  });
}
