import 'package:flutter/material.dart';

import '../../widgets/home/sos_banner.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/identification_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _mostrarMensagem(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              onNotificationsTap: () {
                _mostrarMensagem(context, 'Notificações em desenvolvimento');
              },
              onProfileTap: () {
                _mostrarMensagem(context, 'Perfil em desenvolvimento');
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
                      _mostrarMensagem(context, 'Câmera em desenvolvimento');
                    },
                    onGalleryTap: () {
                      _mostrarMensagem(context, 'Galeria em desenvolvimento');
                    },
                  ),
                  const SizedBox(height: 16),

                  SosBanner(
                    onSosTap: () {
                      _mostrarMensagem(context, 'Tela SOS em desenvolvimento');
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
