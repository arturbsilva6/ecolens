import 'package:ecolens/models/species_model.dart';
import 'package:ecolens/widgets/home/region_alert_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SpeciesModel _s(String name, SpeciesStatus status, {bool photo = true}) =>
    SpeciesModel(
      commonName: name,
      scientificName: '$name sp.',
      status: status,
      imageUrl: photo ? 'https://example.org/$name.jpg' : null,
    );

void main() {
  test('Mostra perigosas antes das de cautela, só com foto, até 8', () {
    final picked = RegionAlertCarousel.pick([
      _s('Urtiga', SpeciesStatus.caution),
      _s('Pitanga', SpeciesStatus.harmless),
      _s('Jararaca', SpeciesStatus.danger),
      _s('Coral', SpeciesStatus.danger, photo: false),
      _s('Aranha', SpeciesStatus.danger),
      for (var i = 0; i < 10; i++) _s('Cautela$i', SpeciesStatus.caution),
    ]);
    expect(picked.take(3).map((s) => s.commonName), [
      'Aranha',
      'Jararaca',
      'Cautela0',
    ]);
    expect(picked, hasLength(8));
    expect(picked.any((s) => s.commonName == 'Pitanga'), isFalse);
    expect(picked.any((s) => s.commonName == 'Coral'), isFalse);
  });

  testWidgets('Avança sozinho e abre a ficha ao tocar', (tester) async {
    SpeciesModel? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RegionAlertCarousel(
              interval: const Duration(seconds: 2),
              fetchPublishedSpecies: () async => [
                _s('Jararaca', SpeciesStatus.danger),
                _s('Taturana', SpeciesStatus.danger),
              ],
              onSpeciesTap: (s) => opened = s,
              onViewAllTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Cuidado na região'), findsOneWidget);
    expect(find.bySemanticsLabel('Espécie 1 de 2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel('Espécie 2 de 2'), findsOneWidget);

    await tester.tap(find.text('Taturana'));
    expect(opened?.commonName, 'Taturana');
  });

  testWidgets('Com TalkBack ligado, não troca de espécie sozinho', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(accessibleNavigation: true),
          child: Scaffold(
            body: SingleChildScrollView(
              child: RegionAlertCarousel(
                interval: const Duration(seconds: 2),
                fetchPublishedSpecies: () async => [
                  _s('Jararaca', SpeciesStatus.danger),
                  _s('Taturana', SpeciesStatus.danger),
                ],
                onSpeciesTap: (_) {},
                onViewAllTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(find.bySemanticsLabel('Espécie 1 de 2'), findsOneWidget);
  });

  testWidgets('Sem espécies de alerta, a seção não aparece', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegionAlertCarousel(
            fetchPublishedSpecies: () async => [
              _s('Pitanga', SpeciesStatus.harmless),
            ],
            onSpeciesTap: (_) {},
            onViewAllTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cuidado na região'), findsNothing);
  });
}
