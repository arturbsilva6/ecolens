import 'dart:convert';
import 'dart:io';

import 'package:ecolens/data/offline_catalog_store.dart';
import 'package:ecolens/models/species_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _jararacaUrl =
    'https://upload.wikimedia.org/wikipedia/commons/8/88/'
    'Bothrops_jararaca_1.jpg';

const _jararaca = SpeciesModel(
  commonName: 'Jararaca',
  scientificName: 'Bothrops jararaca',
  status: SpeciesStatus.danger,
  imageUrl: _jararacaUrl,
  imageCredit: 'Felipe Süssekind',
  imageLicenseLabel: 'CC BY 2.0',
  riskDescription: 'Serpente peçonhenta.',
  safetyAdvice: 'Acione o SAMU 192.',
  sourceName: 'Instituto Butantan',
);

const _leucena = SpeciesModel(
  commonName: 'Leucena',
  scientificName: 'Leucaena leucocephala',
  status: SpeciesStatus.invasive,
);

http.Response _image(http.Request request, {int size = 10}) =>
    http.Response.bytes(
      List<int>.filled(size, 7),
      200,
      headers: {'content-type': 'image/jpeg'},
      request: request,
    );

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('ecolens_offline_test');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  OfflineCatalogStore storeWith([MockClient? client]) => OfflineCatalogStore(
    baseDirectory: () async => dir,
    requestInterval: Duration.zero,
    rateLimitWait: Duration.zero,
    httpClient: client ?? MockClient((request) async => _image(request)),
  );

  test('Salva e lê o catálogo preservando os campos da ficha', () async {
    final store = storeWith();
    expect(await store.init(), isTrue);
    final savedAt = DateTime(2026, 11, 7, 9, 30);

    await store.saveCatalog([_jararaca, _leucena], now: savedAt);
    final snapshot = await store.loadCatalog();

    expect(snapshot, isNotNull);
    expect(snapshot!.savedAt, savedAt);
    expect(snapshot.species, hasLength(2));
    final jararaca = snapshot.species.first;
    expect(jararaca.commonName, 'Jararaca');
    expect(jararaca.status, SpeciesStatus.danger);
    expect(jararaca.imageCredit, 'Felipe Süssekind');
    expect(jararaca.safetyAdvice, 'Acione o SAMU 192.');
    expect(snapshot.species.last.status, SpeciesStatus.invasive);
  });

  test('Arquivo corrompido ou de outra versão é ignorado', () async {
    final store = storeWith();
    await store.init();
    final file = File('${dir.path}/ecolens_offline/catalog.json');

    await file.writeAsString('{não é json');
    expect(await store.loadCatalog(), isNull);

    await file.writeAsString(jsonEncode({'version': 99, 'species': []}));
    expect(await store.loadCatalog(), isNull);
  });

  test('Com internet, usa o servidor e atualiza a cópia salva', () async {
    final store = storeWith();
    await store.init();

    final result = await store.fetchWithFallback(() async => [_jararaca]);

    expect(result.single.commonName, 'Jararaca');
    expect(store.lastLoadFromCache, isFalse);
    expect((await store.loadCatalog())!.species.single.commonName, 'Jararaca');
  });

  test('Sem internet, usa a última cópia salva', () async {
    final store = storeWith();
    await store.init();
    await store.saveCatalog([_jararaca, _leucena]);

    final result = await store.fetchWithFallback(
      () async => throw const SocketException('sem rede'),
    );

    expect(result.map((s) => s.commonName), ['Jararaca', 'Leucena']);
    expect(store.lastLoadFromCache, isTrue);
  });

  test('Sem internet e sem cópia salva, repassa o erro original', () async {
    final store = storeWith();
    await store.init();

    await expectLater(
      store.fetchWithFallback(() async => throw StateError('sem config')),
      throwsStateError,
    );
  });

  test('Sem preparar o armazenamento, nada é gravado nem lido', () async {
    final store = storeWith();

    await store.saveCatalog([_jararaca]);
    expect(await store.loadCatalog(), isNull);
    expect(store.cachedPhoto(_jararacaUrl), isNull);
    await expectLater(
      store.fetchWithFallback(() async => throw StateError('offline')),
      throwsStateError,
    );
    expect(dir.listSync(), isEmpty);
  });

  test('Usa a miniatura da Wikimedia antes do arquivo original', () {
    final candidates = OfflineCatalogStore.downloadCandidates(_jararacaUrl);

    expect(candidates, hasLength(2));
    expect(
      candidates.first.path,
      '/wikipedia/commons/thumb/8/88/Bothrops_jararaca_1.jpg/'
      '500px-Bothrops_jararaca_1.jpg',
    );
    expect(candidates.last.toString(), _jararacaUrl);
    expect(
      OfflineCatalogStore.downloadCandidates('https://example.org/a.png'),
      [Uri.parse('https://example.org/a.png')],
    );
  });

  test('Nome do arquivo da foto é estável e diferente por URL', () {
    final name = OfflineCatalogStore.photoFileName(_jararacaUrl);

    expect(OfflineCatalogStore.photoFileName(_jararacaUrl), name);
    expect(OfflineCatalogStore.photoFileName('$_jararacaUrl?x'), isNot(name));
  });

  test('Baixa as fotos uma vez e informa o progresso', () async {
    final requested = <Uri>[];
    final store = storeWith(
      MockClient((request) async {
        requested.add(request.url);
        return _image(request);
      }),
    );
    await store.init();
    final progress = <String>[];

    final first = await store.downloadPhotos([
      _jararaca,
      _leucena,
    ], onProgress: (done, total) => progress.add('$done/$total'));

    expect(first.downloaded, 1);
    expect(first.failed, 0);
    expect(progress, ['1/1']);
    expect(requested.single.path, contains('/thumb/'));
    expect(store.cachedPhoto(_jararacaUrl), isNotNull);

    final second = await store.downloadPhotos([_jararaca]);
    expect(second.alreadyAvailable, 1);
    expect(requested, hasLength(1));
  });

  test('Sem miniatura, tenta o arquivo original', () async {
    final requested = <String>[];
    final store = storeWith(
      MockClient((request) async {
        requested.add(request.url.path);
        if (request.url.path.contains('/thumb/')) {
          return http.Response('', 404, request: request);
        }
        return _image(request);
      }),
    );
    await store.init();

    final result = await store.downloadPhotos([_jararaca]);

    expect(result.downloaded, 1);
    expect(requested, hasLength(2));
    expect(store.cachedPhoto(_jararacaUrl), isNotNull);
  });

  test('Recusa respostas que não são imagem ou são grandes demais', () async {
    final store = OfflineCatalogStore(
      baseDirectory: () async => dir,
    requestInterval: Duration.zero,
    rateLimitWait: Duration.zero,
      maxPhotoBytes: 5,
      httpClient: MockClient((request) async {
        if (request.url.path.contains('/thumb/')) {
          return http.Response(
            '<html></html>',
            200,
            headers: {'content-type': 'text/html'},
            request: request,
          );
        }
        return _image(request, size: 50);
      }),
    );
    await store.init();

    final result = await store.downloadPhotos([_jararaca]);

    expect(result.failed, 1);
    expect(store.cachedPhoto(_jararacaUrl), isNull);
  });

  test(
    'Status resume fichas e fotos, e as fotos podem ser removidas',
    () async {
      final store = storeWith();
      await store.init();
      await store.saveCatalog([_jararaca, _leucena]);

      var status = await store.status();
      expect(status.speciesCount, 2);
      expect(status.photosAvailable, 1);
      expect(status.photosDownloaded, 0);
      expect(status.allPhotosDownloaded, isFalse);

      await store.downloadPhotos([_jararaca, _leucena]);
      status = await store.status();
      expect(status.photosDownloaded, 1);
      expect(status.photoBytes, 10);
      expect(status.allPhotosDownloaded, isTrue);

      await store.removePhotos();
      status = await store.status();
      expect(status.photosDownloaded, 0);
      expect(status.photoBytes, 0);
      expect(status.speciesCount, 2);
    },
  );

  test('Cabeçalho User-Agent só usa ASCII e é enviado', () async {
    expect(
      OfflineCatalogStore.userAgent.codeUnits.every((unit) => unit < 128),
      isTrue,
    );
    String? sent;
    final store = storeWith(
      MockClient((request) async {
        sent = request.headers['User-Agent'];
        return _image(request);
      }),
    );
    await store.init();

    await store.downloadPhotos([_jararaca]);

    expect(sent, OfflineCatalogStore.userAgent);
  });

  test('Após HTTP 429, espera e tenta de novo o mesmo endereço', () async {
    var calls = 0;
    final store = storeWith(
      MockClient((request) async {
        calls++;
        if (calls == 1) {
          return http.Response(
            'Too many requests',
            429,
            headers: {'content-type': 'text/html', 'retry-after': '0'},
            request: request,
          );
        }
        return _image(request);
      }),
    );
    await store.init();

    final result = await store.downloadPhotos([_jararaca]);

    expect(result.downloaded, 1);
    expect(calls, 2);
  });

  test('Desiste após repetidos HTTP 429 sem travar o pacote', () async {
    var calls = 0;
    final store = storeWith(
      MockClient((request) async {
        calls++;
        return http.Response('Too many requests', 429, request: request);
      }),
    );
    await store.init();

    final result = await store.downloadPhotos([_jararaca]);

    expect(result.failed, 1);
    // Miniatura e original, cada um com a tentativa inicial e 2 repetições.
    expect(calls, 2 * (1 + OfflineCatalogStore.maxRateLimitRetries));
  });
}
