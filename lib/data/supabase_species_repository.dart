import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/species_model.dart';

/// Consulta somente o catálogo de espécies publicadas.
///
/// A política RLS do PostgreSQL também restringe a leitura
/// a registros com is_published = true.
class SupabaseSpeciesRepository {
  final SupabaseClient _client;

  SupabaseSpeciesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<SpeciesModel>> fetchPublishedSpecies() async {
    final rows = await _client
        .from('species')
        .select(
          'common_name,scientific_name,status,description,'
          'characteristics,habitat,risk_description,safety_advice,'
          'source_name,source_url',
        )
        .eq('is_published', true)
        .order('common_name');

    return rows.map((row) {
      final status = switch (row['status']) {
        'danger' => SpeciesStatus.danger,
        'invasive' => SpeciesStatus.invasive,
        _ => SpeciesStatus.unverified,
      };

      return SpeciesModel(
        commonName: row['common_name'] as String,
        scientificName: row['scientific_name'] as String,
        status: status,
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
