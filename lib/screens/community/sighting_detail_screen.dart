import 'package:flutter/material.dart';

import '../../data/community_repository.dart';
import '../../data/favorites_repository.dart';
import '../../data/public_profile_repository.dart';
import '../../data/supabase_species_repository.dart';
import '../../models/sighting.dart';
import '../../models/species_model.dart';
import '../../models/species_status_style.dart';
import '../../utils/species_catalog_filter.dart';
import '../map/heat_map_screen.dart';
import '../species/species_detail_screen.dart';
import '../../widgets/eco_avatar.dart';
import 'community_widgets.dart';
import 'sighting_form_screen.dart';
import '../../widgets/eco_spinner.dart';
import '../../data/blocked_authors_repository.dart';
import '../../widgets/result_dialog.dart';

class SightingDetailScreen extends StatefulWidget {
  final CommunityRepository repository;
  final Sighting sighting;
  final List<Municipality> municipalities;
  final String? accountId;

  /// Catálogo usado para ligar o avistamento à ficha da espécie.
  final Future<List<SpeciesModel>> Function()? loadSpecies;
  final FavoritesRepository? favoritesRepository;

  /// Perfil público do autor (nome e avatar escolhidos por ele).
  final Future<PublicProfile?> Function(String userId)? loadAuthor;

  /// Onde fica a lista de autores bloqueados neste aparelho.
  final BlockedAuthorsRepository? blockedAuthors;
  const SightingDetailScreen({
    super.key,
    required this.repository,
    required this.sighting,
    required this.municipalities,
    this.accountId,
    this.loadSpecies,
    this.favoritesRepository,
    this.loadAuthor,
    this.blockedAuthors,
  });
  @override
  State<SightingDetailScreen> createState() => _SightingDetailScreenState();
}

class _SightingDetailScreenState extends State<SightingDetailScreen> {
  bool _busy = false;
  String? _error;
  SpeciesModel? _species;
  PublicProfile? _author;
  bool _favorite = false;
  late final FavoritesRepository _favorites =
      widget.favoritesRepository ?? FavoritesRepository();

  @override
  void initState() {
    super.initState();
    _findSpecies();
    _findAuthor();
  }

  Future<void> _findAuthor() async {
    try {
      final load = widget.loadAuthor ?? SupabasePublicProfileRepository().fetch;
      final author = await load(widget.sighting.ownerId);
      if (mounted && author != null) setState(() => _author = author);
    } catch (_) {
      // Sem perfil público (ou offline): mostra "membro da comunidade".
    }
  }

  /// Procura a espécie no catálogo (com cópia offline) pelo nome informado.
  Future<void> _findSpecies() async {
    final label = widget.sighting.species;
    if (label == null) return;
    try {
      final catalog =
          await (widget.loadSpecies ??
              () => SupabaseSpeciesRepository().fetchPublishedSpecies())();
      final parts = label.split(' — ').map(normalizeSpeciesSearch).toList();
      final match = catalog.where((sp) {
        final names = {
          normalizeSpeciesSearch(sp.scientificName),
          normalizeSpeciesSearch(sp.commonName),
        };
        return parts.any(names.contains);
      }).firstOrNull;
      if (match == null) return;
      final favorites = await _favorites.load().catchError((_) => <String>{});
      if (!mounted) return;
      setState(() {
        _species = match;
        _favorite = favorites.contains(
          FavoritesRepository.normalize(match.scientificName),
        );
      });
    } catch (_) {
      // Sem catálogo (offline e sem cópia), a tela mostra só o registro.
    }
  }

  Future<void> _toggleFavorite() async {
    final species = _species;
    if (species == null) return;
    final value = !_favorite;
    setState(() => _favorite = value);
    try {
      await _favorites.setFavorite(species.scientificName, value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _favorite = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o favorito.')),
      );
    }
  }

