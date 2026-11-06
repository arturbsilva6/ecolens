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
  const HeatMapScreen({super.key, this.repository, this.loadTiles = true});
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mapa de avistamentos')),
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
          final colors = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'São Roque/SP como ponto inicial. Explore o estado de São Paulo.',
              ),
              const Text(municipalPrecision),
              OutlinedButton.icon(
                icon: const Icon(Icons.location_city),
                label: Text(
                  c.municipality(c.municipalityId ?? '')?.label ??
                      'Escolher município/SP',
                ),
                onPressed: c.loading
                    ? null
                    : () async {
                        final m = await chooseMunicipality(
                          context,
                          c.municipalities,
                        );
                        if (m != null) {
                          setState(() {
                            _center = LatLng(m.latitude, m.longitude);
                            _mapViewRevision++;
                          });
                          c.municipalityId = m.id;
                          c.load(reset: true);
                        }
                      },
              ),
              const Text(
                'Use sem permissão de localização. Nesta versão, escolha seu município manualmente; o app não solicita GPS.',
              ),
              if (c.municipalityId != null)
                TextButton(
                  onPressed: () {
                    c.municipalityId = null;
                    c.load(reset: true);
                  },
                  child: const Text('Ver todo o estado/SP'),
                ),
              TextField(
                controller: _species,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Filtrar espécie'),
                onSubmitted: (value) {
                  c.species = value;
                  c.load(reset: true);
                },
              ),
              OutlinedButton(
                onPressed: c.loading
                    ? null
                    : () {
                        c.species = _species.text;
                        c.load(reset: true);
                      },
                child: const Text('Aplicar filtro'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Concentração por município'),
                value: _concentration,
                onChanged: (value) => setState(() {
                  _concentration = value;
                }),
              ),
              const Text(
                'São registros da comunidade, não estimativa de população, habitat, distribuição ou risco.',
              ),
              if (_concentration)
                const Text(
                  'Legenda — tamanho do círculo: 1 registro; 2–9 registros; 10 ou mais. Contagens somente dos registros carregados com os filtros atuais.',
                ),
              SizedBox(
                height: 320,
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
                      child: ColoredBox(
                        color: colors.surface,
                        child: TextButton(
                          onPressed: _source,
                          child: const Text(
                            '© OpenStreetMap contributors',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _source,
                child: const Text('© OpenStreetMap contributors — ODbL'),
              ),
              if (_tileError)
                const Text(
                  'Mapa-base indisponível. Consulte os registros abaixo ou tente reabrir o mapa com conexão.',
                ),
              if (_tileError)
                OutlinedButton(
                  onPressed: () => setState(() {
                    _tileAttempt++;
                    _tileError = false;
                  }),
                  child: const Text('Tentar carregar mapa-base'),
                ),
              if (c.loading) const Center(child: CircularProgressIndicator()),
              if (c.error != null) ...[
                Semantics(liveRegion: true, child: Text(c.error!)),
                OutlinedButton(
                  onPressed: c.loading ? null : () => c.load(),
                  child: const Text('Tentar novamente'),
                ),
              ],
              if (!c.loading && c.error == null && c.items.isEmpty)
                const Text(
                  'Nenhum avistamento encontrado. Não há ocorrências para mostrar com estes filtros.',
                ),
              Text(
                '${c.items.length} registros carregados${c.hasMore ? ' — há mais páginas; concentração parcial' : ''}.',
              ),
              if (c.hasMore && c.items.isNotEmpty && !c.loading)
                OutlinedButton(
                  onPressed: () => c.load(),
                  child: const Text('Carregar mais avistamentos'),
                ),
              for (final m in municipalities)
                ListTile(
                  title: Text('${m.label}: ${counts[m.id]}'),
                  subtitle: const Text(
                    'Referência municipal — abrir registros',
                  ),
                  onTap: () => _openMunicipality(m),
                ),
              const Text(
                'Habitat e distribuição: consulte apenas as informações com fonte identificada nas fichas do catálogo. A quantidade de avistamentos não permite inferir esses dados.',
              ),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SpeciesCatalogScreen(),
                  ),
                ),
                child: const Text('Consultar catálogo e fontes'),
              ),
              const Text(
                'Referências municipais: kelvins/municipios-brasileiros (MIT), revisão 503e2f7 de 06/11/2026. Fonte e licença disponíveis na documentação. Pontos de apoio ambiental: nenhum ponto com endereço e coordenadas verificados foi incluído nesta versão. O SOS continua disponível pela Home.',
              ),
            ],
          );
        },
      ),
    ),
  );
}
