import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../models/user_model.dart';
import '../services/password_breach_checker.dart';
import '../core/app_config.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository repository;
  final DateTime Function() _now;
  StreamSubscription<AccountEvent>? _subscription;
  Timer? _resendTimer;
  bool _disposed = false;
  Future<void>? _initializing;
  bool initialized = false;
  bool busy = false;
  UserModel? user;
  String? message;

  /// Título do aviso de confirmação. Quando preenchido, a tela mostra
  /// [message] num diálogo central com OK em vez de texto solto.
  String? noticeTitle;
  String? pendingEmail;
  bool recoveryRequired = false;
  bool linkProblem = false;
  bool canRetryCallback = false;
  int callbackRevision = 0;
  int _resends = 0;
  DateTime? _resendAfter;

  AuthController({
    AuthRepository? repository,
    DateTime Function()? now,
    Future<bool> Function(String password)? isLeakedPassword,
  }) : repository = repository ?? SupabaseAuthRepository(),
       _now = now ?? DateTime.now,
       // Nos testes automáticos, nada sai para a internet.
       _isLeakedPassword =
           isLeakedPassword ??
           (AppConfig.isTesting
               ? ((_) async => false)
               : PasswordBreachChecker().isLeaked);

  /// Confere a senha nova na base de senhas vazadas (Have I Been Pwned).
  final Future<bool> Function(String password) _isLeakedPassword;

  Future<void> _rejectLeaked(String password) async {
    if (await _isLeakedPassword(password)) {
      throw const AuthFailure(
        'Esta senha já apareceu em vazamentos de dados na internet e pode ser '
        'adivinhada. Escolha outra.',
      );
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    _subscription ??= repository.changes.listen(
      _event,
      onError: (Object _, StackTrace _) {
        message = 'Serviço de acesso indisponível. Tente novamente.';
        _notify();
      },
    );
    try {
      final restored = await repository.connect();
      if (_disposed) return;
      user = restored;
    } catch (error) {
      message = authErrorMessage(error);
    } finally {
      initialized = true;
      _notify();
    }
  }

  /// Re-read SDK state before returning to an account-required action.
  /// Does not reset PKCE callbacks or discard the caller's draft.
  Future<void> synchronizeSession() async {
    try {
      final restored = await repository.connect();
      if (_disposed) return;
      user = restored;
    } catch (error) {
      if (_disposed) return;
      message = authErrorMessage(error);
    }
    _notify();
  }

  void _event(AccountEvent event) {
    if (_disposed) return;
    switch (event.type) {
      case AccountEventType.session:
        final arrived = initialized && !busy && user == null;
        user = event.user;
        if (user != null && arrived) {
          // Volta do login com Google (ou outro retorno pelo navegador).
          linkProblem = false;
          canRetryCallback = false;
          pendingEmail = null;
          noticeTitle = 'Login realizado';
          message = 'Sua conta foi conectada com sucesso.';
        } else if (user != null) {
          linkProblem = false;
          canRetryCallback = false;
          pendingEmail = null;
          // Não apaga o aviso de sucesso que ainda espera o OK.
          if (noticeTitle == null) message = null;
        }
      case AccountEventType.signedOut:
        canRetryCallback = false;
        user = null;
        recoveryRequired = false;
      case AccountEventType.recovery:
        if (event.user == null) return;
        user = event.user;
        if (!recoveryRequired) callbackRevision++;
        recoveryRequired = true;
        linkProblem = false;
        canRetryCallback = false;
        noticeTitle = null;
        message = 'Link validado. Defina sua nova senha.';
      case AccountEventType.callbackError:
        recoveryRequired = false;
        linkProblem = true;
        canRetryCallback = event.canRetryCallback;
        message =
            event.message ??
            'Link inválido ou expirado. Solicite um novo link.';
        callbackRevision++;
        noticeTitle = null;
      case AccountEventType.serviceError:
        noticeTitle = null;
        message =
            event.message ?? 'Serviço de acesso indisponível. Tente novamente.';
    }
    _notify();
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (busy || _disposed) return;
    busy = true;
    message = null;
    noticeTitle = null;
    _notify();
    try {
      await operation();
    } catch (error) {
      if (!_disposed) message = authErrorMessage(error);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> signIn(String email, String password) => _run(() async {
    if (emailError(email) != null || password.isEmpty) {
      throw const AuthFailure('Informe um e-mail válido e sua senha.');
    }
    final result = await repository.signIn(email.trim(), password);
    if (_disposed) return;
    user = result;
    pendingEmail = null;
    canRetryCallback = false;
    linkProblem = false;
    noticeTitle = 'Login realizado';
    message = 'Sua conta foi conectada com sucesso.';
  });

  Future<void> signUp(
    String email,
    String password,
    String confirmation,
    String name,
  ) => _run(() async {
    final error =
        emailError(email) ?? nameError(name) ?? passwordError(password);
    if (error != null) throw AuthFailure(error);
    if (password != confirmation) {
      throw const AuthFailure('As senhas não coincidem.');
    }
    await _rejectLeaked(password);
    final result = await repository.signUp(email.trim(), password, name.trim());
    if (_disposed) return;
    user = result;
    if (result == null) {
      pendingEmail = email.trim();
      _resends = 0;
      _cooldown();
      noticeTitle = 'Confirme seu e-mail';
      message = 'Confira seu e-mail e siga o link de confirmação antes de entrar. Se a conta já existir, use entrar ou recuperar senha.';
    } else {
      pendingEmail = null;
      noticeTitle = 'Conta criada';
      message = 'Conta criada e sessão iniciada.';
    }
  });

  bool get canResend =>
      !busy &&
      _resends < 3 &&
      (_resendAfter == null || !_now().isBefore(_resendAfter!));
  String get resendHint => _resends >= 3
      ? 'Limite de reenvios nesta sessão atingido. Tente novamente mais tarde.'
      : canResend
      ? 'Você pode reenviar a confirmação.'
      : 'Aguarde 60 segundos entre envios de confirmação.';

  void _cooldown() {
    _resendAfter = _now().add(const Duration(seconds: 60));
    _resendTimer?.cancel();
    _resendTimer = Timer(const Duration(seconds: 60), _notify);
  }

  Future<void> resend(String email) async {
    if (!canResend) return;
    await _run(() async {
      final error = emailError(email);
      if (error != null) throw AuthFailure(error);
      _resends++;
      _cooldown();
      final recipient = email.trim();
      await repository.resendConfirmation(recipient);
      if (!_disposed) {
        noticeTitle = 'Link reenviado';
        message =
            'Se houver uma confirmação pendente, enviaremos um novo link para $recipient.';
      }
    });
  }

  Future<void> requestReset(String email) => _run(() async {
    final error = emailError(email);
    if (error != null) throw AuthFailure(error);
    await repository.requestPasswordReset(email.trim());
    if (_disposed) return;
    noticeTitle = 'E-mail enviado';
    message = 'Se houver uma conta para este e-mail, você receberá instruções para recuperar a senha.';
  });

  Future<void> resetPassword(String password, String confirmation) =>
      _run(() async {
        if (!recoveryRequired || user == null) {
          throw const AuthFailure(
            'Abra um link de recuperação válido antes de definir a senha.',
          );
        }
        final error = passwordError(password);
        if (error != null) throw AuthFailure(error);
        if (password != confirmation) {
          throw const AuthFailure('As senhas não coincidem.');
        }
        await _rejectLeaked(password);
        await repository.updatePassword(password);
        if (_disposed) return;
        recoveryRequired = false;
        noticeTitle = 'Senha atualizada';
        message = 'Senha atualizada com sucesso.';
      });

  void requestNewRecoveryLink() {
    recoveryRequired = false;
    linkProblem = false;
    canRetryCallback = false;
    _notify();
  }

  Future<void> retryCallback() => _run(() async {
    if (!canRetryCallback) {
      throw const AuthFailure('Solicite um novo link para continuar.');
    }
    await repository.retryCallback();
  });

  Future<void> google() => _run(() async {
    final launched = await repository.signInWithGoogle();
    if (_disposed || user != null) return;
    message = launched
        ? 'Conclua o acesso no navegador. Você só estará conectado após retornar com uma sessão válida. Se cancelou, tente novamente ou continue sem conta.'
        : 'Acesso com Google cancelado ou navegador indisponível. Tente novamente ou continue sem conta.';
  });

  Future<void> saveName(String name) => _run(() async {
    if (user == null) throw const AuthFailure('Entre para editar seu nome.');
    final error = nameError(name);
    if (error != null) throw AuthFailure(error);
    final updated = await repository.updateName(name.trim());
    if (!_disposed) {
      user = updated;
      noticeTitle = 'Pronto';
      message = 'Nome atualizado.';
    }
  });

  Future<void> signOut() => _run(() async {
    await repository.signOut();
    if (_disposed) return;
    user = null;
    pendingEmail = null;
    recoveryRequired = false;
    noticeTitle = 'Você saiu da conta';
    message = 'Você saiu da conta. Seus favoritos e histórico continuam neste dispositivo.';
    canRetryCallback = false;
    linkProblem = false;
  });

  Future<void> changePassword(
    String current,
    String password,
    String confirmation,
  ) => _run(() async {
    if (user == null) {
      throw const AuthFailure('Entre na sua conta para alterar a senha.');
    }
    if (current.isEmpty) {
      throw const AuthFailure('Informe a senha atual.');
    }
    final error = passwordError(password);
    if (error != null) throw AuthFailure(error);
    if (password != confirmation) {
      throw const AuthFailure('As senhas não coincidem.');
    }
    await repository.verifyPassword(current);
    await _rejectLeaked(password);
    await repository.updatePassword(password);
    if (_disposed) return;
    noticeTitle = 'Senha alterada';
    message = 'Senha alterada.';
  });

  Future<void> signOutEverywhere() => _run(() async {
    await repository.signOutEverywhere();
    if (_disposed) return;
    _clearAccount();
    noticeTitle = 'Sessões encerradas';
    message = 'Você saiu da conta em todos os aparelhos.';
  });

  Future<void> deleteAccount({String? password}) => _run(() async {
    final current = user;
    if (current == null) {
      throw const AuthFailure('Entre na sua conta para excluí-la.');
    }
    if (current.hasPassword && (password == null || password.isEmpty)) {
      throw const AuthFailure('Informe sua senha para excluir a conta.');
    }
    await repository.deleteAccount(
      password: current.hasPassword ? password : null,
    );
    if (_disposed) return;
    _clearAccount();
    noticeTitle = 'Conta excluída';
    message =
        'Conta excluída. Seus avistamentos e fotos foram apagados do servidor; '
        'favoritos e histórico continuam só neste aparelho.';
  });

  /// Chamado depois que a pessoa toca em OK no aviso.
  void clearNotice() {
    if (noticeTitle == null) return;
    noticeTitle = null;
    message = null;
    _notify();
  }

  void _clearAccount() {
    user = null;
    pendingEmail = null;
    recoveryRequired = false;
    canRetryCallback = false;
    linkProblem = false;
  }

  static String? emailError(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim()) &&
          value.trim().length <= 254
      ? null
      : 'Informe um e-mail válido.';
  static String? passwordError(String value) =>
      value.length >= 8 && value.length <= 128
      ? null
      : 'Use uma senha de 8 a 128 caracteres.';
  static String? nameError(String value) {
    final name = value.trim();
    return name.length < 2 ||
            name.length > 60 ||
            RegExp(r'[\x00-\x1F\x7F<>]').hasMatch(name)
        ? 'Use um nome de 2 a 60 caracteres, sem controles ou sinais < e >.'
        : null;
  }

  @override
  void dispose() {
    _disposed = true;
    _resendTimer?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(repository.dispose());
    super.dispose();
  }
}
