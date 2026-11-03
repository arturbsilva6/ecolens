import 'dart:async';

import 'package:flutter/material.dart';

import 'controllers/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'services/supabase_service.dart';

class EcoLensApp extends StatefulWidget {
  final SupabaseService? supabaseService;

  const EcoLensApp({super.key, this.supabaseService});

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // A primeira tela já está disponível, mesmo sem internet ou sessão.
      unawaited(
        (widget.supabaseService ?? SupabaseService.instance).initialize(),
      );
    });
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
