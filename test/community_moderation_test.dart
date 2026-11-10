import 'package:ecolens/data/blocked_authors_repository.dart';
import 'package:ecolens/models/sighting.dart';
import 'package:ecolens/screens/community/community_screen.dart';
import 'package:ecolens/screens/community/sighting_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/community_fake.dart';

Sighting _sighting(
  String id,
  String owner,
  String species, {
  DateTime? editedAt,
  DateTime? hiddenAt,
}) => Sighting(
  id: id,
  ownerId: owner,
  municipalityId: municipality.id,
  photoPath: '$id.png',
  observedOn: DateTime(2026, 10, 1),
  species: species,
  origin: IdentificationOrigin.user,
  editedAt: editedAt,
  hiddenAt: hiddenAt,
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> show(WidgetTester tester, Widget screen) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  Widget detail(
    CommunityFake repository,
    Sighting sighting, {
    String? account,
    BlockedAuthorsRepository? blocked,
  }) => SightingDetailScreen(
    repository: repository,
    sighting: sighting,
    municipalities: const [municipality],
    accountId: account,
    blockedAuthors: blocked,
    loadSpecies: () async => const [],
    loadAuthor: (_) async => null,
  );

  test('Lê as marcas de edição e ocultação vindas do servidor', () {
    final row = {
      'id': 'a',
      'owner_id': 'author',
      'municipality_id': municipality.id,
      'photo_path': 'author/a/photo.png',
      'species_label': null,
      'notes': '',
      'observed_on': '2026-10-01',
      'identification_origin': 'unknown',
      'status': 'published',
      'edited_at': '2026-11-09T12:00:00Z',
      'hidden_at': null,
    };
    final sighting = Sighting.fromJson(row);
    expect(sighting.edited, isTrue);
    expect(sighting.hidden, isFalse);
  });

  testWidgets('Outra pessoa denuncia com motivo e detalhes', (tester) async {
    final repository = CommunityFake()..user = 'other';
    await show(
      tester,
      detail(repository, _sighting('a', 'author', 'Jararaca'), account: 'other'),
    );
    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Denunciar registro'));
    await tester.pumpAndSettle();

    final send = find.widgetWithText(FilledButton, 'Enviar denúncia');
    expect(tester.widget<FilledButton>(send).onPressed, isNull);
    await tester.tap(find.text('Spam ou propaganda'));
    await tester.enterText(find.byType(TextField), 'Propaganda de loja');
    await tester.pump();
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(repository.reports, [
      ('a', ReportReason.spam, 'Propaganda de loja'),
    ]);
    expect(find.text('Denúncia enviada'), findsOneWidget);
  });

  testWidgets('Visitante não denuncia sem conta', (tester) async {
    final repository = CommunityFake();
    await show(tester, detail(repository, _sighting('a', 'author', 'Jararaca')));
    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Denunciar registro'));
    await tester.pumpAndSettle();
    expect(find.text('Entre para denunciar'), findsOneWidget);
    expect(repository.reports, isEmpty);
  });

  testWidgets('O autor não vê denunciar nem bloquear no próprio registro', (
    tester,
  ) async {
    await show(
      tester,
      detail(
        CommunityFake()..user = 'author',
        _sighting(
          'a',
          'author',
          'Jararaca',
          editedAt: DateTime(2026, 11, 9),
          hiddenAt: DateTime(2026, 11, 9),
        ),
        account: 'author',
      ),
    );
    expect(find.byTooltip('Mais opções'), findsNothing);
    expect(find.text('Oculto após denúncias'), findsOneWidget);
    expect(find.text('Editado depois de publicado'), findsOneWidget);
  });

  testWidgets('Bloquear autor esconde os registros dele na Comunidade', (
    tester,
  ) async {
    final blocked = BlockedAuthorsRepository();
    final repository = CommunityFake()
      ..user = 'other'
      ..items = [
        _sighting('a', 'author', 'Jararaca'),
        _sighting('b', 'someone', 'Capivara'),
      ];
    await show(
      tester,
      detail(
        repository,
        repository.items.first,
        account: 'other',
        blocked: blocked,
      ),
    );
    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bloquear autor'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Bloquear'));
    await tester.pumpAndSettle();
    expect(find.text('Autor bloqueado'), findsOneWidget);
    expect(await blocked.load(), {'author'});

    await show(
      tester,
      CommunityScreen(repository: repository, blockedAuthors: blocked),
    );
    expect(find.text('Capivara'), findsOneWidget);
    expect(find.text('Jararaca'), findsNothing);
  });
}
