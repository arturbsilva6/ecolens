
enum SpeciesStatus {
  danger,
  invasive,
  unverified,
}

class SpeciesModel {
  final String commonName;
  final String scientificName;
  final String? imagePath;
  final SpeciesStatus status;

  const SpeciesModel({
    required this.commonName,
    required this.scientificName,
    this.imagePath,
    required this.status,
  });
}
