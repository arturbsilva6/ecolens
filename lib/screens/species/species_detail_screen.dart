import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/species_model.dart';
import '../../data/favorites_repository.dart';
import '../../widgets/species_favorite_button.dart';
import '../../widgets/species_photo.dart';
import '../../models/species_status_style.dart';
import '../../widgets/eco_spinner.dart';

class SpeciesDetailScreen extends StatelessWidget {
  final SpeciesModel species;
  final bool isDemonstration;
  final FavoritesRepository? favoritesRepository;

  const SpeciesDetailScreen({
    super.key,
    required this.species,
    this.isDemonstration = true,
    this.favoritesRepository,
  });

  Future<void> _openExternalLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link.')),
        );
      }
    }
  }

  Widget _informationCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String? content,
    bool isSafety = false,
  }) {
    if (content == null || content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    final emphasized = isSafety && species.status == SpeciesStatus.danger;

    return Card(
      color: emphasized ? colors.errorContainer : colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: emphasized ? colors.onErrorContainer : colors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: emphasized ? colors.onErrorContainer : null,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(
                      color: emphasized
                          ? colors.onErrorContainer
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.surfaceContainerLow,
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
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '• $item',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _speciesImage(BuildContext context) {
    final imageUrl = species.imageUrl;
    final imagePath = species.imagePath;
    if (imageUrl == null && imagePath == null) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    final Widget image;
    if (imageUrl != null) {
      image = SpeciesPhoto(
        imageUrl,
        fit: BoxFit.cover,
        semanticLabel: 'Fotografia ilustrativa de ${species.commonName}',
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: EcoSpinner(
              semanticsLabel: 'Carregando foto',
              value: progress.expectedTotalBytes == null
                  ? null
                  : progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: colors.onSurfaceVariant,
              size: 46,
            ),
          );
        },
      );
    } else {
      image = Image.asset(
        imagePath!,
        fit: BoxFit.cover,
        semanticLabel: 'Imagem demonstrativa de ${species.commonName}',
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.image_not_supported_outlined));
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: ColoredBox(
              color: colors.surfaceContainerHighest,
              child: image,
            ),
          ),
        ),
        if (imageUrl != null && species.imageCredit != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  'Foto: ${species.imageCredit}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (species.imageSourceUrl != null)
                  TextButton(
                    onPressed: () =>
                        _openExternalLink(context, species.imageSourceUrl!),
                    child: const Text('Origem'),
                  ),
                if (species.imageLicenseUrl != null)
                  TextButton(
                    onPressed: () =>
                        _openExternalLink(context, species.imageLicenseUrl!),
                    child: Text(species.imageLicenseLabel ?? 'Licença'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDanger = species.status == SpeciesStatus.danger;
    final statusText = species.statusSummary;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!isDemonstration)
            SpeciesFavoriteButton(
              scientificName: species.scientificName,
              repository: favoritesRepository,
            ),
        ],
        title: Text(
          isDemonstration ? 'Resultado da identificação' : 'Ficha da espécie',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (isDemonstration)
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
                          'DEMONSTRAÇÃO: este resultado é ilustrativo. '
                          'Nenhuma fotografia foi analisada por IA.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            _speciesImage(context),
            const SizedBox(height: 18),
            Text(
              species.commonName,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              species.scientificName,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
            if (species.otherNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Também conhecida como: ${species.otherNames.join(', ')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDanger
                    ? colors.errorContainer
                    : colors.surfaceContainerHighest,
              ),
              child: Row(
                children: [
                  Icon(
                    species.status.icon,
                    color: isDanger
                        ? colors.onErrorContainer
                        : species.status.color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDanger
                            ? colors.onErrorContainer
                            : colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (isDemonstration)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.analytics_outlined),
                  title: Text('Confiança da identificação'),
                  subtitle: Text(
                    'Não disponível — a inteligência artificial '
                    'ainda não está integrada.',
                  ),
                ),
              ),
            _informationCard(
              context,
              title: 'Orientações de segurança',
              icon: Icons.health_and_safety_outlined,
              content: species.safetyAdvice,
              isSafety: true,
            ),
            _informationCard(
              context,
              title: 'Quando chamar resgate',
              icon: Icons.local_phone_outlined,
              content: species.rescueAdvice,
            ),
            _informationCard(
              context,
              title: 'Riscos conhecidos',
              icon: Icons.warning_amber_outlined,
              content: species.riskDescription,
              isSafety: true,
            ),
            _informationCard(
              context,
              title: 'Sobre a espécie',
              icon: Icons.menu_book_outlined,
              content: species.description,
            ),
            _informationCard(
              context,
              title: 'Como reconhecer',
              icon: Icons.search_outlined,
              content: species.visualPattern,
            ),
            _listCard(
              context,
              title: 'Pode ser confundida com',
              icon: Icons.compare_arrows_outlined,
              items: species.lookalikes,
            ),
            _informationCard(
              context,
              title: 'Características',
              icon: Icons.visibility_outlined,
              content: species.characteristics,
            ),
            _informationCard(
              context,
              title: 'Habitat',
              icon: Icons.park_outlined,
              content: species.habitat,
            ),
            if (species.sourceName != null || species.sourceUrl != null)
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.menu_book_outlined,
                    color: colors.primary,
                  ),
                  title: const Text('Fontes das informações'),
                  subtitle: Text(species.sourceName ?? 'Consultar referência'),
                  trailing: species.sourceUrl != null
                      ? const Icon(Icons.open_in_new)
                      : null,
                  onTap: species.sourceUrl != null
                      ? () => _openExternalLink(context, species.sourceUrl!)
                      : null,
                ),
              ),
            const SizedBox(height: 12),
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
                        isDemonstration
                            ? 'Este exemplo não identifica espécies reais. '
                                  'Não toque ou manipule animais desconhecidos.'
                            : 'Esta ficha é informativa. A fotografia não '
                                  'substitui a identificação por especialistas '
                                  'nem o atendimento médico.',
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
