import 'package:flutter/material.dart';

import '../../data/identification_history_repository.dart';
import '../../models/identification_history_entry.dart';
import '../species/species_catalog_screen.dart';
import '../../widgets/eco_spinner.dart';

String formatIdentificationDate(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Registros salvos voluntariamente no dispositivo; nunca guarda fotografias.
class IdentificationHistoryScreen extends StatefulWidget {
  final IdentificationHistoryRepository? repository;

  const IdentificationHistoryScreen({super.key, this.repository});

  @override
  State<IdentificationHistoryScreen> createState() =>
      _IdentificationHistoryScreenState();
}

class _IdentificationHistoryScreenState
    extends State<IdentificationHistoryScreen> {
  late final IdentificationHistoryRepository _repository;
  late Future<List<IdentificationHistoryEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? IdentificationHistoryRepository();
    _entries = _repository.load();
  }

  void _refresh() {
    final nextEntries = _repository.load();
    setState(() {
      _entries = nextEntries;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar histórico?'),
        content: const Text(
          'Todos os registros de análises salvos neste dispositivo '
          'serão removidos. Não será possível recuperá-los.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repository.clear();
      if (mounted) _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível apagar o histórico.')),
      );
    }
  }

  Future<void> _openEntry(IdentificationHistoryEntry entry) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => _IdentificationHistoryDetailScreen(
          entry: entry,
          repository: _repository,
        ),
      ),
    );
    if (deleted == true && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus registros'),
        actions: [
          IconButton(
            tooltip: 'Apagar todo o histórico',
            onPressed: _clearHistory,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'Só ficam neste dispositivo os resultados que você '
                'escolher salvar. Fotografias não são armazenadas. '
                'As sugestões da IA não são identificações confirmadas.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<IdentificationHistoryEntry>>(
                future: _entries,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: EcoSpinner());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Não foi possível abrir o histórico.'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _refresh,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    );
                  }
                  final items =
                      snapshot.data ?? const <IdentificationHistoryEntry>[];
                  if (items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Nenhum registro salvo ainda. Depois de analisar '
                          'uma foto, toque em "Salvar no histórico" na '
                          'tela de resultado.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            item.identified
                                ? Icons.eco_outlined
                                : Icons.help_outline,
                            color: colors.primary,
                          ),
                          title: Text(item.displayName),
                          subtitle: Text(
                            '${formatIdentificationDate(item.createdAt)}\n'
                            '${item.scientificName ?? "Análise inconclusiva"}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openEntry(item),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentificationHistoryDetailScreen extends StatelessWidget {
  final IdentificationHistoryEntry entry;
  final IdentificationHistoryRepository repository;

  const _IdentificationHistoryDetailScreen({
    required this.entry,
    required this.repository,
  });

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apagar registro?'),
        content: const Text(
          'Este resultado salvo será removido do dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await repository.delete(entry.id);
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível apagar o registro.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasScientificName = entry.identified &&
        entry.scientificName != null &&
        entry.scientificName!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Registro de identificação')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              formatIdentificationDate(entry.createdAt),
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text(
              entry.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (entry.identified && entry.scientificName != null)
              Text(
                entry.scientificName!,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 16),
            Card(
              color: colors.tertiaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sugestão experimental da IA. Este registro não '
                  'confirma a identificação da espécie.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O que a IA observou',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(entry.explanation),
                  ],
                ),
              ),
            ),
            if (entry.matchedCatalog)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Existe uma ficha publicada com o mesmo nome científico '
                  'no catálogo EcoLens. Isso não confirma a foto.',
                ),
              ),
            const SizedBox(height: 12),
            if (hasScientificName) ...[
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => SpeciesCatalogScreen(
                      initialQuery: entry.scientificName!,
                    ),
                  ),
                ),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Buscar ficha no catálogo'),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              'A foto não foi salva. Não utilize sugestões da IA para '
              'avaliar riscos, toxicidade ou decidir primeiros socorros.',
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _delete(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir este registro'),
            ),
          ],
        ),
      ),
    );
  }
}
