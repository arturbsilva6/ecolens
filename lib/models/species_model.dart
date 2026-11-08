/// Classificação de risco exibida nas tags do app.
///
/// - [danger]: risco de morte ou sequela;
/// - [caution]: dor ou reação forte, ou risco que depende de contato;
/// - [harmless]: inofensiva;
/// - [invasive] e [unverified]: registros antigos, anteriores às
///   categorias de risco. Ser invasora agora é indicado por
///   [SpeciesModel.isInvasive].
enum SpeciesStatus { danger, caution, harmless, invasive, unverified }

class SpeciesModel {
  // Identificação da espécie
  final String commonName;
  final String scientificName;
  final String? imagePath;
  final String? imageUrl;
  final String? imageCredit;
  final String? imageSourceUrl;
  final String? imageLicenseUrl;
  final String? imageLicenseLabel;
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

  // Guia de reconhecimento
  final bool isInvasive;
  final String? speciesGroup;
  final List<String> otherNames;
  final List<String> mainColors;
  final String? visualPattern;
  final List<String> lookalikes;
  final String? rescueAdvice;

  const SpeciesModel({
    required this.commonName,
    required this.scientificName,
    this.imagePath,
    this.imageUrl,
    this.imageCredit,
    this.imageSourceUrl,
    this.imageLicenseUrl,
    this.imageLicenseLabel,
    required this.status,
    this.description,
    this.characteristics,
    this.habitat,
    this.riskDescription,
    this.safetyAdvice,
    this.sourceName,
    this.sourceUrl,
    this.isInvasive = false,
    this.speciesGroup,
    this.otherNames = const [],
    this.mainColors = const [],
    this.visualPattern,
    this.lookalikes = const [],
    this.rescueAdvice,
  });

  /// Invasora pela classificação antiga ou pela marcação atual.
  bool get isInvasiveSpecies => isInvasive || status == SpeciesStatus.invasive;

  /// Plantas usam o grupo "planta"; os demais grupos são animais.
  bool get isPlant => speciesGroup == 'planta';

  /// Representação usada pelo pacote offline salvo no aparelho.
  Map<String, dynamic> toJson() => {
    'common_name': commonName,
    'scientific_name': scientificName,
    'status': status.name,
    'image_path': imagePath,
    'image_url': imageUrl,
    'image_credit': imageCredit,
    'image_source_url': imageSourceUrl,
    'image_license_url': imageLicenseUrl,
    'image_license_label': imageLicenseLabel,
    'description': description,
    'characteristics': characteristics,
    'habitat': habitat,
    'risk_description': riskDescription,
    'safety_advice': safetyAdvice,
    'source_name': sourceName,
    'source_url': sourceUrl,
    'is_invasive': isInvasive,
    'species_group': speciesGroup,
    'other_names': otherNames,
    'main_colors': mainColors,
    'visual_pattern': visualPattern,
    'lookalikes': lookalikes,
    'rescue_advice': rescueAdvice,
  };

  static List<String> _strings(Object? value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];

  factory SpeciesModel.fromJson(Map<String, dynamic> json) {
    final status = SpeciesStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => SpeciesStatus.unverified,
    );
    return SpeciesModel(
      commonName: json['common_name'] as String,
      scientificName: json['scientific_name'] as String,
      status: status,
      imagePath: json['image_path'] as String?,
      imageUrl: json['image_url'] as String?,
      imageCredit: json['image_credit'] as String?,
      imageSourceUrl: json['image_source_url'] as String?,
      imageLicenseUrl: json['image_license_url'] as String?,
      imageLicenseLabel: json['image_license_label'] as String?,
      description: json['description'] as String?,
      characteristics: json['characteristics'] as String?,
      habitat: json['habitat'] as String?,
      riskDescription: json['risk_description'] as String?,
      safetyAdvice: json['safety_advice'] as String?,
      sourceName: json['source_name'] as String?,
      sourceUrl: json['source_url'] as String?,
      isInvasive: json['is_invasive'] == true,
      speciesGroup: json['species_group'] as String?,
      otherNames: _strings(json['other_names']),
      mainColors: _strings(json['main_colors']),
      visualPattern: json['visual_pattern'] as String?,
      lookalikes: _strings(json['lookalikes']),
      rescueAdvice: json['rescue_advice'] as String?,
    );
  }
}
