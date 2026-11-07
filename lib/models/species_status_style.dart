import 'package:flutter/material.dart';

import 'species_model.dart';

/// Textos, cores e ícones de cada classificação, usados em todas as telas
/// para que a mesma espécie apareça sempre com a mesma tag.
extension SpeciesStatusStyle on SpeciesStatus {
  /// Rótulo curto das tags dos cards.
  String get shortLabel => switch (this) {
    SpeciesStatus.danger => 'Perigo',
    SpeciesStatus.caution => 'Cautela',
    SpeciesStatus.harmless => 'Inofensiva',
    SpeciesStatus.invasive => 'Invasora',
    SpeciesStatus.unverified => 'Demais',
  };

  /// Descrição usada no catálogo e na ficha.
  String get label => switch (this) {
    SpeciesStatus.danger => 'Espécie perigosa',
    SpeciesStatus.caution => 'Exige cautela: evite contato',
    SpeciesStatus.harmless => 'Espécie inofensiva',
    SpeciesStatus.invasive => 'Espécie invasora',
    SpeciesStatus.unverified => 'Sem alerta específico cadastrado',
  };

  /// Vermelho para perigo, laranja para cautela e verde para inofensiva.
  Color get color => switch (this) {
    SpeciesStatus.danger => const Color(0xFFB4232C),
    SpeciesStatus.caution => const Color(0xFFB45309),
    SpeciesStatus.harmless => const Color(0xFF2E7D32),
    SpeciesStatus.invasive => const Color(0xFF98500B),
    SpeciesStatus.unverified => const Color(0xFF526579),
  };

  IconData get icon => switch (this) {
    SpeciesStatus.danger => Icons.warning_amber_rounded,
    SpeciesStatus.caution => Icons.report_problem_outlined,
    SpeciesStatus.harmless => Icons.check_circle_outline,
    SpeciesStatus.invasive => Icons.eco_outlined,
    SpeciesStatus.unverified => Icons.info_outline,
  };
}

extension SpeciesStatusSummary on SpeciesModel {
  /// Classificação com a indicação de invasora quando ela é separada.
  String get statusSummary => isInvasive && status != SpeciesStatus.invasive
      ? '${status.label} · invasora'
      : status.label;
}
