import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Orientações e contatos públicos; não identifica espécies nem envia dados.
class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  static const String samuNumber = '192';
  static const String firefightersNumber = '193';
  static const String ibamaNumber = '08000618080';
  static const String saoRoqueGcmNumber = '1147122633';
  static const String saoRoqueEnvironmentNumber = '11996231769';
  static const String cetrasSpNumber = '1128232272';

  String _formatPhoneNumber(String number) {
    if (number == ibamaNumber) return '0800 061 8080';
    if (number == saoRoqueGcmNumber) return '(11) 4712-2633';
    if (number == saoRoqueEnvironmentNumber) return '(11) 99623-1769';
    if (number == cetrasSpNumber) return '(11) 2823-2272';
    return number;
  }

  Future<void> _openUri(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o aplicativo solicitado.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o aplicativo solicitado.'),
          ),
        );
      }
    }
  }

  Widget _callCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String number,
    required IconData icon,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    _openUri(context, Uri(scheme: 'tel', path: number)),
                icon: const Icon(Icons.phone_outlined),
                label: Text(
                  'Abrir discador · '
                  '${_formatPhoneNumber(number)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guidanceCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> steps,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final step in steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 6, color: colors.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(child: Text(step)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sourceLink(
    BuildContext context, {
    required String label,
    required String url,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.menu_book_outlined),
      title: Text(label),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => _openUri(context, Uri.parse(url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('SOS ambiental')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: colors.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colors.onErrorContainer,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Priorize sua segurança. Não tente tocar, '
                        'capturar ou resgatar animais desconhecidos. '
                        'Afaste pessoas e animais domésticos e peça '
                        'orientação ao órgão competente.',
                        style: TextStyle(
                          color: colors.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                'Emergência com pessoas',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _callCard(
              context,
              title: 'SAMU · 192',
              subtitle:
                  'Urgência médica, envenenamento e acidentes '
                  'com vítimas. Atendimento gratuito, 24 horas.',
              number: samuNumber,
              icon: Icons.medical_services_outlined,
            ),
            _callCard(
              context,
              title: 'Corpo de Bombeiros · 193',
              subtitle:
                  'Situações de emergência que exigem '
                  'atendimento e socorro imediato. '
                  'A central orienta sobre o encaminhamento.',
              number: firefightersNumber,
              icon: Icons.local_fire_department_outlined,
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                'Animal silvestre em risco',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _guidanceCard(
              context,
              title: 'Como proceder',
              icon: Icons.pets_outlined,
              steps: const [
                'Observe de longe e não alimente ou manuseie o animal.',
                'Mantenha crianças e animais domésticos afastados.',
                'Se houver risco imediato, peça orientação ao '
                    'serviço de emergência da sua região.',
                'Para ocorrências sem urgência, procure o órgão '
                    'ambiental municipal ou estadual competente.',
              ],
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                'Resgate de fauna · São Roque e região',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Contatos regionais para orientação e encaminhamento. '
              'Fora de São Roque, procure os órgãos da sua cidade. '
              'Se houver risco imediato, acione 193 ou 190.',
            ),
            const SizedBox(height: 8),
            _callCard(
              context,
              title: 'Guarda Civil Municipal · São Roque',
              subtitle:
                  'Canal municipal informado pela Prefeitura '
                  'como disponível 24 horas. Relate a ocorrência e '
                  'peça orientação sobre resgate especializado.',
              number: saoRoqueGcmNumber,
              icon: Icons.local_police_outlined,
            ),
            _callCard(
              context,
              title: 'Divisão de Meio Ambiente · São Roque',
              subtitle:
                  'Orientação municipal sobre fauna. '
                  'Atendimento de segunda a sexta, das 9h às 15h. '
                  'Não substitui socorro de emergência.',
              number: saoRoqueEnvironmentNumber,
              icon: Icons.nature_people_outlined,
            ),
            _callCard(
              context,
              title: 'CETRAS-SP · triagem de animais',
              subtitle:
                  'Centro estadual de triagem e reabilitação. '
                  'Entre em contato antes de qualquer deslocamento '
                  'para confirmar as condições de recebimento. '
                  'Não é central de resgate 24 horas.',
              number: cetrasSpNumber,
              icon: Icons.pets_outlined,
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                'Denúncias e orientação ambiental',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _callCard(
              context,
              title: 'Ibama · Linha Verde',
              subtitle:
                  'Denúncias e atendimento ambiental. '
                  'Telefone 0800 061 8080, de segunda a sexta, '
                  'das 7h às 19h. Não é serviço de resgate de emergência.',
              number: ibamaNumber,
              icon: Icons.eco_outlined,
            ),
            const SizedBox(height: 16),
            _guidanceCard(
              context,
              title: 'Se houve picada ou ferroada',
              icon: Icons.health_and_safety_outlined,
              steps: const [
                'Procure atendimento médico imediatamente. '
                    'Em situação de emergência, ligue 192 ou 193.',
                'Em acidentes terrestres com cobras, escorpiões '
                    'ou aranhas, mantenha a pessoa em repouso e '
                    'lave o local com água e sabão.',
                'Não faça torniquete, cortes, sucção ou '
                    'tratamentos caseiros.',
                'Não se aproxime nem tente capturar o animal '
                    'para identificá-lo.',
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Fontes oficiais',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            _sourceLink(
              context,
              label: 'Ministério da Saúde · animais peçonhentos',
              url:
                  'https://www.gov.br/saude/pt-br/assuntos/'
                  'saude-de-a-a-z/a/animais-peconhentos',
            ),
            _sourceLink(
              context,
              label: 'SAMU · orientações oficiais',
              url: 'https://www.gov.br/saude/pt-br/composicao/saes/samu-192',
            ),
            _sourceLink(
              context,
              label: 'Ibama · canais de atendimento',
              url:
                  'https://www.gov.br/ibama/pt-br/'
                  'canais_atendimento/fale-conosco',
            ),
            _sourceLink(
              context,
              label: 'São Roque · secretarias e contatos municipais',
              url: 'https://www.saoroque.sp.gov.br/portal/secretarias/',
            ),
            _sourceLink(
              context,
              label: 'São Roque · Divisão de Meio Ambiente',
              url:
                  'https://www.saoroque.sp.gov.br/portal/'
                  'secretarias/21/divisao-de-meio-ambiente',
            ),
            _sourceLink(
              context,
              label: 'CETRAS-SP · serviço estadual',
              url:
                  'https://servicos.sp.gov.br/fcarta/'
                  '6E290343-FB48-4A8B-93B0-155E4C79637F',
            ),
            _sourceLink(
              context,
              label: 'Polícia Militar Ambiental · orientações',
              url:
                  'https://policiamilitar.sp.gov.br/'
                  'unidades/ambiental/faq.html',
            ),
            const SizedBox(height: 14),
            Text(
              'O EcoLens não realiza resgate, diagnóstico '
              'ou ligação automática. Ao tocar em um telefone, '
              'o aplicativo tenta abrir o discador.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
