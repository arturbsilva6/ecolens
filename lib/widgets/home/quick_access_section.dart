import 'package:flutter/material.dart';

import '../ecolens_card.dart';

/// Preserva todas as ações de acesso rápido ao atualizar a apresentação.
class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({
    super.key,
    required this.onVenomousTap,
    required this.onFirstAidTap,
    required this.onHistoryTap,
    required this.onForumTap,
    required this.onFavoritesTap,
  });

  final VoidCallback onVenomousTap;
  final VoidCallback onFirstAidTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onForumTap;
  final VoidCallback onFavoritesTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acessos rápidos',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final oneColumn = constraints.maxWidth < 340 || textScale > 1.3;
            final cardWidth = oneColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: QuickAccessCard(
                    icon: Icons.favorite_border_rounded,
                    title: 'Favoritos',
                    subtitle: 'Espécies salvas no dispositivo',
                    onTap: onFavoritesTap,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: QuickAccessCard(
                    icon: Icons.history_rounded,
                    title: 'Meus Registros',
                    subtitle: 'Suas identificações',
                    onTap: onHistoryTap,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: QuickAccessCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'Animais Peçonhentos',
                    subtitle: 'Saiba como agir',
                    onTap: onVenomousTap,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: QuickAccessCard(
                    icon: Icons.medical_services_outlined,
                    title: 'Primeiros Socorros',
                    subtitle: 'Dicas e orientações',
                    onTap: onFirstAidTap,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: QuickAccessCard(
                    icon: Icons.forum_outlined,
                    title: 'Fórum Local',
                    subtitle: 'Compartilhe descobertas',
                    onTap: onForumTap,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class QuickAccessCard extends StatelessWidget {
  const QuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return EcoLensCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: colors.primaryContainer,
              child: Icon(icon, color: colors.onPrimaryContainer, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.arrow_forward_rounded,
                  color: colors.primary, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
