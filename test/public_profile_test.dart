import 'package:ecolens/data/public_profile_repository.dart';
import 'package:ecolens/models/sighting.dart';
import 'package:ecolens/screens/community/sighting_detail_screen.dart';
import 'package:ecolens/screens/profile/public_profile_screen.dart';
import 'package:ecolens/widgets/eco_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/community_fake.dart';

class _Profiles implements PublicProfileRepository {
  PublicProfile? current;
  int saves = 0, removals = 0;

  @override
  Future<PublicProfile?> fetch(String userId) async =>
      current?.userId == userId ? current : null;

  @override
  Future<PublicProfile?> mine() async => current;

  @override
  Future<PublicProfile> save(String displayName, String avatar) async {
    saves++;
    return current = PublicProfile(
      userId: 'author',
      displayName: displayName.trim(),
      avatar: avatar,
    );
  }

  @override
  Future<void> remove() async {
    removals++;
    current = null;
  }
}

void main() {
  test('Regras do nome público iguais às do banco', () {
    expect(PublicProfile.nameError('A'), isNotNull);
    expect(PublicProfile.nameError('x' * 31), isNotNull);
    expect(PublicProfile.nameError('<b>Ana</b>'), isNotNull);
    expect(PublicProfile.nameError('  Ana S.  '), isNull);
  });

  test('Avatares têm as mesmas chaves aceitas pelo banco', () {
    expect(EcoAvatars.options.keys.toSet(), {
      'pegada',
      'coelho',
      'borboleta',
      'abelha',
      'peixe',
      'flor',
      'arvore',
      'folha',
      'lotus',
      'grama',
      'montanha',
      'sol',
    });
  });

  testWidgets('Salva nome e avatar e depois remove', (tester) async {
    final repository = _Profiles();
    await tester.pumpWidget(
      MaterialApp(home: PublicProfileScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'A');
    await tester.tap(find.text('Salvar perfil público'));
    await tester.pumpAndSettle();
    expect(find.text('Use um nome de 2 a 30 caracteres.'), findsOneWidget);
    expect(repository.saves, 0);

    await tester.enterText(find.byType(TextField), 'Ana S.');
    await tester.tap(find.bySemanticsLabel('Avatar Flor'));
    await tester.pump();
    expect(find.text('Publicado por Ana S.'), findsOneWidget);
    await tester.ensureVisible(find.text('Salvar perfil público'));
    await tester.tap(find.text('Salvar perfil público'));
    await tester.pumpAndSettle();
    expect(repository.current?.avatar, 'flor');
    // Espera o aviso "Perfil público salvo." sumir de cima do botão.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Remover perfil público'));
    await tester.tap(find.text('Remover perfil público'));
    await tester.pumpAndSettle();
    expect(repository.removals, 1);
  });

  testWidgets('Avistamento mostra o nome público do autor', (tester) async {
    final profiles = _Profiles()
      ..current = const PublicProfile(
        userId: 'author',
        displayName: 'Ana S.',
        avatar: 'flor',
      );
    await tester.pumpWidget(
      MaterialApp(
        home: SightingDetailScreen(
          repository: CommunityFake(),
          sighting: Sighting(
            id: 's1',
            ownerId: 'author',
            municipalityId: '3550605',
            photoPath: 'author/s1/photo.png',
            observedOn: DateTime(2026, 11, 7),
          ),
          municipalities: const [],
          loadSpecies: () async => [],
          loadAuthor: profiles.fetch,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Publicado por Ana S.'), findsOneWidget);
  });
}
