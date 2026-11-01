import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/supabase_species_repository.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurações fornecidas na execução do aplicativo.
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  // Inicializa o Supabase somente quando configurado.
  if (supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );

    try {
      final especies = await SupabaseSpeciesRepository()
          .fetchPublishedSpecies();

      debugPrint('Supabase conectado: ${especies.length} espécies publicadas.');
    } catch (erro) {
      debugPrint('Erro na consulta: ${erro.runtimeType}');
    }
  }

  runApp(const EcoLensApp());
}
