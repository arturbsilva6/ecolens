/// Saída preliminar de IA. Não é identificação taxonômica confirmada.
class AiIdentificationResult {
  final bool identified;
  final String? commonName;
  final String? scientificName;
  final String explanation;

  const AiIdentificationResult({
    required this.identified,
    required this.commonName,
    required this.scientificName,
    required this.explanation,
  });

  factory AiIdentificationResult.fromJson(Map<String, dynamic> data) {
    final identified = data['identified'] == true;
    String? clean(Object? value) {
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final common = clean(data['commonName']);
    final scientific = clean(data['scientificName']);
    final explanation = clean(data['explanation']) ??
        'Não há dados suficientes para sugerir uma espécie.';

    // Sem sugestão utilizável, o resultado é sempre inconclusivo.
    final hasSuggestion = common != null || scientific != null;
    return AiIdentificationResult(
      identified: identified && hasSuggestion,
      commonName: identified && hasSuggestion ? common : null,
      scientificName: identified && hasSuggestion ? scientific : null,
      explanation: explanation,
    );
  }
}
