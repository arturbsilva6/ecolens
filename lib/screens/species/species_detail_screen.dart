import 'package:flutter/material.dart';

import '../../models/species_model.dart';

class SpeciesDetailScreen extends StatelessWidget {
  final SpeciesModel species;

  const SpeciesDetailScreen({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final statusText = switch (species.status) {
      SpeciesStatus.danger => 'Espécie perigosa',
      SpeciesStatus.invasive => 'Espécie invasora',
      SpeciesStatus.unverified => 'Não verificada',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado da identificação')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              color: colors.tertiaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.science_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'DEMONSTRAÇÃO: este resultado é '
                        'ilustrativo. Nenhuma fotografia '
                        'foi analisada por IA.',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (species.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  species.imagePath!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 24),

            Text(
              species.commonName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 6),

            Text(
              species.scientificName,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 20),

            Chip(
              avatar: const Icon(Icons.info_outline, size: 18),
              label: Text(statusText),
            ),

            const SizedBox(height: 16),

            const Card(
              child: ListTile(
                leading: Icon(Icons.analytics_outlined),
                title: Text('Confiança da identificação'),
                subtitle: Text(
                  'Não disponível — a inteligência '
                  'artificial ainda não está integrada.',
                ),
              ),
            ),

            const SizedBox(height: 16),
            for (final section
                in <({String title, String? content, IconData icon})>[
                  (
                    title: 'Sobre a espécie',
                    content: species.description,
                    icon: Icons.menu_book_outlined,
                  ),
                  (
                    title: 'Características',
                    content: species.characteristics,
                    icon: Icons.visibility_outlined,
                  ),
                  (
                    title: 'Habitat',
                    content: species.habitat,
                    icon: Icons.park_outlined,
                  ),
                  (
                    title: 'Riscos conhecidos',
                    content: species.riskDescription,
                    icon: Icons.warning_amber_outlined,
                  ),
                  (
                    title: 'Orientações de segurança',
                    content: species.safetyAdvice,
                    icon: Icons.health_and_safety_outlined,
                  ),
                  (
                    title: 'Fonte das informações',
                    content: species.sourceName,
                    icon: Icons.source_outlined,
                  ),
                  (
                    title: 'Endereço da fonte',
                    content: species.sourceUrl,
                    icon: Icons.link_outlined,
                  ),
                ])
              if (section.content != null &&
                  section.content!.trim().isNotEmpty) ...[
                Card(
                  child: ListTile(
                    leading: Icon(section.icon, color: colors.primary),
                    title: Text(section.title),
                    subtitle: Text(section.content!),
                  ),
                ),
                const SizedBox(height: 8),
              ],

            Card(
              color: colors.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colors.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Não utilize este exemplo para '
                        'identificar espécies reais. '
                        'Mantenha distância de animais '
                        'desconhecidos e não os manuseie.',
                        style: TextStyle(color: colors.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
