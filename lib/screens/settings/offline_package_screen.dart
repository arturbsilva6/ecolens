import 'package:flutter/material.dart';

import '../../data/offline_catalog_store.dart';
import '../../data/supabase_species_repository.dart';
import '../../models/species_model.dart';
import '../../widgets/result_dialog.dart';

/// Permite baixar as fichas e fotos do catálogo para usar sem internet.
class OfflinePackageScreen extends StatefulWidget {
  final OfflineCatalogStore? store;

  /// Consulta ao servidor; os testes substituem para não usar a rede.
  final Future<List<SpeciesModel>> Function()? fetchRemote;

  const OfflinePackageScreen({super.key, this.store, this.fetchRemote});

  @override
  State<OfflinePackageScreen> createState() => _OfflinePackageScreenState();
}

class _OfflinePackageScreenState extends State<OfflinePackageScreen> {
  late final OfflineCatalogStore _store =
      widget.store ?? OfflineCatalogStore.instance;
  OfflinePackageStatus? _status;
  bool _ready = false;
  bool _busy = false;
  String? _progress;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final ready = await _store.init();
    final status = await _store.status();
    if (!mounted) return;
    setState(() {
      _ready = ready;
      _status = status;
    });
  }

  Future<List<SpeciesModel>> _fetch() => _store.fetchWithFallback(
    widget.fetchRemote ?? SupabaseSpeciesRepository().fetchRemoteSpecies,
  );

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _progress = 'Atualizando fichas…';
    });
    String message;
    try {
      message = await _downloadPackage();
    } catch (_) {
      message =
          'Não foi possível baixar o pacote. Confira sua conexão e tente '
          'novamente.';
    }
    await _refresh();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = null;
    });
    final ok = message.startsWith('Pacote offline pronto');
    await showResultDialog(
      context,
      title: ok ? 'Download concluído' : 'Download incompleto',
      message: message,
      success: ok,
    );
  }

  Future<String> _downloadPackage() async {
    final species = await _fetch();
    if (_store.lastLoadFromCache) {
      return 'Sem conexão. As fichas já salvas continuam disponíveis; '
          'tente baixar as fotos quando tiver internet.';
    }
    final result = await _store.downloadPhotos(
      species,
      onProgress: (done, total) {
        if (!mounted) return;
        setState(() => _progress = 'Baixando fotos: $done de $total');
      },
    );
    if (result.failed == 0) {
      return 'Pacote offline pronto: ${species.length} fichas salvas.';
    }
    final fotos = result.failed == 1
        ? '1 foto não foi baixada'
        : '${result.failed} fotos não foram baixadas';
    return 'Fichas salvas, mas $fotos. Tente novamente com uma conexão '
        'melhor.';
  }

  Future<void> _removePhotos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover fotos baixadas?'),
        content: const Text(
          'As fichas continuam salvas. As fotos voltarão a ser carregadas '
          'pela internet até você baixar o pacote de novo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.removePhotos();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Uso offline')),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Baixe as fichas e as fotos das espécies para consultar '
                  'mesmo sem internet. A identificação por foto com IA '
                  'precisa de conexão; o SOS funciona sempre, porque '
                  'ligações não usam dados.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (!_ready)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Indisponível neste dispositivo'),
                      subtitle: Text(
                        'Não foi possível acessar o armazenamento do '
                        'aparelho.',
                      ),
                    ),
                  )
                else ...[
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.menu_book_outlined),
                          title: Text(
                            status.hasCatalog
                                ? '${status.speciesCount} fichas salvas'
                                : 'Nenhuma ficha salva ainda',
                          ),
                          subtitle: Text(
                            status.hasCatalog
                                ? 'Atualizado em ${formatDateTime(status.savedAt!)}'
                                : 'As fichas são salvas ao abrir o catálogo '
                                      'com internet.',
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library_outlined),
                          title: Text(
                            '${status.photosDownloaded} de '
                            '${status.photosAvailable} fotos no aparelho',
                          ),
                          subtitle: Text(
                            'Espaço usado: ${formatBytes(status.photoBytes)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_progress != null) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(_progress!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: _busy ? null : _download,
                    icon: const Icon(Icons.download_for_offline_outlined),
                    label: Text(
                      status.allPhotosDownloaded
                          ? 'Atualizar pacote offline'
                          : 'Baixar pacote offline',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recomendado usar Wi-Fi.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (status.photosDownloaded > 0) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _removePhotos,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remover fotos baixadas'),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}

/// Data no formato dd/mm/aaaa hh:mm.
String formatDateTime(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)}/${value.year} '
      '${two(value.hour)}:${two(value.minute)}';
}

/// Tamanho legível em KB ou MB, com vírgula decimal.
String formatBytes(int bytes) {
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).round()} KB';
  }
  final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
  return '${mb.replaceAll('.', ',')} MB';
}
