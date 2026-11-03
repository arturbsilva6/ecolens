import '../models/ai_identification_result.dart';
import '../models/species_model.dart';

/// Encontra uma ficha publicada apenas quando o nome científico da sugestão
/// corresponde exatamente ao nome de uma espécie obtida do catálogo.
/// A correspondência NÃO confirma a identificação da foto.
SpeciesModel? matchAiSuggestionToPublishedSpecies(
  AiIdentificationResult suggestion,
  Iterable<SpeciesModel> publishedSpecies,
) {
  if (!suggestion.identified || suggestion.scientificName == null) {
    return null;
  }

  String normalize(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  final scientificName = normalize(suggestion.scientificName!);
  final terms = scientificName.split(' ');

  // "Bothrops sp." ou "cf." não são identificações específicas suficientes.
  if (terms.length < 2 ||
      terms.any((term) => const {
            'sp',
            'sp.',
            'spp',
            'spp.',
            'cf',
            'cf.',
            'aff',
            'aff.',
          }.contains(term))) {
    return null;
  }

  for (final species in publishedSpecies) {
    if (normalize(species.scientificName) == scientificName) {
      return species;
    }
  }

  return null;
}
