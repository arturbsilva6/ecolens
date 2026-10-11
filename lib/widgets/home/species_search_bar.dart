
import 'package:flutter/material.dart';

class SpeciesSearchBar extends StatelessWidget {
  final ValueChanged<String> onSearch;
  final VoidCallback onFilterTap;

  const SpeciesSearchBar({
    super.key,
    required this.onSearch,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextField(
      textInputAction: TextInputAction.search,

      // Executa a busca ao pressionar pesquisar
      onSubmitted: (texto) {
        onSearch(texto.trim());
      },

      decoration: InputDecoration(
        hintText: 'Buscar espécie, planta ou animal...',

        prefixIcon: Icon(
          Icons.search,
          color: colors.primary,
        ),

        // Botão de filtros
        suffixIcon: IconButton(
          tooltip: 'Filtrar espécies',
          onPressed: onFilterTap,
          icon: Icon(
            Icons.tune,
            color: colors.primary,
          ),
        ),

        filled: true,
        fillColor: colors.surface,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
