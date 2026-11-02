import 'package:flutter/material.dart';

import '../../data/supabase_species_repository.dart';
import '../../models/species_model.dart';
import '../species/species_detail_screen.dart';

/// Catálogo público: apenas espécies publicadas no Supabase.
class SpeciesCatalogScreen extends StatefulWidget {
  final String initialQuery;

  const SpeciesCatalogScreen({
    super.key,
    this.initialQuery = '',
  });

  @override
  State<SpeciesCatalogScreen> createState() => _SpeciesCatalogScreenState();
}

class _SpeciesCatalogScreenState extends State<SpeciesCatalogScreen> {
  late final TextEditingController _searchController;
  late Future<List<SpeciesModel>> _speciesFuture;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
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

  // A busca é feita sobre o catálogo público recebido do Supabase.
  // Para catálogos grandes, poderemos usar uma consulta filtrada no servidor.
  String _normalizeSearch(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c');
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
            Expanded(
              child: FutureBuilder<List<SpeciesModel>>(
                future: _speciesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
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

                  final query = _normalizeSearch(_searchController.text);
                  final matchingSpecies = query.isEmpty
                      ? species
                      : species.where((item) {
                          final common = _normalizeSearch(item.commonName);
                          final scientific = _normalizeSearch(
                            item.scientificName,
                          );
                          return common.contains(query) ||
                              scientific.contains(query);
                        }).toList(growable: false);

                  if (matchingSpecies.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          species.isEmpty
                              ? 'Ainda não há espécies publicadas.'
                              : 'Nenhuma espécie publicada encontrada '
                                'para esta pesquisa.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: matchingSpecies.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = matchingSpecies[index];
                      final isDanger = item.status == SpeciesStatus.danger;

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: item.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
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
                                  isDanger
                                      ? Icons.warning_amber_rounded
                                      : Icons.eco_outlined,
                                  color:
                                      isDanger ? colors.error : colors.primary,
                                ),
                          title: Text(item.commonName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.scientificName),
                              if (isDanger)
                                Text(
                                  'Espécie perigosa',
                                  style: TextStyle(color: colors.error),
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
