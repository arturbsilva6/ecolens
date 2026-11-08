import 'package:flutter/material.dart';

import '../../data/favorites_repository.dart';
import '../../data/supabase_species_repository.dart';
import '../../models/species_model.dart';
import 'species_detail_screen.dart';
import '../../widgets/eco_spinner.dart';

class FavoritesScreen extends StatefulWidget {
  final FavoritesRepository? repository;
  final Future<List<SpeciesModel>> Function()? fetchPublishedSpecies;

  const FavoritesScreen({
    super.key,
    this.repository,
    this.fetchPublishedSpecies,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final FavoritesRepository _repository;
  Set<String> _names = {};
  Map<String, SpeciesModel> _published = {};
  bool _loading = true;
  String? _error;
  String? _removing;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FavoritesRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _published = {};
    });
    try {
      final names = await _repository.load();
      if (!mounted) return;
      setState(() {
        _names = names;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível ler os favoritos locais.';
          _loading = false;
        });
      }
      return;
    }
    try {
      if (_names.isNotEmpty) {
        final species =
            await (widget.fetchPublishedSpecies ??
                SupabaseSpeciesRepository().fetchPublishedSpecies)();
        if (!mounted) return;
        setState(() {
          _published = {
            for (final item in species)
              FavoritesRepository.normalize(item.scientificName): item,
          };
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível consultar o catálogo. Seus favoritos permanecem salvos localmente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _remove(String name) async {
    setState(() {
      _removing = name;
    });
    try {
      await _repository.setFavorite(name, false);
      if (!mounted) return;
      setState(() {
        _names.remove(name);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Espécie removida dos favoritos.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível remover. Tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _removing = null;
        });
      }
    }
  }

  Future<void> _open(SpeciesModel species) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SpeciesDetailScreen(
          species: species,
          isDemonstration: false,
          favoritesRepository: _repository,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Favoritos')),
    body: SafeArea(
      child: _loading
          ? const Center(child: EcoSpinner())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  Text(_error!),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
                if (_names.isEmpty && _error == null)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Nenhum favorito ainda. Abra uma ficha no catálogo e toque no coração para adicionar uma espécie.',
                    ),
                  ),
                for (final name in _names)
                  Card(
                    child: ListTile(
                      title: Text(_published[name]?.commonName ?? name),
                      subtitle: Text(
                        _published.containsKey(name)
                            ? _published[name]!.scientificName
                            : _error != null
                            ? 'Ficha indisponível sem consultar o catálogo.'
                            : 'Espécie não disponível no catálogo publicado.',
                      ),
                      onTap: _published.containsKey(name)
                          ? () => _open(_published[name]!)
                          : null,
                      trailing: IconButton(
                        tooltip: 'Remover $name dos favoritos',
                        onPressed: _removing != null
                            ? null
                            : () => _remove(name),
                        icon: const Icon(Icons.favorite),
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );
}
