import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';

/// Ações de segurança da conta: senha, sessões e exclusão.
class AccountSecuritySection extends StatelessWidget {
  final AuthController controller;

  const AccountSecuritySection({super.key, required this.controller});

  Future<void> _changePassword(BuildContext context) async {
    final result = await showDialog<(String, String, String)>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (result == null) return;
    await controller.changePassword(result.$1, result.$2, result.$3);
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

  /// Exclusão em duas etapas: primeiro o que será perdido, depois a
  /// confirmação final digitando EXCLUIR.
  Future<void> _deleteAccount(BuildContext context) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteAccountWarning(email: controller.user?.email),
    );
    if (proceed != true || !context.mounted) return;
    final hasPassword = controller.user?.hasPassword ?? true;
    final confirmed = await showDialog<(bool, String)>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteAccountDialog(askPassword: hasPassword),
    );
    if (confirmed?.$1 == true) {
      await controller.deleteAccount(
        password: hasPassword ? confirmed!.$2 : null,
      );
    }
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
        if (controller.user?.hasPassword ?? true)
          OutlinedButton.icon(
            onPressed: busy ? null : () => _changePassword(context),
            icon: const Icon(Icons.password),
            label: const Text('Alterar senha'),
          )
        else
          Text(
            'Você entra com o Google, então não há senha do EcoLens para '
            'alterar.',
            style: Theme.of(context).textTheme.bodySmall,
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
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _hidden = true;

  @override
  void dispose() {
    _current.dispose();
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
              controller: _current,
              obscureText: _hidden,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Senha atual'),
            ),
            const SizedBox(height: 12),
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
          ).pop((_current.text, _password.text, _confirmation.text)),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

/// Primeiro aviso: mostra o que será apagado e o que continua no aparelho.
class _DeleteAccountWarning extends StatelessWidget {
  const _DeleteAccountWarning({this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget item(IconData icon, String text, {Color? color}) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, size: 40, color: colors.error),
      title: const Text('Excluir sua conta?', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email != null) Text('Conta: $email'),
            const SizedBox(height: 6),
            const Text('Serão apagados do servidor:'),
            item(
              Icons.person_off_outlined,
              'Sua conta e o acesso com ela',
              color: colors.error,
            ),
            item(
              Icons.photo_library_outlined,
              'Todos os seus avistamentos e as fotos enviadas',
              color: colors.error,
            ),
            item(
              Icons.badge_outlined,
              'Seu perfil público (nome e avatar)',
              color: colors.error,
            ),
            const SizedBox(height: 14),
            const Text('Continuam só neste aparelho:'),
            item(
              Icons.favorite_border,
              'Favoritos e histórico de '
              'identificações',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: colors.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continuar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Manter minha conta'),
        ),
      ],
    );
  }
}

/// Segundo aviso: última confirmação, só libera depois de digitar EXCLUIR.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.askPassword});

  /// Contas com senha confirmam com ela; contas do Google, com login recente.
  final bool askPassword;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const _word = 'EXCLUIR';
  final _typed = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _typed.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _typed.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready =
        _typed.text.trim().toUpperCase() == _word &&
        (!widget.askPassword || _password.text.isNotEmpty);
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      icon: Icon(Icons.delete_forever_rounded, size: 40, color: error),
      title: const Text('Tem certeza?', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta é a última etapa. A exclusão é definitiva: depois dela, '
              'não é possível recuperar a conta nem os avistamentos.',
              style: TextStyle(color: error, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text('Para confirmar, digite $_word:'),
            TextField(
              controller: _typed,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              decoration: const InputDecoration(hintText: _word),
            ),
            const SizedBox(height: 12),
            if (widget.askPassword)
              TextField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Sua senha'),
              )
            else
              Text(
                'Por segurança, se você entrou com o Google há mais de 15 '
                'minutos, será preciso entrar de novo antes de excluir.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop((false, '')),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: error),
          onPressed: ready
              ? () => Navigator.of(context).pop((true, _password.text))
              : null,
          child: const Text('Excluir definitivamente'),
        ),
      ],
    );
  }
}
