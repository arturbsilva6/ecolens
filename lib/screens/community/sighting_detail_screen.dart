import 'package:flutter/material.dart';

import '../../data/community_repository.dart';
import '../../models/sighting.dart';
import 'community_widgets.dart';
import 'sighting_form_screen.dart';

class SightingDetailScreen extends StatefulWidget {
  final CommunityRepository repository;
  final Sighting sighting;
  final List<Municipality> municipalities;
  final String? accountId;
  const SightingDetailScreen({
    super.key,
    required this.repository,
    required this.sighting,
    required this.municipalities,
    this.accountId,
  });
  @override
  State<SightingDetailScreen> createState() => _SightingDetailScreenState();
}

class _SightingDetailScreenState extends State<SightingDetailScreen> {
  bool _busy = false;
  String? _error;
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Excluir avistamento?'),
        content: const Text(
          'O registro e sua foto serão removidos. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.delete(widget.sighting);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is CommunityFailure
              ? e.message
              : 'Exclusão não confirmada. Tente novamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sighting;
    final municipality = widget.municipalities
        .where((m) => m.id == s.municipalityId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Avistamento')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (s.status == 'published')
              CommunityPhoto(repository: widget.repository, path: s.photoPath),
            Text(s.speciesLabel, style: Theme.of(context).textTheme.titleLarge),
            Text(s.identificationLabel),
            Text(
              '${s.observedOn.day}/${s.observedOn.month}/${s.observedOn.year} • ${municipality?.label ?? 'Município indisponível'}',
            ),
            const Text(municipalPrecision),
            const SizedBox(height: 16),
            Text(s.notes.isEmpty ? 'Sem observações.' : s.notes),
            if (s.status != 'published')
              Text(
                s.status == 'draft'
                    ? 'Rascunho não publicado. Se o envio falhou, exclua este rascunho antes de criar outro.'
                    : 'Exclusão pendente. Tente excluir novamente para concluir a limpeza da foto.',
              ),
            if (widget.accountId == s.ownerId) ...[
              if (s.status == 'published')
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SightingFormScreen(
                                repository: widget.repository,
                                municipalities: widget.municipalities,
                                sighting: s,
                              ),
                            ),
                          );
                          if (changed == true && context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                  child: const Text('Editar'),
                ),
              OutlinedButton(
                onPressed: _busy ? null : _delete,
                child: const Text('Excluir'),
              ),
            ],
            if (_busy) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Semantics(liveRegion: true, child: Text(_error!)),
          ],
        ),
      ),
    );
  }
}
