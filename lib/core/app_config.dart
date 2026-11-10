import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Configuração pública do app.
///
/// Os valores padrão permitem rodar com um simples `flutter run`. Ainda dá
/// para trocar qualquer um com `--dart-define` (por exemplo, para apontar
/// para outro projeto do Supabase).
///
/// A chave publicável do Supabase é feita para ficar dentro de apps e
/// páginas: ela não dá acesso administrativo, e o que cada usuário pode ler
/// ou alterar é controlado pelas regras (RLS) do banco. Chaves secretas
/// (`sb_secret_...`, `service_role`, Gemini) nunca entram aqui.
abstract final class AppConfig {
  static const _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://giyzvoowefyyaotsxqcx.supabase.co',
  );
  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_tpAH4hG43w2Z0S6JE-aCNQ_XPTFtFG_',
  );
  static const _google = bool.fromEnvironment(
    'AUTH_GOOGLE_ENABLED',
    defaultValue: true,
  );
  static const _ai = bool.fromEnvironment(
    'ECOLENS_AI_ENABLED',
    defaultValue: true,
  );

  /// Nos testes automáticos o app fica desconectado, como antes, para que
  /// nenhum teste dependa da internet ou do projeto real.
  static bool get _testing =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  static String get supabaseUrl => _testing ? '' : _url;
  static String get supabasePublishableKey => _testing ? '' : _publishableKey;
  static bool get googleEnabled => !_testing && _google;
  static bool get aiEnabled => !_testing && _ai;
}
