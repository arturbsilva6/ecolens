import 'package:flutter/material.dart';

import '../../controllers/theme_controller.dart';

class AccessibilityScreen extends StatelessWidget {
  final ThemeController themeController;

  const AccessibilityScreen({super.key, required this.themeController});

  static String label(double? scale) => switch (scale) {
    null => 'Padrão do aparelho',
    1.15 => 'Grande',
    1.3 => 'Muito grande',
    _ => 'Personalizado',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acessibilidade')),
      body: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          final current = themeController.textScale;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Semantics(header: true, child: Text(
                'Tamanho do texto',
                style: Theme.of(context).textTheme.titleLarge,
              )),
              const SizedBox(height: 8),
              const Text(
                'Amplia o texto do EcoLens além do tamanho definido nas '
                'configurações do Android.',
              ),
              const SizedBox(height: 12),
              RadioGroup<double?>(
                groupValue: current,
                onChanged: themeController.changeTextScale,
                child: Column(
                  children: [
                    for (final scale in <double?>[
                      null,
                      ...ThemeController.textScales,
                    ])
                      RadioListTile<double?>(
                        value: scale,
                        title: Text(label(scale)),
                        subtitle: scale == null
                            ? const Text('Segue o ajuste do Android')
                            : Text('${(scale * 100).round()}% do padrão'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Exemplo: Jararaca (Bothrops jararaca) — espécie perigosa. '
                    'Em caso de picada, ligue 192.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Semantics(header: true, child: Text(
                'Leitor de tela',
                style: Theme.of(context).textTheme.titleLarge,
              )),
              const SizedBox(height: 8),
              const Text(
                'O EcoLens pode ser usado com o TalkBack (Configurações do '
                'Android > Acessibilidade > TalkBack). A revisão completa das '
                'telas com o leitor de tela ainda está em andamento.',
              ),
            ],
          );
        },
      ),
    );
  }
}
