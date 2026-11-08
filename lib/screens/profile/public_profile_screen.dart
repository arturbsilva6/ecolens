import 'package:flutter/material.dart';

import '../../data/public_profile_repository.dart';
import '../../widgets/eco_avatar.dart';
import '../../widgets/result_dialog.dart';

/// Escolha do nome e do avatar mostrados nos avistamentos.
class PublicProfileScreen extends StatefulWidget {
  final PublicProfileRepository? repository;

  const PublicProfileScreen({super.key, this.repository});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late final PublicProfileRepository _repository =
      widget.repository ?? SupabasePublicProfileRepository();
  final _name = TextEditingController();
  String _avatar = EcoAvatars.options.keys.first;
  bool _loading = true, _saving = false, _exists = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await _repository.mine();
      if (!mounted) return;
      setState(() {
        if (profile != null) {
          _name.text = profile.displayName;
          if (EcoAvatars.isValid(profile.avatar)) _avatar = profile.avatar;
          _exists = true;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível carregar o perfil público.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String title, String text) {
    showResultDialog(context, title: title, message: text);
  }

  Future<void> _save() async {
    final error = PublicProfile.nameError(_name.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.save(_name.text, _avatar);
      if (!mounted) return;
      setState(() => _exists = true);
      _message(
        'Perfil público salvo',
        'Seus avistamentos vão mostrar seu nome e avatar.',
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível salvar. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.remove();
      if (!mounted) return;
      setState(() {
        _exists = false;
        _name.clear();
      });
      _message(
        'Perfil público removido',
        'Seus avistamentos voltam a mostrar "membro da comunidade".',
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível remover. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final name = _name.text.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil público')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    'Escolha como você aparece nos avistamentos que publicar. '
                    'É opcional: sem perfil público, eles mostram "membro da '
                    'comunidade". Não use seu nome completo nem dados pessoais.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: EcoAvatar(avatar: _avatar),
                      title: Text(
                        name.isEmpty
                            ? 'Seu nome público'
                            : 'Publicado por $name',
                      ),
                      subtitle: const Text('Prévia nos avistamentos'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _name,
                    maxLength: 30,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome público',
                      hintText: 'Ex.: Ana S. ou Observadora de aves',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text('Avatar', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final entry in EcoAvatars.options.entries)
                        Semantics(
                          button: true,
                          selected: entry.key == _avatar,
                          label: 'Avatar ${entry.value.$3}',
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => setState(() => _avatar = entry.key),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 3,
                                  color: entry.key == _avatar
                                      ? colors.primary
                                      : Colors.transparent,
                                ),
                              ),
                              child: ExcludeSemantics(
                                child: EcoAvatar(avatar: entry.key, radius: 24),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('Salvar perfil público'),
                  ),
                  if (_exists)
                    TextButton(
                      onPressed: _saving ? null : _remove,
                      child: const Text('Remover perfil público'),
                    ),
                ],
              ),
      ),
    );
  }
}
