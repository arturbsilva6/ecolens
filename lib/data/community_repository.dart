import 'dart:typed_data';

import '../models/sighting.dart';

class CommunityFailure implements Exception {
  final String message;
  const CommunityFailure(this.message);
  @override
  String toString() => message;
}

class CommunityPublicationUncertain extends CommunityFailure {
  const CommunityPublicationUncertain()
    : super(
        'Não foi possível confirmar a publicação. Consulte Meus registros antes de tentar de novo. Um rascunho pode ser excluído; um registro publicado já está visível.',
      );
}

abstract class CommunityRepository {
  Future<String?> accountId();
  Future<List<Municipality>> municipalities();
  Future<List<Sighting>> page({
    int offset = 0,
    String? municipalityId,
    String species = '',
    bool mine = false,
  });
  Future<Uint8List> photo(String path);
  Future<Sighting> create(SightingDraft draft, Uint8List sanitizedPhoto);
  Future<void> update(Sighting sighting, SightingDraft draft);
  Future<void> delete(Sighting sighting);

  /// Denuncia um registro de outra pessoa. Com denúncias de três pessoas
  /// diferentes, o servidor oculta o registro.
  Future<void> report(Sighting sighting, ReportReason reason, String details);
}
