
import 'package:flutter/material.dart';

class QuickAccessSection extends StatelessWidget {
  final VoidCallback onVenomousTap;
  final VoidCallback onFirstAidTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onForumTap;

  const QuickAccessSection({
    super.key,
    required this.onVenomousTap,
    required this.onFirstAidTap,
    required this.onHistoryTap,
    required this.onForumTap,
  });

  @override
  Widget build(BuildContext context) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acessos rápidos',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),

        LayoutBuilder(
          builder: (context, constraints) {
            final oneColumn =
                constraints.maxWidth < 330 ||
                textScale > 1.3;

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
                    icon: Icons.history,
                    title: 'Meus Registros',
                    subtitle: 'Suas identificações',
                    onTap: onHistoryTap,
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
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const QuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 170,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  icon,
                  color: colors.onPrimaryContainer,
                  size: 25,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
              ),

              const SizedBox(height: 6),

              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
