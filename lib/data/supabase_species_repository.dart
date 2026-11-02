import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/species_model.dart';

/// Consulta somente o catálogo de espécies publicadas.
///
/// A política RLS do PostgreSQL também restringe a leitura
/// a registros com is_published = true.
class SupabaseSpeciesRepository {
  // Somente URLs verificadas com crédito e condições de reutilização.
  // Não exibir imagens desconhecidas sem confirmar os direitos de uso.
  static const _licensedImages = <
      String,
      ({
        String credit,
        String sourceUrl,
        String licenseUrl,
        String licenseLabel,
      })>{
    'https://upload.wikimedia.org/wikipedia/commons/8/88/'
        'Bothrops_jararaca_1.jpg': (
      credit: 'Felipe Süssekind',
      sourceUrl:
          'https://commons.wikimedia.org/wiki/File:Bothrops_jararaca_1.jpg',
      licenseUrl: 'https://creativecommons.org/licenses/by/2.0/',
      licenseLabel: 'CC BY 2.0',
    ),
    'https://upload.wikimedia.org/wikipedia/commons/9/99/'
        'Tityus_serrulatus_%28Buthidae%29_%2822768698194%29.jpg': (
      credit: 'José Roberto Peruca',
      sourceUrl:
          'https://commons.wikimedia.org/wiki/'
          'File:Tityus_serrulatus_(Buthidae)_(22768698194).jpg',
      licenseUrl: 'https://creativecommons.org/licenses/by/2.0/',
      licenseLabel: 'CC BY 2.0',
    ),
    'https://upload.wikimedia.org/wikipedia/commons/c/c2/'
        'Wild_boar_%28Sus_scrofa%29.jpg': (
      credit: 'Bramans',
      sourceUrl:
          'https://commons.wikimedia.org/wiki/File:Wild_boar_(Sus_scrofa).jpg',
      licenseUrl: 'https://creativecommons.org/licenses/by-sa/4.0/',
      licenseLabel: 'CC BY-SA 4.0',
    ),
    'https://upload.wikimedia.org/wikipedia/commons/4/49/'
        'Leucaena_leucocephala.jpg': (
      credit: 'Scott Bauer / USDA-ARS',
      sourceUrl:
          'https://commons.wikimedia.org/wiki/File:Leucaena_leucocephala.jpg',
      licenseUrl:
          'https://commons.wikimedia.org/wiki/File:Leucaena_leucocephala.jpg',
      licenseLabel: 'Domínio público',
    ),
  };

  final SupabaseClient _client;

  SupabaseSpeciesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<SpeciesModel>> fetchPublishedSpecies() async {
    final rows = await _client
        .from('species')
        .select(
          'common_name,scientific_name,status,description,'
          'characteristics,habitat,risk_description,safety_advice,'
          'source_name,source_url,image_url',
        )
        .eq('is_published', true)
        .order('common_name');

    return rows.map((row) {
      final imageUrl = row['image_url'] as String?;
      final photo = imageUrl == null ? null : _licensedImages[imageUrl];

      final status = switch (row['status']) {
        'danger' => SpeciesStatus.danger,
        'invasive' => SpeciesStatus.invasive,
        _ => SpeciesStatus.unverified,
      };

      return SpeciesModel(
        commonName: row['common_name'] as String,
        scientificName: row['scientific_name'] as String,
        status: status,
        imageUrl: photo == null ? null : imageUrl,
        imageCredit: photo?.credit,
        imageSourceUrl: photo?.sourceUrl,
        imageLicenseUrl: photo?.licenseUrl,
        imageLicenseLabel: photo?.licenseLabel,
        description: row['description'] as String?,
        characteristics: row['characteristics'] as String?,
        habitat: row['habitat'] as String?,
        riskDescription: row['risk_description'] as String?,
        safetyAdvice: row['safety_advice'] as String?,
        sourceName: row['source_name'] as String?,
        sourceUrl: row['source_url'] as String?,
      );
    }).toList(growable: false);
  }
}
