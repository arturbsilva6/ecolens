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
import '../identification/identification_screen.dart';

class HomeScreen extends StatelessWidget {
  final ThemeController themeController;

  const HomeScreen({super.key, required this.themeController});
  static const List<SpeciesModel> _recentSpecies = [
    SpeciesModel(
      commonName: 'Jararaca',
      scientificName: 'Bothrops jararaca',
      status: SpeciesStatus.danger,
      imagePath: 'assets/images/jararaca.jpg',
    ),
    SpeciesModel(
      commonName: 'Cambará',
      scientificName: 'Lantana camara',
      status: SpeciesStatus.invasive,
      imagePath: 'assets/images/cambara.jpg',
    ),
    SpeciesModel(
      commonName: 'Sagui',
      scientificName: 'Callithrix sp.',
      imagePath: 'assets/images/sagui_banner.jpg',
      status: SpeciesStatus.unverified,
    ),
  ];

  void _mostrarMensagem(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  void _abrirIdentificacao(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const IdentificationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: EcoLensBottomNavBar(
        selectedIndex: 0,

        onDestinationSelected: (index) {
          if (index == 0) return;

          // Abre a tela de identificação
          if (index == 1) {
            _abrirIdentificacao(context);
            return;
          }

          const paginas = [
            'Início',
            'Identificar',
            'Mapa',
            'Comunidade',
            'Perfil',
          ];

          _mostrarMensagem(context, '${paginas[index]} em desenvolvimento');
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  IdentificationBanner(
                    onCameraTap: () {
                      _abrirIdentificacao(context);
                    },
                    onGalleryTap: () {
                      _abrirIdentificacao(context);
                    },
                  ),
                  const SizedBox(height: 16),

                  SosBanner(
                    onSosTap: () {
                      _mostrarMensagem(context, 'Tela SOS em desenvolvimento');
                    },
                  ),

                  const SizedBox(height: 20),
                  SpeciesSearchBar(
                    onSearch: (texto) {
                      if (texto.isEmpty) {
                        _mostrarMensagem(
                          context,
                          'Digite o nome de uma espécie',
                        );
                        return;
                      }

                      _mostrarMensagem(
                        context,
                        'Pesquisa por "$texto" em desenvolvimento',
                      );
                    },

                    onFilterTap: () {
                      _mostrarMensagem(context, 'Filtros em desenvolvimento');
                    },
                  ),

                  const SizedBox(height: 24),

                  QuickAccessSection(
                    onVenomousTap: () {
                      _mostrarMensagem(
                        context,
                        'Animais peçonhentos em desenvolvimento',
                      );
                    },
                    onFirstAidTap: () {
                      _mostrarMensagem(
                        context,
                        'Primeiros socorros em desenvolvimento',
                      );
                    },
                    onHistoryTap: () {
                      _mostrarMensagem(
                        context,
                        'Meus registros em desenvolvimento',
                      );
                    },
                    onForumTap: () {
                      _mostrarMensagem(
                        context,
                        'Fórum local em desenvolvimento',
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  RecentSpeciesSection(
                    species: _recentSpecies,

                    onSpeciesTap: (species) {
                      _mostrarMensagem(
                        context,
                        'Detalhes de ${species.commonName} em desenvolvimento',
                      );
                    },

                    onViewAllTap: () {
                      _mostrarMensagem(
                        context,
                        'Todos os registros em desenvolvimento',
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
