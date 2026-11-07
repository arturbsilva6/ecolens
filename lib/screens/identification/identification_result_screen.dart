import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/ai_identification_result.dart';
import '../../models/community_identification_seed.dart';
import '../../data/community_repository.dart';
import '../../data/supabase_community_repository.dart';
import '../../services/community_photo_service.dart';
import '../community/sighting_form_screen.dart';
import '../../data/identification_history_repository.dart';
import '../../models/species_model.dart';
import '../species/species_detail_screen.dart';

/// Resultado preliminar: a IA sugere um nome, mas não confirma a espécie.
class IdentificationResultScreen extends StatelessWidget {
  final Uint8List? imageBytes;
  final AiIdentificationResult result;
  final SpeciesModel? matchedSpecies;
  final bool catalogUnavailable;
  final IdentificationHistoryRepository? historyRepository;
  final bool isDemonstration;
  final CommunityRepository? communityRepository;
  final CommunityPhotoService? communityPhotoService;
  final Future<void> Function(BuildContext)? openCommunityAccount;

  const IdentificationResultScreen({
    super.key,
    required this.imageBytes,
    required this.result,
    this.matchedSpecies,
    this.catalogUnavailable = false,
    this.historyRepository,
    this.isDemonstration = false,
    this.communityRepository,
    this.communityPhotoService,
    this.openCommunityAccount,
  });

  void _openPublishedSpecies(BuildContext context) {
    final species = matchedSpecies;
    if (species == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            SpeciesDetailScreen(species: species, isDemonstration: false),
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
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
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
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
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
    final suggestedName =
        result.commonName ??
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
                      child: imageBytes == null || imageBytes!.isEmpty
                          ? const Center(
                              child: Text(
                                'Foto original indisponível. Você pode selecionar uma foto válida no formulário da comunidade.',
                              ),
                            )
                          : Image.memory(
                              imageBytes!,
                              fit: BoxFit.cover,
                              semanticLabel: 'Fotografia enviada para análise',
                              errorBuilder: (context, error, stackTrace) {
                                return ColoredBox(
                                  color: colors.surfaceContainerHighest,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 48,
                                    ),
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
                    hasSuggestion
                        ? 'Espécie sugerida'
                        : 'Resultado inconclusivo',
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
                  _AiExplanationCard(
                    message: result.explanation,
                    title: hasSuggestion
                        ? 'O que a IA observou'
                        : 'Por que a análise foi inconclusiva',
                  ),
                  if (hasSuggestion) ...[
                    const SizedBox(height: 12),
                    _informationCard(
                      context,
                      icon: Icons.menu_book_outlined,
                      title: 'Correspondência no catálogo EcoLens',
                      message: catalogMessage,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _SaveHistoryButton(
                    result: result,
                    matchedCatalog: matchedSpecies != null,
                    repository: historyRepository,
                  ),
                  const SizedBox(height: 12),
                  if (isDemonstration)
                    const Text(
                      'Resultado demonstrativo: não pode ser compartilhado como identificação real.',
                    )
                  else
                    _ShareCommunityButton(
                      seed: CommunityIdentificationSeed.fromResult(
                        result,
                        imageBytes,
                      ),
                      repository: communityRepository,
                      photoService: communityPhotoService,
                      openAccount: openCommunityAccount,
                    ),
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
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.outlineVariant)),
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

/// A análise gerada pela IA pode ser extensa. Mostramos um resumo de até
/// três linhas e permitimos que o usuário escolha ler a explicação inteira.
class _AiExplanationCard extends StatefulWidget {
  final String title;
  final String message;

  const _AiExplanationCard({required this.title, required this.message});

  @override
  State<_AiExplanationCard> createState() => _AiExplanationCardState();
}

class _AiExplanationCardState extends State<_AiExplanationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canExpand = widget.message.length > 180;

    return Card(
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome_outlined, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.message,
                    maxLines: canExpand && !_expanded ? 3 : null,
                    overflow: canExpand && !_expanded
                        ? TextOverflow.ellipsis
                        : TextOverflow.visible,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(height: 1.5, color: colors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explicação automática; pode conter imprecisões.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  if (canExpand) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _expanded = !_expanded);
                      },
                      icon: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      label: Text(
                        _expanded
                            ? 'Recolher explicação'
                            : 'Ler explicação completa',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O salvamento é opcional; só guarda o resultado textual no dispositivo.
class _SaveHistoryButton extends StatefulWidget {
  final AiIdentificationResult result;
  final bool matchedCatalog;
  final IdentificationHistoryRepository? repository;

  const _SaveHistoryButton({
    required this.result,
    required this.matchedCatalog,
    this.repository,
  });

  @override
  State<_SaveHistoryButton> createState() => _SaveHistoryButtonState();
}

class _SaveHistoryButtonState extends State<_SaveHistoryButton> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    if (_saved || _saving) return;
    setState(() => _saving = true);
    try {
      await (widget.repository ?? IdentificationHistoryRepository()).save(
        widget.result,
        matchedCatalog: widget.matchedCatalog,
      );
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resultado salvo no histórico deste dispositivo.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o resultado.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: _saving || _saved ? null : _save,
              icon: Icon(
                _saved
                    ? Icons.check_circle_outline
                    : Icons.bookmark_add_outlined,
              ),
              label: Text(
                _saved ? 'Salvo no histórico' : 'Salvar no histórico',
              ),
            ),
            const Text(
              'Salva somente a data, o nome sugerido e a explicação '
              'no dispositivo. A fotografia não é armazenada.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareCommunityButton extends StatefulWidget {
  final CommunityIdentificationSeed seed;
  final CommunityRepository? repository;
  final CommunityPhotoService? photoService;
  final Future<void> Function(BuildContext)? openAccount;
  const _ShareCommunityButton({
    required this.seed,
    this.repository,
    this.photoService,
    this.openAccount,
  });
  @override
  State<_ShareCommunityButton> createState() => _ShareCommunityButtonState();
}

class _ShareCommunityButtonState extends State<_ShareCommunityButton> {
  bool _opening = false;
  String? _error;
  Future<void> _open() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final repository = widget.repository ?? SupabaseCommunityRepository();
      final municipalities = await repository.municipalities();
      if (!mounted) return;
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => SightingFormScreen(
            repository: repository,
            municipalities: municipalities,
            initialIdentification: widget.seed,
            photoService: widget.photoService,
            openAccount: widget.openAccount,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível abrir o formulário. Seu resultado foi preservado; tente novamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OutlinedButton.icon(
        onPressed: _opening ? null : _open,
        icon: const Icon(Icons.share_outlined),
        label: const Text('Compartilhar na comunidade'),
      ),
      const Text(
        'Abre um formulário revisável. Compartilhar não publica automaticamente nem salva fotos no histórico.',
      ),
      if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
    ],
  );
}
