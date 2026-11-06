import 'dart:convert';

import 'package:ecolens/controllers/species_controller.dart';
import 'package:ecolens/core/theme/app_theme.dart';
import 'package:ecolens/screens/identification/identification_screen.dart';
import 'package:ecolens/services/camera_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

final _testPhoto = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/pL8AAAAASUVORK5CYII=',
);

class _FakeCameraService extends CameraService {
  int cameraCalls = 0;
  int galleryCalls = 0;

  @override
  Future<XFile?> takePhoto() async {
    cameraCalls++;
    return XFile.fromData(_testPhoto, mimeType: 'image/png');
  }

  @override
  Future<XFile?> pickFromGallery() async {
    galleryCalls++;
    return XFile.fromData(_testPhoto, mimeType: 'image/png');
  }
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Identificação no $mode mostra prévia e ações reais', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const IdentificationScreen(),
        ),
      );
      expect(find.text('Identificar espécie'), findsOneWidget);
      expect(find.text('Sua foto aparecerá aqui'), findsOneWidget);
      expect(find.text('PRÉ-VISUALIZAÇÃO'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Abrir câmera'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Abrir câmera'), findsOneWidget);
      expect(find.text('Escolher da galeria'), findsOneWidget);
      expect(find.text('Ver resultado demonstrativo'), findsNothing);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Captura, remoção e galeria preservam fluxo existente', (
    tester,
  ) async {
    final service = _FakeCameraService();
    final controller = SpeciesController(cameraService: service);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: IdentificationScreen(controller: controller),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Abrir câmera'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Abrir câmera'));
    await tester.pumpAndSettle();
    expect(service.cameraCalls, 1);
    expect(controller.imageBytes, isNotNull);
    expect(
      find.text(
        'Reconhecimento por IA em preparação. '
        'Por enquanto, use a demonstração abaixo.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Remover imagem'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Remover imagem'));
    await tester.pumpAndSettle();
    expect(controller.imageBytes, isNull);
    expect(find.text('Ver resultado demonstrativo'), findsNothing);
    await tester.ensureVisible(find.text('Escolher da galeria'));
    await tester.tap(find.text('Escolher da galeria'));
    await tester.pumpAndSettle();
    expect(service.galleryCalls, 1);
    expect(controller.imageBytes, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Origem câmera recebida pela Home continua automática', (
    tester,
  ) async {
    final service = _FakeCameraService();
    final controller = SpeciesController(cameraService: service);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: IdentificationScreen(
          initialSource: IdentificationSource.camera,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(service.cameraCalls, 1);
    expect(find.text('FOTO SELECIONADA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tela estreita com texto ampliado não apresenta overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: const IdentificationScreen(),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Abrir câmera'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Abrir câmera'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
