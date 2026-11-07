import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/community_repository.dart';
import '../../data/share_identification_draft_store.dart';
import '../../models/community_share_draft.dart';
import '../../models/sighting.dart';
import '../../models/community_identification_seed.dart';
import '../../widgets/auth/account_navigation_scope.dart';
import '../profile/profile_screen.dart';
import '../map/heat_map_screen.dart';
import 'community_screen.dart';
import 'sighting_detail_screen.dart';
import '../../services/community_photo_service.dart';
import 'community_widgets.dart';
import '../../widgets/camera_notice.dart';

class SightingFormScreen extends StatefulWidget {
  final CommunityRepository repository;
  final List<Municipality> municipalities;
  final Sighting? sighting;
  final CommunityIdentificationSeed? initialIdentification;
  final CommunityShareDraft? restoredDraft;
  final ShareIdentificationDraftStore? draftStore;
  final Future<void> Function(BuildContext)? openAccount;
  final Future<Uint8List?> Function(ImageSource)? selectPhoto;
  final CommunityPhotoService? photoService;
  const SightingFormScreen({
    super.key,
    required this.repository,
    required this.municipalities,
    this.sighting,
    this.initialIdentification,
    this.restoredDraft,
    this.draftStore,
    this.openAccount,
    this.selectPhoto,
    this.photoService,
  });
  @override
  State<SightingFormScreen> createState() => _SightingFormScreenState();
}

