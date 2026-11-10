class Municipality {
  final String id, name, uf;
  final double latitude, longitude;
  const Municipality(
    this.id,
    this.name,
    this.uf,
    this.latitude,
    this.longitude,
  );
  String get label => '$name/$uf';
  factory Municipality.fromJson(Map<String, dynamic> row) => Municipality(
    row['id'] as String,
    row['name'] as String,
    row['uf'] as String,
    (row['latitude'] as num).toDouble(),
    (row['longitude'] as num).toDouble(),
  );
}

/// Neither a user's identification nor an AI suggestion is scientific validation.
enum IdentificationOrigin { unknown, user, ai }

class Sighting {
  final String id, ownerId, municipalityId, photoPath;
  final String? species;
  final String notes;
  final DateTime observedOn;
  final IdentificationOrigin origin;
  final String status;

  /// Quando o autor alterou o registro depois de publicado.
  final DateTime? editedAt;

  /// Quando o registro foi ocultado por denúncias (só o autor ainda o vê).
  final DateTime? hiddenAt;
  const Sighting({
    required this.id,
    required this.ownerId,
    required this.municipalityId,
    required this.photoPath,
    required this.observedOn,
    this.species,
    this.notes = '',
    this.origin = IdentificationOrigin.unknown,
    this.status = 'published',
    this.editedAt,
    this.hiddenAt,
  });
  bool get edited => editedAt != null;
  bool get hidden => hiddenAt != null;
  String get speciesLabel => species ?? 'Espécie não identificada';
  String get identificationLabel => switch (origin) {
    IdentificationOrigin.unknown => 'Espécie não identificada',
    IdentificationOrigin.user =>
      'Identificação informada pelo usuário — não verificada',
    IdentificationOrigin.ai => 'Sugestão de IA — não verificada',
  };
  factory Sighting.fromJson(Map<String, dynamic> row) => Sighting(
    id: row['id'] as String,
    ownerId: row['owner_id'] as String,
    municipalityId: row['municipality_id'] as String,
    photoPath: row['photo_path'] as String,
    species: row['species_label'] as String?,
    notes: row['notes'] as String,
    observedOn: DateTime.parse(row['observed_on'] as String),
    origin: IdentificationOrigin.values.byName(
      row['identification_origin'] as String,
    ),
    status: row['status'] as String,
    editedAt: DateTime.tryParse(row['edited_at'] as String? ?? ''),
    hiddenAt: DateTime.tryParse(row['hidden_at'] as String? ?? ''),
  );
}

/// Motivos de denúncia aceitos pelo servidor.
enum ReportReason {
  offensive('Conteúdo ofensivo ou abusivo'),
  spam('Spam ou propaganda'),
  wrongInfo('Informação falsa ou perigosa'),
  inappropriatePhoto('Foto imprópria'),
  other('Outro motivo');

  const ReportReason(this.label);
  final String label;

  String get code => switch (this) {
    offensive => 'offensive',
    spam => 'spam',
    wrongInfo => 'wrong_info',
    inappropriatePhoto => 'inappropriate_photo',
    other => 'other',
  };
}

class SightingDraft {
  final DateTime observedOn;
  final String municipalityId, notes;
  final String? species;
  final IdentificationOrigin origin;
  const SightingDraft({
    required this.observedOn,
    required this.municipalityId,
    this.notes = '',
    this.species,
    this.origin = IdentificationOrigin.unknown,
  });
  Map<String, dynamic> toJson() => {
    'observed_on': observedOn.toIso8601String().substring(0, 10),
    'municipality_id': municipalityId,
    'notes': notes.trim(),
    'species_label': species?.trim(),
    'identification_origin': origin.name,
  };
}
