import 'package:ecolens/controllers/auth_controller.dart';
import 'package:ecolens/controllers/theme_controller.dart';
import 'package:ecolens/core/theme/app_theme.dart';
import 'package:ecolens/models/species_model.dart';
import 'package:ecolens/screens/community/community_screen.dart';
import 'package:ecolens/screens/home/home_screen.dart';
import 'package:ecolens/screens/identification/identification_history_screen.dart';
import 'package:ecolens/screens/identification/identification_screen.dart';
import 'package:ecolens/screens/map/heat_map_screen.dart';
import 'package:ecolens/screens/profile/profile_screen.dart';
import 'package:ecolens/screens/settings/about_screen.dart';
import 'package:ecolens/screens/settings/accessibility_screen.dart';
import 'package:ecolens/screens/settings/privacy_policy_screen.dart';
import 'package:ecolens/screens/settings/privacy_screen.dart';
import 'package:ecolens/screens/settings/settings_screen.dart';
import 'package:ecolens/screens/sos/sos_screen.dart';
import 'package:ecolens/screens/species/favorites_screen.dart';
import 'package:ecolens/screens/species/species_catalog_screen.dart';
import 'package:ecolens/screens/species/species_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/community_fake.dart';
import 'support/fake_auth_repository.dart';

/// Diretrizes automáticas de acessibilidade do Flutter nas telas principais:
/// área de toque mínima de 48 dp, botões com rótulo para o leitor de tela e
/// contraste de texto, nos temas claro e escuro.
const _danger = SpeciesModel(
  commonName: 'Jararaca',
  scientificName: 'Bothrops jararaca',
  status: SpeciesStatus.danger,
  description: 'Serpente peçonhenta comum na região.',
);
const _harmless = SpeciesModel(
  commonName: 'Capivara',
  scientificName: 'Hydrochoerus hydrochaeris',
  status: SpeciesStatus.harmless,
);

Future<List<SpeciesModel>> _species() async => const [_danger, _harmless];

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  final screens = <String, Widget Function()>{
    'Home': () => HomeScreen(
      themeController: ThemeController(),
      fetchPublishedSpecies: _species,
    ),
    'Catálogo': () => SpeciesCatalogScreen(fetchPublishedSpecies: _species),
    'Ficha da espécie': () => const SpeciesDetailScreen(species: _danger),
    'Favoritos': () => const FavoritesScreen(fetchPublishedSpecies: _species),
    'Identificação': () => const IdentificationScreen(),
    'Histórico': () => const IdentificationHistoryScreen(),
    'Comunidade': () => CommunityScreen(repository: CommunityFake()),
    'Mapa': () => HeatMapScreen(repository: CommunityFake(), loadTiles: false),
    'Perfil (visitante)': () => ProfileScreen(
      controller: AuthController(repository: FakeAuthRepository()),
    ),
    'SOS': () => const SosScreen(),
    'Configurações': () => SettingsScreen(themeController: ThemeController()),
    'Acessibilidade': () =>
        AccessibilityScreen(themeController: ThemeController()),
    'Privacidade': () => const PrivacyScreen(),
    'Política de privacidade': () => const PrivacyPolicyScreen(),
    'Sobre': () => const AboutScreen(),
  };

  for (final dark in [false, true]) {
    final theme = dark ? 'escuro' : 'claro';
    for (final MapEntry(key: name, value: build) in screens.entries) {
      testWidgets('$name segue as diretrizes de acessibilidade ($theme)', (
        tester,
      ) async {
        tester.view
          ..physicalSize = const Size(1080, 2340)
          ..devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: build(),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });
    }
  }
}
