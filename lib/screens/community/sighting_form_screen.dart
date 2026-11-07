import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/community_repository.dart';
import '../../models/sighting.dart';
import '../../services/community_photo_service.dart';
import 'community_widgets.dart';

class SightingFormScreen extends StatefulWidget {
  final CommunityRepository repository;
  final List<Municipality> municipalities;
  final Sighting? sighting;
  const SightingFormScreen({
    super.key,
    required this.repository,
    required this.municipalities,
    this.sighting,
  });
  @override
  State<SightingFormScreen> createState() => _SightingFormScreenState();
}

class _SightingFormScreenState extends State<SightingFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _species, _notes;
  late DateTime _date;
  late IdentificationOrigin _origin;
  String? _municipalityId, _error;
  Uint8List? _photo;
  bool _busy = false, _checkRecords = false;
  @override
  void initState() {
    super.initState();
    final s = widget.sighting;
    _species = TextEditingController(text: s?.species);
    _notes = TextEditingController(text: s?.notes);
    _date = s?.observedOn ?? DateTime.now();
    _origin = s?.origin ?? IdentificationOrigin.unknown;
    _municipalityId = s?.municipalityId;
  }

  @override
  void dispose() {
    _species.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        requestFullMetadata: false,
      );
      if (file == null) return;
      if (await file.length() > CommunityPhotoService.maxInputBytes) {
        throw StateError('Foto muito grande.');
      }
      final photo = await CommunityPhotoService().sanitize(
        await file.readAsBytes(),
      );
      if (mounted) {
        setState(() {
          _photo = photo;
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
    if (!_form.currentState!.validate()) return;
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
      final draft = SightingDraft(
        observedOn: _date,
        municipalityId: _municipalityId!,
        notes: _notes.text,
        species: _origin == IdentificationOrigin.unknown ? null : _species.text,
        origin: _origin,
      );
      if (widget.sighting == null) {
        await widget.repository.create(draft, _photo!);
      } else {
        await widget.repository.update(widget.sighting!, draft);
      }
      if (mounted) Navigator.pop(context, true);
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
    return Scaffold(
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
                      onPressed: _busy ? null : () => _pick(ImageSource.camera),
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
                          initialDate: _date,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null && mounted) {
                          setState(() {
                            _date = date;
                          });
                        }
                      },
                icon: const Icon(Icons.calendar_today),
                label: Text('Data: ${_date.day}/${_date.month}/${_date.year}'),
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
                      }),
              ),
              if (_origin != IdentificationOrigin.unknown)
                TextFormField(
                  controller: _species,
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
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Voltar e conferir Meus registros'),
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
    );
  }
}
