import 'package:flutter/material.dart';

import '../../widgets/home/region_alert_carousel.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/identification_banner.dart';
import '../../widgets/home/species_search_bar.dart';
import '../../widgets/home/quick_access_section.dart';
import '../../models/species_model.dart';
import '../../widgets/home/recent_species_section.dart';
import '../../widgets/home/bottom_nav_bar.dart';
import '../../controllers/theme_controller.dart';
import '../settings/settings_screen.dart';
import '../community/community_screen.dart';
import '../map/heat_map_screen.dart';
import '../profile/profile_screen.dart';
import '../identification/identification_screen.dart';
import '../identification/identification_history_screen.dart';
import '../species/species_catalog_screen.dart';
import '../species/favorites_screen.dart';
import '../species/species_detail_screen.dart';
import '../sos/sos_screen.dart';
import '../../utils/species_catalog_filter.dart';
import '../../widgets/intro/intro_status.dart';
import '../../widgets/onboarding/onboarding_tour.dart';

class HomeScreen extends StatefulWidget {
  final ThemeController themeController;
  final Future<List<SpeciesModel>> Function()? fetchPublishedSpecies;
  final VoidCallback? onProfileTap;

  /// Telas abertas pelo menu inferior e pelo atalho do fórum. Os testes
  /// substituem estas telas para não depender do Supabase nem de tiles.
  final WidgetBuilder mapBuilder;
  final WidgetBuilder communityBuilder;

  /// Mostra o tour de primeiro contato (só no app real; desligado nos testes).
  final bool showTour;

  const HomeScreen({
    super.key,
    required this.themeController,
    this.fetchPublishedSpecies,
    this.onProfileTap,
    this.mapBuilder = _defaultMap,
    this.communityBuilder = _defaultCommunity,
    this.showTour = false,
  });

  static Widget _defaultMap(BuildContext context) => const HeatMapScreen();
  static Widget _defaultCommunity(BuildContext context) =>
      const CommunityScreen();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _identifyKey = GlobalKey();
  final _shortcutsKey = GlobalKey();
  final _sosKey = GlobalKey();
  final _navKey = GlobalKey();
  bool _tourScheduled = false;

