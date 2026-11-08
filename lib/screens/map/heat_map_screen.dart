import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/community_controller.dart';
import '../../data/community_repository.dart';
import '../../data/supabase_community_repository.dart';
import '../../models/sighting.dart';
import '../community/community_widgets.dart';
import '../community/sighting_detail_screen.dart';
import '../species/species_catalog_screen.dart';

class HeatMapScreen extends StatefulWidget {
  final CommunityRepository? repository;
  final bool loadTiles;
  final Municipality? initialMunicipality;
  const HeatMapScreen({
    super.key,
    this.repository,
    this.loadTiles = true,
    this.initialMunicipality,
  });
  @override
  State<HeatMapScreen> createState() => _HeatMapScreenState();
}

class _HeatMapScreenState extends State<HeatMapScreen> {
  late final CommunityController _controller;
  LatLng _center = const LatLng(-23.5226, -47.1357);
  int _mapViewRevision = 0;
  final _species = TextEditingController();
  bool _concentration = false, _tileError = false;
  int _tileAttempt = 0;
  @override
  void initState() {
    super.initState();
    _controller = CommunityController(
      widget.repository ?? SupabaseCommunityRepository(),
    );
    final municipality = widget.initialMunicipality;
    if (municipality != null) {
      _center = LatLng(municipality.latitude, municipality.longitude);
      _controller.municipalityId = municipality.id;
    }
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _species.dispose();
    super.dispose();
  }

