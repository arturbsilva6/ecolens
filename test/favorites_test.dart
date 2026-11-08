import 'dart:async';

import 'package:ecolens/data/favorites_repository.dart';
import 'package:ecolens/data/identification_history_repository.dart';
import 'package:ecolens/controllers/theme_controller.dart';
import 'package:ecolens/models/ai_identification_result.dart';
import 'package:ecolens/models/species_model.dart';
import 'package:ecolens/screens/home/home_screen.dart';
import 'package:ecolens/screens/identification/identification_history_screen.dart';
import 'package:ecolens/screens/sos/sos_screen.dart';
import 'package:ecolens/screens/species/species_catalog_screen.dart';
import 'package:ecolens/utils/species_catalog_filter.dart';
import 'package:ecolens/screens/species/favorites_screen.dart';
import 'package:ecolens/screens/species/species_detail_screen.dart';
import 'package:ecolens/widgets/home/quick_access_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class MemoryFavoritesStore implements FavoritesStore {
  List<String> values = [];
  bool fail = false;
  bool failRead = false;
  @override
  Future<List<String>?> read() async {
    if (failRead) throw StateError('storage unavailable');
    return List.of(values);
  }

  @override
  Future<void> write(List<String> values) async {
    if (fail) throw StateError('storage unavailable');
    this.values = List.of(values);
  }
}

const species = SpeciesModel(
  commonName: 'Jararaca',
  scientificName: 'Bothrops jararaca',
  status: SpeciesStatus.danger,
);

