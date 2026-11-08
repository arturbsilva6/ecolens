import 'package:flutter/material.dart';

import '../../controllers/community_controller.dart';
import '../../data/community_repository.dart';
import '../../data/supabase_community_repository.dart';
import '../../models/sighting.dart';
import '../profile/profile_screen.dart';
import 'community_widgets.dart';
import 'sighting_detail_screen.dart';
import 'sighting_form_screen.dart';

class CommunityScreen extends StatefulWidget {
  final CommunityRepository? repository;
  final bool initialMine;
  const CommunityScreen({super.key, this.repository, this.initialMine = false});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late final CommunityController _controller;
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    _controller = CommunityController(
      widget.repository ?? SupabaseCommunityRepository(),
    );
    _controller.mine = widget.initialMine;
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    try {
      final account = await _controller.repository.accountId();
      if (!mounted) return;
      if (account == null) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: const Text('Entre para publicar'),
            content: const Text(
              'Convidados podem consultar. Publicar exige conta cadastrada; uma sessão anônima não é suficiente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continuar consultando'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(this.context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
                child: const Text('Abrir Perfil'),
              ),
            ],
          ),
        );
        return;
      }
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => SightingFormScreen(
            repository: _controller.repository,
            municipalities: _controller.municipalities,
          ),
        ),
      );
      _controller.mine = true;
      await _controller.load(reset: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Serviço de Comunidade indisponível. Confira a configuração e tente novamente.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _chooseMunicipality() async {
    final c = _controller;
    final municipality = await chooseMunicipality(context, c.municipalities);
    if (municipality != null) {
      c.municipalityId = municipality.id;
      c.load(reset: true);
    }
  }

  void _applySpecies() {
    _controller.species = _search.text;
    _controller.load(reset: true);
  }

  void _showAbout() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            'Sobre a comunidade',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.fact_check_outlined),
            title: Text(
              'As identificações são de usuários ou sugestões de IA e não '
              'foram verificadas cientificamente.',
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.location_off_outlined),
            title: Text(municipalPrecision),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.photo_outlined),
            title: Text(
              'As fotos são publicadas sem metadados de localização.',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Comunidade'),
      actions: [
        IconButton(
          tooltip: 'Sobre a comunidade',
          icon: const Icon(Icons.info_outline),
          onPressed: _showAbout,
        ),
      ],
    ),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          final muted = theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          );
          final selected = c.municipality(c.municipalityId ?? '');
          return RefreshIndicator(
            onRefresh: () => c.load(reset: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  'Avistamentos registrados por moradores da região. '
                  'Identificações não verificadas.',
                  style: muted,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: c.loading ? null : _publish,
                  icon: const Icon(Icons.add),
                  label: const Text('Publicar avistamento'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _search,
                  maxLength: 120,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Filtrar por espécie',
                    prefixIcon: const Icon(Icons.search),
                    counterText: '',
                    suffixIcon: IconButton(
                      tooltip: 'Aplicar filtro de espécie',
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: c.loading ? null : _applySpecies,
                    ),
                  ),
                  onSubmitted: (_) => _applySpecies(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (selected == null)
                      ActionChip(
                        avatar: const Icon(Icons.location_city, size: 18),
                        label: const Text('Todos os municípios/SP'),
                        onPressed: c.loading ? null : _chooseMunicipality,
                      )
                    else
                      InputChip(
                        avatar: const Icon(Icons.location_city, size: 18),
                        label: Text(selected.label),
                        onPressed: c.loading ? null : _chooseMunicipality,
                        deleteButtonTooltipMessage: 'Limpar município',
                        onDeleted: c.loading
                            ? null
                            : () {
                                c.municipalityId = null;
                                c.load(reset: true);
                              },
                      ),
                    if (c.accountId != null)
                      FilterChip(
                        avatar: const Icon(Icons.person_outline, size: 18),
                        label: const Text('Meus registros'),
                        tooltip: 'Inclui rascunhos e exclusões pendentes',
                        selected: c.mine,
                        onSelected: c.loading
                            ? null
                            : (value) {
                                c.mine = value;
                                c.load(reset: true);
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (c.error != null) ...[
                  Semantics(liveRegion: true, child: Text(c.error!)),
                  OutlinedButton(
                    onPressed: c.loading ? null : () => c.load(),
                    child: const Text('Tentar novamente'),
                  ),
                ],
                if (c.items.isEmpty && !c.loading && c.error == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.forest_outlined,
                          size: 40,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nenhum avistamento encontrado.',
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Seja o primeiro a registrar um avistamento.',
                          textAlign: TextAlign.center,
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                for (final s in c.items) _tile(context, s),
                if (c.loading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (c.hasMore && c.items.isNotEmpty && !c.loading)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.expand_more),
                    onPressed: () => c.load(),
                    label: const Text('Carregar mais'),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _tile(BuildContext context, Sighting s) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // "Nome popular — Nome científico" vira título e subtítulo em itálico.
    final parts = s.speciesLabel.split(' — ');
    final common = parts.first;
    final scientific = parts.length > 1 ? parts.sublist(1).join(' — ') : null;
    final date =
        '${s.observedOn.day}/${s.observedOn.month}/${s.observedOn.year}';
    final place = _controller.municipality(s.municipalityId)?.label ?? 'SP';
    final (tag, tagColor, tagText) = switch (s.status) {
      'published' => (
        s.identificationLabel,
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      'draft' => (
        'Rascunho não publicado',
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      _ => (
        'Exclusão pendente',
        colors.errorContainer,
        colors.onErrorContainer,
      ),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => SightingDetailScreen(
                repository: _controller.repository,
                sighting: s,
                municipalities: _controller.municipalities,
                accountId: _controller.accountId,
              ),
            ),
          );
          await _controller.load(reset: true);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: const Icon(Icons.visibility_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(common, style: theme.textTheme.titleMedium),
                    if (scientific != null)
                      Text(
                        scientific,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '$place · $date',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: tagText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
