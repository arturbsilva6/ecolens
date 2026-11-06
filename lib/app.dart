import 'dart:async';

import 'package:flutter/material.dart';

import 'controllers/theme_controller.dart';
import 'widgets/auth/account_navigation_scope.dart';
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
  Future<void>? _profileNavigation;

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

  Future<void> _openProfile({String? returnLabel}) {
    final pending = _profileNavigation;
    if (pending != null) return pending;
    if (_navigatorKey.currentState == null) return Future.value();
    final navigation = _showProfile(returnLabel);
    _profileNavigation = navigation;
    navigation.whenComplete(() {
      _profileNavigation = null;
    });
    return navigation;
  }

  Future<void> _showProfile(String? returnLabel) async {
    if (returnLabel != null) await _authController.synchronizeSession();
    if (!mounted || _navigatorKey.currentState == null) return;
    await _navigatorKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(
          controller: _authController,
          returnLabel: returnLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          builder: (context, child) =>
              AccountNavigationScope(openAccount: _openProfile, child: child!),
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
