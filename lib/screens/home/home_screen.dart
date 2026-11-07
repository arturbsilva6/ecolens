import 'package:flutter/material.dart';

import '../../widgets/home/sos_banner.dart';
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

class HomeScreen extends StatelessWidget {
  final ThemeController themeController;
  final Future<List<SpeciesModel>> Function()? fetchPublishedSpecies;
  final VoidCallback? onProfileTap;

  /// Telas abertas pelo menu inferior e pelo atalho do fórum. Os testes
  /// substituem estas telas para não depender do Supabase nem de tiles.
  final WidgetBuilder mapBuilder;
  final WidgetBuilder communityBuilder;

  const HomeScreen({
    super.key,
    required this.themeController,
    this.fetchPublishedSpecies,
    this.onProfileTap,
    this.mapBuilder = _defaultMap,
    this.communityBuilder = _defaultCommunity,
  });

  static Widget _defaultMap(BuildContext context) => const HeatMapScreen();
  static Widget _defaultCommunity(BuildContext context) =>
      const CommunityScreen();

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
              onNotificationsTap: () {
                _mostrarMensagem(context, 'Notificações em desenvolvimento');
              },
              onSettingsTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        SettingsScreen(themeController: themeController),
                  ),
                );
              },
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  IdentificationBanner(
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

                  SosBanner(onSosTap: () => _abrirSos(context)),
                  const SizedBox(height: 24),

                  QuickAccessSection(
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
                    onForumTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: communityBuilder),
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
