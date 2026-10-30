import 'package:flutter/material.dart';

import '../../controllers/species_controller.dart';

enum IdentificationSource { camera, gallery }

class IdentificationScreen extends StatefulWidget {
  final IdentificationSource? initialSource;

  const IdentificationScreen({super.key, this.initialSource});

  @override
  State<IdentificationScreen> createState() => _IdentificationScreenState();
}

class _IdentificationScreenState extends State<IdentificationScreen> {
  late final SpeciesController _controller;

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
            final isLoading = _controller.isLoading;

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
                  const SizedBox(height: 12),

                  TextButton.icon(
                    onPressed: isLoading ? null : _controller.clearImage,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover imagem'),
                  ),
                ],

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: colors.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Fotografe a espécie com '
                            'boa iluminação e foco. '
                            'Não se aproxime de animais '
                            'desconhecidos ou perigosos.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
