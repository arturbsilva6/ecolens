import 'package:flutter/material.dart';

import '../../data/supabase_species_repository.dart';
import '../../models/species_model.dart';
import '../../utils/species_catalog_filter.dart';
import '../species/species_detail_screen.dart';
import '../../widgets/species_photo.dart';
import '../../models/species_status_style.dart';
import '../../widgets/eco_spinner.dart';

/// Catálogo público: apenas espécies publicadas no Supabase.
class SpeciesCatalogScreen extends StatefulWidget {
  final String initialQuery;
  final SpeciesCatalogFilter initialFilter;
  final SpeciesKindFilter initialKind;

  const SpeciesCatalogScreen({
    super.key,
    this.initialQuery = '',
    this.initialFilter = SpeciesCatalogFilter.all,
    this.initialKind = SpeciesKindFilter.all,
  });

  @override
  State<SpeciesCatalogScreen> createState() => _SpeciesCatalogScreenState();
}

class _SpeciesCatalogScreenState extends State<SpeciesCatalogScreen> {
  late final TextEditingController _searchController;
  late Future<List<SpeciesModel>> _speciesFuture;
  late SpeciesCatalogFilter _selectedFilter;
  late SpeciesKindFilter _kind;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _selectedFilter = widget.initialFilter;
    _kind = widget.initialKind;
    _speciesFuture = _fetchSpecies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<SpeciesModel>> _fetchSpecies() async {
    return SupabaseSpeciesRepository().fetchPublishedSpecies();
  }

  void _refresh() {
    setState(() {
      _speciesFuture = _fetchSpecies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de espécies')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'Fichas informativas publicadas no EcoLens. '
                'Esta consulta não identifica animais ou plantas '
                'a partir de fotografias.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Nome popular ou científico',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Limpar pesquisa',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: SpeciesKindFilter.values.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final kind = SpeciesKindFilter.values[index];
                  return ChoiceChip(
                    avatar: Icon(switch (kind) {
                      SpeciesKindFilter.all => Icons.apps,
                      SpeciesKindFilter.animals => Icons.pets,
                      SpeciesKindFilter.plants => Icons.local_florist,
                    }, size: 18),
                    label: Text(kind.label),
                    selected: _kind == kind,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _kind = kind),
                  );
                },
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: SpeciesCatalogFilter.values.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = SpeciesCatalogFilter.values[index];
                  return ChoiceChip(
                    label: Text(filter.label),
                    selected: _selectedFilter == filter,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter);
                    },
                  );
                },
              ),
            ),
            if (_selectedFilter == SpeciesCatalogFilter.unverified)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Demais inclui espécies sem etiqueta específica de perigo '
                  'ou invasão neste catálogo. Isso não significa que sejam seguras.',
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<SpeciesModel>>(
                future: _speciesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: EcoSpinner());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_outlined, size: 40),
                            const SizedBox(height: 12),
                            const Text(
                              'Não foi possível carregar o catálogo. '
                              'Verifique a internet e a configuração '
                              'do Supabase.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _refresh,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final species = snapshot.data ?? const <SpeciesModel>[];

                  final matchingSpecies = filterSpeciesCatalog(
                    species,
                    query: _searchController.text,
                    filter: _selectedFilter,
                    kind: _kind,
                  );

                  if (matchingSpecies.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          species.isEmpty
                              ? '0 espécies encontradas. '
                                    'Ainda não há espécies publicadas.'
                              : _searchController.text.trim().isEmpty
                              ? 'Nenhuma espécie publicada '
                                    'nesta classificação.'
                              : 'Nenhuma espécie publicada encontrada '
                                    'para esta pesquisa e filtro.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: matchingSpecies.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Text(
                          '${matchingSpecies.length} '
                          '${matchingSpecies.length == 1 ? 'espécie encontrada' : 'espécies encontradas'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      }
                      final item = matchingSpecies[index - 1];
                      final isDanger = item.status == SpeciesStatus.danger;

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: item.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SpeciesPhoto(
                                    item.imageUrl!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    semanticLabel:
                                        'Fotografia de ${item.commonName}',
                                    errorBuilder: (context, error, stackTrace) {
                                      return const SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  item.status.icon,
                                  color: isDanger
                                      ? colors.error
                                      : item.status.color,
                                ),
                          title: Text(item.commonName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.scientificName),
                              Text(
                                item.statusSummary,
                                style: TextStyle(
                                  color: isDanger
                                      ? colors.error
                                      : colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => SpeciesDetailScreen(
                                  species: item,
                                  isDemonstration: false,
                                ),
                              ),
                            );
                          },
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
