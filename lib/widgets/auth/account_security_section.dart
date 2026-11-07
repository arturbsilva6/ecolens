import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';

/// Ações de segurança da conta: senha, sessões e exclusão.
class AccountSecuritySection extends StatelessWidget {
  final AuthController controller;

  const AccountSecuritySection({super.key, required this.controller});

  Future<void> _changePassword(BuildContext context) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (result == null) return;
    await controller.changePassword(result.$1, result.$2);
  }

  Future<void> _signOutEverywhere(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair de todos os aparelhos?'),
        content: const Text(
          'A sessão será encerrada neste e em qualquer outro aparelho em que '
          'você tenha entrado. Favoritos e histórico continuam em cada aparelho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair de todos'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.signOutEverywhere();
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed == true) await controller.deleteAccount();
  }

  @override
  Widget build(BuildContext context) {
    final busy = controller.busy;
    final error = Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          'Segurança da conta',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: busy ? null : () => _changePassword(context),
          icon: const Icon(Icons.password),
          label: const Text('Alterar senha'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: busy ? null : () => _signOutEverywhere(context),
          icon: const Icon(Icons.devices_other),
          label: const Text('Sair de todos os aparelhos'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: busy ? null : () => _deleteAccount(context),
          style: TextButton.styleFrom(foregroundColor: error),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Excluir minha conta'),
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _hidden = true;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alterar senha'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _password,
              obscureText: _hidden,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Nova senha',
                helperText: 'De 8 a 128 caracteres',
                suffixIcon: IconButton(
                  tooltip: _hidden ? 'Mostrar senha' : 'Ocultar senha',
                  onPressed: () => setState(() => _hidden = !_hidden),
                  icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmation,
              obscureText: _hidden,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                labelText: 'Confirmar nova senha',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop((_password.text, _confirmation.text)),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const _word = 'EXCLUIR';
  final _typed = TextEditingController();

  @override
  void initState() {
    super.initState();
    _typed.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _typed.text.trim().toUpperCase() == _word;
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      title: const Text('Excluir sua conta?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sua conta, seus avistamentos e as fotos enviadas serão apagados '
              'do servidor. Não é possível desfazer. Favoritos e histórico '
              'continuam só neste aparelho.',
            ),
            const SizedBox(height: 16),
            const Text('Para confirmar, digite $_word:'),
            TextField(
              controller: _typed,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              decoration: const InputDecoration(hintText: _word),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: error),
          onPressed: ready ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Excluir conta'),
        ),
      ],
    );
  }
}
