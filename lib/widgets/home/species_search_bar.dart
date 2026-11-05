import 'package:flutter/material.dart';

/// Busca existente com aparência centralizada no ThemeData do EcoLens.
class SpeciesSearchBar extends StatelessWidget {
  const SpeciesSearchBar({
    super.key,
    required this.onSearch,
    required this.onFilterTap,
  });

  final ValueChanged<String> onSearch;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextField(
      textInputAction: TextInputAction.search,
      onSubmitted: (text) => onSearch(text.trim()),
      decoration: InputDecoration(
        hintText: 'Buscar espécie, planta ou animal...',
        prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
        suffixIcon: IconButton(
          tooltip: 'Filtrar espécies',
          onPressed: onFilterTap,
          icon: Icon(Icons.tune_rounded, color: colors.primary),
        ),
      ),
    );
  }
}
