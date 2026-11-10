import 'package:ecolens/utils/ai_analysis_error_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Tempo limite do Gemini tem mensagem específica', () {
    expect(
      aiAnalysisErrorMessage(FunctionException(status: 504)),
      contains('demorou mais'),
    );
  });

  test('Limite diário tem mensagem específica', () {
    expect(
      aiAnalysisErrorMessage(FunctionException(status: 429)),
      contains('Limite diário'),
    );
  });

  test('Visitante no limite é convidado a entrar na conta', () {
    expect(
      aiAnalysisErrorMessage(
        FunctionException(
          status: 429,
          details: {
            'error': 'Limite diário de análises para visitantes atingido.',
          },
        ),
      ),
      contains('Entre na sua conta'),
    );
  });

  test('Falha temporária não expõe detalhes internos', () {
    expect(
      aiAnalysisErrorMessage(FunctionException(status: 502)),
      contains('temporariamente indisponível'),
    );
  });

  test('Formato inválido mantém a mensagem original', () {
    expect(
      aiAnalysisErrorMessage(const FormatException('Formato inválido')),
      'Formato inválido',
    );
  });
}
