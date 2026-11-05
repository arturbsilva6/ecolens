import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../services/auth_links.dart';
import '../services/supabase_service.dart';
import 'auth_repository.dart';

enum _CallbackStatus {
  inProgress,
  completed,
  retryableFailure,
  terminalFailure,
}

/// O SDK mantém sessão, refresh e PKCE; nenhum token é persistido aqui.
class SupabaseAuthRepository implements AuthRepository {
  final Future<SupabaseClient> Function() _clientProvider;
  final AuthLinks _links;
  final String Function() _redirect;
  final bool googleEnabled;
  final _events = StreamController<AccountEvent>.broadcast(sync: true);
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _linkSubscription;
  SupabaseClient? _client;
  Future<UserModel?>? _connecting;
  final _callbackStates = <int, _CallbackStatus>{};
  final _reportedCallbackSessions = Expando<bool>();
  int? _activeCallback;
  // Apenas em memória e enquanto houver uma falha transitória a repetir.
  Uri? _retryableCallback;
  bool _disposed = false;
  bool get _processingCallback => _activeCallback != null;

  SupabaseAuthRepository({
    SupabaseService? service,
    Future<SupabaseClient> Function()? clientProvider,
    AuthLinks? links,
    String Function()? redirect,
    this.googleEnabled = const bool.fromEnvironment('AUTH_GOOGLE_ENABLED'),
  }) : _clientProvider =
           clientProvider ??
           (service ?? SupabaseService.instance).requireClient,
       _links = links ?? PlatformAuthLinks(),
       _redirect = redirect ?? (() => AuthRedirects.target);

  @override
  Stream<AccountEvent> get changes => _events.stream;

  UserModel? _profile(User? user) => user == null
      ? null
      : UserModel(
          id: user.id,
          email: user.email ?? '',
          displayName: user.userMetadata?['display_name'] is String
              ? user.userMetadata!['display_name'] as String
              : '',
        );

  void _emit(AccountEvent event) {
    if (!_disposed) _events.add(event);
  }

  @override
  Future<UserModel?> connect() {
    if (_client != null) {
      return Future.value(_profile(_client!.auth.currentUser));
    }
    return _connecting ??= _connect().whenComplete(() {
      _connecting = null;
    });
  }

  Future<UserModel?> _connect() async {
    try {
      final client = await _clientProvider();
      if (_disposed) return null;
      _client = client;
      _authSubscription = client.auth.onAuthStateChange.listen(
        (state) {
          // O callback é publicado uma única vez após a troca ser validada.
          if (_processingCallback) return;
          // O stream do SDK pode entregar o mesmo sucesso depois do await.
          final session = state.session;
          if (session != null &&
              (state.event == AuthChangeEvent.signedIn ||
                  state.event == AuthChangeEvent.passwordRecovery) &&
              _reportedCallbackSessions[session] == true) {
            return;
          }
          _emit(
            AccountEvent(
              state.event == AuthChangeEvent.passwordRecovery
                  ? AccountEventType.recovery
                  : state.session == null
                  ? AccountEventType.signedOut
                  : AccountEventType.session,
              user: _profile(state.session?.user),
            ),
          );
        },
        onError: (Object error, StackTrace stack) {
          _emit(
            AccountEvent(
              AccountEventType.serviceError,
              message: authErrorMessage(error),
            ),
          );
        },
      );
      _linkSubscription = _links.stream.listen(
        (uri) {
          unawaited(processCallback(uri));
        },
        onError: (Object _, StackTrace _) {
          _emit(
            const AccountEvent(
              AccountEventType.callbackError,
              message: 'Não foi possível abrir o link de acesso. Solicite um novo link.',
            ),
          );
        },
      );
      final initial = await _links.initial();
      if (!_disposed && initial != null) await processCallback(initial);
      return _profile(client.auth.currentUser);
    } catch (error) {
      throw AuthFailure(authErrorMessage(error));
    }
  }

  /// Aceita somente o endpoint configurado. A sessão vem da validação do SDK.
  Future<void> processCallback(Uri uri) async {
    if (_disposed || _processingCallback) return;
    int? fingerprint;
    try {
      final expected = Uri.parse(_redirect());
      if (!AuthRedirects.accepts(uri, expected)) return;
      if (kIsWeb && !AuthRedirects.hasAuthParameters(uri)) return;
      final parameters = {
        ...uri.queryParameters,
        ...Uri.splitQueryString(uri.fragment),
      };
      // A URL inicial web sem parâmetros é apenas a Home.
      if (parameters.isEmpty && kIsWeb) return;
      fingerprint = uri.toString().hashCode;
      final status = _callbackStates[fingerprint];
      if (status == _CallbackStatus.completed ||
          status == _CallbackStatus.inProgress) {
        return;
      }
      if (status == _CallbackStatus.terminalFailure) {
        throw const AuthFailure(
          'Solicite um novo link ou tente entrar novamente.',
        );
      }
      _activeCallback = fingerprint;
      _callbackStates[fingerprint] = _CallbackStatus.inProgress;
      _retryableCallback = null;
      if (parameters.containsKey('error') ||
          parameters.containsKey('error_code') ||
          parameters.containsKey('error_description')) {
        throw const AuthFailure(
          'Link inválido, expirado ou acesso cancelado. Solicite um novo link ou tente entrar novamente.',
        );
      }
      // PKCE: somente códigos são aceitos; tokens na URL não são importados.
      if ((parameters['code'] ?? '').isEmpty) {
        throw const AuthFailure(
          'Link inválido ou expirado. Solicite um novo link.',
        );
      }
      final response = await _client!.auth.getSessionFromUrl(uri);
      if (_disposed) return;
      _callbackStates[fingerprint] = _CallbackStatus.completed;
      _reportedCallbackSessions[response.session] = true;
      _emit(
        AccountEvent(
          (response.redirectType == 'recovery' ||
                  response.redirectType == 'passwordRecovery')
              ? AccountEventType.recovery
              : AccountEventType.session,
          user: _profile(response.session.user),
        ),
      );
    } catch (error) {
      if (_disposed) return;
      final retryable = fingerprint != null && _isTransientCallbackError(error);
      if (fingerprint != null) {
        _callbackStates[fingerprint] = retryable
            ? _CallbackStatus.retryableFailure
            : _CallbackStatus.terminalFailure;
      }
      _retryableCallback = retryable ? uri : null;
      _emit(
        AccountEvent(
          AccountEventType.callbackError,
          canRetryCallback: retryable,
          message: retryable
              ? 'Falha temporária ao validar o link. Tente novamente com este link ou solicite um novo.'
              : 'Link inválido, expirado, já utilizado ou acesso cancelado. Solicite um novo link ou tente entrar novamente.',
        ),
      );
    } finally {
      if (_activeCallback == fingerprint) _activeCallback = null;
    }
  }