  Future<void> _openMunicipality(Municipality municipality) async {
    final sightings = _controller.items
        .where((s) => s.municipalityId == municipality.id)
        .toList();
    final selected = await showModalBottomSheet<Sighting>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${municipality.label}: ${sightings.length} registros carregados',
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(municipalPrecision),
            ),
            for (final s in sightings)
              ListTile(
                title: Text(s.speciesLabel),
                subtitle: Text(s.identificationLabel),
                onTap: () => Navigator.pop(context, s),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SightingDetailScreen(
          repository: _controller.repository,
          sighting: selected,
          municipalities: _controller.municipalities,
          accountId: _controller.accountId,
        ),
      ),
    );
    await _controller.load(reset: true);
  }

  Future<void> _source() async {
    bool success = false;
    try {
      success = await launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      /* Display attribution URL below if launch fails. */
    }
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atribuição: https://www.openstreetmap.org/copyright'),
        ),
      );
    }
  }

  Future<void> _chooseMunicipality() async {
    final c = _controller;
    final m = await chooseMunicipality(context, c.municipalities);
    if (m == null) return;
    setState(() {
      _center = LatLng(m.latitude, m.longitude);
      _mapViewRevision++;
    });
    c.municipalityId = m.id;
    c.load(reset: true);
  }

  void _applySpecies() {
    _controller.species = _species.text;
    _controller.load(reset: true);
  }

  void _showAbout() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            'Sobre o mapa',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const _AboutItem(
            icon: Icons.location_off_outlined,
            text: '$municipalPrecision O app não pede permissão de '
                'localização: você escolhe o município.',
          ),
          const _AboutItem(
            icon: Icons.groups_outlined,
            text: 'Os pontos são registros da comunidade. Não indicam '
                'população, habitat, distribuição nem risco da espécie.',
          ),
          const _AboutItem(
            icon: Icons.menu_book_outlined,
            text: 'Para habitat e distribuição, use as fichas do catálogo, '
                'que têm fonte identificada.',
          ),
          const _AboutItem(
            icon: Icons.source_outlined,
            text: 'Coordenadas dos municípios: kelvins/municipios-brasileiros '
                '(MIT), revisão 503e2f7 de 06/11/2026. Mapa-base: '
                'OpenStreetMap (ODbL).',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                this.context,
                MaterialPageRoute<void>(
                  builder: (_) => const SpeciesCatalogScreen(),
                ),
              );
            },
            label: const Text('Consultar catálogo e fontes'),
          ),
          TextButton(
            onPressed: _source,
            child: const Text('© OpenStreetMap contributors — ODbL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mapa de avistamentos'),
      actions: [
        IconButton(
          tooltip: 'Sobre o mapa',
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
          final counts = <String, int>{};
          for (final s in c.items) {
            counts.update(s.municipalityId, (n) => n + 1, ifAbsent: () => 1);
          }
          final municipalities = c.municipalities
              .where((m) => counts.containsKey(m.id))
              .toList();
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          final muted = theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          );
          final selected = c.municipality(c.municipalityId ?? '');
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Filtros
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        alignment: Alignment.centerLeft,
                      ),
                      icon: const Icon(Icons.location_city),
                      label: Text(
                        selected?.label ?? 'Escolher município/SP',
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: c.loading ? null : _chooseMunicipality,
                    ),
                  ),
                  if (c.municipalityId != null)
                    IconButton(
                      tooltip: 'Ver todo o estado/SP',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        c.municipalityId = null;
                        c.load(reset: true);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _species,
                maxLength: 120,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Filtrar por espécie',
                  prefixIcon: const Icon(Icons.search),
                  counterText: '',
                  suffixIcon: IconButton(
                    tooltip: 'Aplicar filtro',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: c.loading ? null : _applySpecies,
                  ),
                ),
                onSubmitted: (_) => _applySpecies(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: muted?.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Só o município aparece no mapa. Sem GPS.',
                      style: muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Mapa
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 340,
                  child: FlutterMap(
                    key: ValueKey(_mapViewRevision),
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: 10,
                      minZoom: 5,
                      maxZoom: 16,
                    ),
                    children: [
                      if (widget.loadTiles)
                        TileLayer(
                          key: ValueKey(_tileAttempt),
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'br.com.ecolens',
                          errorTileCallback: (_, _, _) {
                            if (!_tileError && mounted) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _tileError = true;
                                  });
                                }
                              });
                            }
                          },
                        ),
                      if (_concentration)
                        CircleLayer(
                          circles: municipalities
                              .map(
                                (m) => CircleMarker(
                                  point: LatLng(m.latitude, m.longitude),
                                  radius: counts[m.id]! >= 10
                                      ? 44
                                      : counts[m.id]! >= 2
                                      ? 30
                                      : 18,
                                  color: colors.primary.withValues(alpha: .25),
                                  borderColor: colors.primary,
                                  borderStrokeWidth: 2,
                                ),
                              )
                              .toList(),
                        ),
                      MarkerLayer(
                        markers: municipalities
                            .map(
                              (m) => Marker(
                                point: LatLng(m.latitude, m.longitude),
                                width: 64,
                                height: 64,
                                child: Semantics(
                                  label:
                                      '${m.label}, ${counts[m.id]} registros carregados',
                                  button: true,
                                  child: IconButton(
                                    tooltip: '${m.label}: ${counts[m.id]}',
                                    onPressed: () => _openMunicipality(m),
                                    icon: Badge(
                                      label: Text('${counts[m.id]}'),
                                      child: const Icon(Icons.location_on),
                                    ),
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: .85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: _source,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                '© OpenStreetMap',
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.bubble_chart_outlined),
                title: const Text('Concentração por município'),
                value: _concentration,
                onChanged: (value) => setState(() {
                  _concentration = value;
                }),
              ),
              if (_concentration)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Legenda: círculo pequeno = 1 registro; médio = 2 a 9; '
                    'grande = 10 ou mais. Conta só os registros carregados.',
                    style: muted,
                  ),
                ),
              if (_tileError) ...[
                Text(
                  'Mapa-base indisponível. Os registros continuam na lista abaixo.',
                  style: muted,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() {
                    _tileAttempt++;
                    _tileError = false;
                  }),
                  label: const Text('Tentar carregar mapa-base'),
                ),
              ],

              // Registros
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Municípios com registros',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (c.items.isNotEmpty)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        '${c.items.length}${c.hasMore ? '+' : ''} registros',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (c.loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (c.error != null) ...[
                Semantics(liveRegion: true, child: Text(c.error!)),
                OutlinedButton(
                  onPressed: c.loading ? null : () => c.load(),
                  child: const Text('Tentar novamente'),
                ),
              ],
              if (!c.loading && c.error == null && c.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.travel_explore,
                        size: 40,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nenhum avistamento encontrado.',
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Tente outro município ou outra espécie.',
                        textAlign: TextAlign.center,
                        style: muted,
                      ),
                    ],
                  ),
                ),
              for (final m in municipalities)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text('${m.label}: ${counts[m.id]}'),
                    subtitle: const Text('Ver registros'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openMunicipality(m),
                  ),
                ),
              if (c.hasMore && c.items.isNotEmpty && !c.loading)
                OutlinedButton.icon(
                  icon: const Icon(Icons.expand_more),
                  onPressed: () => c.load(),
                  label: const Text('Carregar mais avistamentos'),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class _AboutItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AboutItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
