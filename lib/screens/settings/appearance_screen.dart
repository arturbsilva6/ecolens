
import 'package:flutter/material.dart';

import '../../controllers/theme_controller.dart';

class AppearanceScreen extends StatelessWidget {
  final ThemeController themeController;

  const AppearanceScreen({
    super.key,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aparência'),
      ),
      body: ListenableBuilder(
        listenable: themeController,
        builder: (context, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Tema do aplicativo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Escolha como o EcoLens será exibido.',
              ),
              const SizedBox(height: 20),

              _themeOption(
                context: context,
                title: 'Automático',
                subtitle: 'Seguir o tema do dispositivo',
                icon: Icons.brightness_auto_outlined,
                mode: ThemeMode.system,
              ),

              _themeOption(
                context: context,
                title: 'Claro',
                subtitle: 'Utilizar o tema claro',
                icon: Icons.light_mode_outlined,
                mode: ThemeMode.light,
              ),

              _themeOption(
                context: context,
                title: 'Escuro',
                subtitle: 'Utilizar o tema escuro',
                icon: Icons.dark_mode_outlined,
                mode: ThemeMode.dark,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _themeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
  }) {
    final selected = themeController.themeMode == mode;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        selected: selected,
        trailing: Icon(
          selected
              ? Icons.check_circle
              : Icons.circle_outlined,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
        onTap: () {
          themeController.changeTheme(mode);
        },
      ),
    );
  }
}
