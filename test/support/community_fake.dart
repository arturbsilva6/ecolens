import 'dart:typed_data';

import 'package:ecolens/data/community_repository.dart';
import 'package:ecolens/models/sighting.dart';

const municipality = Municipality(
  '3550605',
  'São Roque',
  'SP',
  -23.5226,
  -47.1357,
);
Sighting fixture({
  String id = 'one',
  String owner = 'author',
  String status = 'published',
}) => Sighting(
  id: id,
  ownerId: owner,
  municipalityId: municipality.id,
  photoPath: '$id.png',
  observedOn: DateTime(2026, 10, 1),
  status: status,
);

class CommunityFake implements CommunityRepository {
  String? user;
  List<Sighting> items = [];
  int calls = 0, deletions = 0, updates = 0, creations = 0;
  bool fail = false, failDelete = false;
  @override
  Future<String?> accountId() async => user;
  @override
  Future<List<Municipality>> municipalities() async => [municipality];
  @override
  Future<List<Sighting>> page({
    int offset = 0,
    String? municipalityId,
    String species = '',
    bool mine = false,
  }) async {
    calls++;
    if (fail) throw const CommunityFailure('Falha de rede');
    return items
        .where(
          (s) =>
              (!mine || s.ownerId == user) &&
              (municipalityId == null || s.municipalityId == municipalityId) &&
              (species.isEmpty || (s.species ?? '').contains(species)),
        )
        .skip(offset)
        .take(20)
        .toList();
  }

  @override
  Future<Uint8List> photo(String path) async =>
      throw const CommunityFailure('Foto indisponível');
  @override
  Future<void> create(SightingDraft draft, Uint8List sanitizedPhoto) async {
    creations++;
  }

  @override
  Future<void> update(Sighting sighting, SightingDraft draft) async {
    updates++;
  }

  @override
  Future<void> delete(Sighting sighting) async {
    if (failDelete) throw const CommunityFailure('Exclusão não confirmada');
    deletions++;
    items.removeWhere((s) => s.id == sighting.id);
  }
}
