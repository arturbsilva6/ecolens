import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';

enum _AccessForm { guest, login, register, requestReset }

class ProfileScreen extends StatefulWidget {
  final AuthController? controller;
  final String? returnLabel;
  const ProfileScreen({super.key, this.controller, this.returnLabel});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthController _auth;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  _AccessForm _mode = _AccessForm.guest;
  bool _hidden = true;
  bool _confirmationHidden = true;
  String? _lastName;
  bool _wasRecovering = false,
      _hadAccount = false,
      _readyToReturn = false,
      _returnScheduled = false;

  @override
  void initState() {
    super.initState();
    _auth = widget.controller ?? AuthController();
    _hadAccount = _auth.user != null;
    _email.text = _auth.pendingEmail ?? '';
    _changed();
    _auth.addListener(_changed);
    if (widget.controller == null) _auth.initialize();
  }

  void _changed() {
    if (!mounted) return;
    if (_wasRecovering && !_auth.recoveryRequired && !_auth.linkProblem) {
      _mode = _AccessForm.guest;
    }
    _wasRecovering = _auth.recoveryRequired;
    if (!_hadAccount &&
        _auth.user != null &&
        !_auth.recoveryRequired &&
        !_auth.linkProblem) {
      _readyToReturn = true;
    }
    _hadAccount = _auth.user != null;
    if (widget.returnLabel != null &&
        _readyToReturn &&
        !_returnScheduled &&
        !_auth.busy &&
        !_auth.recoveryRequired &&
        !_auth.linkProblem &&
        _auth.user != null) {
      _returnScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ModalRoute.of(context)?.isCurrent == true &&
            _auth.user != null &&
            !_auth.recoveryRequired &&
            !_auth.linkProblem) {
          Navigator.of(context).pop();
        }
      });
    }
    final name = _auth.user?.displayName;
    if (name != _lastName) {
      _name.text = name ?? '';
      _lastName = name;
    }
    // Apaga senhas após uma sessão válida; nunca as persiste.
    if (_auth.user != null && !_auth.recoveryRequired) {
      _password.clear();
      _confirmation.clear();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _auth.removeListener(_changed);
    if (widget.controller == null) _auth.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _name.dispose();
    super.dispose();
  }

  void _select(_AccessForm mode) {
    _form.currentState?.reset();
    _password.clear();
    _confirmation.clear();
    setState(() {
      _mode = mode;
    });
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false) || _auth.busy) return;
    if (_auth.recoveryRequired) {
      await _auth.resetPassword(_password.text, _confirmation.text);
    } else if (_mode == _AccessForm.requestReset) {
      await _auth.requestReset(_email.text);
    } else if (_auth.user != null) {
      await _auth.saveName(_name.text);
    } else if (_mode == _AccessForm.register) {
      await _auth.signUp(
        _email.text,
        _password.text,
        _confirmation.text,
        _name.text,
      );
    } else {
      await _auth.signIn(_email.text, _password.text);
    }
    if (!mounted) return;
    _password.clear();
    _confirmation.clear();
  }

  Widget _emailField() => TextFormField(
    key: const ValueKey('auth-email'),
    controller: _email,
    enabled: !_auth.busy,
    decoration: const InputDecoration(labelText: 'E-mail'),
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    autocorrect: false,
    autofillHints: const [AutofillHints.email],
    validator: (value) => AuthController.emailError(value ?? ''),
    onFieldSubmitted: (_) {
      if (_mode == _AccessForm.requestReset) _submit();
    },
  );

  Widget _nameField() => TextFormField(
    key: const ValueKey('auth-name'),
    controller: _name,
    enabled: !_auth.busy,
    decoration: const InputDecoration(labelText: 'Nome de exibição'),
    maxLength: 60,
    textCapitalization: TextCapitalization.words,
    textInputAction: TextInputAction.next,
    validator: (value) => AuthController.nameError(value ?? ''),
  );

  Widget _passwordField({bool confirmation = false}) => TextFormField(
    key: ValueKey(confirmation ? 'auth-confirmation' : 'auth-password'),
    controller: confirmation ? _confirmation : _password,
    enabled: !_auth.busy,
    obscureText: confirmation ? _confirmationHidden : _hidden,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: [
      (_mode == _AccessForm.register || _auth.recoveryRequired)
          ? AutofillHints.newPassword
          : AutofillHints.password,
    ],
    textInputAction: confirmation || _mode == _AccessForm.login
        ? TextInputAction.done
        : TextInputAction.next,
    decoration: InputDecoration(
      labelText: confirmation
          ? 'Confirmar senha'
          : _auth.recoveryRequired
          ? 'Nova senha'
          : 'Senha',
      suffixIcon: IconButton(
        tooltip: (confirmation ? _confirmationHidden : _hidden)
            ? 'Mostrar ${confirmation ? 'confirmação de senha' : 'senha'}'
            : 'Ocultar ${confirmation ? 'confirmação de senha' : 'senha'}',
        onPressed: () {
          setState(() {
            if (confirmation) {
              _confirmationHidden = !_confirmationHidden;
            } else {
              _hidden = !_hidden;
            }
          });
        },
        icon: Icon(
          (confirmation ? _confirmationHidden : _hidden)
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator: (value) {
      if (confirmation) {
        return value == _password.text ? null : 'As senhas não coincidem.';
      }
      return _mode == _AccessForm.login && !_auth.recoveryRequired
          ? (value?.isNotEmpty ?? false)
                ? null
                : 'Informe sua senha.'
          : AuthController.passwordError(value ?? '');
    },
    onFieldSubmitted: (_) {
      if (confirmation || _mode == _AccessForm.login) _submit();
    },
  );

  Widget _submitButton(String label) =>
      FilledButton(onPressed: _auth.busy ? null : _submit, child: Text(label));

  Widget _resendConfirmation() => ValueListenableBuilder<TextEditingValue>(
    valueListenable: _email,
    builder: (context, value, child) {
      final recipient = value.text.trim();
      final valid = AuthController.emailError(recipient) == null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            valid ? 'Destinatário da confirmação: $recipient' : 'Informe um e-mail válido no formulário para reenviar a confirmação.',
          ),
          OutlinedButton(
            onPressed: _auth.canResend && valid
                ? () => _auth.resend(recipient)
                : null,
            child: const Text('Reenviar confirmação'),
          ),
          Text(_auth.resendHint),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final guest = _auth.user == null;
    final requestReset =
        _mode == _AccessForm.requestReset && !_auth.recoveryRequired;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.returnLabel != null)
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(widget.returnLabel!),
                      ),
                    Text(
                      _auth.recoveryRequired
                          ? 'Definir nova senha'
                          : requestReset
                          ? 'Recuperar senha'
                          : guest
                          ? 'Acesse sua conta'
                          : 'Sua conta',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Favoritos e histórico são dados deste dispositivo e não são sincronizados com sua conta.',
                    ),
                    if (_auth.busy)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: 'Processando acesso',
                          ),
                        ),
                      ),
                    if (_auth.message != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(_auth.message!),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (_auth.canRetryCallback)
                      OutlinedButton(
                        onPressed: _auth.busy ? null : _auth.retryCallback,
                        child: const Text('Tentar novamente com este link'),
                      ),
                    if (_auth.linkProblem && !_auth.recoveryRequired)
                      TextButton(
                        onPressed: _auth.busy
                            ? null
                            : () => _select(_AccessForm.requestReset),
                        child: const Text('Solicitar novo link de recuperação'),
                      ),
                    if (_auth.recoveryRequired) ...[
                      _passwordField(),
                      const SizedBox(height: 12),
                      _passwordField(confirmation: true),
                      const SizedBox(height: 16),
                      _submitButton('Salvar nova senha'),
                      TextButton(
                        onPressed: _auth.busy
                            ? null
                            : () {
                                _auth.requestNewRecoveryLink();
                                _select(_AccessForm.requestReset);
                              },
                        child: const Text('Solicitar novo link de recuperação'),
                      ),
                    ] else if (requestReset) ...[
                      const Text(
                        'Informe seu e-mail para receber um link de recuperação.',
                      ),
                      _emailField(),
                      const SizedBox(height: 16),
                      _submitButton('Enviar recuperação'),
                      TextButton(
                        onPressed: _auth.busy
                            ? null
                            : () => _select(_AccessForm.login),
                        child: const Text('Voltar para entrar'),
                      ),
                    ] else if (!guest) ...[
                      SelectableText(_auth.user!.email),
                      const SizedBox(height: 16),
                      _nameField(),
                      _submitButton('Salvar nome'),
                      OutlinedButton(
                        onPressed: _auth.busy ? null : _auth.signOut,
                        child: const Text('Sair da conta'),
                      ),
                    ] else ...[
                      if (_mode == _AccessForm.guest) ...[
                        FilledButton(
                          onPressed: _auth.busy
                              ? null
                              : () => _select(_AccessForm.login),
                          child: const Text('Entrar com e-mail'),
                        ),
                        OutlinedButton(
                          onPressed: _auth.busy
                              ? null
                              : () => _select(_AccessForm.register),
                          child: const Text('Criar conta'),
                        ),
                      ] else ...[
                        if (_mode == _AccessForm.register) _nameField(),
                        _emailField(),
                        const SizedBox(height: 12),
                        _passwordField(),
                        if (_mode == _AccessForm.register) ...[
                          const SizedBox(height: 12),
                          _passwordField(confirmation: true),
                        ],
                        const SizedBox(height: 16),
                        _submitButton(
                          _mode == _AccessForm.register
                              ? 'Cadastrar'
                              : 'Entrar',
                        ),
                        TextButton(
                          onPressed: _auth.busy
                              ? null
                              : () => _select(
                                  _mode == _AccessForm.register
                                      ? _AccessForm.login
                                      : _AccessForm.register,
                                ),
                          child: Text(
                            _mode == _AccessForm.register
                                ? 'Já tenho conta'
                                : 'Criar conta',
                          ),
                        ),
                      ],
                      OutlinedButton(
                        onPressed: _auth.busy ? null : _auth.google,
                        child: const Text('Entrar com Google'),
                      ),
                      TextButton(
                        onPressed: _auth.busy
                            ? null
                            : () => _select(_AccessForm.requestReset),
                        child: const Text('Esqueci minha senha'),
                      ),
                      if (_mode != _AccessForm.guest ||
                          _auth.pendingEmail != null) ...[
                        if (_mode == _AccessForm.guest) _emailField(),
                        _resendConfirmation(),
                      ],
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(
                        guest ? 'Continuar sem conta' : 'Voltar ao início',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
