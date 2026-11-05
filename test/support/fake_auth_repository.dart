import 'dart:async';

import 'package:ecolens/data/auth_repository.dart';
import 'package:ecolens/models/user_model.dart';

const account = UserModel(
  id: 'user-test',
  email: 'pessoa@example.com',
  displayName: 'Pessoa',
);

class FakeAuthRepository implements AuthRepository {
  final events = StreamController<AccountEvent>.broadcast(sync: true);
  UserModel? restored;
  UserModel? registered;
  Object? failure;
  Completer<void>? pending;
  bool googleLaunched = true;
  bool disposed = false;
  int calls = 0;
  int connects = 0;
  String? lastName;
  String? lastConfirmationEmail;
  AccountEvent? retryEvent;
  int callbackRetries = 0;

  Future<void> _call() async {
    calls++;
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
  }

  @override
  Stream<AccountEvent> get changes => events.stream;
  @override
  Future<UserModel?> connect() async {
    connects++;
    return restored;
  }

  @override
  Future<UserModel?> signUp(String email, String password, String name) async {
    await _call();
    lastName = name;
    return registered;
  }

  @override
  Future<UserModel> signIn(String email, String password) async {
    await _call();
    return account;
  }

  @override
  Future<void> resendConfirmation(String email) {
    lastConfirmationEmail = email;
    return _call();
  }

  @override
  Future<void> retryCallback() async {
    callbackRetries++;
    await _call();
    if (retryEvent != null) events.add(retryEvent!);
  }

  @override
  Future<void> requestPasswordReset(String email) => _call();
  @override
  Future<void> updatePassword(String password) => _call();
  @override
  Future<bool> signInWithGoogle() async {
    await _call();
    return googleLaunched;
  }

  @override
  Future<UserModel> updateName(String name) async {
    await _call();
    lastName = name;
    return UserModel(id: account.id, email: account.email, displayName: name);
  }

  @override
  Future<void> signOut() => _call();
  @override
  Future<void> dispose() async {
    disposed = true;
    await events.close();
  }
}
