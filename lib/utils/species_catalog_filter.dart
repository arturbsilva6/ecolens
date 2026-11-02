import '../models/species_model.dart';

/// Filtros do catálogo público. Não alteram as permissões do Supabase.
enum SpeciesCatalogFilter {
  all,
  danger,
  invasive,
  unverified,
}

extension SpeciesCatalogFilterLabel on SpeciesCatalogFilter {
  String get label => switch (this) {
    SpeciesCatalogFilter.all => 'Todas',
    SpeciesCatalogFilter.danger => 'Perigosas',
    SpeciesCatalogFilter.invasive => 'Invasoras',
    SpeciesCatalogFilter.unverified => 'A verificar',
  };
}

/// Retorna somente os registros que atendem ao texto e à classificação.
///
/// O repositório Supabase já consulta somente linhas com is_published = true,
/// usando também a política RLS do banco de dados.
List<SpeciesModel> filterSpeciesCatalog(
  List<SpeciesModel> species, {
  String query = '',
  SpeciesCatalogFilter filter = SpeciesCatalogFilter.all,
}) {
  final normalizedQuery = normalizeSpeciesSearch(query);

  return species.where((item) {
    final matchesStatus = switch (filter) {
      SpeciesCatalogFilter.all => true,
      SpeciesCatalogFilter.danger => item.status == SpeciesStatus.danger,
      SpeciesCatalogFilter.invasive => item.status == SpeciesStatus.invasive,
      SpeciesCatalogFilter.unverified =>
        item.status == SpeciesStatus.unverified,
    };

    if (!matchesStatus) return false;
    if (normalizedQuery.isEmpty) return true;

    return normalizeSpeciesSearch(item.commonName).contains(normalizedQuery) ||
        normalizeSpeciesSearch(item.scientificName).contains(normalizedQuery);
  }).toList(growable: false);
}

String normalizeSpeciesSearch(String text) {
  return text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâãä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôõö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ç', 'c');
}
