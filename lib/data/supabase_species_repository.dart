import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/species_model.dart';

/// Consulta somente o catálogo de espécies publicadas.
///
/// A política RLS do PostgreSQL também restringe a leitura
/// a registros com is_published = true.
class SupabaseSpeciesRepository {
  // Fotografia com autoria/licença conferidas no Wikimedia Commons.
  // Outras fotografias exigirão cadastro de créditos próprio.
  static const _licensedJararacaPhoto =
      'https://upload.wikimedia.org/wikipedia/commons/8/88/'
      'Bothrops_jararaca_1.jpg';


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
      final hasLicensedPhoto = imageUrl == _licensedJararacaPhoto;

      final status = switch (row['status']) {
        'danger' => SpeciesStatus.danger,
        'invasive' => SpeciesStatus.invasive,
        _ => SpeciesStatus.unverified,
      };

      return SpeciesModel(
        commonName: row['common_name'] as String,
        scientificName: row['scientific_name'] as String,
        status: status,
        imageUrl: hasLicensedPhoto ? imageUrl : null,
        imageCredit: hasLicensedPhoto ? 'Felipe Süssekind' : null,
        imageSourceUrl: hasLicensedPhoto
            ? 'https://commons.wikimedia.org/wiki/File:Bothrops_jararaca_1.jpg'
            : null,
        imageLicenseUrl: hasLicensedPhoto
            ? 'https://creativecommons.org/licenses/by/2.0/'
            : null,
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
