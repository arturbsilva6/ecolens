
import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  const HomeHeader({
    super.key,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      child: Row(
        children: [
          // Logo provisório
          CircleAvatar(
            radius: 26,
            backgroundColor: colors.primaryContainer,
            child: Icon(
              Icons.eco,
              color: colors.primary,
              size: 30,
            ),
          ),

          const SizedBox(width: 12),

          // Nome e slogan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EcoLens',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  'Identificar e proteger',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Notificações
          IconButton(
            tooltip: 'Notificações',
            onPressed: onNotificationsTap,
            icon: const Icon(
              Icons.notifications_outlined,
            ),
          ),

          // Perfil
          IconButton(
            tooltip: 'Meu perfil',
            onPressed: onProfileTap,
            icon: const Icon(
              Icons.account_circle_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
