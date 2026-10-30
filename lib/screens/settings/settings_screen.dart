
import 'package:flutter/material.dart';

import '../../controllers/theme_controller.dart';
import 'appearance_screen.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeController themeController;

  const SettingsScreen({
    super.key,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Aparência'),
            subtitle: const Text('Tema e personalização'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => AppearanceScreen(
                    themeController: themeController,
                  ),
                ),
              );
            },
          ),

          const Divider(height: 1),

          ListTile(
            leading: const Icon(
              Icons.notifications_outlined,
            ),
            title: const Text('Notificações'),
            subtitle: const Text('Preferências de avisos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showComingSoon(context);
            },
          ),

          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Privacidade'),
            subtitle: const Text('Dados e permissões'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showComingSoon(context);
            },
          ),

          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.accessibility_new),
            title: const Text('Acessibilidade'),
            subtitle: const Text('Preferências de acessibilidade'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showComingSoon(context);
            },
          ),

          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre o EcoLens'),
            subtitle: const Text('Informações do aplicativo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showComingSoon(context);
            },
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
      ),
    );
  }
}
