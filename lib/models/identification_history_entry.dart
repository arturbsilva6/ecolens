import '../models/ai_identification_result.dart';

/// Somente metadados textuais. Nunca armazena a fotografia ou tokens da IA.
class IdentificationHistoryEntry {
  final String id;
  final DateTime createdAt;
  final bool identified;
  final String? commonName;
  final String? scientificName;
  final String explanation;
  final bool matchedCatalog;

  const IdentificationHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.identified,
    required this.commonName,
    required this.scientificName,
    required this.explanation,
    required this.matchedCatalog,
  });

  factory IdentificationHistoryEntry.fromResult(
    AiIdentificationResult result, {
    required DateTime createdAt,
    required bool matchedCatalog,
  }) {
    final instant = createdAt.toUtc();
    return IdentificationHistoryEntry(
      id: instant.microsecondsSinceEpoch.toString(),
      createdAt: instant,
      identified: result.identified,
      commonName: result.commonName,
      scientificName: result.scientificName,
      explanation: result.explanation,
      matchedCatalog: matchedCatalog,
    );
  }

  String get displayName =>
      (identified ? commonName ?? scientificName : null) ??
      'Análise inconclusiva';

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'identified': identified,
    'commonName': commonName,
    'scientificName': scientificName,
    'explanation': explanation,
    'matchedCatalog': matchedCatalog,
  };

  factory IdentificationHistoryEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final date = json['createdAt'];
    final explanation = json['explanation'];
    final identified = json['identified'];
    if (id is! String ||
        id.isEmpty ||
        date is! String ||
        explanation is! String ||
        identified is! bool) {
      throw const FormatException('Registro de identificação inválido.');
    }
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) {
      throw const FormatException('Data do registro inválida.');
    }
    final commonName = json['commonName'];
    final scientificName = json['scientificName'];
    return IdentificationHistoryEntry(
      id: id,
      createdAt: parsedDate.toUtc(),
      identified: identified,
      commonName: commonName is String ? commonName : null,
      scientificName: scientificName is String ? scientificName : null,
      explanation: explanation,
      matchedCatalog: json['matchedCatalog'] == true,
    );
  }
}
