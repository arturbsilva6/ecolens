import '../models/user_model.dart';

enum AccountEventType {
  session,
  signedOut,
  recovery,
  callbackError,
  serviceError,
}

class AccountEvent {
  final AccountEventType type;
  final UserModel? user;
  final String? message;
  final bool canRetryCallback;
  const AccountEvent(
    this.type, {
    this.user,
    this.message,
    this.canRetryCallback = false,
  });
}

class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
}

abstract class AuthRepository {
  Stream<AccountEvent> get changes;
  Future<UserModel?> connect();
  Future<void> retryCallback();
  Future<UserModel?> signUp(String email, String password, String name);
  Future<UserModel> signIn(String email, String password);
  Future<void> resendConfirmation(String email);
  Future<void> requestPasswordReset(String email);
  Future<void> updatePassword(String password);
  Future<bool> signInWithGoogle();
  Future<UserModel> updateName(String name);
  Future<void> signOut();

  /// Encerra a sessão em todos os aparelhos (revoga os refresh tokens).
  Future<void> signOutEverywhere();

  /// Exclui a conta, os avistamentos e as fotos do usuário no servidor.
  /// Confere a senha atual da conta conectada, antes de ações sensíveis.
  Future<void> verifyPassword(String password);

  /// Contas com senha precisam informá-la; contas do Google precisam ter
  /// entrado há pouco tempo (o servidor confere as duas coisas).
  Future<void> deleteAccount({String? password});
  Future<void> dispose();
}
