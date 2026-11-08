import 'dart:convert';
import 'dart:io';

import 'package:ecolens/models/species_model.dart';
import 'package:ecolens/utils/species_catalog_filter.dart';
import 'package:flutter_test/flutter_test.dart';

const _catalogo = <SpeciesModel>[
  SpeciesModel(
    commonName: 'Jararaca',
    scientificName: 'Bothrops jararaca',
    status: SpeciesStatus.danger,
    speciesGroup: 'serpente',
  ),
  SpeciesModel(
    commonName: 'Chapéu-de-napoleão',
    scientificName: 'Thevetia peruviana',
    status: SpeciesStatus.danger,
    speciesGroup: 'planta',
  ),
  SpeciesModel(
    commonName: 'Pitangueira',
    scientificName: 'Eugenia uniflora',
    status: SpeciesStatus.harmless,
    speciesGroup: 'planta',
    otherNames: ['Pitanga'],
  ),
  SpeciesModel(
    commonName: 'Tucano-toco',
    scientificName: 'Ramphastos toco',
    status: SpeciesStatus.unverified,
  ),
];

List<String> _nomes(
  SpeciesKindFilter kind, {
  SpeciesCatalogFilter filter = SpeciesCatalogFilter.all,
  String query = '',
}) => filterSpeciesCatalog(
  _catalogo,
  kind: kind,
  filter: filter,
  query: query,
).map((s) => s.commonName).toList();

void main() {
  test('Filtro separa animais e plantas', () {
    expect(_nomes(SpeciesKindFilter.all), hasLength(4));
    expect(_nomes(SpeciesKindFilter.plants), [
      'Chapéu-de-napoleão',
      'Pitangueira',
    ]);
    // Sem grupo informado, a ficha fica entre os animais.
    expect(_nomes(SpeciesKindFilter.animals), ['Jararaca', 'Tucano-toco']);
    expect(SpeciesKindFilter.plants.label, 'Plantas');
  });

  test('Filtro de plantas combina com risco e busca', () {
    expect(
      _nomes(SpeciesKindFilter.plants, filter: SpeciesCatalogFilter.danger),
      ['Chapéu-de-napoleão'],
    );
    expect(_nomes(SpeciesKindFilter.plants, query: 'pitanga'), ['Pitangueira']);
    expect(_nomes(SpeciesKindFilter.animals, query: 'pitanga'), isEmpty);
  });

  test('Plantas novas estão completas e com orientação correta', () {
    final fichas = (jsonDecode(
      File('supabase/data/curated_plants.json').readAsStringSync(),
    ) as List).cast<Map<String, dynamic>>();
    final atuais = (jsonDecode(
      File('supabase/data/curated_species.json').readAsStringSync(),
    ) as List).cast<Map<String, dynamic>>();

    expect(fichas, hasLength(12));
    final slugs = fichas.map((f) => f['slug']).toSet();
    expect(slugs, hasLength(12));
    // Não repete fichas da curadoria anterior.
    expect(slugs.intersection(atuais.map((f) => f['slug']).toSet()), isEmpty);

    for (final ficha in fichas) {
      final slug = ficha['slug'] as String;
      expect(ficha['species_group'], 'planta', reason: slug);
      expect(
        ['danger', 'caution', 'harmless'],
        contains(ficha['status']),
        reason: slug,
      );
      for (final campo in [
        'common_name',
        'scientific_name',
        'visual_pattern',
        'description',
        'characteristics',
        'habitat',
        'risk_description',
        'safety_advice',
        'source_name',
      ]) {
        expect(
          (ficha[campo] as String).trim(),
          isNotEmpty,
          reason: '$slug: $campo',
        );
      }
      expect(ficha['source_url'] as String, startsWith('https://'));
      // Plantas tóxicas indicam o Disque-Intoxicação nacional.
      if (ficha['status'] != 'harmless' && slug != 'urera-baccifera') {
        expect(
          ficha['safety_advice'] as String,
          contains('0800 722 6001'),
          reason: slug,
        );
      }
    }
  });

  test('Cada planta nova tem foto com licença livre', () {
    final fotos =
        ((jsonDecode(File('supabase/data/plant_photos.json').readAsStringSync())
                    as Map<String, dynamic>)['novas']
                as List)
            .cast<Map<String, dynamic>>();
    final fichas = (jsonDecode(
      File('supabase/data/curated_plants.json').readAsStringSync(),
    ) as List).cast<Map<String, dynamic>>();
    final licencas = RegExp(r'^(CC0|CC BY(-SA)? \d\.\d|Domínio público)$');

    expect(
      fotos.map((f) => f['slug']).toSet(),
      fichas.map((f) => f['slug']).toSet(),
    );
    for (final foto in fotos) {
      expect(
        licencas.hasMatch(foto['image_license_label'] as String),
        isTrue,
        reason: foto['slug'] as String,
      );
      expect((foto['image_credit'] as String).trim(), isNotEmpty);
      expect(
        foto['image_url'] as String,
        startsWith('https://upload.wikimedia.org/'),
      );
      expect(foto['image_license_url'] as String, startsWith('https://'));
    }
  });
}
