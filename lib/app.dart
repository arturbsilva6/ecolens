import 'package:flutter/material.dart';

import 'controllers/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

class EcoLensApp extends StatefulWidget {
  const EcoLensApp({super.key});

  @override
  State<EcoLensApp> createState() => _EcoLensAppState();
}

class _EcoLensAppState extends State<EcoLensApp> {
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();

    _themeController = ThemeController();

    // Recupera o tema salvo anteriormente
    _themeController.loadTheme();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, child) {
        return MaterialApp(
          title: 'EcoLens',
          debugShowCheckedModeBanner: false,

          // Temas disponíveis
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,

          // Tema controlado pelo ThemeController
          themeMode: _themeController.themeMode,

          home: HomeScreen(themeController: _themeController),
        );
      },
    );
  }
}