  static bool _isTransientCallbackError(Object error) {
    if (error is AuthRetryableFetchException ||
        error is http.ClientException ||
        error is TimeoutException) {
      return true;
    }
    if (error is AuthException) {
      final status = int.tryParse(error.statusCode ?? '');
      return status == 408 ||
          status == 429 ||
          (status != null && status >= 500 && status < 600);
    }
    return false;
  }

  @override
  Future<void> retryCallback() async {
    final uri = _retryableCallback;
    if (uri == null) {
      throw const AuthFailure(
        'Este link não pode ser reutilizado. Solicite um novo link.',
      );
    }
    await processCallback(uri);
  }

  Future<T> _call<T>(Future<T> Function(GoTrueClient auth) operation) async {
    try {
      await connect();
      return await operation(_client!.auth);
    } catch (error) {
      throw AuthFailure(authErrorMessage(error));
    }
  }

  @override
  Future<UserModel?> signUp(String email, String password, String name) =>
      _call((auth) async {
        final result = await auth.signUp(
          email: email,
          password: password,
          data: {'display_name': name},
          emailRedirectTo: _redirect(),
        );
        return result.session == null ? null : _profile(result.user);
      });

  @override
  Future<UserModel> signIn(String email, String password) =>
      _call((auth) async {
        final response = await auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (response.session == null) {
          throw const AuthFailure('Não foi possível iniciar a sessão.');
        }
        return _profile(response.user)!;
      });

  @override
  Future<void> resendConfirmation(String email) => _call((auth) async {
    await auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: _redirect(),
    );
  });

  @override
  Future<void> requestPasswordReset(String email) => _call((auth) async {
    try {
      await auth.resetPasswordForEmail(email, redirectTo: _redirect());
    } on AuthException catch (error) {
      if (error.code != 'user_not_found') rethrow;
    }
  });

  @override
  Future<void> updatePassword(String password) => _call((auth) async {
    await auth.updateUser(UserAttributes(password: password));
  });

  @override
  Future<bool> signInWithGoogle() async {
    if (!googleEnabled) {
      throw const AuthFailure(
        'Google ainda não está habilitado neste aplicativo. Consulte a configuração de autenticação.',
      );
    }
    return _call(
      (auth) => auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _redirect(),
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      ),
    );
  }

  @override
  Future<UserModel> updateName(String name) => _call((auth) async {
    final response = await auth.updateUser(
      UserAttributes(data: {'display_name': name}),
    );
    if (response.user == null) {
      throw const AuthFailure('Não foi possível salvar o nome.');
    }
    return _profile(response.user)!;
  });

  @override
  Future<void> signOut() => _call((auth) async {
    try {
      await auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // O SDK encerra a sessão local antes de revogar a sessão no servidor.
      if (auth.currentSession == null) {
        throw const AuthFailure(
          'A sessão local foi encerrada, mas não foi possível confirmar a saída no servidor. Seus dados locais foram mantidos.',
        );
      }
      rethrow;
    }
  });

  @override
  Future<void> dispose() async {
    _disposed = true;
    _retryableCallback = null;
    _callbackStates.clear();
    await _authSubscription?.cancel();
    await _linkSubscription?.cancel();
    await _events.close();
  }
}

String authErrorMessage(Object error) {
  if (error is AuthFailure) return error.message;
  if (error is AuthException) {
    if (error.statusCode == '429') {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }
    if (error is AuthRetryableFetchException ||
        error.statusCode == '500' ||
        error.statusCode == '503') {
      return 'Serviço de acesso indisponível. Verifique sua conexão e tente novamente.';
    }
    return switch (error.code) {
      'invalid_credentials' => 'E-mail ou senha incorretos.',
      'email_not_confirmed' => 'Confirme seu e-mail antes de entrar. Você pode reenviar a confirmação.',
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' ||
      'over_sms_send_rate_limit' =>
        'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
      'weak_password' =>
        'A senha não atende aos requisitos. Use uma senha mais forte.',
      'otp_expired' ||
      'flow_state_expired' ||
      'flow_state_not_found' ||
      'session_not_found' =>
        'Link ou sessão inválida ou expirada. Solicite um novo link.',
      'provider_disabled' || 'oauth_provider_not_supported' => 'Google indisponível. É necessário habilitar o provedor e configurar as URLs de retorno.',
      'same_password' => 'Escolha uma senha diferente da anterior.',
      _ => 'Não foi possível concluir o acesso. Verifique os dados e tente novamente.',
    };
  }
  return 'Serviço de acesso indisponível. Verifique sua conexão e tente novamente. Você pode continuar sem conta.';
}
