import 'package:flutter/material.dart';

import '../../data/supabase_species_repository.dart';
import '../../models/species_model.dart';
import '../species/species_detail_screen.dart';

/// Catálogo público: apenas espécies publicadas no Supabase.
class SpeciesCatalogScreen extends StatefulWidget {
  const SpeciesCatalogScreen({super.key});

  @override
  State<SpeciesCatalogScreen> createState() => _SpeciesCatalogScreenState();
}

class _SpeciesCatalogScreenState extends State<SpeciesCatalogScreen> {
  late Future<List<SpeciesModel>> _speciesFuture;

  @override
  void initState() {
    super.initState();
    _speciesFuture = _fetchSpecies();
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

                  if (species.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Ainda não há espécies publicadas.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: species.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = species[index];
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
