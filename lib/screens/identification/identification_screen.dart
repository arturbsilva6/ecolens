import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../controllers/species_controller.dart';
import '../../core/theme/app_colors.dart';
import '../species/species_detail_screen.dart';
import '../../data/mock_species_repository.dart';
import '../../data/supabase_species_repository.dart';
import '../../models/species_model.dart';
import '../../utils/ai_species_matcher.dart';
import '../../services/ai_service.dart';
import '../../utils/ai_analysis_error_message.dart';
import '../../widgets/camera_notice.dart';
import 'identification_result_screen.dart';

enum IdentificationSource { camera, gallery }

class IdentificationScreen extends StatefulWidget {
  final IdentificationSource? initialSource;
  final SpeciesController? controller;

  const IdentificationScreen({super.key, this.initialSource, this.controller});

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
  late final bool _ownsController;
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

      // Só relaciona a sugestão com fichas publicadas no catálogo.
      // Falhas na consulta não ocultam o resultado experimental da IA.
      SpeciesModel? matchedSpecies;
      var catalogUnavailable = false;
      if (result.identified) {
        try {
          final publishedSpecies = await SupabaseSpeciesRepository()
              .fetchPublishedSpecies();
          matchedSpecies = matchAiSuggestionToPublishedSpecies(
            result,
            publishedSpecies,
          );
        } catch (_) {
          catalogUnavailable = true;
        }
      }

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      // Uma tela dedicada mantém a foto e a sugestão visíveis. Ao pedir nova
      // identificação, a imagem anterior é removida somente quando voltar.
      final startAgain = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (context) => IdentificationResultScreen(
            imageBytes: bytes,
            result: result,
            matchedSpecies: matchedSpecies,
            catalogUnavailable: catalogUnavailable,
          ),
        ),
      );

      if (!mounted) return;
      if (startAgain == true) {
        _controller.clearImage();
      }
    } catch (error) {
      if (!mounted) return;
      final message = aiAnalysisErrorMessage(error);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  void initState() {
    super.initState();

    _ownsController = widget.controller == null;
    _controller = widget.controller ?? SpeciesController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.initialSource == IdentificationSource.camera) {
        _openCamera();
      } else if (widget.initialSource == IdentificationSource.gallery) {
        _controller.pickFromGallery();
      }
    });
  }

  Future<void> _openCamera() async {
    if (!await const CameraNotice().confirm(context) || !mounted) return;
    await _controller.takePhoto();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identificar espécie'),
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            final imageBytes = _controller.imageBytes;
            final isLoading = _controller.isLoading || _isAnalyzing;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'NATUREZA + TECNOLOGIA',
                        softWrap: true,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Observe. Fotografe. Descubra.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use a câmera ou escolha uma foto da galeria para '
                  'conhecer mais sobre fauna e flora.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _IdentificationPreview(imageBytes: imageBytes),
                const SizedBox(height: 18),
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
                  onPressed: isLoading ? null : _openCamera,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Abrir câmera'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _controller.pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Escolher da galeria'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onSurface,
                    backgroundColor: colors.surface,
                    minimumSize: const Size.fromHeight(54),
                    side: BorderSide(color: colors.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (imageBytes != null) ...[
                  const SizedBox(height: 22),
                  Text(
                    'Foto pronta para explorar',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                    Text(
                      'Reconhecimento por IA em preparação. '
                      'Por enquanto, use a demonstração abaixo.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
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
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: isLoading ? null : _controller.clearImage,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover imagem'),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.health_and_safety_outlined,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Fotografe a uma distância segura. Não toque '
                          'em espécies desconhecidas nem use uma sugestão '
                          'automática como confirmação de segurança.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
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

/// A câmera é aberta pelo seletor nativo; a área mostra a foto somente
/// depois da captura ou escolha na galeria (não é uma câmera ao vivo).
class _IdentificationPreview extends StatelessWidget {
  final Uint8List? imageBytes;

  const _IdentificationPreview({required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;
    final compact =
        MediaQuery.sizeOf(context).width < 400 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: AspectRatio(
        aspectRatio: 1.1,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF081C16)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                Image.memory(
                  imageBytes!,
                  fit: BoxFit.cover,
                  semanticLabel: 'Fotografia selecionada',
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              if (hasImage)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.13),
                  child: const SizedBox.expand(),
                ),
              const Center(
                child: SizedBox(
                  width: 204,
                  height: 204,
                  child: CustomPaint(painter: _ScanCornersPainter()),
                ),
              ),
              if (!hasImage)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 12 : 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          color: AppColors.accent,
                          size: compact ? 36 : 48,
                        ),
                        SizedBox(height: compact ? 8 : 16),
                        Text(
                          'Sua foto aparecerá aqui',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Abra a câmera ou escolha uma imagem.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFFE0EFE6)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 16,
                left: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: Text(
                      hasImage ? 'FOTO SELECIONADA' : 'PRÉ-VISUALIZAÇÃO',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanCornersPainter extends CustomPainter {
  const _ScanCornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const corner = 30.0;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, corner)
      ..lineTo(0, 0)
      ..lineTo(corner, 0)
      ..moveTo(w - corner, 0)
      ..lineTo(w, 0)
      ..lineTo(w, corner)
      ..moveTo(0, h - corner)
      ..lineTo(0, h)
      ..lineTo(corner, h)
      ..moveTo(w - corner, h)
      ..lineTo(w, h)
      ..lineTo(w, h - corner);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanCornersPainter oldDelegate) => false;
}
