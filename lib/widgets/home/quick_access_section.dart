import 'package:flutter/material.dart';

/// Atalhos compactos da Home: ícones redondos com legenda curta.
/// A Comunidade fica só na barra inferior, para não repetir destinos.
class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({
    super.key,
    required this.onVenomousTap,
    required this.onFirstAidTap,
    required this.onHistoryTap,
    required this.onFavoritesTap,
  });

  final VoidCallback onVenomousTap;
  final VoidCallback onFirstAidTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onFavoritesTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      QuickAccessCard(
        icon: Icons.favorite_border_rounded,
        title: 'Favoritos',
        onTap: onFavoritesTap,
      ),
      QuickAccessCard(
        icon: Icons.history_rounded,
        title: 'Histórico',
        onTap: onHistoryTap,
      ),
      QuickAccessCard(
        icon: Icons.warning_amber_rounded,
        title: 'Perigosas',
        onTap: onVenomousTap,
      ),
      QuickAccessCard(
        icon: Icons.medical_services_outlined,
        title: 'Primeiros socorros',
        onTap: onFirstAidTap,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Em tela estreita ou texto grande, os atalhos quebram em duas linhas.
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final perRow = constraints.maxWidth < 340 || scale > 1.3 ? 2 : 4;
        final width = constraints.maxWidth / perRow;
        return Wrap(
          runSpacing: 12,
          children: [
            for (final item in items) SizedBox(width: width, child: item),
          ],
        );
      },
    );
  }
}

class QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const QuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.onPrimaryContainer, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
