import 'package:flutter/material.dart';

import '../../controllers/theme_controller.dart';
import '../../widgets/auth/account_navigation_scope.dart';
import 'about_screen.dart';
import 'accessibility_screen.dart';
import 'appearance_screen.dart';
import 'offline_package_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeController themeController;

  const SettingsScreen({super.key, required this.themeController});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final account = AccountNavigationScope.maybeOf(context);
    final items = <Widget>[
      _item(
        icon: Icons.palette_outlined,
        title: 'Aparência',
        subtitle: 'Tema claro, escuro ou automático',
        onTap: () =>
            _open(context, AppearanceScreen(themeController: themeController)),
      ),
      _item(
        icon: Icons.accessibility_new,
        title: 'Acessibilidade',
        subtitle: 'Tamanho do texto e leitor de tela',
        onTap: () => _open(
          context,
          AccessibilityScreen(themeController: themeController),
        ),
      ),
      _item(
        icon: Icons.download_for_offline_outlined,
        title: 'Uso offline',
        subtitle: 'Fichas e fotos sem internet',
        onTap: () => _open(context, const OfflinePackageScreen()),
      ),
      if (account != null)
        _item(
          icon: Icons.manage_accounts_outlined,
          title: 'Conta e segurança',
          subtitle: 'Senha, sessões e exclusão da conta',
          onTap: () => account.openAccount(),
        ),
      _item(
        icon: Icons.lock_outline,
        title: 'Privacidade e dados',
        subtitle: 'Permissões, dados no aparelho e política',
        onTap: () => _open(context, const PrivacyScreen()),
      ),
      _item(
        icon: Icons.info_outline,
        title: 'Sobre o EcoLens',
        subtitle: 'Versão, fontes e licenças',
        onTap: () => _open(context, const AboutScreen()),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView.separated(
        itemCount: items.length,
        itemBuilder: (context, index) => items[index],
        separatorBuilder: (context, index) => const Divider(height: 1),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
