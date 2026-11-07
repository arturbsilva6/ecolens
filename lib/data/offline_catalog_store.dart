import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/species_model.dart';

/// Catálogo salvo no aparelho e a data da última atualização.
class OfflineCatalogSnapshot {
  final List<SpeciesModel> species;
  final DateTime savedAt;

  const OfflineCatalogSnapshot({required this.species, required this.savedAt});
}

/// Resumo do pacote offline exibido nas Configurações.
class OfflinePackageStatus {
  final int speciesCount;
  final DateTime? savedAt;
  final int photosAvailable;
  final int photosDownloaded;
  final int photoBytes;

  const OfflinePackageStatus({
    required this.speciesCount,
    required this.savedAt,
    required this.photosAvailable,
    required this.photosDownloaded,
    required this.photoBytes,
  });

  bool get hasCatalog => savedAt != null;
  bool get allPhotosDownloaded =>
      photosAvailable > 0 && photosDownloaded >= photosAvailable;
}

class PhotoDownloadResult {
  final int downloaded;
  final int alreadyAvailable;
  final int failed;

  const PhotoDownloadResult({
    required this.downloaded,
    required this.alreadyAvailable,
    required this.failed,
  });
}

/// Guarda o catálogo de espécies e as fotos no armazenamento do aparelho.
///
/// O texto das fichas é salvo automaticamente sempre que o catálogo é
/// carregado com internet. As fotos só são baixadas quando a pessoa pede,
/// pela tela "Uso offline", para não consumir o plano de dados sem aviso.
///
/// Enquanto [init] não for concluído (testes, web ou falha do sistema de
/// arquivos), todas as operações são ignoradas e o app funciona como antes.
class OfflineCatalogStore extends ChangeNotifier {
  static const _formatVersion = 1;

  /// Largura das miniaturas da Wikimedia usadas no pacote offline.
  static const thumbnailWidth = 500;

  static final OfflineCatalogStore instance = OfflineCatalogStore();

  final Future<Directory> Function() _baseDirectory;
  final http.Client? _httpClient;
  final int maxPhotoBytes;
  final Duration requestTimeout;

  OfflineCatalogStore({
    Future<Directory> Function()? baseDirectory,
    http.Client? httpClient,
    this.maxPhotoBytes = 3 * 1024 * 1024,
    this.requestTimeout = const Duration(seconds: 30),
  }) : _baseDirectory = baseDirectory ?? getApplicationSupportDirectory,
       _httpClient = httpClient;

  Directory? _root;
  Future<bool>? _initFuture;
  bool _lastLoadFromCache = false;

  bool get isReady => _root != null;

  /// Indica se a última leitura do catálogo veio do aparelho por falta
  /// de conexão.
  bool get lastLoadFromCache => _lastLoadFromCache;

  /// Prepara as pastas do pacote offline. Chamado uma vez ao abrir o app.
  Future<bool> init() {
    final pending = _initFuture ??= _init();
    return pending.then((ready) {
      if (!ready) _initFuture = null;
      return ready;
    });
  }

