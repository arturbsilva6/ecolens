import 'package:flutter/material.dart';

import '../../data/supabase_species_repository.dart';
import '../../models/species_model.dart';

class RecentSpeciesSection extends StatefulWidget {
  final Future<List<SpeciesModel>> Function()? fetchPublishedSpecies;
  final ValueChanged<SpeciesModel> onSpeciesTap;
  final VoidCallback onViewAllTap;

  const RecentSpeciesSection({
    super.key,
    this.fetchPublishedSpecies,
    required this.onSpeciesTap,
    required this.onViewAllTap,
  });

  @override
  State<RecentSpeciesSection> createState() => _RecentSpeciesSectionState();
}

class _RecentSpeciesSectionState extends State<RecentSpeciesSection> {
  late Future<List<SpeciesModel>> _speciesFuture;

  @override
  void initState() {
    super.initState();
    _speciesFuture = _fetch();
  }

  Future<List<SpeciesModel>> _fetch() async =>
      (widget.fetchPublishedSpecies ??
      SupabaseSpeciesRepository().fetchPublishedSpecies)();

  void _retry() {
    setState(() {
      _speciesFuture = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Explore as espécies',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: widget.onViewAllTap,
              child: const Text('Ver todas'),
            ),
          ],
        ),

        const SizedBox(height: 12),
        FutureBuilder<List<SpeciesModel>>(
          future: _speciesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Carregando espécies do catálogo',
                ),
              );
            }
            if (snapshot.hasError) {
              // As chaves publicáveis devem ser fornecidas no início do app.
              // Não registrar exceções nem exibir URLs ou valores de chaves.
              const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
              const publishableKey = String.fromEnvironment(
                'SUPABASE_PUBLISHABLE_KEY',
              );
              final missingConfig =
                  widget.fetchPublishedSpecies == null &&
                  (supabaseUrl.isEmpty || publishableKey.isEmpty);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Não foi possível carregar as espécies.'),
                  const SizedBox(height: 6),
                  Text(
                    missingConfig
                        ? 'O catálogo online não está configurado nesta execução. Reinicie o app com SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY.'
                        : 'Verifique a conexão com a internet e tente novamente.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              );
            }
            final species = snapshot.data ?? <SpeciesModel>[];
            if (species.isEmpty) {
              return const Text(
                'Nenhuma espécie publicada disponível no momento.',
              );
            }
            final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
            return SizedBox(
              height: 250 + (textScale - 1).clamp(0, double.infinity) * 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: species.length.clamp(0, 3),
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = species[index];

                  return _SpeciesCard(
                    species: item,
                    onTap: () => widget.onSpeciesTap(item),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  final SpeciesModel species;
  final VoidCallback onTap;

  const _SpeciesCard({required this.species, required this.onTap});

  String get statusLabel => switch (species.status) {
    SpeciesStatus.danger => 'Perigo',
    SpeciesStatus.invasive => 'Invasora',
    SpeciesStatus.unverified => 'Demais',
  };

  Color get statusColor => switch (species.status) {
    SpeciesStatus.danger => const Color(0xFFB4232C),
    SpeciesStatus.invasive => const Color(0xFF98500B),
    SpeciesStatus.unverified => const Color(0xFF526579),
  };

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.eco_outlined,
        size: 44,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 166,
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem da espécie
              SizedBox(
                height: 120,
                width: double.infinity,
                child: species.imageUrl != null
                    ? Image.network(
                        species.imageUrl!,
                        fit: BoxFit.cover,
                        semanticLabel:
                            'Fotografia ilustrativa de ${species.commonName}',
                        loadingBuilder: (context, child, progress) =>
                            progress == null ? child : _placeholder(context),
                        errorBuilder: (context, error, stackTrace) =>
                            _placeholder(context),
                      )
                    : species.imagePath == null
                    ? _placeholder(context)
                    : Image.asset(
                        species.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _placeholder(context);
                        },
                      ),
              ),

              // Informações da espécie
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      species.commonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      species.scientificName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
