import 'dart:typed_data';

import 'ai_identification_result.dart';

/// Active-flow data only: no date, municipality, catalog photo, or disk storage.
class CommunityIdentificationSeed {
  final Uint8List? originalPhoto;
  final String? hypothesis;
  const CommunityIdentificationSeed({this.originalPhoto, this.hypothesis});
  factory CommunityIdentificationSeed.fromResult(
    AiIdentificationResult result,
    Uint8List? photo,
  ) {
    final common = result.commonName?.trim();
    final scientific = result.scientificName?.trim();
    final names = [
      if (common != null && common.isNotEmpty) common,
      if (scientific != null && scientific.isNotEmpty && scientific != common)
        scientific,
    ];
    final combined = names.join(' — ');
    return CommunityIdentificationSeed(
      originalPhoto: photo,
      hypothesis: result.identified && combined.isNotEmpty
          ? combined.length <= 120
                ? combined
                : scientific != null && scientific.length <= 120
                ? scientific
                : common != null && common.length <= 120
                ? common
                : null
          : null,
    );
  }
}
