import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/ai_identification_result.dart';
import '../../models/species_model.dart';
import '../species/species_detail_screen.dart';

/// Resultado preliminar: a IA sugere um nome, mas não confirma a espécie.
class IdentificationResultScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final AiIdentificationResult result;
  final SpeciesModel? matchedSpecies;
  final bool catalogUnavailable;

  const IdentificationResultScreen({
    super.key,
    required this.imageBytes,
    required this.result,
    this.matchedSpecies,
    this.catalogUnavailable = false,
  });

  void _openPublishedSpecies(BuildContext context) {
    final species = matchedSpecies;
    if (species == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SpeciesDetailScreen(
          species: species,
          isDemonstration: false,
        ),
      ),
    );
  }

  Widget _informationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.surfaceContainerLow,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasSuggestion = result.identified;
    final suggestedName = result.commonName ??
        result.scientificName ??
        'Espécie não identificada';

    final catalogMessage = matchedSpecies != null
        ? 'Encontramos uma ficha publicada com o mesmo nome científico. '
            'Isso não confirma a espécie da fotografia.'
        : catalogUnavailable
            ? 'Não foi possível consultar o catálogo neste momento. '
                'A sugestão da IA continua não confirmada.'
            : 'Nenhuma ficha publicada corresponde exatamente ao nome '
                'científico sugerido. A identificação não foi confirmada.';

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado da análise')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 16 / 11,
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.cover,
                        semanticLabel: 'Fotografia enviada para análise',
                        errorBuilder: (context, error, stackTrace) {
                          return ColoredBox(
                            color: colors.surfaceContainerHighest,
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined, size: 48),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colors.onTertiaryContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hasSuggestion
                                ? 'Sugestão da IA — identificação não confirmada'
                                : 'Análise inconclusiva — espécie não identificada',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colors.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    hasSuggestion ? 'Espécie sugerida' : 'Resultado inconclusivo',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestedName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (hasSuggestion &&
                      result.commonName != null &&
                      result.scientificName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      result.scientificName!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _informationCard(
                    context,
                    icon: Icons.auto_awesome_outlined,
                    title: hasSuggestion
                        ? 'O que a IA observou'
                        : 'Por que a análise foi inconclusiva',
                    message: result.explanation,
                  ),
                  if (hasSuggestion) ...[
                    const SizedBox(height: 12),
                    _informationCard(
                      context,
                      icon: Icons.menu_book_outlined,
                      title: 'Conferência no catálogo EcoLens',
                      message: catalogMessage,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    color: colors.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.health_and_safety_outlined,
                            color: colors.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Não use este resultado para decidir se um '
                              'animal é seguro, avaliar toxicidade ou '
                              'orientar primeiros socorros. Não se aproxime '
                              'nem manipule animais desconhecidos. '
                              'Consulte especialistas.',
                              style: TextStyle(
                                color: colors.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  top: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (matchedSpecies != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _openPublishedSpecies(context),
                          icon: const Icon(Icons.menu_book_outlined),
                          label: const Text('Ver ficha da espécie'),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Nova identificação'),
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
