import 'package:flutter/material.dart';

import '../data/favorites_repository.dart';
import 'eco_spinner.dart';

class SpeciesFavoriteButton extends StatefulWidget {
  final String scientificName;
  final FavoritesRepository? repository;

  const SpeciesFavoriteButton({
    super.key,
    required this.scientificName,
    this.repository,
  });

  @override
  State<SpeciesFavoriteButton> createState() => _SpeciesFavoriteButtonState();
}

class _SpeciesFavoriteButtonState extends State<SpeciesFavoriteButton> {
  late final FavoritesRepository _repository;
  bool _favorite = false;
  bool _busy = true;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FavoritesRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
    });
    try {
      final names = await _repository.load();
      if (!mounted) return;
      setState(() {
        _favorite = names.contains(
          FavoritesRepository.normalize(widget.scientificName),
        );
        _loadError = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = true;
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

  Future<void> _toggle() async {
    setState(() {
      _busy = true;
    });
    final next = !_favorite;
    try {
      await _repository.setFavorite(widget.scientificName, next);
      if (!mounted) return;
      setState(() {
        _favorite = next;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next
                ? 'Espécie adicionada aos favoritos.'
                : 'Espécie removida dos favoritos.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar a alteração. Tente novamente.',
            ),
          ),
        );
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
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      toggled: _favorite,
      child: IconButton(
        tooltip: _loadError
            ? 'Não foi possível ler favoritos. Tentar novamente'
            : _busy
            ? 'Carregando favoritos'
            : _favorite
            ? 'Remover dos favoritos'
            : 'Adicionar aos favoritos',
        onPressed: _busy
            ? null
            : _loadError
            ? _load
            : _toggle,
        icon: _busy
            ? const EcoSpinner(size: 20)
            : Icon(
                _loadError
                    ? Icons.refresh
                    : _favorite
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
      ),
    ),
  );
}
