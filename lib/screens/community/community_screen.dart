import 'package:flutter/material.dart';

import '../../controllers/community_controller.dart';
import '../../data/community_repository.dart';
import '../../data/supabase_community_repository.dart';
import '../../models/sighting.dart';
import '../profile/profile_screen.dart';
import 'community_widgets.dart';
import 'sighting_detail_screen.dart';
import 'sighting_form_screen.dart';

class CommunityScreen extends StatefulWidget {
  final CommunityRepository? repository;
  const CommunityScreen({super.key, this.repository});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late final CommunityController _controller;
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    _controller = CommunityController(
      widget.repository ?? SupabaseCommunityRepository(),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    try {
      final account = await _controller.repository.accountId();
      if (!mounted) return;
      if (account == null) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: const Text('Entre para publicar'),
            content: const Text(
              'Convidados podem consultar. Publicar exige conta cadastrada; uma sessão anônima não é suficiente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continuar consultando'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(this.context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
                child: const Text('Abrir Perfil'),
              ),
            ],
          ),
        );
        return;
      }
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => SightingFormScreen(
            repository: _controller.repository,
            municipalities: _controller.municipalities,
          ),
        ),
      );
      _controller.mine = true;
      await _controller.load(reset: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Serviço de Comunidade indisponível. Confira a configuração e tente novamente.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Comunidade')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          return RefreshIndicator(
            onRefresh: () => c.load(reset: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Avistamentos da comunidade. Identificações não verificadas cientificamente.',
                ),
                const Text(municipalPrecision),
                FilledButton.icon(
                  onPressed: c.loading ? null : _publish,
                  icon: const Icon(Icons.add),
                  label: const Text('Publicar avistamento'),
                ),
                TextField(
                  controller: _search,
                  maxLength: 120,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar espécie',
                    suffixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (value) {
                    c.species = value;
                    c.load(reset: true);
                  },
                ),
                OutlinedButton(
                  onPressed: c.loading
                      ? null
                      : () {
                          c.species = _search.text;
                          c.load(reset: true);
                        },
                  child: const Text('Aplicar filtro de espécie'),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: c.loading
                          ? null
                          : () async {
                              final municipality = await chooseMunicipality(
                                context,
                                c.municipalities,
                              );
                              if (municipality != null) {
                                c.municipalityId = municipality.id;
                                c.load(reset: true);
                              }
                            },
                      child: Text(
                        c.municipality(c.municipalityId ?? '')?.label ??
                            'Todos os municípios/SP',
                      ),
                    ),
                    if (c.municipalityId != null)
                      TextButton(
                        onPressed: c.loading
                            ? null
                            : () {
                                c.municipalityId = null;
                                c.load(reset: true);
                              },
                        child: const Text('Limpar município'),
                      ),
                  ],
                ),
                if (c.accountId != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Meus registros'),
                    subtitle: const Text(
                      'Inclui rascunhos e exclusões pendentes',
                    ),
                    value: c.mine,
                    onChanged: c.loading
                        ? null
                        : (value) {
                            c.mine = value;
                            c.load(reset: true);
                          },
                  ),
                if (c.error != null) ...[
                  Semantics(liveRegion: true, child: Text(c.error!)),
                  OutlinedButton(
                    onPressed: c.loading ? null : () => c.load(),
                    child: const Text('Tentar novamente'),
                  ),
                ],
                if (c.items.isEmpty && !c.loading && c.error == null)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nenhum avistamento encontrado.'),
                  ),
                for (final s in c.items) _tile(context, s),
                if (c.loading) const Center(child: CircularProgressIndicator()),
                if (c.hasMore && c.items.isNotEmpty && !c.loading)
                  OutlinedButton(
                    onPressed: () => c.load(),
                    child: const Text('Carregar mais'),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
  Widget _tile(BuildContext context, Sighting s) => Card(
    child: ListTile(
      isThreeLine: true,
      title: Text(s.speciesLabel),
      subtitle: Text(
        '${_controller.municipality(s.municipalityId)?.label ?? 'SP'} • '
        '${s.observedOn.day}/${s.observedOn.month}/${s.observedOn.year}\n'
        '${s.status == 'published'
            ? s.identificationLabel
            : s.status == 'draft'
            ? 'Rascunho não publicado'
            : 'Exclusão pendente'}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => SightingDetailScreen(
              repository: _controller.repository,
              sighting: s,
              municipalities: _controller.municipalities,
              accountId: _controller.accountId,
            ),
          ),
        );
        await _controller.load(reset: true);
      },
    ),
  );
}