  ThemeController get themeController => widget.themeController;
  Future<List<SpeciesModel>> Function()? get fetchPublishedSpecies =>
      widget.fetchPublishedSpecies;
  VoidCallback? get onProfileTap => widget.onProfileTap;
  WidgetBuilder get mapBuilder => widget.mapBuilder;
  WidgetBuilder get communityBuilder => widget.communityBuilder;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Só depois da abertura animada, e só na primeira vez.
    if (!widget.showTour || _tourScheduled || !IntroStatus.doneOf(context)) {
      return;
    }
    _tourScheduled = true;
    _maybeStartTour();
  }

  Future<void> _maybeStartTour() async {
    if (await OnboardingTour.seen()) return;
    // Deixa o galho do cabeçalho aparecer antes de escurecer a tela.
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    await _startTour();
  }

  Future<void> _startTour() {
    // Cinco destinos de mesma largura na barra inferior.
    Rect slots(Rect bar, int first, int count) => Rect.fromLTWH(
      bar.left + bar.width * first / 5,
      bar.top,
      bar.width * count / 5,
      bar.height,
    );
    return OnboardingTour.show(context, [
      TourStep(
        target: _identifyKey,
        title: 'Identifique pela foto',
        text:
            'Tire uma foto ou escolha uma da galeria. A IA sugere a espécie '
            'e mostra se ela está no catálogo. A sugestão não é uma '
            'confirmação.',
      ),
      TourStep(
        target: _shortcutsKey,
        title: 'Atalhos',
        text:
            'Seus favoritos, o histórico de identificações, as espécies '
            'perigosas da região e os primeiros socorros.',
      ),
      TourStep(
        target: _sosKey,
        title: 'SOS',
        text:
            'Em uma emergência, toque aqui para ligar para o SAMU, o Corpo de '
            'Bombeiros ou o resgate de fauna e ver o que fazer em caso de '
            'picada.',
      ),
      TourStep(
        target: _navKey,
        area: (bar) => slots(bar, 2, 2),
        title: 'Mapa e Comunidade',
        text:
            'Veja onde as espécies foram avistadas e registre os seus '
            'avistamentos, sempre pelo município, sem localização exata.',
      ),
      TourStep(
        target: _navKey,
        area: (bar) => slots(bar, 4, 1),
        title: 'Perfil',
        text:
            'Entre para publicar na Comunidade. O catálogo, a identificação '
            'e o SOS funcionam sem conta. Para ver este tour de novo, use '
            'Configurações.',
      ),
    ]);
  }

  void _mostrarMensagem(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  void _abrirIdentificacao(
    BuildContext context, {
    IdentificationSource? initialSource,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            IdentificationScreen(initialSource: initialSource),
      ),
    );
  }

  void _abrirSos(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => const SosScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: _sosKey,
        heroTag: 'ecolens-sos-home',
        tooltip: 'Abrir SOS ambiental',
        onPressed: () => _abrirSos(context),
        icon: const Icon(Icons.shield_outlined),
        label: const Text('SOS'),
        backgroundColor: const Color(0xFFD9292F),
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: EcoLensBottomNavBar(
        key: _navKey,
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 0) return;
          if (index == 1) {
            _abrirIdentificacao(context);
            return;
          }
          if (index == 4) {
            if (onProfileTap != null) {
              onProfileTap!();
            } else {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              );
            }
            return;
          }
          if (index == 2 || index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: index == 2 ? mapBuilder : communityBuilder,
              ),
            );
          }
        },
      ),

      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              onSettingsTap: () async {
                final result = await Navigator.of(context).push<String>(
                  MaterialPageRoute<String>(
                    builder: (context) =>
                        SettingsScreen(themeController: themeController),
                  ),
                );
                // "Ver o tour de novo" em Configurações volta para cá.
                if (result == SettingsScreen.replayTour && mounted) {
                  await _startTour();
                }
              },
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  IdentificationBanner(
                    key: _identifyKey,
                    onCameraTap: () {
                      _abrirIdentificacao(
                        context,
                        initialSource: IdentificationSource.camera,
                      );
                    },
                    onGalleryTap: () {
                      _abrirIdentificacao(
                        context,
                        initialSource: IdentificationSource.gallery,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  SpeciesSearchBar(
                    onSearch: (texto) {
                      if (texto.isEmpty) {
                        _mostrarMensagem(
                          context,
                          'Digite o nome de uma espécie',
                        );
                        return;
                      }

                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              SpeciesCatalogScreen(initialQuery: texto),
                        ),
                      );
                    },

                    onFilterTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const SpeciesCatalogScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  QuickAccessSection(
                    key: _shortcutsKey,
                    onFavoritesTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const FavoritesScreen(),
                        ),
                      );
                    },
                    onVenomousTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const SpeciesCatalogScreen(
                            initialFilter: SpeciesCatalogFilter.danger,
                          ),
                        ),
                      );
                    },
                    onFirstAidTap: () => _abrirSos(context),
                    onHistoryTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              const IdentificationHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  RegionAlertCarousel(
                    fetchPublishedSpecies: fetchPublishedSpecies,
                    onSpeciesTap: (species) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => SpeciesDetailScreen(
                            species: species,
                            isDemonstration: false,
                          ),
                        ),
                      );
                    },
                    onViewAllTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const SpeciesCatalogScreen(
                            initialFilter: SpeciesCatalogFilter.danger,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  RecentSpeciesSection(
                    fetchPublishedSpecies: fetchPublishedSpecies,

                    onSpeciesTap: (species) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => SpeciesDetailScreen(
                            species: species,
                            isDemonstration: false,
                          ),
                        ),
                      );
                    },

                    onViewAllTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const SpeciesCatalogScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