  Future<void> _report() async {
    if (widget.accountId == null) {
      await showResultDialog(
        context,
        title: 'Entre para denunciar',
        message:
            'Denúncias exigem uma conta, para evitar abusos. Você ainda pode '
            'bloquear o autor neste aparelho.',
        success: false,
      );
      return;
    }
    final result = await showDialog<(ReportReason, String)>(
      context: context,
      builder: (_) => const _ReportDialog(),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.report(widget.sighting, result.$1, result.$2);
      if (!mounted) return;
      await showResultDialog(
        context,
        title: 'Denúncia enviada',
        message:
            'Obrigado por avisar. Registros denunciados por várias pessoas '
            'são ocultados automaticamente da Comunidade.',
      );
    } catch (e) {
      if (!mounted) return;
      await showResultDialog(
        context,
        title: 'Denúncia não enviada',
        message: e is CommunityFailure
            ? e.message
            : 'Não foi possível enviar agora. Tente novamente.',
        success: false,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _block() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Bloquear este autor?'),
        content: const Text(
          'Os registros dele deixam de aparecer para você na Comunidade. '
          'Vale só neste aparelho e o autor não é avisado. Dá para desfazer '
          'em Configurações > Privacidade e dados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await (widget.blockedAuthors ?? BlockedAuthorsRepository()).block(
        widget.sighting.ownerId,
      );
    } catch (_) {
      if (!mounted) return;
      await showResultDialog(
        context,
        title: 'Não foi possível bloquear',
        message: 'Tente novamente.',
        success: false,
      );
      return;
    }
    if (!mounted) return;
    await showResultDialog(
      context,
      title: 'Autor bloqueado',
      message: 'Os registros dele não vão mais aparecer para você.',
    );
    if (mounted) Navigator.pop(context, true);
  }

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final parts = s.speciesLabel.split(' — ');
    final scientific = parts.length > 1 ? parts.sublist(1).join(' — ') : null;
    final mine = widget.accountId != null && widget.accountId == s.ownerId;
    final species = _species;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avistamento'),
        actions: [
          if (species != null)
            IconButton(
              tooltip: _favorite
                  ? 'Remover espécie dos favoritos'
                  : 'Favoritar espécie',
              icon: Icon(_favorite ? Icons.favorite : Icons.favorite_border),
              color: _favorite ? colors.error : null,
              onPressed: _toggleFavorite,
            ),
          if (!mine)
            PopupMenuButton<String>(
              tooltip: 'Mais opções',
              enabled: !_busy,
              onSelected: (value) =>
                  value == 'report' ? _report() : _block(),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'report',
                  child: ListTile(
                    leading: Icon(Icons.flag_outlined),
                    title: Text('Denunciar registro'),
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: ListTile(
                    leading: Icon(Icons.block),
                    title: Text('Bloquear autor'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (s.hidden && mine) ...[
              Card(
                margin: EdgeInsets.zero,
                color: colors.errorContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.visibility_off_outlined,
                    color: colors.onErrorContainer,
                  ),
                  title: Text(
                    'Oculto após denúncias',
                    style: TextStyle(color: colors.onErrorContainer),
                  ),
                  subtitle: Text(
                    'Só você vê este registro. Você pode editá-lo ou excluí-lo.',
                    style: TextStyle(color: colors.onErrorContainer),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (s.status == 'published')
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CommunityPhoto(
                  repository: widget.repository,
                  path: s.photoPath,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              parts.first,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (scientific != null)
              Text(
                scientific,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colors.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.identificationLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ),
            ),
            if (s.edited) ...[
              const SizedBox(height: 6),
              Text(
                'Editado depois de publicado',
                style: muted?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(
                      '${s.observedOn.day}/${s.observedOn.month}/${s.observedOn.year}',
                    ),
                    subtitle: const Text('Data do avistamento'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(
                      municipality?.label ?? 'Município indisponível',
                    ),
                    subtitle: const Text(
                      'Referência do município, não o local exato',
                    ),
                  ),
                  ListTile(
                    leading: EcoAvatar(avatar: _author?.avatar, radius: 16),
                    title: Text(
                      _author != null
                          ? 'Publicado por ${_author!.displayName}'
                                '${mine ? ' (você)' : ''}'
                          : mine
                          ? 'Publicado por você'
                          : 'Publicado por um membro da comunidade',
                    ),
                    subtitle: const Text('Identificação não verificada'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notes, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Observações',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(s.notes.isEmpty ? 'Sem observações.' : s.notes),
                  ],
                ),
              ),
            ),
            if (species != null) ...[
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                color: species.status.color.withValues(alpha: .12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            species.status.icon,
                            color: species.status.color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              species.statusSummary,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: species.status.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if ((species.safetyAdvice ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          species.safetyAdvice!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: const Text('Ver ficha completa da espécie'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => SpeciesDetailScreen(
                              species: species,
                              isDemonstration: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (s.status != 'published') ...[
              const SizedBox(height: 12),
              Text(
                s.status == 'draft'
                    ? 'Rascunho não publicado. Se o envio falhou, exclua este rascunho antes de criar outro.'
                    : 'Exclusão pendente. Tente excluir novamente para concluir a limpeza da foto.',
              ),
            ],
            const SizedBox(height: 16),
            if (municipality != null && s.status == 'published')
              OutlinedButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: const Text('Ver no mapa'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => HeatMapScreen(
                      repository: widget.repository,
                      initialMunicipality: municipality,
                    ),
                  ),
                ),
              ),
            if (mine) ...[
              if (s.status == 'published') ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined),
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
                  label: const Text('Editar'),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: colors.error),
                icon: const Icon(Icons.delete_outline),
                onPressed: _busy ? null : _delete,
                label: const Text('Excluir'),
              ),
            ],
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: EcoSpinner()),
              ),
            if (_error != null)
              Semantics(liveRegion: true, child: Text(_error!)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 16, color: muted?.color),
                const SizedBox(width: 6),
                Expanded(child: Text(municipalPrecision, style: muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Escolha do motivo da denúncia, com detalhes opcionais.
class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  ReportReason? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Denunciar registro'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Qual é o problema?'),
        RadioGroup<ReportReason>(
          groupValue: _reason,
          onChanged: (value) => setState(() => _reason = value),
          child: Column(
            children: [
              for (final reason in ReportReason.values)
                RadioListTile<ReportReason>(
                  value: reason,
                  contentPadding: EdgeInsets.zero,
                  title: Text(reason.label),
                ),
            ],
          ),
        ),
        TextField(
          controller: _details,
          maxLength: 500,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(
            labelText: 'Detalhes (opcional)',
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _reason == null
            ? null
            : () => Navigator.pop(context, (_reason!, _details.text)),
        child: const Text('Enviar denúncia'),
      ),
    ],
  );
}
