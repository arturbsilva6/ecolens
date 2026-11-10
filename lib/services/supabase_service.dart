import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_config.dart';

/// Inicializa somente o SDK; não consulta o catálogo nem exige login.
class SupabaseService {
  SupabaseService({
    String? url,
    String? publishableKey,
    Future<SupabaseClient> Function(String url, String publishableKey)?
    initializer,
  }) : _url = (url ?? AppConfig.supabaseUrl).trim(),
       _publishableKey = (publishableKey ?? AppConfig.supabasePublishableKey)
           .trim(),
       _initializer = initializer ?? _initializeSdk;

  static final SupabaseService instance = SupabaseService();

  final String _url;
  final String _publishableKey;
  final Future<SupabaseClient> Function(String, String) _initializer;
  SupabaseClient? _client;
  Future<SupabaseClient?>? _initialization;

  /// Chamadas simultâneas compartilham a mesma tentativa. Uma falha permite
  /// nova tentativa quando um recurso online for solicitado novamente.
  Future<SupabaseClient?> initialize() async {
    if (_client != null) return _client;

    final pending = _initialization ??= _initializeSafely();
    try {
      return await pending;
    } finally {
      if (identical(_initialization, pending)) _initialization = null;
    }
  }

  Future<SupabaseClient?> _initializeSafely() async {
    final uri = Uri.tryParse(_url);
    if (_publishableKey.isEmpty ||
        uri == null ||
        !const ['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      return null;
    }

    try {
      _client = await _initializer(_url, _publishableKey);
      return _client;
    } catch (_) {
      // Não registrar exceções do SDK, URLs, tokens ou credenciais.
      debugPrint('Serviços online indisponíveis. O SOS continua disponível.');
      return null;
    }
  }

  /// Somente operações online aguardam o SDK. Um timeout não cancela nem
  /// duplica a inicialização em andamento; ela pode concluir depois.
  Future<SupabaseClient> requireClient() async {
    final client = await initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
    if (client == null) {
      throw StateError(
        'Serviços online indisponíveis. Tente novamente mais tarde. '
        'O SOS continua disponível.',
      );
    }
    return client;
  }

  static Future<SupabaseClient> _initializeSdk(
    String url,
    String publishableKey,
  ) async {
    try {
      final supabase = await Supabase.initialize(
        url: url,
        publishableKey: publishableKey,
        debug: false,
        // AuthRepository trata callbacks uma única vez e apresenta erros na UI.
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          detectSessionInUri: false,
        ),
      );
      return supabase.client;
    } catch (_) {
      // O SDK pode criar o singleton antes de falhar na recuperação local.
      // Libera esse estado parcial para permitir uma tentativa posterior.
      try {
        await Supabase.instance.dispose();
      } catch (_) {
        // O singleton pode não ter sido criado antes da falha.
      }
      rethrow;
    }
  }
}
