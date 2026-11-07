import 'dart:async';

import 'package:flutter/material.dart';

import 'controllers/theme_controller.dart';
import 'widgets/auth/account_navigation_scope.dart';
import 'controllers/auth_controller.dart';
import 'data/supabase_auth_repository.dart';
import 'data/community_repository.dart';
import 'data/supabase_community_repository.dart';
import 'data/share_identification_draft_store.dart';
import 'screens/community/sighting_form_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'models/species_model.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'services/supabase_service.dart';

class EcoLensApp extends StatefulWidget {
  final SupabaseService? supabaseService;
  final Future<List<SpeciesModel>> Function()? fetchPublishedSpecies;
  final AuthController? authController;
  final ShareIdentificationDraftStore? shareDraftStore;
  final CommunityRepository? communityRepository;

  const EcoLensApp({
    super.key,
    this.supabaseService,
    this.fetchPublishedSpecies,
    this.authController,
    this.shareDraftStore,
    this.communityRepository,
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
  Future<void> _draftRestoration = Future.value();
  bool _restoredSharingForm = false;
  ShareIdentificationDraftStore get _draftStore =>
      widget.shareDraftStore ?? ShareIdentificationDraftStore();

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
      // Restore the caller independently of auth outcome, including cold starts
      // and browser cancellation. Home/SOS stay available while storage loads.
      _draftRestoration = _restoreSharingDraft();
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

  Future<void> _restoreSharingDraft() async {
    try {
      final draft = await _draftStore.load();
      if (!mounted || draft == null || _navigatorKey.currentState == null) {
        return;
      }
      _restoredSharingForm = true;
      unawaited(
        _navigatorKey.currentState!
            .push<void>(
              MaterialPageRoute(
                settings: const RouteSettings(
                  name: '/community/resume-sharing',
                ),
                builder: (_) => SightingFormScreen(
                  repository:
                      widget.communityRepository ??
                      SupabaseCommunityRepository(),
                  municipalities: draft.municipalities,
                  restoredDraft: draft,
                  draftStore: _draftStore,
                ),
              ),
            )
            .whenComplete(() => _restoredSharingForm = false),
      );
    } catch (_) {
      // Never print photo, fields, callback URI or session data.
      if (!mounted) return;
      final context = _navigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível recuperar o rascunho local. Seus registros publicados não foram alterados.',
            ),
          ),
        );
      }
    }
  }

  void _onAuthChanged() {
    if (!mounted || _authController.callbackRevision == _callbackRevision) {
      return;
    }
    _callbackRevision = _authController.callbackRevision;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // A callback error/recovery must not outrun local caller restoration.
      await _draftRestoration;
      if (mounted) {
        _openProfile(
          returnLabel: _restoredSharingForm ? 'Voltar ao avistamento' : null,
        );
      }
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