  Future<bool> _init() async {
    if (_root != null) return true;
    if (kIsWeb) return false;
    try {
      final base = await _baseDirectory();
      final root = Directory('${base.path}/ecolens_offline');
      await Directory('${root.path}/photos').create(recursive: true);
      _root = root;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  File get _catalogFile => File('${_root!.path}/catalog.json');
  Directory get _photosDir => Directory('${_root!.path}/photos');

  Future<void> saveCatalog(List<SpeciesModel> species, {DateTime? now}) async {
    if (!isReady) return;
    final content = jsonEncode({
      'version': _formatVersion,
      'saved_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'species': species.map((item) => item.toJson()).toList(),
    });
    // Grava em arquivo temporário e renomeia, para nunca deixar um
    // catálogo pela metade se o app for fechado durante a gravação.
    final temp = File('${_catalogFile.path}.tmp');
    await temp.writeAsString(content, flush: true);
    await temp.rename(_catalogFile.path);
    notifyListeners();
  }

  Future<OfflineCatalogSnapshot?> loadCatalog() async {
    if (!isReady) return null;
    try {
      if (!await _catalogFile.exists()) return null;
      final json = jsonDecode(await _catalogFile.readAsString());
      if (json is! Map<String, dynamic> ||
          json['version'] != _formatVersion) {
        return null;
      }
      final species = (json['species'] as List)
          .map((item) => SpeciesModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
      return OfflineCatalogSnapshot(
        species: species,
        savedAt: DateTime.parse(json['saved_at'] as String).toLocal(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Busca o catálogo online e, se não houver conexão, usa a cópia salva.
  ///
  /// Sem cópia salva, o erro original é repassado para a tela tratá-lo
  /// como antes.
  Future<List<SpeciesModel>> fetchWithFallback(
    Future<List<SpeciesModel>> Function() remote,
  ) async {
    // Se a preparação já começou ao abrir o app, espera terminar para
    // conseguir usar a cópia salva logo na primeira tela.
    final pendingInit = _initFuture;
    if (pendingInit != null) await pendingInit;
    try {
      final species = await remote();
      _lastLoadFromCache = false;
      try {
        await saveCatalog(species);
      } catch (_) {
        // Falha ao salvar não deve impedir a exibição do catálogo.
      }
      return species;
    } catch (error, stackTrace) {
      final cached = await loadCatalog();
      if (cached == null) Error.throwWithStackTrace(error, stackTrace);
      _lastLoadFromCache = true;
      return cached.species;
    }
  }

  /// Foto já baixada para a [url], ou `null` se ainda não estiver no aparelho.
  File? cachedPhoto(String url) {
    if (!isReady) return null;
    final file = _photoFile(url);
    return file.existsSync() ? file : null;
  }

  Future<PhotoDownloadResult> downloadPhotos(
    List<SpeciesModel> species, {
    void Function(int done, int total)? onProgress,
  }) async {
    if (!isReady) {
      return const PhotoDownloadResult(
        downloaded: 0,
        alreadyAvailable: 0,
        failed: 0,
      );
    }
    final urls = _photoUrls(species);
    final client = _httpClient ?? http.Client();
    var downloaded = 0, alreadyAvailable = 0, failed = 0, done = 0;
    try {
      for (final url in urls) {
        if (cachedPhoto(url) != null) {
          alreadyAvailable++;
        } else if (await _downloadPhoto(client, url)) {
          downloaded++;
        } else {
          failed++;
        }
        done++;
        onProgress?.call(done, urls.length);
      }
    } finally {
      if (_httpClient == null) client.close();
    }
    notifyListeners();
    return PhotoDownloadResult(
      downloaded: downloaded,
      alreadyAvailable: alreadyAvailable,
      failed: failed,
    );
  }

  Future<void> removePhotos() async {
    if (!isReady) return;
    if (await _photosDir.exists()) {
      await _photosDir.delete(recursive: true);
    }
    await _photosDir.create(recursive: true);
    notifyListeners();
  }

  Future<OfflinePackageStatus> status() async {
    final snapshot = await loadCatalog();
    final urls = snapshot == null ? <String>{} : _photoUrls(snapshot.species);
    var downloaded = 0;
    for (final url in urls) {
      if (cachedPhoto(url) != null) downloaded++;
    }
    var bytes = 0;
    if (isReady && await _photosDir.exists()) {
      await for (final entity in _photosDir.list()) {
        if (entity is File) bytes += await entity.length();
      }
    }
    return OfflinePackageStatus(
      speciesCount: snapshot?.species.length ?? 0,
      savedAt: snapshot?.savedAt,
      photosAvailable: urls.length,
      photosDownloaded: downloaded,
      photoBytes: bytes,
    );
  }

  Set<String> _photoUrls(List<SpeciesModel> species) =>
      species.map((item) => item.imageUrl).whereType<String>().toSet();

  Future<bool> _downloadPhoto(http.Client client, String url) async {
    for (final candidate in downloadCandidates(url)) {
      try {
        final response = await client
            .get(
              candidate,
              headers: const {
                'User-Agent': 'EcoLens/1.0 (app de TCC; catálogo offline)',
              },
            )
            .timeout(requestTimeout);
        final type = response.headers['content-type'] ?? '';
        if (response.statusCode != 200 ||
            !type.startsWith('image/') ||
            response.bodyBytes.isEmpty ||
            response.bodyBytes.length > maxPhotoBytes) {
          continue;
        }
        final target = _photoFile(url);
        final temp = File('${target.path}.tmp');
        await temp.writeAsBytes(response.bodyBytes, flush: true);
        await temp.rename(target.path);
        return true;
      } catch (_) {
        // Tenta o próximo endereço ou registra a falha.
      }
    }
    return false;
  }

  /// Endereços tentados para baixar a foto: primeiro a miniatura da
  /// Wikimedia (bem mais leve) e depois o arquivo original.
  @visibleForTesting
  static List<Uri> downloadCandidates(String url) {
    final original = Uri.parse(url);
    final segments = original.pathSegments;
    final isWikimediaOriginal = original.host == 'upload.wikimedia.org' &&
        segments.length == 5 &&
        segments[0] == 'wikipedia' &&
        segments[1] == 'commons';
    if (!isWikimediaOriginal) return [original];
    final name = segments[4];
    final thumbnail = original.replace(
      pathSegments: [
        'wikipedia',
        'commons',
        'thumb',
        segments[2],
        segments[3],
        name,
        '${thumbnailWidth}px-$name',
      ],
    );
    return [thumbnail, original];
  }

  File _photoFile(String url) =>
      File('${_photosDir.path}/${photoFileName(url)}');

  /// Nome estável do arquivo local de uma foto, derivado da URL.
  @visibleForTesting
  static String photoFileName(String url) {
    // FNV-1a de 32 bits: estável entre execuções, ao contrário de hashCode.
    var hash = 0x811c9dc5;
    for (final unit in url.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return '${hash.toRadixString(16).padLeft(8, '0')}_${url.length}.img';
  }
}
