import '../models/species_model.dart';

/// Filtros do catálogo público. Não alteram as permissões do Supabase.
enum SpeciesCatalogFilter { all, danger, caution, harmless, invasive, unverified }

extension SpeciesCatalogFilterLabel on SpeciesCatalogFilter {
  String get label => switch (this) {
    SpeciesCatalogFilter.all => 'Todas',
    SpeciesCatalogFilter.danger => 'Perigosas',
    SpeciesCatalogFilter.caution => 'Cautela',
    SpeciesCatalogFilter.harmless => 'Inofensivas',
    SpeciesCatalogFilter.invasive => 'Invasoras',
    SpeciesCatalogFilter.unverified => 'Demais',
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
      SpeciesCatalogFilter.caution => item.status == SpeciesStatus.caution,
      SpeciesCatalogFilter.harmless => item.status == SpeciesStatus.harmless,
      SpeciesCatalogFilter.invasive => item.isInvasiveSpecies,
      SpeciesCatalogFilter.unverified =>
        item.status == SpeciesStatus.unverified,
    };

    if (!matchesStatus) return false;
    if (normalizedQuery.isEmpty) return true;

    return normalizeSpeciesSearch(item.commonName).contains(normalizedQuery) ||
        normalizeSpeciesSearch(item.scientificName).contains(normalizedQuery) ||
        item.otherNames.any(
          (name) => normalizeSpeciesSearch(name).contains(normalizedQuery),
        );
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
