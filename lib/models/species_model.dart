
enum SpeciesStatus {
  danger,
  invasive,
  unverified,
}

class SpeciesModel {
  // Identificação da espécie
  final String commonName;
  final String scientificName;
  final String? imagePath;
  final SpeciesStatus status;

  // Informações gerais
  final String? description;
  final String? characteristics;
  final String? habitat;

  // Segurança
  final String? riskDescription;
  final String? safetyAdvice;

  // Fontes das informações
  final String? sourceName;
  final String? sourceUrl;

  const SpeciesModel({
    required this.commonName,
    required this.scientificName,
    this.imagePath,
    required this.status,
    this.description,
    this.characteristics,
    this.habitat,
    this.riskDescription,
    this.safetyAdvice,
    this.sourceName,
    this.sourceUrl,
  });
}
