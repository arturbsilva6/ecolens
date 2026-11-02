import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../controllers/species_controller.dart';
import '../species/species_detail_screen.dart';
import '../../data/mock_species_repository.dart';
import '../../models/ai_identification_result.dart';
import '../../services/ai_service.dart';

enum IdentificationSource { camera, gallery }

class IdentificationScreen extends StatefulWidget {
  final IdentificationSource? initialSource;

  const IdentificationScreen({super.key, this.initialSource});

  @override
  State<IdentificationScreen> createState() => _IdentificationScreenState();
}

class _IdentificationScreenState extends State<IdentificationScreen> {
  // Mantido desligado até configurar Auth, segredo Gemini e limites de uso.
  static const bool _aiEnabled = bool.fromEnvironment(
    'ECOLENS_AI_ENABLED',
    defaultValue: false,
  );

  late final SpeciesController _controller;
  bool _isAnalyzing = false;

  Future<void> _analyzeImage(Uint8List bytes) async {
    final allowed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar foto para análise?'),
        content: const Text(
          'Se você continuar, sua foto será enviada ao serviço '
          'do EcoLens e ao provedor de IA (Google Gemini). '
          'A imagem pode conter informações ou metadados pessoais. '
          'Não envie fotos com pessoas ou dados sensíveis. '
          'A análise pode errar, especialmente em espécies perigosas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Aceitar e analisar'),
          ),
        ],
      ),
    );

    if (allowed != true || !mounted) return;

    setState(() => _isAnalyzing = true);
    try {
      final result = await AiService().suggestSpecies(bytes);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => _suggestionDialog(context, result),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is FormatException
          ? error.message
          : 'Não foi possível analisar a foto. '
              'Verifique a conexão e a configuração da IA.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Widget _suggestionDialog(
    BuildContext context,
    AiIdentificationResult result,
  ) {
    final speciesName = [
      result.commonName,
      result.scientificName,
    ].whereType<String>().join(' · ');

    return AlertDialog(
      title: Text(
        result.identified ? 'Sugestão da IA (não confirmada)' : 'Análise inconclusiva',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.identified) ...[
              Text(speciesName),
              const SizedBox(height: 12),
            ],
            Text(result.explanation),
            const SizedBox(height: 12),
            const Text(
              'Não utilize esta sugestão para avaliar toxicidade, '
              'decidir se um animal é seguro ou orientar primeiros '
              'socorros. Mantenha distância e consulte especialistas.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi'),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = SpeciesController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.initialSource == IdentificationSource.camera) {
        _controller.takePhoto();
      } else if (widget.initialSource == IdentificationSource.gallery) {
        _controller.pickFromGallery();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Identificar espécie')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            final imageBytes = _controller.imageBytes;
            final isLoading = _controller.isLoading || _isAnalyzing;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Vamos identificar?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),

                const Text(
                  'Fotografe um animal ou planta, '
                  'ou selecione uma imagem da galeria.',
                ),
                const SizedBox(height: 24),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    color: colors.surfaceContainerHighest,
                    child: imageBytes == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 65,
                              ),
                              SizedBox(height: 12),
                              Text('Nenhuma imagem selecionada'),
                            ],
                          )
                        : Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                            semanticLabel: 'Fotografia selecionada',
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                if (isLoading) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                ],

                if (_controller.errorMessage != null) ...[
                  Text(
                    _controller.errorMessage!,
                    style: TextStyle(color: colors.error),
                  ),
                  const SizedBox(height: 16),
                ],

                FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          _controller.takePhoto();
                        },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Abrir câmera'),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          _controller.pickFromGallery();
                        },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Escolher da galeria'),
                ),

                if (imageBytes != null) ...[
                  const SizedBox(height: 20),
                  if (_aiEnabled) ...[
                    OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => _analyzeImage(imageBytes),
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('Analisar com IA (experimental)'),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    const Text(
                      'Reconhecimento por IA em preparação. '
                      'Por enquanto, use a demonstração abaixo.',
                    ),
                    const SizedBox(height: 12),
                  ],

                  FilledButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const SpeciesDetailScreen(
                                 species: MockSpeciesRepository.jararaca,
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Ver resultado demonstrativo'),
                  ),

                  const SizedBox(height: 12),

                  TextButton.icon(
                    onPressed: isLoading ? null : _controller.clearImage,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover imagem'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
