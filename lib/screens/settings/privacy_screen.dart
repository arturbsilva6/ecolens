import 'package:flutter/material.dart';

import '../../data/favorites_repository.dart';
import '../../data/identification_history_repository.dart';
import '../../widgets/auth/account_navigation_scope.dart';
import 'offline_package_screen.dart';
import 'privacy_policy_screen.dart';

class PrivacyScreen extends StatefulWidget {
  final IdentificationHistoryRepository? historyRepository;
  final FavoritesRepository? favoritesRepository;

  const PrivacyScreen({
    super.key,
    this.historyRepository,
    this.favoritesRepository,
  });

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _busy = false;

  Future<void> _clear({
    required String title,
    required String content,
    required String done,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    var message = done;
    try {
      await action();
    } catch (_) {
      message = 'Não foi possível apagar agora. Tente novamente.';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e dados')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _Header('Permissões', style: titleStyle),
          const _Info(
            icon: Icons.photo_camera_outlined,
            title: 'Câmera',
            text:
                'Usada só quando você toca em "Abrir câmera". A foto é tirada '
                'pelo app de câmera do Android e fica no aparelho até você '
                'decidir analisar ou compartilhar.',
          ),
          const _Info(
            icon: Icons.photo_library_outlined,
            title: 'Fotos da galeria',
            text:
                'O seletor do Android entrega ao EcoLens apenas a foto que '
                'você escolher. O app não lê o restante da galeria.',
          ),
          const _Info(
            icon: Icons.location_off_outlined,
            title: 'Localização',
            text:
                'O EcoLens não usa o GPS. Nos avistamentos, você escolhe o '
                'município, e as fotos são enviadas sem metadados.',
          ),
          const _Info(
            icon: Icons.notifications_off_outlined,
            title: 'Notificações',
            text: 'O EcoLens não envia notificações nesta versão.',
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Para revisar ou retirar permissões: Configurações do Android > '
              'Apps > EcoLens > Permissões.',
            ),
          ),
          const Divider(),
          _Header('Dados neste aparelho', style: titleStyle),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Apagar histórico de identificações'),
            subtitle: const Text('Remove as análises salvas neste aparelho'),
            enabled: !_busy,
            onTap: () => _clear(
              title: 'Apagar o histórico?',
              content:
                  'As análises salvas neste aparelho serão removidas. '
                  'Não é possível desfazer.',
              done: 'Histórico apagado.',
              action: () =>
                  (widget.historyRepository ??
                          IdentificationHistoryRepository())
                      .clear(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Apagar favoritos'),
            subtitle: const Text('Desmarca todas as espécies favoritas'),
            enabled: !_busy,
            onTap: () => _clear(
              title: 'Apagar os favoritos?',
              content: 'Todas as espécies serão desmarcadas neste aparelho.',
              done: 'Favoritos apagados.',
              action: () =>
                  (widget.favoritesRepository ?? FavoritesRepository()).clear(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: const Text('Fotos do pacote offline'),
            subtitle: const Text('Ver espaço usado ou remover as fotos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const OfflinePackageScreen(),
              ),
            ),
          ),
          const Divider(),
          _Header('Dados no servidor', style: titleStyle),
          const _Info(
            icon: Icons.cloud_outlined,
            title: 'O que fica guardado',
            text:
                'Conta (e-mail e nome) e avistamentos que você registrar. '
                'Fotos enviadas para identificação por IA não são guardadas.',
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('Conta e exclusão de dados'),
            subtitle: const Text(
              'Alterar senha, sair de todos os aparelhos ou excluir a conta',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AccountNavigationScope.maybeOf(context)?.openAccount(),
          ),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('Política de privacidade'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PrivacyPolicyScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _Header(this.text, {this.style});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Semantics(header: true, child: Text(text, style: style)),
  );
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _Info({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) =>
      ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(text));
}
