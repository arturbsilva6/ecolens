import 'dart:convert';
import 'dart:io';

import 'package:ecolens/data/supabase_species_repository.dart';
import 'package:ecolens/models/species_model.dart';
import 'package:ecolens/models/species_status_style.dart';
import 'package:ecolens/screens/species/species_detail_screen.dart';
import 'package:ecolens/services/supabase_service.dart';
import 'package:ecolens/utils/species_catalog_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _caramujo = SpeciesModel(
  commonName: 'Caramujo-africano',
  scientificName: 'Achatina fulica',
  status: SpeciesStatus.caution,
  isInvasive: true,
  speciesGroup: 'molusco',
  otherNames: ['Caramujo-gigante'],
  mainColors: ['marrom'],
  visualPattern: 'Concha cônica alongada com listras marrons.',
  lookalikes: ['Aruá-do-mato (Megalobulimus spp.): nativo e protegido.'],
  rescueAdvice: 'Não é caso de resgate.',
  safetyAdvice: 'Use luvas.',
);

const _catalogo = <SpeciesModel>[
  SpeciesModel(
    commonName: 'Jararaca',
    scientificName: 'Bothrops jararaca',
    status: SpeciesStatus.danger,
  ),
  _caramujo,
  SpeciesModel(
    commonName: 'Falsa-coral',
    scientificName: 'Oxyrhopus guibei',
    status: SpeciesStatus.harmless,
    otherNames: ['Coral-falsa'],
  ),
  SpeciesModel(
    commonName: 'Leucena',
    scientificName: 'Leucaena leucocephala',
    status: SpeciesStatus.invasive,
  ),
];

