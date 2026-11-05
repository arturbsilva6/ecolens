import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Hero do Conceito 2; somente a apresentação muda, os callbacks são os mesmos.
class IdentificationBanner extends StatelessWidget {
  const IdentificationBanner({
    super.key,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Evita overflow dos botões em celulares estreitos ou com texto ampliado.
        final stacked = constraints.maxWidth < 440 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.15;

        final cameraButton = FilledButton.icon(
          onPressed: onCameraTap,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Abrir câmera', textAlign: TextAlign.center),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.primary,
            minimumSize: const Size(0, 54),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
        final galleryButton = OutlinedButton.icon(
          onPressed: onGalleryTap,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Enviar foto', textAlign: TextAlign.center),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: Colors.white),
            minimumSize: const Size(0, 54),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            image: const DecorationImage(
              image: AssetImage('assets/images/sagui_banner_home.jpg'),
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.98),
                  AppColors.primary.withValues(alpha: 0.84),
                  AppColors.primary.withValues(alpha: 0.48),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.eco_outlined,
                        color: AppColors.accent, size: 19),
                    const SizedBox(width: 6),
                    Text(
                      'NATUREZA + TECNOLOGIA',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Olá! Explore e proteja a biodiversidade.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Identifique fauna e flora com segurança usando uma foto.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                if (stacked)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cameraButton,
                      const SizedBox(height: 10),
                      galleryButton,
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(child: cameraButton),
                      const SizedBox(width: 10),
                      Expanded(child: galleryButton),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
