import 'package:flutter/material.dart';

import 'privacy_policy_screen.dart';

class AboutScreen extends StatelessWidget {
  /// Manter igual ao `version` do pubspec.yaml.
  static const version = '1.0.0';

  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o EcoLens')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.eco,
                  size: 32,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EcoLens', style: theme.textTheme.headlineSmall),
                    Text('Versão $version'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Aplicativo de reconhecimento e prevenção de acidentes com fauna e '
            'flora, voltado a São Roque (SP) e municípios vizinhos. Reúne fichas '
            'de espécies revisadas, orientações de segurança, contatos de '
            'emergência e consulta sem internet.',
          ),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'O EcoLens não substitui atendimento médico. Em caso de picada, '
                'mordida ou intoxicação, ligue 192 (SAMU) ou 0800 722 6001 '
                '(Disque-Intoxicação). A identificação por IA é apenas uma '
                'sugestão e pode errar.',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.school_outlined),
            title: Text('Trabalho de Graduação'),
            subtitle: Text(
              'CST em Sistemas para Internet — Fatec São Roque\n'
              'Autores: Artur Barbosa e João Messias\n'
              'Orientador: Prof. Sandro Amancio de Sá',
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.menu_book_outlined),
            title: Text('Fontes das fichas'),
            subtitle: Text(
              'Instituto Butantan, Sinitox/Fiocruz, Ibama e outras fontes '
              'oficiais indicadas em cada ficha.',
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.photo_outlined),
            title: Text('Fotos das espécies'),
            subtitle: Text(
              'Imagens com licença livre (CC0, CC BY, CC BY-SA ou domínio '
              'público). Autoria e licença aparecem em cada ficha.',
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.policy_outlined),
            title: const Text('Política de privacidade'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PrivacyPolicyScreen(),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licenças de software'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'EcoLens',
              applicationVersion: version,
            ),
          ),
        ],
      ),
    );
  }
}
