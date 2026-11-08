import 'dart:async';

import 'package:ecolens/widgets/eco_spinner.dart';
import 'package:ecolens/controllers/theme_controller.dart';
import 'package:ecolens/core/theme/app_theme.dart';
import 'package:ecolens/models/species_model.dart';
import 'package:ecolens/screens/home/home_screen.dart';
import 'package:ecolens/screens/species/species_catalog_screen.dart';
import 'package:ecolens/screens/species/species_detail_screen.dart';
import 'package:ecolens/widgets/home/recent_species_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const first = SpeciesModel(
  commonName: 'Escorpião-amarelo',
  scientificName: 'Tityus serrulatus',
  status: SpeciesStatus.danger,
  description: 'Descrição atualizada do catálogo',
  imageCredit: 'Autoria preservada',
  sourceName: 'Fonte do catálogo',
);
const second = SpeciesModel(
  commonName: 'Capivara',
  scientificName: 'Hydrochoerus hydrochaeris',
  status: SpeciesStatus.unverified,
);
const third = SpeciesModel(
  commonName: 'Jararaca',
  scientificName: 'Bothrops jararaca',
  status: SpeciesStatus.danger,
);
const fourth = SpeciesModel(
  commonName: 'Tucano',
  scientificName: 'Ramphastos toco',
  status: SpeciesStatus.unverified,
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Widget section(
    Future<List<SpeciesModel>> Function() fetch, {
    ValueChanged<SpeciesModel>? onTap,
    bool dark = false,
    double scale = 1,
  }) => MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: RecentSpeciesSection(
            fetchPublishedSpecies: fetch,
            onSpeciesTap: onTap ?? (_) {},
            onViewAllTap: () {},
          ),
        ),
      ),
    ),
  );

  testWidgets('Carregamento da seção não bloqueia ações da Home', (
    tester,
  ) async {
    final pending = Completer<List<SpeciesModel>>();
    final theme = ThemeController();
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          themeController: theme,
          fetchPublishedSpecies: () => pending.future,
        ),
      ),
    );
    await tester.pump();
    expect(find.byTooltip('Abrir SOS ambiental'), findsOneWidget);
    expect(
      tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .onPressed,
      isNotNull,
    );
    await tester.scrollUntilVisible(
      find.byType(RecentSpeciesSection),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(EcoSpinner), findsOneWidget);
    expect(find.text('Dados de demonstração'), findsNothing);
    pending.complete([first]);
    await tester.pumpAndSettle();
    expect(find.text(first.commonName), findsOneWidget);
  });

  testWidgets('Sucesso mantém ordem retornada e limita a três cards', (
    tester,
  ) async {
    SpeciesModel? tapped;
    await tester.pumpWidget(
      section(
        () async => [first, second, third, fourth],
        onTap: (item) {
          tapped = item;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Explore as espécies'), findsOneWidget);
    await tester.tap(find.text(first.commonName));
    expect(tapped, same(first));
    final horizontal = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text(second.commonName),
      100,
      scrollable: horizontal,
    );
    await tester.tap(find.text(second.commonName));
    expect(tapped, same(second));
    await tester.scrollUntilVisible(
      find.text(third.commonName),
      100,
      scrollable: horizontal,
    );
    await tester.tap(find.text(third.commonName));
    expect(tapped, same(third));
    await tester.drag(find.byType(ListView), const Offset(-800, 0));
    await tester.pumpAndSettle();
    expect(find.text(fourth.commonName), findsNothing);
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(
      list.childrenDelegate.estimatedChildCount,
      5,
    ); // 3 cards + 2 separadores.
  });

  testWidgets('Vazio informa ausência de espécies publicadas', (tester) async {
    await tester.pumpWidget(section(() async => []));
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhuma espécie publicada disponível no momento.'),
      findsOneWidget,
    );
    expect(find.byType(InkWell), findsOneWidget); // Apenas Ver todas.
  });

  testWidgets('Falha não usa demonstração e retry consulta novamente', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      section(() async {
        if (++calls == 1) throw StateError('offline');
        return [first];
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar as espécies.'), findsOneWidget);
    expect(find.text('Jararaca'), findsNothing);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text(first.commonName), findsOneWidget);
    expect(find.text('Não foi possível carregar as espécies.'), findsNothing);
  });

  testWidgets('Rebuild de tema não repete consulta', (tester) async {
    var calls = 0;
    Future<List<SpeciesModel>> fetch() async {
      calls++;
      return [first];
    }

    await tester.pumpWidget(section(fetch));
    await tester.pumpAndSettle();
    await tester.pumpWidget(section(fetch, dark: true));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text(first.commonName), findsOneWidget);
  });

  for (final fail in [false, true]) {
    testWidgets(
      'Consulta concluída após descarte: ${fail ? 'erro' : 'sucesso'}',
      (tester) async {
        final pending = Completer<List<SpeciesModel>>();
        await tester.pumpWidget(section(() => pending.future));
        await tester.pump();
        await tester.pumpWidget(const SizedBox());
        if (fail) {
          pending.completeError(StateError('offline'));
        } else {
          pending.complete([first]);
        }
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Home abre modelo real com favorito e preserva detalhes; Ver todas abre catálogo',
    (tester) async {
      final theme = ThemeController();
      addTearDown(theme.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            themeController: theme,
            fetchPublishedSpecies: () async => [first],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(first.commonName),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text(first.commonName)),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(first.commonName));
      await tester.pumpAndSettle();
      final detail = tester.widget<SpeciesDetailScreen>(
        find.byType(SpeciesDetailScreen),
      );
      expect(detail.species, same(first));
      expect(detail.species.imageCredit, 'Autoria preservada');
      expect(detail.isDemonstration, isFalse);
      await tester.tap(find.byTooltip('Adicionar aos favoritos'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remover dos favoritos'), findsOneWidget);
      expect(find.textContaining('DEMONSTRAÇÃO'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Ver todas'),
        -100,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(find.text('Ver todas')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver todas'));
      await tester.pumpAndSettle();
      expect(find.byType(SpeciesCatalogScreen), findsOneWidget);
      expect(
        tester
            .widget<SpeciesCatalogScreen>(find.byType(SpeciesCatalogScreen))
            .initialQuery,
        isEmpty,
      );
    },
  );

  testWidgets('Imagem de rede com falha e imagem ausente usam placeholder', (
    tester,
  ) async {
    const withImage = SpeciesModel(
      commonName: 'Espécie com foto',
      scientificName: 'Genus species',
      status: SpeciesStatus.unverified,
      imageUrl: 'https://example.invalid/photo.jpg',
    );
    await tester.pumpWidget(section(() async => [withImage, second]));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.eco_outlined), findsWidgets);
    await tester.scrollUntilVisible(
      find.text(second.commonName),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text(second.commonName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    for (final state in ['carregando', 'sucesso', 'vazio', 'erro']) {
      testWidgets('320x480 texto 2x ${dark ? 'escuro' : 'claro'}: $state', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final pending = Completer<List<SpeciesModel>>();
        Future<List<SpeciesModel>> fetch() async {
          if (state == 'carregando') return pending.future;
          if (state == 'erro') throw StateError('offline');
          return state == 'vazio' ? [] : [first, second, third];
        }

        await tester.pumpWidget(section(fetch, dark: dark, scale: 2));
        if (state == 'carregando') {
          await tester.pump();
          expect(find.byType(EcoSpinner), findsOneWidget);
        } else {
          await tester.pumpAndSettle();
          if (state == 'sucesso') {
            await tester.scrollUntilVisible(
              find.text(first.commonName),
              100,
              scrollable: find.byType(Scrollable).first,
            );
            await Scrollable.ensureVisible(
              tester.element(find.byType(ListView)),
              alignment: 0.5,
            );
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.text(third.commonName),
              100,
              scrollable: find.byType(Scrollable).last,
            );
            expect(find.text(third.commonName), findsOneWidget);
          }
          if (state == 'erro') {
            expect(find.text('Tentar novamente'), findsOneWidget);
          }
          if (state == 'vazio') {
            expect(
              find.textContaining('Nenhuma espécie publicada'),
              findsOneWidget,
            );
          }
        }
        expect(tester.takeException(), isNull);
        if (state == 'carregando') {
          await tester.pumpWidget(const SizedBox());
          pending.complete([]);
          await tester.pump();
        }
      });
    }
  }
}
