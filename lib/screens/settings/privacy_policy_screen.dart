import 'package:flutter/material.dart';

/// Política de privacidade exibida no app (LGPD, Lei nº 13.709/2018).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const updatedAt = '7 de novembro de 2026';

  static const sections = <(String, String)>[
    (
      'Quem somos',
      'O EcoLens é um aplicativo desenvolvido como Trabalho de Graduação do '
          'curso de Sistemas para Internet da Fatec São Roque, por Artur '
          'Barbosa e João Messias. Os autores são os responsáveis pelo '
          'tratamento dos dados descritos aqui.',
    ),
    (
      'Dados que coletamos',
      '• Conta: e-mail, nome de exibição e senha (guardada de forma '
          'criptografada pelo serviço de autenticação).\n'
          '• Avistamentos: município, data, nome da espécie, observações e a '
          'foto que você decidir publicar, sempre sem localização exata e sem '
          'metadados.\n'
          '• Identificação por IA: a foto escolhida é enviada para análise '
          'somente depois do seu consentimento e não é armazenada.\n'
          '• No aparelho: favoritos, histórico de identificações, preferências '
          'e o pacote offline ficam só no seu celular.',
    ),
    (
      'Para que usamos',
      'Para manter sua conta, exibir os avistamentos da comunidade, gerar '
          'sugestões de identificação quando você pede e limitar o uso da IA '
          'para evitar abusos. Não vendemos dados e não exibimos publicidade.',
    ),
    (
      'Com quem compartilhamos',
      '• Supabase: hospeda a conta, o banco de dados e as fotos dos '
          'avistamentos (servidores em São Paulo).\n'
          '• Google (Gemini): recebe a foto enviada para identificação, apenas '
          'quando você aceita a análise.\n'
          '• Google (login): quando você escolhe entrar com sua conta Google.\n'
          'Avistamentos publicados ficam visíveis para outros usuários.',
    ),
    (
      'Por quanto tempo',
      'Os dados da conta e os avistamentos ficam guardados enquanto a conta '
          'existir. Ao excluir a conta, eles são apagados do servidor.',
    ),
    (
      'Seus direitos',
      'Você pode consultar e corrigir seus dados no Perfil, apagar '
          'avistamentos, apagar o histórico e os favoritos em Privacidade e '
          'dados, e excluir a conta a qualquer momento em Perfil > Excluir '
          'minha conta (art. 18 da LGPD).',
    ),
    (
      'Segurança',
      'A comunicação com o servidor é criptografada, cada usuário só altera '
          'os próprios registros e as chaves administrativas ficam apenas no '
          'servidor.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Política de privacidade')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Atualizada em $updatedAt', style: theme.textTheme.bodySmall),
          for (final (title, body) in sections) ...[
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 6),
            Text(body),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
