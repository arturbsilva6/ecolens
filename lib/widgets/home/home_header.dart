import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Cabeçalho da Home com o símbolo simplificado do Conceito 2.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.onNotificationsTap,
    required this.onSettingsTap,
  });

  /// Sem notificações nesta versão: o sino só aparece se houver ação.
  final VoidCallback? onNotificationsTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          Image.asset(
            'assets/branding/ecolens_logo_loader.png',
            width: 42,
            height: 42,
            fit: BoxFit.contain,
            semanticLabel: 'Símbolo do EcoLens',
            errorBuilder: (_, _, _) =>
                Icon(Icons.eco_outlined, color: colors.primary, size: 36),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: 'Eco',
                    children: [
                      TextSpan(
                        text: 'Lens',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.accent
                              : AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Identificar e proteger',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onNotificationsTap != null)
            IconButton(
              tooltip: 'Notificações',
              onPressed: onNotificationsTap,
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'settings') onSettingsTap();
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 12),
                    Text('Configurações'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