void main() {
  late MemoryFavoritesStore store;
  late FavoritesRepository repository;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = MemoryFavoritesStore();
    repository = FavoritesRepository(store: store);
  });

  test(
    'Salva somente identificador normalizado, deduplica e persiste',
    () async {
      await repository.setFavorite(' Bothrops JARARACA ', true);
      await repository.setFavorite('bothrops jararaca', true);
      expect(store.values, ['bothrops jararaca']);
      expect(await FavoritesRepository(store: store).load(), {
        'bothrops jararaca',
      });
      await repository.setFavorite(' BOTHROPS jararaca ', false);
      expect(await repository.load(), isEmpty);
    },
  );

  test(
    'Ignora registros inválidos e normaliza duplicatas existentes',
    () async {
      store.values = [
        '',
        ' ',
        '{}',
        'https://example.com',
        '123',
        'Jararaca',
        ' Bothrops jararaca ',
        'BOTHROPS JARARACA',
      ];
      expect(await repository.load(), {'bothrops jararaca'});
      await expectLater(repository.setFavorite('', true), throwsArgumentError);
      await repository.setFavorite('Tityus serrulatus', true);
      expect(store.values, ['bothrops jararaca', 'tityus serrulatus']);
    },
  );

  test('Alterações concorrentes não perdem favoritos', () async {
    await Future.wait([
      repository.setFavorite('Bothrops jararaca', true),
      FavoritesRepository(store: store).setFavorite('Tityus serrulatus', true),
    ]);
    expect(await repository.load(), hasLength(2));
  });

  test('Falha de gravação preserva dados e permite nova tentativa', () async {
    await repository.setFavorite(species.scientificName, true);
    store.fail = true;
    await expectLater(
      repository.setFavorite(species.scientificName, false),
      throwsStateError,
    );
    expect(await repository.load(), hasLength(1));
    store.fail = false;
    await repository.setFavorite(species.scientificName, false);
    expect(await repository.load(), isEmpty);
  });

  test(
    'SharedPreferences usa chave v1 estável e persiste entre instâncias',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final preferences = SharedPreferencesAsync();
      final saved = FavoritesRepository();
      await saved.setFavorite(species.scientificName, true);
      expect(
        SharedPreferencesFavoritesStore.storageKey,
        'ecolens_species_favorites_v1',
      );
      expect(await preferences.getStringList('ecolens_species_favorites_v1'), [
        'bothrops jararaca',
      ]);
      expect(await FavoritesRepository().load(), {'bothrops jararaca'});
      await preferences.setString('ecolens_species_favorites_v1', 'invalid');
      expect(await FavoritesRepository().load(), isEmpty);
    },
  );

  testWidgets('Ficha publicada mostra estado, confirmação e desfavorita', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SpeciesDetailScreen(
          species: species,
          isDemonstration: false,
          favoritesRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byTooltip('Adicionar aos favoritos')),
      matchesSemantics(
        tooltip: 'Adicionar aos favoritos',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasToggledState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    await tester.tap(find.byTooltip('Adicionar aos favoritos'));
    await tester.pumpAndSettle();
    expect(find.text('Espécie adicionada aos favoritos.'), findsOneWidget);
    expect(find.byTooltip('Remover dos favoritos'), findsOneWidget);
    expect(
      tester.getSemantics(find.byTooltip('Remover dos favoritos')),
      matchesSemantics(
        tooltip: 'Remover dos favoritos',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    // Aguarda a confirmação anterior para conferir a de remoção separadamente.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remover dos favoritos'));
    await tester.pumpAndSettle();
    expect(find.text('Espécie removida dos favoritos.'), findsOneWidget);
    expect(await repository.load(), isEmpty);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('Ficha demonstração não permite favoritar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SpeciesDetailScreen(species: species)),
    );
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });

  testWidgets('Falha ao salvar mantém estado do botão', (tester) async {
    store.fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: SpeciesDetailScreen(
          species: species,
          isDemonstration: false,
          favoritesRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar aos favoritos'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Adicionar aos favoritos'), findsOneWidget);
    expect(find.textContaining('Não foi possível salvar'), findsOneWidget);
  });

  testWidgets('Falha de leitura na ficha informa erro e permite recarregar', (
    tester,
  ) async {
    await repository.setFavorite(species.scientificName, true);
    store.failRead = true;
    await tester.pumpWidget(
      MaterialApp(
        home: SpeciesDetailScreen(
          species: species,
          isDemonstration: false,
          favoritesRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final retry = find.byTooltip(
      'Não foi possível ler favoritos. Tentar novamente',
    );
    expect(retry, findsOneWidget);
    expect(find.byTooltip('Adicionar aos favoritos'), findsNothing);
    expect(store.values, ['bothrops jararaca']);
    store.failRead = false;
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remover dos favoritos'), findsOneWidget);
    expect(await repository.load(), {'bothrops jararaca'});
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Falha de leitura na lista preserva storage e permite tentar novamente',
    (tester) async {
      await repository.setFavorite(species.scientificName, true);
      store.failRead = true;
      var queries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: FavoritesScreen(
            repository: repository,
            fetchPublishedSpecies: () async {
              queries++;
              return [species];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Não foi possível ler os favoritos locais.'),
        findsOneWidget,
      );
      expect(find.textContaining('Nenhum favorito ainda'), findsNothing);
      expect(find.byType(ListTile), findsNothing);
      expect(store.values, ['bothrops jararaca']);
      expect(queries, 0);
      store.failRead = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Jararaca'), findsOneWidget);
      expect(
        find.text('Não foi possível ler os favoritos locais.'),
        findsNothing,
      );
      expect(queries, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Falha ao remover pela lista mantém item e permite repetir remoção',
    (tester) async {
      await repository.setFavorite(species.scientificName, true);
      await tester.pumpWidget(
        MaterialApp(
          home: FavoritesScreen(
            repository: repository,
            fetchPublishedSpecies: () async => [species],
          ),
        ),
      );
      await tester.pumpAndSettle();
      store.fail = true;
      final remove = find.byTooltip('Remover bothrops jararaca dos favoritos');
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(
        find.text('Não foi possível remover. Tente novamente.'),
        findsOneWidget,
      );
      expect(find.text('Jararaca'), findsOneWidget);
      expect(await repository.load(), {'bothrops jararaca'});
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(of: remove, matching: find.byType(IconButton)),
            )
            .onPressed,
        isNotNull,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      store.fail = false;
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.text('Espécie removida dos favoritos.'), findsOneWidget);
      expect(find.text('Jararaca'), findsNothing);
      expect(find.textContaining('Nenhum favorito ainda'), findsOneWidget);
      expect(await repository.load(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Favoritos e histórico são independentes no mesmo SharedPreferences',
    () async {
      final preferences = SharedPreferencesAsync();
      final favorites = FavoritesRepository(
        store: SharedPreferencesFavoritesStore(preferences: preferences),
      );
      final history = IdentificationHistoryRepository(
        store: SharedPreferencesHistoryStore(preferences: preferences),
      );
      const result = AiIdentificationResult(
        identified: true,
        commonName: 'Jararaca',
        scientificName: 'Bothrops jararaca',
        explanation: 'Teste',
      );
      final entry = await history.save(result, matchedCatalog: true);
      final historyBefore = await preferences.getStringList(
        SharedPreferencesHistoryStore.storageKey,
      );
      await favorites.setFavorite(species.scientificName, true);
      await favorites.setFavorite(species.scientificName, false);
      expect(
        await preferences.getStringList(
          SharedPreferencesHistoryStore.storageKey,
        ),
        historyBefore,
      );
      expect((await history.load()).single.id, entry.id);
      await favorites.setFavorite(species.scientificName, true);
      await history.delete(entry.id);
      expect(await favorites.load(), {'bothrops jararaca'});
      await history.save(result, matchedCatalog: true);
      await history.clear();
      expect(await history.load(), isEmpty);
      expect(await favorites.load(), {'bothrops jararaca'});
    },
  );

  testWidgets('Home abre os quatro atalhos compactos', (tester) async {
    final themeController = ThemeController();
    addTearDown(themeController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          themeController: themeController,
          fetchPublishedSpecies: () async => [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tapShortcut(String title) async {
      final card = find.widgetWithText(QuickAccessCard, title);
      await tester.scrollUntilVisible(
        card,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(card), alignment: 0.2);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();
    }

    await tapShortcut('Favoritos');
    expect(find.byType(FavoritesScreen), findsOneWidget);
    expect(find.textContaining('Nenhum favorito ainda'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapShortcut('Perigosas');
    expect(find.byType(SpeciesCatalogScreen), findsOneWidget);
    expect(
      tester
          .widget<SpeciesCatalogScreen>(find.byType(SpeciesCatalogScreen))
          .initialFilter,
      SpeciesCatalogFilter.danger,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapShortcut('Primeiros socorros');
    expect(find.byType(SosScreen), findsOneWidget);
    expect(find.text('SAMU · 192'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapShortcut('Histórico');
    expect(find.byType(IdentificationHistoryScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byTooltip('Abrir SOS ambiental'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Lista preenchida em tela pequena escura com texto 2x permite ler e remover',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const second = SpeciesModel(
        commonName: 'Escorpião-amarelo',
        scientificName: 'Tityus serrulatus',
        status: SpeciesStatus.danger,
      );
      await repository.setFavorite(species.scientificName, true);
      await repository.setFavorite(second.scientificName, true);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: FavoritesScreen(
            repository: repository,
            fetchPublishedSpecies: () async => [species, second],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jararaca'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final secondName = find.text(second.scientificName);
      await tester.scrollUntilVisible(secondName, 100);
      await Scrollable.ensureVisible(tester.element(secondName));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final remove = find.byTooltip('Remover tityus serrulatus dos favoritos');
      await Scrollable.ensureVisible(tester.element(remove));
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(await repository.load(), {'bothrops jararaca'});
      expect(find.text('Escorpião-amarelo'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tela vazia orienta sem depender de rede, tema escuro e tela pequena',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: FavoritesScreen(
            repository: repository,
            fetchPublishedSpecies: () async =>
                throw StateError('não consultar'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Nenhum favorito ainda'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Carrega ficha atualizada e remoção na ficha atualiza lista', (
    tester,
  ) async {
    await repository.setFavorite(species.scientificName, true);
    await tester.pumpWidget(
      MaterialApp(
        home: FavoritesScreen(
          repository: repository,
          fetchPublishedSpecies: () async => [species],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jararaca'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remover dos favoritos'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('Nenhum favorito ainda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Espécie despublicada não abre ficha e pode ser removida', (
    tester,
  ) async {
    await repository.setFavorite(species.scientificName, true);
    await tester.pumpWidget(
      MaterialApp(
        home: FavoritesScreen(
          repository: repository,
          fetchPublishedSpecies: () async => [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('não disponível no catálogo publicado'),
      findsOneWidget,
    );
    await tester.tap(find.text('bothrops jararaca'));
    await tester.pumpAndSettle();
    expect(find.byType(SpeciesDetailScreen), findsNothing);
    await tester.tap(find.byTooltip('Remover bothrops jararaca dos favoritos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nenhum favorito ainda'), findsOneWidget);
    expect(await repository.load(), isEmpty);
  });

  testWidgets('Rede falha, preserva favoritos e tentar novamente recarrega', (
    tester,
  ) async {
    await repository.setFavorite(species.scientificName, true);
    var fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: FavoritesScreen(
          repository: repository,
          fetchPublishedSpecies: () async {
            if (fail) throw StateError('offline');
            return [species];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('permanecem salvos localmente'), findsOneWidget);
    expect(await repository.load(), hasLength(1));
    expect(find.text('Jararaca'), findsNothing);
    fail = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Jararaca'), findsOneWidget);
  });

  testWidgets('Consulta pendente exibe carregamento e permite sair', (
    tester,
  ) async {
    await repository.setFavorite(species.scientificName, true);
    final pending = Completer<List<SpeciesModel>>();
    await tester.pumpWidget(
      MaterialApp(
        home: FavoritesScreen(
          repository: repository,
          fetchPublishedSpecies: () => pending.future,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    pending.complete([species]);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Acesso rápido tem quatro atalhos, incluindo favoritos', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QuickAccessSection(
              onVenomousTap: () {},
              onFirstAidTap: () {},
              onHistoryTap: () {},
              onFavoritesTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );
    expect(find.byType(QuickAccessCard), findsNWidgets(4));
    await tester.scrollUntilVisible(find.text('Favoritos'), 100);
    await tester.tap(find.text('Favoritos'));
    expect(tapped, isTrue);
  });
}
