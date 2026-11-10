import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduz falhas conhecidas sem expor detalhes internos ou credenciais.
String aiAnalysisErrorMessage(Object error) {
  if (error is FormatException) {
    return error.message;
  }
  if (error is FunctionException) {
    switch (error.status) {
      case 429:
        final details = error.details;
        final serverText = details is Map ? details['error'] : null;
        // Visitantes têm cota menor; entrar na conta libera mais análises.
        if (serverText is String && serverText.contains('visitantes')) {
          return 'Limite diário de análises para visitantes atingido. '
              'Entre na sua conta para analisar mais fotos.';
        }
        return 'Limite diário de análises atingido. '
            'Tente novamente no próximo dia.';
      case 504:
        return 'A análise demorou mais que o esperado. '
            'Tente novamente mais tarde.';
      case 502:
      case 503:
        return 'O serviço de IA está temporariamente indisponível. '
            'Tente novamente mais tarde.';
      case 401:
      case 403:
        return 'Não foi possível validar sua sessão. '
            'Reinicie o aplicativo e tente novamente.';
    }
  }
  return 'Não foi possível analisar a foto. '
      'Verifique a conexão e a configuração da IA.';
}
