import 'package:ecolens/core/theme/app_theme.dart';
import 'package:ecolens/widgets/home/home_header.dart';
import 'package:ecolens/widgets/home/bottom_nav_bar.dart';
import 'package:ecolens/widgets/home/identification_banner.dart';
import 'package:ecolens/controllers/theme_controller.dart';
import 'package:ecolens/screens/home/home_screen.dart';
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
    final style = tester.widget<NavigationBarTheme>(
      find.byType(NavigationBarTheme),
    );
    expect(
      style.data.iconTheme!.resolve({WidgetState.selected})!.color,
      AppTheme.dark.colorScheme.primary,
    );
    expect(
      style.data.iconTheme!.resolve({})!.color,
      AppTheme.dark.colorScheme.secondary,
    );
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

  testWidgets('Menu inferior preserva Mapa e Comunidade e usa cores da marca', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
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
      ['Início', 'Identificar', 'Mapa', 'Comunidade', 'Perfil'],
    );
    for (final (index, label) in [
      (1, 'Identificar'),
      (2, 'Mapa'),
      (3, 'Comunidade'),
      (4, 'Perfil'),
    ]) {
      await tester.tap(find.text(label));
      expect(selected.last, index);
    }
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byIcon(Icons.people_outline), findsOneWidget);
    final style = tester.widget<NavigationBarTheme>(
      find.byType(NavigationBarTheme),
    );
    expect(
      style.data.iconTheme!.resolve({WidgetState.selected})!.color,
      AppTheme.light.colorScheme.primary,
    );
    expect(
      style.data.iconTheme!.resolve({})!.color,
      AppTheme.light.colorScheme.secondary,
    );
  });

  testWidgets('Mapa permanece visível e informa que está em desenvolvimento', (
    tester,
  ) async {
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
        matching: find.text('Mapa'),
      ),
    );
    await tester.pump();
    expect(find.text('Mapa em desenvolvimento'), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
