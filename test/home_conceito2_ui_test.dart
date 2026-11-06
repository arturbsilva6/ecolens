import 'package:ecolens/core/theme/app_theme.dart';
import 'package:ecolens/widgets/home/home_header.dart';
import 'package:ecolens/widgets/home/bottom_nav_bar.dart';
import 'package:ecolens/widgets/home/identification_banner.dart';
import 'package:ecolens/controllers/theme_controller.dart';
import 'package:ecolens/screens/home/home_screen.dart';
import 'package:ecolens/screens/species/species_catalog_screen.dart';
import 'package:ecolens/screens/species/favorites_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Cabeçalho mostra a marca e mantém as ações', (tester) async {
    var notifications = 0;
    var settings = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeHeader(
            onNotificationsTap: () => notifications++,
            onSettingsTap: () => settings++,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(
      (image.image as AssetImage).assetName,
      'assets/branding/ecolens_logo_loader.png',
    );
    await tester.tap(find.byTooltip('Notificações'));
    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configurações'));
    expect(notifications, 1);
    expect(settings, 1);
    expect(tester.takeException(), isNull);
  });

  for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Banner mantém câmera e galeria no modo $themeMode', (
      tester,
    ) async {
      var camera = 0;
      var gallery = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: Scaffold(
            body: SingleChildScrollView(
              child: IdentificationBanner(
                onCameraTap: () => camera++,
                onGalleryTap: () => gallery++,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir câmera'));
      await tester.tap(find.text('Enviar foto'));
      expect(camera, 1);
      expect(gallery, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Banner funciona em 320 px com texto ampliado', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.8),
            ),
            child: SingleChildScrollView(
              child: IdentificationBanner(
                onCameraTap: () {},
                onGalleryTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Abrir câmera'), findsOneWidget);
    expect(find.text('Enviar foto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Barra inferior sem linha nem elevação no modo escuro', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          bottomNavigationBar: EcoLensBottomNavBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
          body: const SizedBox(),
        ),
      ),
    );

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.elevation, 0);
    expect(bar.shadowColor, Colors.transparent);
    expect(bar.surfaceTintColor, Colors.transparent);
    expect(bar.backgroundColor, AppTheme.dark.scaffoldBackgroundColor);
  });

  testWidgets('Cabeçalho não desenha borda separadora', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: HomeHeader(onNotificationsTap: () {}, onSettingsTap: () {}),
        ),
      ),
    );
    final outer = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(HomeHeader),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(outer.decoration, isNull);
  });

  testWidgets('Menu inferior usa os cinco destinos do Conceito 2', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: EcoLensBottomNavBar(
            selectedIndex: 0,
            onDestinationSelected: selected.add,
          ),
        ),
      ),
    );
    final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      navigation.destinations.map(
        (destination) => (destination as NavigationDestination).label,
      ),
      ['Início', 'Câmera', 'Buscar', 'Favoritos', 'Perfil'],
    );
    for (final (index, label) in [
      (1, 'Câmera'),
      (2, 'Buscar'),
      (3, 'Favoritos'),
      (4, 'Perfil'),
    ]) {
      await tester.tap(find.text(label));
      expect(selected.last, index);
    }
    expect(find.byIcon(Icons.map_outlined), findsNothing);
    expect(find.byIcon(Icons.people_outline), findsNothing);
  });

  testWidgets('Menu da Home abre busca real no catálogo', (tester) async {
    final theme = ThemeController();
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          themeController: theme,
          fetchPublishedSpecies: () async => [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(EcoLensBottomNavBar),
        matching: find.text('Buscar'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SpeciesCatalogScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Menu da Home abre favoritos locais', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final theme = ThemeController();
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          themeController: theme,
          fetchPublishedSpecies: () async => [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(EcoLensBottomNavBar),
        matching: find.text('Favoritos'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
