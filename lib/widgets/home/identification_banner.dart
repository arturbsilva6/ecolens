import 'package:flutter/material.dart';
import '../custom_button.dart';

class IdentificationBanner extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  const IdentificationBanner({
    super.key,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: const DecorationImage(
          image: AssetImage('assets/images/sagui_banner_home.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.black.withValues(alpha: 0.60),
              Colors.black.withValues(alpha: 0.25),
              Colors.transparent,
            ],
          ),
        ),

        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.eco_outlined, color: Colors.white, size: 24),
            const SizedBox(height: 12),
            const SizedBox(
              width: 230,
              child: Text(
                'Identifique fauna e\nflora com segurança',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: 230,
              child: Text(
                'Conhecimento hoje para um amanhã mais seguro.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: EcoLensButton(
                    onPressed: onCameraTap,
                    icon: Icons.camera_alt_outlined,
                    label: 'Abrir câmera',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: EcoLensButton(
                    onPressed: onGalleryTap,
                    icon: Icons.image_outlined,
                    label: 'Enviar foto',
                    tonal: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
