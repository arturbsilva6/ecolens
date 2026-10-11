
import 'package:flutter/material.dart';
import '../../widgets/home/home_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _mostrarMensagem(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              onNotificationsTap: () {
                _mostrarMensagem(
                  context,
                  'Notificações em desenvolvimento',
                );
              },
              onProfileTap: () {
                _mostrarMensagem(
                  context,
                  'Perfil em desenvolvimento',
                );
              },
            ),

            const Expanded(
              child: Center(
                child: Text(
                  'Nossa nova Home começa aqui!',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
