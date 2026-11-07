import 'dart:convert';
import 'dart:typed_data';

import 'sighting.dart';

/// Only a reviewed, sanitized sharing form. No session, callback URL or token.
class CommunityShareDraft {
  static const maxPhotoBytes = 4 * 1024 * 1024;
  final Uint8List photo;
  final String hypothesis, municipalityId, notes;
  final IdentificationOrigin origin;
  final DateTime observedOn;
  final List<Municipality> municipalities;

  const CommunityShareDraft({
    required this.photo,
    required this.hypothesis,
    required this.origin,
    required this.observedOn,
    required this.municipalityId,
    required this.municipalities,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
    'photo': base64Encode(photo),
    'hypothesis': hypothesis,
    'origin': origin.name,
    'observed_on': observedOn.toIso8601String(),
    'municipality_id': municipalityId,
    'municipalities': [
      for (final m in municipalities)
        {
          'id': m.id,
          'name': m.name,
          'uf': m.uf,
          'latitude': m.latitude,
          'longitude': m.longitude,
        },
    ],
    'notes': notes,
  };

  factory CommunityShareDraft.fromJson(Map<String, dynamic> json) {
    final encoded = json['photo'] as String;
    if (encoded.length > ((maxPhotoBytes + 2) ~/ 3) * 4) {
      throw const FormatException('Draft photo too large');
    }
    final photo = base64Decode(encoded);
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (photo.length < 8 ||
        photo.length > maxPhotoBytes ||
        !List.generate(8, (i) => photo[i] == signature[i]).every((v) => v)) {
      throw const FormatException('Invalid sanitized draft photo');
    }
    final hypothesis = json['hypothesis'] as String;
    final notes = json['notes'] as String;
    final rows = json['municipalities'] as List;
    if (hypothesis.length > 120 ||
        notes.length > 2000 ||
        rows.isEmpty ||
        rows.length > 1000) {
      throw const FormatException('Invalid sharing draft');
    }
    final municipalities = rows
        .map((row) => Municipality.fromJson(row as Map<String, dynamic>))
        .toList();
    final municipalityId = json['municipality_id'] as String;
    if (!municipalities.any((m) => m.id == municipalityId)) {
      throw const FormatException('Unknown draft municipality');
    }
    return CommunityShareDraft(
      photo: photo,
      hypothesis: hypothesis,
      origin: IdentificationOrigin.values.byName(json['origin'] as String),
      observedOn: DateTime.parse(json['observed_on'] as String),
      municipalityId: municipalityId,
      municipalities: municipalities,
      notes: notes,
    );
  }
}
