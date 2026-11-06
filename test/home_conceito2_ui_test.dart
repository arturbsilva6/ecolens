import 'package:ecolens/core/theme/app_theme.dart';
import 'package:ecolens/widgets/home/home_header.dart';
import 'package:ecolens/widgets/home/bottom_nav_bar.dart';
import 'package:ecolens/widgets/home/identification_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
          body: HomeHeader(
            onNotificationsTap: () {},
            onSettingsTap: () {},
          ),
        ),
      ),
    );
    final outer = tester.widget<Container>(
      find.descendant(
        of: find.byType(HomeHeader),
        matching: find.byType(Container),
      ).first,
    );
    expect(outer.decoration, isNull);
  });
}
