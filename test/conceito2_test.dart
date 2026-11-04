import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecolens/core/theme/app_theme.dart';
import 'package:ecolens/controllers/theme_controller.dart';
import 'package:ecolens/services/preferences_service.dart';
import 'package:ecolens/screens/settings/appearance_screen.dart';
import 'package:ecolens/widgets/custom_button.dart';
import 'package:ecolens/widgets/ecolens_card.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

double contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return first > second
      ? (first + 0.05) / (second + 0.05)
      : (second + 0.05) / (first + 0.05);
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Componentes preservam ações em $mode', (tester) async {
      var calls = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: Scaffold(
          body: Column(children: [
            EcoLensButton(
              label: 'Câmera',
              icon: Icons.camera_alt_outlined,
              onPressed: () => calls++,
            ),
            const EcoLensButton(label: 'Indisponível', onPressed: null),
            EcoLensCard(
              onTap: () => calls++,
              child: const Text('Registro'),
            ),
          ]),
        ),
      ));
      await tester.tap(find.text('Câmera'));
      await tester.tap(find.text('Registro'));
      await tester.tap(find.text('Indisponível'));
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    });
  }

  test('Texto e ações têm contraste mínimo AA nos dois temas', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final c = theme.colorScheme;
      for (final pair in [
        (c.onSurface, c.surface),
        (c.onSurfaceVariant, c.surface),
        (c.onPrimary, c.primary),
        (c.onPrimaryContainer, c.primaryContainer),
        (c.onSecondaryContainer, c.secondaryContainer),
        (c.onTertiaryContainer, c.tertiaryContainer),
      ]) {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
    }
  });

  testWidgets('Aparência mantém escolha e persistência do tema', (tester) async {
    final controller = ThemeController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(ListenableBuilder(
      listenable: controller,
      builder: (context, child) => MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: controller.themeMode,
        home: AppearanceScreen(themeController: controller),
      ),
    ));
    for (final entry in [
      ('Escuro', ThemeMode.dark),
      ('Claro', ThemeMode.light),
      ('Automático', ThemeMode.system),
    ]) {
      await tester.tap(find.text(entry.$1));
      await tester.pumpAndSettle();
      expect(controller.themeMode, entry.$2);
      expect(await PreferencesService().loadThemeMode(), entry.$2.name);
      final restored = ThemeController();
      await restored.loadTheme();
      expect(restored.themeMode, entry.$2);
      restored.dispose();
      expect(tester.takeException(), isNull);
    }
  });
}
