import 'dart:async';

import 'package:flutter/material.dart';

import 'controllers/theme_controller.dart';
import 'controllers/auth_controller.dart';
import 'data/supabase_auth_repository.dart';
import 'screens/profile/profile_screen.dart';
import 'models/species_model.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'services/supabase_service.dart';

class EcoLensApp extends StatefulWidget {
  final SupabaseService? supabaseService;
  final Future<List<SpeciesModel>> Function()? fetchPublishedSpecies;
  final AuthController? authController;

  const EcoLensApp({
    super.key,
    this.supabaseService,
    this.fetchPublishedSpecies,
    this.authController,
  });

  @override
  State<EcoLensApp> createState() => _EcoLensAppState();
}

class _EcoLensAppState extends State<EcoLensApp> {
  late final ThemeController _themeController;
  late final AuthController _authController;
  final _navigatorKey = GlobalKey<NavigatorState>();
  int _callbackRevision = 0;
  bool _profileOpen = false;

  @override
  void initState() {
    super.initState();

    _themeController = ThemeController();
    _authController =
        widget.authController ??
        AuthController(
          repository: SupabaseAuthRepository(service: widget.supabaseService),
        );
    _authController.addListener(_onAuthChanged);

    // Recupera o tema salvo anteriormente
    _themeController.loadTheme();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // A primeira tela já está disponível, mesmo sem internet ou sessão.
      unawaited(
        (widget.supabaseService ?? SupabaseService.instance).initialize(),
      );
      unawaited(_authController.initialize());
    });
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    if (widget.authController == null) _authController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted || _authController.callbackRevision == _callbackRevision) {
      return;
    }
    _callbackRevision = _authController.callbackRevision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openProfile();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _openProfile() {
    if (_profileOpen || _navigatorKey.currentState == null) return;
    _profileOpen = true;
    _navigatorKey.currentState!
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ProfileScreen(controller: _authController),
          ),
        )
        .whenComplete(() {
          _profileOpen = false;
        });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          // O callback é processado por AuthRepository, não como rota nomeada.
          initialRoute: '/',
          title: 'EcoLens',
          debugShowCheckedModeBanner: false,

          // Temas disponíveis
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,

          // Tema controlado pelo ThemeController
          themeMode: _themeController.themeMode,

          home: HomeScreen(
            themeController: _themeController,
            fetchPublishedSpecies: widget.fetchPublishedSpecies,
            onProfileTap: _openProfile,
          ),
        );
      },
    );
  }
}