Map<String, dynamic> _linha({bool comGuia = true}) => {
  'common_name': 'Caramujo-africano',
  'scientific_name': 'Achatina fulica',
  'status': 'caution',
  'description': 'Exótico invasor.',
  'characteristics': null,
  'habitat': null,
  'risk_description': null,
  'safety_advice': 'Use luvas.',
  'source_name': 'Ministério da Saúde',
  'source_url': 'https://www.gov.br/saude',
  'image_url': 'https://example.org/sem-licenca.jpg',
  if (comGuia) ...{
    'is_invasive': true,
    'species_group': 'molusco',
    'other_names': ['Caramujo-gigante'],
    'main_colors': ['marrom'],
    'visual_pattern': 'Concha cônica.',
    'lookalikes': ['Aruá-do-mato.'],
    'rescue_advice': 'Não é caso de resgate.',
  },
};

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  SupabaseClient client(http.Client transport) {
    final result = SupabaseClient(
      'https://example.invalid',
      'test-publishable-key',
      httpClient: transport,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(result.dispose);
    return result;
  }

  SupabaseSpeciesRepository repositorio(http.Client transport) =>
      SupabaseSpeciesRepository(
        client: client(transport),
        supabaseService: SupabaseService(url: '', publishableKey: ''),
      );

  http.Response json(http.Request request, Object body, {int status = 200}) =>
      http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
        request: request,
      );

  test('Lê categorias novas e campos do guia', () async {
    final selects = <String>[];
    final transport = MockClient((request) async {
      selects.add(request.url.queryParameters['select']!);
      return json(request, [_linha()]);
    });
    addTearDown(transport.close);

    final species = (await repositorio(transport).fetchRemoteSpecies()).single;

    expect(selects.single, contains('rescue_advice'));
    expect(species.status, SpeciesStatus.caution);
    expect(species.isInvasive, isTrue);
    expect(species.otherNames, ['Caramujo-gigante']);
    expect(species.lookalikes, ['Aruá-do-mato.']);
    expect(species.rescueAdvice, 'Não é caso de resgate.');
    // Foto sem licença verificada não é exibida.
    expect(species.imageUrl, isNull);
  });

  test('Sem a migração aplicada, lê só as colunas antigas', () async {
    final selects = <String>[];
    final transport = MockClient((request) async {
      final select = request.url.queryParameters['select']!;
      selects.add(select);
      if (select.contains('rescue_advice')) {
        return json(request, {
          'code': '42703',
          'message': 'column species.is_invasive does not exist',
        }, status: 400);
      }
      return json(request, [_linha(comGuia: false)]);
    });
    addTearDown(transport.close);

    final species = (await repositorio(transport).fetchRemoteSpecies()).single;

    expect(selects, hasLength(2));
    expect(selects.last, isNot(contains('rescue_advice')));
    expect(species.status, SpeciesStatus.caution);
    expect(species.isInvasive, isFalse);
    expect(species.otherNames, isEmpty);
  });

  test('Outros erros do servidor não são escondidos', () async {
    final transport = MockClient(
      (request) async => json(request, {
        'code': '42501',
        'message': 'permission denied',
      }, status: 401),
    );
    addTearDown(transport.close);

    await expectLater(
      repositorio(transport).fetchRemoteSpecies(),
      throwsA(isA<PostgrestException>()),
    );
  });

  test('Status desconhecido vira "Demais"', () {
    final species = SpeciesModel.fromJson({
      'common_name': 'X',
      'scientific_name': 'Y',
      'status': 'novo-status',
    });
    expect(species.status, SpeciesStatus.unverified);
  });

  test('Cópia offline preserva os campos do guia', () {
    final copia = SpeciesModel.fromJson(
      jsonDecode(jsonEncode(_caramujo.toJson())) as Map<String, dynamic>,
    );
    expect(copia.status, SpeciesStatus.caution);
    expect(copia.isInvasive, isTrue);
    expect(copia.speciesGroup, 'molusco');
    expect(copia.otherNames, _caramujo.otherNames);
    expect(copia.mainColors, _caramujo.mainColors);
    expect(copia.visualPattern, _caramujo.visualPattern);
    expect(copia.lookalikes, _caramujo.lookalikes);
    expect(copia.rescueAdvice, _caramujo.rescueAdvice);
  });

  test('Filtros de cautela, inofensivas e invasoras', () {
    List<String> nomes(SpeciesCatalogFilter filter) => filterSpeciesCatalog(
      _catalogo,
      filter: filter,
    ).map((s) => s.commonName).toList();

    expect(nomes(SpeciesCatalogFilter.caution), ['Caramujo-africano']);
    expect(nomes(SpeciesCatalogFilter.harmless), ['Falsa-coral']);
    expect(nomes(SpeciesCatalogFilter.invasive), [
      'Caramujo-africano',
      'Leucena',
    ]);
    expect(SpeciesCatalogFilter.caution.label, 'Cautela');
    expect(SpeciesCatalogFilter.harmless.label, 'Inofensivas');
  });

  test('Busca também encontra outros nomes populares', () {
    final result = filterSpeciesCatalog(_catalogo, query: 'coral falsa');
    expect(result, isEmpty);
    final porNome = filterSpeciesCatalog(_catalogo, query: 'Coral-falsa');
    expect(porNome.single.commonName, 'Falsa-coral');
  });

  test('Cada categoria tem rótulo e cor próprios', () {
    final cores = SpeciesStatus.values.map((s) => s.color).toSet();
    expect(cores, hasLength(SpeciesStatus.values.length));
    expect(SpeciesStatus.harmless.shortLabel, 'Inofensiva');
    expect(SpeciesStatus.caution.shortLabel, 'Cautela');
    expect(_caramujo.statusSummary, 'Exige cautela: evite contato · invasora');
  });

  testWidgets('Ficha mostra outros nomes, confusões e resgate', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SpeciesDetailScreen(species: _caramujo, isDemonstration: false),
      ),
    );

    expect(
      find.text('Também conhecida como: Caramujo-gigante'),
      findsOneWidget,
    );
    expect(
      find.text('Exige cautela: evite contato · invasora'),
      findsOneWidget,
    );

    for (final texto in [
      'Quando chamar resgate',
      'Como reconhecer',
      'Pode ser confundida com',
      '• Aruá-do-mato (Megalobulimus spp.): nativo e protegido.',
    ]) {
      await tester.scrollUntilVisible(
        find.text(texto),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(texto), findsOneWidget);
    }
  });

  test('Dados curados do catálogo estão completos', () {
    final file = File('supabase/data/curated_species.json');
    final fichas = (jsonDecode(file.readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

    expect(fichas, hasLength(50));
    expect(fichas.map((f) => f['slug']).toSet(), hasLength(50));
    for (final ficha in fichas) {
      expect(
        ['danger', 'caution', 'harmless'],
        contains(ficha['status']),
        reason: ficha['slug'] as String,
      );
      for (final campo in ['safety_advice', 'risk_description', 'habitat']) {
        expect(
          (ficha[campo] as String).trim(),
          isNotEmpty,
          reason: '${ficha['slug']}: $campo',
        );
      }
      // Disque-Intoxicação é o número nacional; CIATox são os centros
      // regionais e só podem aparecer como nome de fonte.
      for (final campo in ['safety_advice', 'risk_description', 'rescue_advice']) {
        expect(
          ficha[campo] as String,
          isNot(contains('CIATox')),
          reason: '${ficha['slug']}: $campo',
        );
      }
      final url = ficha['source_url'] as String?;
      if (url != null) {
        expect(url, startsWith('https://'), reason: ficha['slug'] as String);
      }
    }
  });
}
