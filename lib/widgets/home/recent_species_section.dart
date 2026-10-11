
import 'package:flutter/material.dart';
import '../../models/species_model.dart';

class RecentSpeciesSection extends StatelessWidget {
  final List<SpeciesModel> species;
  final ValueChanged<SpeciesModel> onSpeciesTap;
  final VoidCallback onViewAllTap;

  const RecentSpeciesSection({
    super.key,
    required this.species,
    required this.onSpeciesTap,
    required this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Registros recentes',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: onViewAllTap,
              child: const Text('Ver todos'),
            ),
          ],
        ),

        Text(
          'Dados de demonstração',
          style: Theme.of(context).textTheme.bodySmall,
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: species.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = species[index];

              return _SpeciesCard(
                species: item,
                onTap: () => onSpeciesTap(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  final SpeciesModel species;
  final VoidCallback onTap;

  const _SpeciesCard({
    required this.species,
    required this.onTap,
  });

  String get statusLabel => switch (species.status) {
    SpeciesStatus.danger => 'Perigo',
    SpeciesStatus.invasive => 'Invasora',
    SpeciesStatus.unverified => 'A verificar',
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
                child: species.imagePath == null
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
