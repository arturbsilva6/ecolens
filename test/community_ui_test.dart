import 'package:ecolens/core/theme/app_theme.dart';
import 'package:ecolens/models/sighting.dart';
import 'package:ecolens/screens/community/community_screen.dart';
import 'package:ecolens/screens/community/sighting_detail_screen.dart';
import 'package:ecolens/screens/community/sighting_form_screen.dart';
import 'package:ecolens/screens/map/heat_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/community_fake.dart';

Future<void> reveal(
  WidgetTester tester,
  Finder finder,
  double step, {
  Finder? scrollable,
}) async {
  for (var n = 0; n < 100; n++) {
    if (finder.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(
        tester.element(finder.first),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      return;
    }
    final state = tester.state<ScrollableState>(
      scrollable ?? find.byType(Scrollable).first,
    );
    state.position.jumpTo(
      (state.position.pixels + step).clamp(0, state.position.maxScrollExtent),
    );
    await tester.pumpAndSettle();
  }
  fail('Widget not found: $finder');
}

void main() {
  Future<void> mount(
    WidgetTester tester,
    Widget screen, {
    bool dark = false,
  }) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets(
      'community empty, retry and guest publishing, 320x480 text2 dark=$dark',
      (tester) async {
        final repository = CommunityFake()..fail = true;
        await mount(
          tester,
          CommunityScreen(repository: repository),
          dark: dark,
        );
        await reveal(tester, find.text('Tentar novamente'), 150);
        repository.fail = false;
        await tester.tap(find.text('Tentar novamente'));
        await tester.pumpAndSettle();
        expect(find.text('Nenhum avistamento encontrado.'), findsOneWidget);
        await reveal(tester, find.text('Publicar avistamento'), -200);
        await tester.tap(find.text('Publicar avistamento'));
        await tester.pumpAndSettle();
        expect(find.text('Entre para publicar'), findsOneWidget);
        expect(repository.creations, 0);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'map empty and concentration disclaimer, 320x480 text2 dark=$dark',
      (tester) async {
        await mount(
          tester,
          HeatMapScreen(repository: CommunityFake(), loadTiles: false),
          dark: dark,
        );
        await reveal(tester, find.byType(Switch), 200);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        await reveal(tester, find.textContaining('Legenda'), 150);
        expect(find.textContaining('Legenda'), findsOneWidget);
        await reveal(
          tester,
          find.textContaining('Nenhum avistamento encontrado.'),
          200,
        );
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('form scrolls with enlarged text dark=$dark', (tester) async {
      await mount(
        tester,
        SightingFormScreen(
          repository: CommunityFake(),
          municipalities: const [municipality],
        ),
        dark: dark,
      );
      await reveal(tester, find.text('Publicar'), 180);
      await tester.tap(find.text('Publicar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Selecione o município e uma foto para publicar.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('author edits identification and notes with text 2x', (
    tester,
  ) async {
    final repository = CommunityFake()..user = 'author';
    await mount(
      tester,
      SightingFormScreen(
        repository: repository,
        municipalities: const [municipality],
        sighting: fixture(),
      ),
    );
    await reveal(
      tester,
      find.byType(DropdownButtonFormField<IdentificationOrigin>),
      150,
    );
    await tester.tap(
      find.byType(DropdownButtonFormField<IdentificationOrigin>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sugerida por IA').last);
    await tester.pumpAndSettle();
    await reveal(
      tester,
      find.widgetWithText(TextFormField, 'Nome da espécie (hipótese)'),
      150,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome da espécie (hipótese)'),
      'Jararaca',
    );
    await reveal(tester, find.text('Salvar alterações'), 150);
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();
    expect(repository.updates, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'deletion requires confirmation; author can retry failed deletion',
    (tester) async {
      final repository = CommunityFake()
        ..user = 'author'
        ..failDelete = true;
      await mount(
        tester,
        SightingDetailScreen(
          repository: repository,
          sighting: fixture(),
          municipalities: const [municipality],
          accountId: 'author',
        ),
      );
      await reveal(tester, find.text('Excluir'), 150);
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repository.deletions, 0);
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();
      expect(find.text('Exclusão não confirmada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('another user sees no mutation controls', (tester) async {
    await mount(
      tester,
      SightingDetailScreen(
        repository: CommunityFake(),
        sighting: fixture(),
        municipalities: const [municipality],
        accountId: 'other',
      ),
    );
    await reveal(tester, find.text('Sem observações.'), 150);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Excluir'), findsNothing);
  });
  testWidgets(
    'municipality can be chosen before map is rendered, without GPS',
    (tester) async {
      await mount(
        tester,
        HeatMapScreen(repository: CommunityFake(), loadTiles: false),
      );
      await reveal(tester, find.text('Escolher município/SP'), 150);
      await tester.tap(find.text('Escolher município/SP'));
      await tester.pumpAndSettle();
      await reveal(
        tester,
        find.text('São Roque/SP'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('São Roque/SP'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('São Roque/SP'), findsOneWidget);
    },
  );
  testWidgets('map opens published sighting from municipality list', (
    tester,
  ) async {
    final repository = CommunityFake()..items = [fixture()];
    await mount(
      tester,
      HeatMapScreen(repository: repository, loadTiles: false),
    );
    await reveal(tester, find.text('São Roque/SP: 1'), 180);
    await tester.tap(find.text('São Roque/SP: 1'));
    await tester.pumpAndSettle();
    await reveal(
      tester,
      find.text('Espécie não identificada'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Espécie não identificada').first);
    await tester.pumpAndSettle();
    expect(find.text('Avistamento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