class _SightingFormScreenState extends State<SightingFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _species, _notes;
  DateTime? _date;
  late IdentificationOrigin _origin;
  String? _municipalityId, _error;
  Uint8List? _photo;
  bool _busy = false, _checkRecords = false, _dirty = false;
  bool _allowPop = false, _discardOpen = false;
  Sighting? _published;
  bool get _keepsLoginDraft =>
      widget.sighting == null &&
      (widget.initialIdentification != null || widget.restoredDraft != null);
  ShareIdentificationDraftStore get _draftStore =>
      widget.draftStore ?? ShareIdentificationDraftStore();

  Future<void> _clearLoginDraft() async {
    if (_keepsLoginDraft) await _draftStore.clear();
  }

  @override
  void initState() {
    super.initState();
    final s = widget.sighting;
    final seed = widget.initialIdentification;
    final restored = widget.restoredDraft;
    _species = TextEditingController(
      text: s?.species ?? restored?.hypothesis ?? seed?.hypothesis,
    );
    _notes = TextEditingController(text: s?.notes ?? restored?.notes);
    _date =
        s?.observedOn ??
        restored?.observedOn ??
        (seed == null ? DateTime.now() : null);
    _origin =
        s?.origin ??
        restored?.origin ??
        (seed?.hypothesis != null
            ? IdentificationOrigin.ai
            : IdentificationOrigin.unknown);
    _municipalityId = s?.municipalityId ?? restored?.municipalityId;
    if (restored != null) {
      _photo = restored.photo;
      _dirty = true;
      _error = 'Rascunho recuperado neste dispositivo. Revise os dados antes de publicar. Nada foi publicado.';
    }
    if (seed != null && restored == null) {
      _busy = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _prepareInitialPhoto(seed.originalPhoto),
      );
    }
  }

  Future<void> _prepareInitialPhoto(Uint8List? original) async {
    try {
      if (original == null || original.isEmpty) {
        throw StateError('Foto ausente');
      }
      final photo = await (widget.photoService ?? CommunityPhotoService())
          .sanitize(original);
      if (mounted) {
        setState(() {
          _photo = photo;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Foto original ausente ou indisponível. Selecione uma foto válida; nenhuma imagem do catálogo será usada.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _discard() async {
    if (_busy || _discardOpen) return;
    _discardOpen = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Descartar alterações?'),
        content: const Text(
          'Os dados editados neste formulário serão descartados. O resultado, histórico e favoritos permanecem como estão.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    _discardOpen = false;
    if (discard == true && mounted) {
      try {
        await _clearLoginDraft();
      } catch (_) {
        if (mounted) {
          setState(
            () => _error =
                'Não foi possível descartar o rascunho local. Tente novamente.',
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        _allowPop = true;
      });
      Navigator.pop(context);
    }
  }

  Future<void> _login() async {
    // Await persistence BEFORE opening the browser; pause is too late on Android.
    if (_keepsLoginDraft) {
      await _draftStore.save(
        CommunityShareDraft(
          photo: _photo!,
          hypothesis: _species.text,
          origin: _origin,
          observedOn: _date!,
          municipalityId: _municipalityId!,
          municipalities: widget.municipalities,
          notes: _notes.text,
        ),
      );
    }
    if (!mounted) return;
    final injected = widget.openAccount;
    final shared = AccountNavigationScope.maybeOf(context);
    if (injected != null) {
      await injected(context);
    } else if (shared != null) {
      await shared.openAccount(returnLabel: 'Voltar ao avistamento');
    } else {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ProfileScreen(returnLabel: 'Voltar ao avistamento'),
        ),
      );
    }
    if (!mounted) return;
    final account = await widget.repository.accountId();
    await _clearLoginDraft();
    if (mounted) {
      setState(() {
        _error = account == null
            ? 'Acesso não concluído. Seus dados estão preservados; entre com uma conta cadastrada para publicar.'
            : 'Conta conectada. Revise os dados e toque em Publicar quando quiser. Nada foi publicado.';
      });
    }
  }

  @override
  void dispose() {
    _species.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (source == ImageSource.camera &&
        widget.selectPhoto == null &&
        !await CameraNotice().confirm(context)) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      Uint8List? original;
      if (widget.selectPhoto != null) {
        original = await widget.selectPhoto!(source);
      } else {
        final file = await ImagePicker().pickImage(
          source: source,
          requestFullMetadata: false,
        );
        if (file == null) return;
        if (await file.length() > CommunityPhotoService.maxInputBytes) {
          throw StateError('Foto muito grande.');
        }
        original = await file.readAsBytes();
      }
      if (original == null) return;
      final photo = await (widget.photoService ?? CommunityPhotoService())
          .sanitize(original);
      if (mounted) {
        setState(() {
          _photo = photo;
          _dirty = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível preparar a foto. Escolha uma imagem de até 20 MB e tente novamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_busy || _checkRecords || _published != null) return;
    if (!_form.currentState!.validate()) return;
    if (_date == null) {
      setState(() {
        _error = 'Selecione e confirme a data do avistamento; ela não é inferida da foto.';
      });
      return;
    }
    if (_municipalityId == null ||
        (widget.sighting == null && _photo == null)) {
      setState(() {
        _error = 'Selecione o município e uma foto para publicar.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Recheck at the explicit send action; repository and server check again.
      if (await widget.repository.accountId() == null) {
        if (mounted) await _login();
        return; // Never publish automatically when login returns.
      }
      // Remove the OAuth checkpoint BEFORE any publication attempt. An uncertain
      // send must be reconciled in Meus registros, never restored for blind retry.
      await _clearLoginDraft();
      final draft = SightingDraft(
        observedOn: _date!,
        municipalityId: _municipalityId!,
        notes: _notes.text,
        species: _origin == IdentificationOrigin.unknown ? null : _species.text,
        origin: _origin,
      );
      if (widget.sighting == null) {
        final published = await widget.repository.create(draft, _photo!);
        if (mounted) {
          setState(() {
            _published = published;
            _dirty = false;
          });
        }
      } else {
        await widget.repository.update(widget.sighting!, draft);
      }
      if (mounted && widget.sighting != null) {
        setState(() {
          _allowPop = true;
        });
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkRecords = e is CommunityPublicationUncertain;
          _error = e is CommunityFailure
              ? e.message
              : 'Não foi possível salvar. Tente novamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final municipality = widget.municipalities
        .where((m) => m.id == _municipalityId)
        .firstOrNull;
    if (_published != null) return _publicationSuccess(context, _published!);
    return PopScope<bool>(
      canPop: _allowPop || (!_dirty && !_busy),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _discard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.sighting == null
                ? 'Publicar avistamento'
                : 'Editar avistamento',
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Publicação visível a todos. Não inclua pessoas, placas, endereços, e-mail ou outros dados privados na foto ou nas observações. Os metadados da foto são removidos antes do envio.',
                ),
                if (_keepsLoginDraft)
                  const Text(
                    'Revise a sugestão não verificada, a data e o município. Nada será publicado ao entrar na conta. Antes do login, foto e campos são salvos temporariamente neste dispositivo para recuperar o formulário se o Android encerrar o app (até 24 horas).',
                  ),
                const SizedBox(height: 16),
                if (_photo != null)
                  Image.memory(
                    _photo!,
                    height: 180,
                    semanticLabel: 'Foto selecionada',
                  ),
                if (widget.sighting == null)
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Câmera'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo),
                        label: const Text('Galeria'),
                      ),
                    ],
                  ),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _date ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null && mounted) {
                            setState(() {
                              _date = date;
                              _dirty = true;
                            });
                          }
                        },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _date == null
                        ? 'Selecionar data do avistamento'
                        : 'Data: ${_date!.day}/${_date!.month}/${_date!.year}',
                  ),
                ),
                if (_date == null)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _date = DateTime.now();
                            _dirty = true;
                          }),
                    child: const Text('Usar hoje como data do avistamento'),
                  ),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          final m = await chooseMunicipality(
                            context,
                            widget.municipalities,
                          );
                          if (m != null && mounted) {
                            setState(() {
                              _municipalityId = m.id;
                              _dirty = true;
                            });
                          }
                        },
                  child: Text(
                    municipality?.label ?? 'Selecionar município/UF (SP)',
                  ),
                ),
                const Text(municipalPrecision),
                const SizedBox(height: 16),
                DropdownButtonFormField<IdentificationOrigin>(
                  key: ValueKey(_origin),
                  initialValue: _origin,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Origem da identificação',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: IdentificationOrigin.unknown,
                      child: Text('Espécie não identificada'),
                    ),
                    DropdownMenuItem(
                      value: IdentificationOrigin.user,
                      child: Text('Informada por mim'),
                    ),
                    DropdownMenuItem(
                      value: IdentificationOrigin.ai,
                      child: Text('Sugerida por IA'),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                          _origin = value!;
                          _dirty = true;
                        }),
                ),
                if (_origin != IdentificationOrigin.unknown)
                  TextFormField(
                    controller: _species,
                    onChanged: (_) => setState(() {
                      _dirty = true;
                      if (_origin == IdentificationOrigin.ai) {
                        _origin = IdentificationOrigin.user;
                      }
                    }),
                    enabled: !_busy,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      labelText: 'Nome da espécie (hipótese)',
                    ),
                    validator: (value) =>
                        _origin != IdentificationOrigin.unknown &&
                            (value?.trim().isEmpty ?? true)
                        ? 'Informe a hipótese ou escolha espécie não identificada.'
                        : null,
                  ),
                const Text(
                  'Identificações informadas e sugestões de IA não são confirmação científica. Não use este registro para avaliar segurança ou risco.',
                ),
                TextFormField(
                  controller: _notes,
                  onChanged: (_) => setState(() {
                    _dirty = true;
                  }),
                  enabled: !_busy,
                  maxLength: 2000,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                  ),
                ),
                if (_error != null)
                  Semantics(liveRegion: true, child: Text(_error!)),
                if (_checkRecords)
                  TextButton(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommunityScreen(
                          repository: widget.repository,
                          initialMine: true,
                        ),
                      ),
                    ),
                    child: const Text('Conferir Meus registros'),
                  ),
                if (_busy) const Center(child: CircularProgressIndicator()),
                FilledButton(
                  onPressed: _busy || _checkRecords ? null : _save,
                  child: Text(
                    widget.sighting == null ? 'Publicar' : 'Salvar alterações',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _publicationSuccess(BuildContext context, Sighting published) =>
      Scaffold(
        appBar: AppBar(title: const Text('Avistamento publicado')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Publicação confirmada. A identificação continua não verificada cientificamente.',
              ),
              FilledButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SightingDetailScreen(
                      repository: widget.repository,
                      sighting: published,
                      municipalities: widget.municipalities,
                      accountId: published.ownerId,
                    ),
                  ),
                ),
                child: const Text('Ver avistamento publicado'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CommunityScreen(repository: widget.repository),
                  ),
                ),
                child: const Text('Ver comunidade'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HeatMapScreen(
                      repository: widget.repository,
                      initialMunicipality: widget.municipalities
                          .where((m) => m.id == published.municipalityId)
                          .firstOrNull,
                    ),
                  ),
                ),
                child: const Text('Ver no mapa'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Concluir'),
              ),
            ],
          ),
        ),
      );
}
