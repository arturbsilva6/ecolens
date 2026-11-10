import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Confere se uma senha aparece na base pública de senhas vazadas
/// (Have I Been Pwned, "Pwned Passwords").
///
/// A senha nunca sai do aparelho: o app calcula o SHA-1 dela e envia só os
/// 5 primeiros caracteres desse código. O serviço devolve centenas de códigos
/// com esse começo, e a comparação final é feita aqui (k-anonimato).
///
/// No plano gratuito do Supabase essa proteção não existe no servidor, então
/// ela é feita no app ao criar conta ou trocar a senha.
class PasswordBreachChecker {
  PasswordBreachChecker({http.Client? client, Duration? timeout})
    : _client = client,
      _timeout = timeout ?? const Duration(seconds: 6);

  final http.Client? _client;
  final Duration _timeout;

  /// `true` se a senha já vazou. Sem internet ou com o serviço fora do ar,
  /// devolve `false` para não impedir o cadastro.
  Future<bool> isLeaked(String password) async {
    final hash = sha1.convert(utf8.encode(password)).toString().toUpperCase();
    final prefix = hash.substring(0, 5);
    final suffix = hash.substring(5);
    final client = _client ?? http.Client();
    try {
      final response = await client
          .get(
            Uri.https('api.pwnedpasswords.com', '/range/$prefix'),
            // Respostas com tamanho parecido, para não revelar o prefixo.
            headers: const {'Add-Padding': 'true'},
          )
          .timeout(_timeout);
      if (response.statusCode != 200) return false;
      for (final line in const LineSplitter().convert(response.body)) {
        final parts = line.split(':');
        if (parts.length != 2) continue;
        // Linhas de preenchimento vêm com contagem 0.
        if (parts[0].trim() == suffix && (int.tryParse(parts[1].trim()) ?? 0) > 0) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      if (_client == null) client.close();
    }
  }
}
