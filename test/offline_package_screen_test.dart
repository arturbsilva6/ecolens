import 'dart:io';

import 'package:ecolens/data/offline_catalog_store.dart';
import 'package:ecolens/models/species_model.dart';
import 'package:ecolens/screens/settings/offline_package_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _species = [
  SpeciesModel(
    commonName: 'Jararaca',
    scientificName: 'Bothrops jararaca',
    status: SpeciesStatus.danger,
    imageUrl: 'https://example.org/jararaca.jpg',
  ),
  SpeciesModel(
    commonName: 'Leucena',
    scientificName: 'Leucaena leucocephala',
    status: SpeciesStatus.invasive,
  ),
];

void main() {
  late Directory dir;
  late OfflineCatalogStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('ecolens_offline_ui');
    store = OfflineCatalogStore(
      baseDirectory: () async => dir,
      httpClient: MockClient(
        (request) async => http.Response.bytes(
          List<int>.filled(2048, 1),
          200,
          headers: {'content-type': 'image/jpeg'},
          request: request,
        ),
      ),
    );
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
  }

  Future<void> open(
    WidgetTester tester,
    Future<List<SpeciesModel>> Function() fetchRemote,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OfflinePackageScreen(store: store, fetchRemote: fetchRemote),
      ),
    );
    await settle(tester);
  }

  testWidgets('Baixa fichas e fotos e mostra o resumo', (tester) async {
    await open(tester, () async => _species);

    expect(find.text('Nenhuma ficha salva ainda'), findsOneWidget);
    expect(find.text('0 de 0 fotos no aparelho'), findsOneWidget);

    await tester.tap(find.text('Baixar pacote offline'));
    await settle(tester);
    await settle(tester);

    expect(find.text('2 fichas salvas'), findsOneWidget);
    expect(find.text('1 de 1 fotos no aparelho'), findsOneWidget);
    expect(find.text('Espaço usado: 2 KB'), findsOneWidget);
    expect(
      find.text('Pacote offline pronto: 2 fichas salvas.'),
      findsOneWidget,
    );
    expect(find.text('Remover fotos baixadas'), findsOneWidget);
    expect(find.text('Atualizar pacote offline'), findsOneWidget);
  });

  testWidgets('Sem conexão, mantém as fichas salvas e avisa', (tester) async {
    await tester.runAsync(() async {
      await store.init();
      await store.saveCatalog(_species);
    });
    await open(tester, () async => throw const SocketException('sem rede'));

    expect(find.text('2 fichas salvas'), findsOneWidget);

    await tester.tap(find.text('Baixar pacote offline'));
    await settle(tester);
    await settle(tester);

    expect(find.textContaining('Sem conexão.'), findsOneWidget);
    expect(find.text('2 fichas salvas'), findsOneWidget);
    expect(find.text('0 de 1 fotos no aparelho'), findsOneWidget);
  });

  testWidgets('Sem conexão e sem fichas, mostra erro amigável', (tester) async {
    await open(tester, () async => throw const SocketException('sem rede'));

    await tester.tap(find.text('Baixar pacote offline'));
    await settle(tester);
    await settle(tester);

    expect(
      find.textContaining('Não foi possível baixar o pacote.'),
      findsOneWidget,
    );
    expect(find.text('Nenhuma ficha salva ainda'), findsOneWidget);
  });

  test('Formata data e tamanho em português', () {
    expect(formatDateTime(DateTime(2026, 11, 7, 9, 5)), '07/11/2026 09:05');
    expect(formatBytes(512 * 1024), '512 KB');
    expect(formatBytes(3 * 1024 * 1024 + 300 * 1024), '3,3 MB');
  });
}
