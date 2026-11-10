import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ecolens/app.dart';
import 'package:ecolens/controllers/auth_controller.dart';
import 'package:ecolens/core/theme/app_theme.dart';
import 'package:ecolens/data/auth_repository.dart';
import 'package:ecolens/data/community_repository.dart';
import 'package:ecolens/data/share_identification_draft_store.dart';
import 'package:ecolens/models/community_share_draft.dart';
import 'package:ecolens/data/favorites_repository.dart';
import 'package:ecolens/data/identification_history_repository.dart';
import 'package:ecolens/models/ai_identification_result.dart';
import 'package:ecolens/models/community_identification_seed.dart';
import 'package:ecolens/models/sighting.dart';
import 'package:ecolens/models/species_model.dart';
import 'package:ecolens/screens/community/community_screen.dart';
import 'package:ecolens/screens/community/sighting_form_screen.dart';
import 'package:ecolens/screens/community/sighting_detail_screen.dart';
import 'package:ecolens/screens/identification/identification_result_screen.dart';
import 'package:ecolens/screens/map/heat_map_screen.dart';
import 'package:ecolens/screens/profile/profile_screen.dart';
import 'package:ecolens/services/community_photo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/community_fake.dart';
import 'support/fake_auth_repository.dart';

final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/pL8AAAAASUVORK5CYII=',
);
const suggestion = AiIdentificationResult(
  identified: true,
  commonName: 'Jararaca',
  scientificName: 'Bothrops jararaca',
  explanation: 'Hipótese experimental.',
);

class _Photos extends CommunityPhotoService {
  final inputs = <Uint8List>[];
  @override
  Future<Uint8List> sanitize(Uint8List input) async {
    inputs.add(Uint8List.fromList(input));
    if (input.length < 8) throw StateError('Invalid photo');
    return Uint8List.fromList(png);
  }
}

class _Repository extends CommunityFake {
  SightingDraft? submitted;
  Uint8List? uploaded;
  Object? publicationFailure;
  Completer<void>? pending;
  String? Function()? currentAccount;
  int accountChecks = 0;
  @override
  Future<String?> accountId() async {
    accountChecks++;
    return currentAccount != null ? currentAccount!() : user;
  }

  @override
  Future<Sighting> create(SightingDraft draft, Uint8List sanitizedPhoto) async {
    submitted = draft;
    uploaded = sanitizedPhoto;
    if (pending != null) await pending!.future;
    if (publicationFailure != null) {
      creations++;
      throw publicationFailure!;
    }
    return super.create(draft, sanitizedPhoto);
  }
}

Future<void> reveal(
  WidgetTester tester,
  Finder finder, {
  bool modal = false,
}) async {
  for (var i = 0; i < 120; i++) {
    if (finder.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(
        tester.element(finder.first),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      return;
    }
    final scrollable = modal
        ? find.byType(Scrollable).last
        : find.byType(Scrollable).first;
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(
      i == 0 ? 0 : (position.pixels + 180).clamp(0, position.maxScrollExtent),
    );
    await tester.pumpAndSettle();
  }
  fail('Missing widget: $finder');
}

/// Fecha o aviso central de sucesso (ex.: "Login realizado"), se aberto.
Future<void> dismissNotice(WidgetTester tester) async {
  final ok = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.text('OK'),
  );
  if (ok.evaluate().isEmpty) return;
  await tester.tap(ok);
  await tester.pumpAndSettle();
}

Future<void> tap(
  WidgetTester tester,
  String label, {
  bool modal = false,
}) async {
  await reveal(tester, find.text(label), modal: modal);
  await tester.tap(find.text(label).first);
  await tester.pumpAndSettle();
}

Future<void> reviewRequired(WidgetTester tester) async {
  await tap(tester, 'Usar hoje como data do avistamento');
  await tap(tester, 'Selecionar município/UF (SP)');
  await tap(tester, 'São Roque/SP', modal: true);
}

Finder get hypothesis =>
    find.widgetWithText(TextFormField, 'Nome da espécie (hipótese)');
Finder get notes =>
    find.widgetWithText(TextFormField, 'Observações (opcional)');
Future<void> edit(WidgetTester tester, Finder finder, String value) async {
  await reveal(tester, finder);
  await tester.enterText(finder, value);
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  Future<void> mount(
    WidgetTester tester,
    Widget screen, {
    bool small = false,
    bool dark = false,
  }) async {
    if (small) {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(small ? 2 : 1)),
          child: child!,
        ),
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget form(
    _Repository repository,
    _Photos photos, {
    Uint8List? photo,
    Future<void> Function(BuildContext)? login,
  }) => SightingFormScreen(
    repository: repository,
    municipalities: const [municipality],
    photoService: photos,
    openAccount: login,
    initialIdentification: CommunityIdentificationSeed.fromResult(
      suggestion,
      photo ?? png,
    ),
  );

  test('seed contains only available user photo and unverified hypothesis, no date/location', () {
    final seed = CommunityIdentificationSeed.fromResult(suggestion, png);
    expect(seed.originalPhoto, same(png));
    expect(seed.hypothesis, 'Jararaca — Bothrops jararaca');
    final unknown = CommunityIdentificationSeed.fromResult(
      const AiIdentificationResult(
        identified: false,
        commonName: 'ignored',
        scientificName: null,
        explanation: '',
      ),
      null,
    );
    expect(unknown.hypothesis, isNull);
    expect(unknown.originalPhoto, isNull);
  });
  testWidgets(
    'result opens existing form, preserves original and writes nothing',
    (tester) async {
      final repository = _Repository();
      final photos = _Photos();
      final original = Uint8List.fromList([
        ...png,
        ...'private-metadata'.codeUnits,
      ]);
      await mount(
        tester,
        IdentificationResultScreen(
          imageBytes: original,
          result: suggestion,
          communityRepository: repository,
          communityPhotoService: photos,
        ),
      );
      await tap(tester, 'Compartilhar na comunidade');
      expect(find.byType(SightingFormScreen), findsOneWidget);
      await reveal(tester, hypothesis);
      final field = tester.widget<TextFormField>(hypothesis);
      expect(field.controller!.text, 'Jararaca — Bothrops jararaca');
      expect(photos.inputs.single, original);
      expect(original, [...png, ...'private-metadata'.codeUnits]);
      expect(repository.creations, 0);
      expect(repository.accountChecks, 0);
      await reveal(tester, find.text('Selecionar data do avistamento'));
      expect(find.text('Selecionar município/UF (SP)'), findsOneWidget);
    },
  );
  testWidgets(
    'missing or corrupt original permits selecting valid photo without catalog fallback',
    (tester) async {
      final repository = _Repository()..user = 'author';
      final photos = _Photos();
      await mount(
        tester,
        SightingFormScreen(
          repository: repository,
          municipalities: const [municipality],
          initialIdentification: const CommunityIdentificationSeed(),
          photoService: photos,
          selectPhoto: (_) async => png,
        ),
      );
      await reveal(tester, find.textContaining('Foto original ausente'));
      expect(repository.creations, 0);
      await tap(tester, 'Galeria');
      await reviewRequired(tester);
      await tap(tester, 'Publicar');
      expect(find.text('Avistamento publicado'), findsOneWidget);
      expect(repository.submitted!.species, isNull);
      expect(repository.submitted!.origin, IdentificationOrigin.unknown);
      expect(repository.uploaded, png);
    },
  );
  testWidgets('demonstration offers no sharing action', (tester) async {
    await mount(
      tester,
      IdentificationResultScreen(
        imageBytes: png,
        result: suggestion,
        isDemonstration: true,
      ),
    );
    await reveal(tester, find.textContaining('Resultado demonstrativo:'));
    expect(find.text('Compartilhar na comunidade'), findsNothing);
  });
  testWidgets(
    'missing result photo opens form and explains need for real photo',
    (tester) async {
      final repository = _Repository();
      await mount(
        tester,
        IdentificationResultScreen(
          imageBytes: null,
          result: suggestion,
          communityRepository: repository,
          communityPhotoService: _Photos(),
        ),
      );
      expect(
        find.textContaining('Foto original indisponível.'),
        findsOneWidget,
      );
      await tap(tester, 'Compartilhar na comunidade');
      await reveal(tester, find.textContaining('Foto original ausente'));
      expect(repository.creations, 0);
      expect(find.byType(SightingFormScreen), findsOneWidget);
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'review AI, change origin and publish in 320x480 text2 dark=$dark',
      (tester) async {
        final repository = _Repository()..user = 'author';
        await mount(
          tester,
          IdentificationResultScreen(
            imageBytes: png,
            result: suggestion,
            communityRepository: repository,
            communityPhotoService: _Photos(),
            matchedSpecies: const SpeciesModel(
              commonName: 'Jararaca',
              scientificName: 'Bothrops jararaca',
              status: SpeciesStatus.danger,
            ),
          ),
          small: true,
          dark: dark,
        );
        await tap(tester, 'Compartilhar na comunidade');
        await reviewRequired(tester);
        await edit(tester, hypothesis, 'Espécie informada');
        final origin = tester
            .widget<DropdownButtonFormField<IdentificationOrigin>>(
              find.byType(DropdownButtonFormField<IdentificationOrigin>),
            );
        expect(origin.initialValue, IdentificationOrigin.user);
        await edit(tester, notes, 'Observação revisada');
        await tap(tester, 'Publicar');
        expect(repository.submitted!.species, 'Espécie informada');
        expect(repository.submitted!.origin, IdentificationOrigin.user);
        expect(repository.submitted!.notes, 'Observação revisada');
        expect(repository.submitted!.municipalityId, municipality.id);
        expect(find.text('Avistamento publicado'), findsOneWidget);
        await tap(tester, 'Ver avistamento publicado');
        expect(find.byType(SightingDetailScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('date must be explicitly reviewed before sending', (
    tester,
  ) async {
    final repository = _Repository()..user = 'author';
    await mount(tester, form(repository, _Photos()));
    await tap(tester, 'Publicar');
    expect(find.textContaining('Selecione e confirme a data'), findsOneWidget);
    expect(repository.creations, 0);
    expect(repository.accountChecks, 0);
  });
  for (final mode in ['cancelled', 'email', 'google', 'failure']) {
    testWidgets(
      'login $mode retains photo and edits, never automatically publishes',
      (tester) async {
        final repository = _Repository();
        final photos = _Photos();
        var logins = 0;
        await mount(
          tester,
          form(
            repository,
            photos,
            login: (context) async {
              logins++;
              if (mode == 'failure') throw StateError('network');
              if (mode == 'email' || mode == 'google') {
                repository.user = 'author';
              }
            },
          ),
        );
        await reviewRequired(tester);
        await edit(tester, notes, 'Dados preservados');
        await tap(tester, 'Publicar');
        expect(logins, 1);
        expect(repository.creations, 0);
        expect(photos.inputs.length, 1);
        await reveal(tester, notes);
        expect(
          tester.widget<TextFormField>(notes).controller!.text,
          'Dados preservados',
        );
        if (mode == 'email' || mode == 'google') {
          await tap(tester, 'Publicar');
          expect(repository.creations, 1);
        }
      },
    );
  }
  testWidgets(
    'expired session is checked again and retains edits without writing',
    (tester) async {
      final repository = _Repository()..user = 'author';
      var logins = 0;
      await mount(
        tester,
        form(
          repository,
          _Photos(),
          login: (_) async {
            logins++;
          },
        ),
      );
      await reviewRequired(tester);
      await edit(tester, notes, 'Ainda aqui');
      repository.user = null;
      await tap(tester, 'Publicar');
      expect(logins, 1);
      expect(repository.creations, 0);
      expect(repository.accountChecks, greaterThanOrEqualTo(2));
    },
  );
  testWidgets(
    'uncertain publication blocks retry and offers real own-records query',
    (tester) async {
      final repository = _Repository()
        ..user = 'author'
        ..publicationFailure = const CommunityPublicationUncertain();
      await mount(tester, form(repository, _Photos()));
      await reviewRequired(tester);
      await tap(tester, 'Publicar');
      await reveal(tester, find.text('Publicar'));
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Publicar'))
            .onPressed,
        isNull,
      );
      await tap(tester, 'Conferir Meus registros');
      expect(
        tester
            .widget<CommunityScreen>(find.byType(CommunityScreen))
            .initialMine,
        true,
      );
      expect(repository.creations, 1);
      expect(repository.calls, 1);
    },
  );
  testWidgets(
    'double send is blocked until response and successful map reload uses municipality',
    (tester) async {
      final pending = Completer<void>();
      final repository = _Repository()
        ..user = 'author'
        ..pending = pending;
      await mount(tester, form(repository, _Photos()));
      await reviewRequired(tester);
      await reveal(tester, find.text('Publicar'));
      final send = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Publicar'))
          .onPressed!;
      send();
      send();
      await tester.pump();
      expect(repository.accountChecks, 1);
      pending.complete();
      await tester.pumpAndSettle();
      expect(repository.creations, 1);
      await tap(tester, 'Ver no mapa');
      final map = tester.widget<HeatMapScreen>(find.byType(HeatMapScreen));
      expect(map.initialMunicipality!.id, municipality.id);
      expect(repository.calls, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'edited form asks before discard and result plus saved local data remain',
    (tester) async {
      final repository = _Repository();
      final preferences = SharedPreferencesAsyncPlatform.instance;
      await mount(
        tester,
        IdentificationResultScreen(
          imageBytes: png,
          result: suggestion,
          communityRepository: repository,
          communityPhotoService: _Photos(),
        ),
      );
      await tap(tester, 'Salvar no histórico');
      await tap(tester, 'Compartilhar na comunidade');
      await edit(tester, notes, 'Não perder');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Descartar alterações?'), findsOneWidget);
      await tap(tester, 'Continuar editando');
      await reveal(tester, notes);
      expect(
        tester.widget<TextFormField>(notes).controller!.text,
        'Não perder',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(tester, 'Descartar');
      expect(find.byType(IdentificationResultScreen), findsOneWidget);
      await reveal(tester, find.text('Salvo no histórico'));
      expect(find.text('Salvo no histórico'), findsOneWidget);
      expect(SharedPreferencesAsyncPlatform.instance, same(preferences));
      expect(repository.creations, 0);
    },
  );

  testWidgets(
    'confirmed share and conclusion preserve result, history and favorites',
    (tester) async {
      final favorites = FavoritesRepository();
      await favorites.setFavorite('Bothrops jararaca', true);
      final history = IdentificationHistoryRepository();
      final entry = await history.save(suggestion, matchedCatalog: false);
      final repository = _Repository()..user = 'author';
      await mount(
        tester,
        IdentificationResultScreen(
          imageBytes: png,
          result: suggestion,
          communityRepository: repository,
          communityPhotoService: _Photos(),
        ),
      );
      await tap(tester, 'Compartilhar na comunidade');
      await reviewRequired(tester);
      await tap(tester, 'Publicar');
      await tap(tester, 'Concluir');
      expect(find.byType(IdentificationResultScreen), findsOneWidget);
      final result = tester.widget<IdentificationResultScreen>(
        find.byType(IdentificationResultScreen),
      );
      expect(result.result, same(suggestion));
      expect(result.imageBytes, png);
      expect((await history.load()).single.id, entry.id);
      expect(await favorites.load(), {'bothrops jararaca'});
      expect(repository.creations, 1);
    },
  );
  testWidgets('user can replace AI hypothesis with unidentified species', (
    tester,
  ) async {
    final repository = _Repository()..user = 'author';
    await mount(tester, form(repository, _Photos()));
    await reviewRequired(tester);
    final origin = find.byType(DropdownButtonFormField<IdentificationOrigin>);
    await reveal(tester, origin);
    await tester.tap(origin);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Espécie não identificada').last);
    await tester.pumpAndSettle();
    await tap(tester, 'Publicar');
    expect(repository.submitted!.species, isNull);
    expect(repository.submitted!.origin, IdentificationOrigin.unknown);
  });
  testWidgets(
    'invalid photo preparation never writes and preserves hypothesis',
    (tester) async {
      final repository = _Repository()..user = 'author';
      await mount(
        tester,
        form(repository, _Photos(), photo: Uint8List.fromList([1, 2, 3])),
      );
      await reviewRequired(tester);
      await tap(tester, 'Publicar');
      expect(repository.creations, 0);
      expect(
        find.text('Selecione o município e uma foto para publicar.'),
        findsOneWidget,
      );
      await reveal(tester, hypothesis);
      expect(
        tester.widget<TextFormField>(hypothesis).controller!.text,
        'Jararaca — Bothrops jararaca',
      );
    },
  );
  for (final method in ['email', 'google', 'cancel', 'callback-error']) {
    testWidgets(
      'application reuses one Profile route and resumes after $method login',
      (tester) async {
        final authRepository = FakeAuthRepository();
        final auth = AuthController(repository: authRepository);
        addTearDown(auth.dispose);
        final repository = _Repository()..currentAccount = () => auth.user?.id;
        await tester.pumpWidget(
          EcoLensApp(
            authController: auth,
            fetchPublishedSpecies: () async => [],
          ),
        );
        await tester.pumpAndSettle();
        final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        unawaited(
          nav.push<void>(
            MaterialPageRoute(builder: (_) => form(repository, _Photos())),
          ),
        );
        await tester.pumpAndSettle();
        await reviewRequired(tester);
        await edit(tester, notes, 'Login real na UI simulada');
        await tap(tester, 'Publicar');
        expect(find.byType(ProfileScreen), findsOneWidget);
        if (method == 'cancel' || method == 'callback-error') {
          if (method == 'callback-error') {
            authRepository.events.add(
              const AccountEvent(
                AccountEventType.callbackError,
                message: 'Link expirado',
              ),
            );
            await tester.pumpAndSettle();
            expect(
              find.byType(ProfileScreen, skipOffstage: false),
              findsOneWidget,
            );
          }
          await tap(tester, 'Voltar ao avistamento');
          expect(find.byType(SightingFormScreen), findsOneWidget);
          await reveal(tester, notes);
          expect(
            tester.widget<TextFormField>(notes).controller!.text,
            'Login real na UI simulada',
          );
          expect(repository.creations, 0);
          return;
        }
        if (method == 'email') {
          await tap(tester, 'Entrar com e-mail');
          await edit(
            tester,
            find.byKey(const ValueKey('auth-email')),
            'pessoa@example.com',
          );
          await edit(
            tester,
            find.byKey(const ValueKey('auth-password')),
            'Password12',
          );
          await tap(tester, 'Entrar');
        } else {
          await tap(tester, 'Entrar com Google');
          expect(repository.creations, 0);
          authRepository.events.add(
            const AccountEvent(AccountEventType.session, user: account),
          );
          await tester.pumpAndSettle();
        }
        expect(find.text('Login realizado'), findsOneWidget);
        await dismissNotice(tester);
        expect(find.byType(ProfileScreen), findsNothing);
        expect(find.byType(SightingFormScreen), findsOneWidget);
        expect(repository.creations, 0);
        await tap(tester, 'Publicar');
        expect(repository.creations, 1);
      },
    );
  }
  for (final mode in ['google', 'cancel', 'failure']) {
    testWidgets(
      'real result to OAuth $mode retains the same form state on lifecycle/rebuild',
      (tester) async {
        final authRepository = FakeAuthRepository();
        final auth = AuthController(repository: authRepository);
        addTearDown(auth.dispose);
        final repository = _Repository()..currentAccount = () => auth.user?.id;
        final photos = _Photos();
        EcoLensApp app() => EcoLensApp(
          authController: auth,
          fetchPublishedSpecies: () async => [],
          communityRepository: repository,
        );
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        unawaited(
          nav.push<void>(
            MaterialPageRoute(
              builder: (_) => IdentificationResultScreen(
                imageBytes: png,
                result: suggestion,
                communityRepository: repository,
                communityPhotoService: photos,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tap(tester, 'Compartilhar na comunidade');
        await reviewRequired(tester);
        await edit(tester, hypothesis, 'Hipótese mantida após OAuth');
        await edit(tester, notes, 'Campos revisados antes do navegador');
        final formState = tester.state(find.byType(SightingFormScreen));
        await tap(tester, 'Publicar');
        expect(await ShareIdentificationDraftStore().load(), isNotNull);
        await tap(tester, 'Entrar com Google');
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        await tester.pumpWidget(
          app(),
        ); // Rebuild without destroying the Navigator.
        for (final state in [
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        await tester.pumpAndSettle();
        if (mode == 'google') {
          authRepository.events.add(
            const AccountEvent(AccountEventType.session, user: account),
          );
          await tester.pumpAndSettle();
          await dismissNotice(tester);
        } else {
          if (mode == 'failure') {
            authRepository.events.add(
              const AccountEvent(
                AccountEventType.callbackError,
                message: 'Google não concluiu o acesso',
              ),
            );
            await tester.pumpAndSettle();
          }
          expect(
            find.byType(ProfileScreen, skipOffstage: false),
            findsOneWidget,
          );
          await tap(tester, 'Voltar ao avistamento');
        }
        expect(tester.state(find.byType(SightingFormScreen)), same(formState));
        expect(repository.creations, 0);
        expect(await ShareIdentificationDraftStore().load(), isNull);
        await reveal(tester, hypothesis);
        expect(
          tester.widget<TextFormField>(hypothesis).controller!.text,
          'Hipótese mantida após OAuth',
        );
        expect(
          tester
              .widget<DropdownButtonFormField<IdentificationOrigin>>(
                find.byType(DropdownButtonFormField<IdentificationOrigin>),
              )
              .initialValue,
          IdentificationOrigin.user,
        );
        await reveal(tester, notes);
        expect(
          tester.widget<TextFormField>(notes).controller!.text,
          'Campos revisados antes do navegador',
        );
        expect(photos.inputs.length, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final mode in ['session', 'cancel', 'callback-error']) {
    testWidgets(
      'new application after process loss restores sharing draft: $mode',
      (tester) async {
        final firstAuth = AuthController(repository: FakeAuthRepository());
        addTearDown(firstAuth.dispose);
        var activeAuth = firstAuth;
        final repository = _Repository()
          ..currentAccount = () => activeAuth.user?.id;
        await tester.pumpWidget(
          EcoLensApp(
            authController: firstAuth,
            fetchPublishedSpecies: () async => [],
            communityRepository: repository,
          ),
        );
        await tester.pumpAndSettle();
        final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        unawaited(
          nav.push<void>(
            MaterialPageRoute(builder: (_) => form(repository, _Photos())),
          ),
        );
        await tester.pumpAndSettle();
        await reviewRequired(tester);
        await edit(tester, hypothesis, 'Hipótese recuperável');
        await edit(tester, notes, 'Não perder no reinício');
        await tap(tester, 'Publicar');
        await tap(tester, 'Entrar com Google');
        final checkpoint = (await ShareIdentificationDraftStore().load())!;
        expect(checkpoint.photo, png);
        await tester.pumpWidget(
          const SizedBox(),
        ); // All route/form States are disposed.
        await tester.pumpAndSettle();
        final nextRepository = FakeAuthRepository()
          ..restored = mode == 'session' ? account : null;
        activeAuth = AuthController(repository: nextRepository);
        addTearDown(activeAuth.dispose);
        await tester.pumpWidget(
          EcoLensApp(
            authController: activeAuth,
            fetchPublishedSpecies: () async => [],
            communityRepository: repository,
          ),
        );
        await tester.pumpAndSettle();
        if (mode == 'callback-error') {
          nextRepository.events.add(
            const AccountEvent(
              AccountEventType.callbackError,
              message: 'Callback não concluído',
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byType(ProfileScreen, skipOffstage: false),
            findsOneWidget,
          );
          await tap(tester, 'Voltar ao avistamento');
        }
        expect(find.byType(SightingFormScreen), findsOneWidget);
        expect(repository.creations, 0);
        final restored = tester
            .widget<SightingFormScreen>(find.byType(SightingFormScreen))
            .restoredDraft!;
        expect(restored.photo, checkpoint.photo);
        expect(restored.hypothesis, checkpoint.hypothesis);
        expect(restored.origin, checkpoint.origin);
        expect(restored.observedOn, checkpoint.observedOn);
        expect(restored.municipalityId, checkpoint.municipalityId);
        expect(restored.notes, checkpoint.notes);
        await reveal(tester, hypothesis);
        expect(
          tester.widget<TextFormField>(hypothesis).controller!.text,
          'Hipótese recuperável',
        );
        await reveal(tester, notes);
        expect(
          tester.widget<TextFormField>(notes).controller!.text,
          'Não perder no reinício',
        );
        if (mode == 'session') {
          await tap(
            tester,
            'Publicar',
          ); // Explicit second action, after review.
          expect(repository.creations, 1);
          expect(repository.uploaded, checkpoint.photo);
          expect(
            repository.submitted!.municipalityId,
            checkpoint.municipalityId,
          );
          expect(repository.submitted!.observedOn, checkpoint.observedOn);
          expect(await ShareIdentificationDraftStore().load(), isNull);
        } else {
          await tester.pageBack();
          await tester.pumpAndSettle();
          await tap(tester, 'Descartar');
          expect(await ShareIdentificationDraftStore().load(), isNull);
          expect(repository.creations, 0);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'storage failure keeps fields and prevents leaving for account access',
    (tester) async {
      final repository = _Repository();
      var logins = 0;
      await mount(
        tester,
        SightingFormScreen(
          repository: repository,
          municipalities: const [municipality],
          photoService: _Photos(),
          initialIdentification: CommunityIdentificationSeed.fromResult(
            suggestion,
            png,
          ),
          draftStore: _FailingDraftStore(),
          openAccount: (_) async {
            logins++;
          },
        ),
      );
      await reviewRequired(tester);
      await edit(tester, notes, 'Não sair sem salvar o rascunho');
      await tap(tester, 'Publicar');
      expect(logins, 0);
      expect(repository.creations, 0);
      await reveal(tester, notes);
      expect(
        tester.widget<TextFormField>(notes).controller!.text,
        'Não sair sem salvar o rascunho',
      );
    },
  );
  testWidgets(
    'early callback error waits for the sharing checkpoint before opening Profile',
    (tester) async {
      final pending = Completer<CommunityShareDraft?>();
      final authRepository = FakeAuthRepository();
      final auth = AuthController(repository: authRepository);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        EcoLensApp(
          authController: auth,
          shareDraftStore: _DelayedDraftStore(pending),
          communityRepository: _Repository(),
          fetchPublishedSpecies: () async => [],
        ),
      );
      await tester.pumpAndSettle();
      authRepository.events.add(
        const AccountEvent(
          AccountEventType.callbackError,
          message: 'Callback antecipado',
        ),
      );
      await tester.pump();
      expect(find.byType(ProfileScreen), findsNothing);
      pending.complete(
        CommunityShareDraft(
          photo: png,
          hypothesis: 'Hipótese',
          origin: IdentificationOrigin.ai,
          observedOn: DateTime(2026, 11, 6),
          municipalityId: municipality.id,
          municipalities: const [municipality],
          notes: 'Rascunho antes do callback',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen, skipOffstage: false), findsOneWidget);
      expect(
        find.byType(SightingFormScreen, skipOffstage: false),
        findsOneWidget,
      );
      await tap(tester, 'Voltar ao avistamento');
      expect(find.byType(SightingFormScreen), findsOneWidget);
      await reveal(tester, notes);
      expect(
        tester.widget<TextFormField>(notes).controller!.text,
        'Rascunho antes do callback',
      );
    },
  );
}

class _FailingDraftStore extends ShareIdentificationDraftStore {
  @override
  Future<void> save(CommunityShareDraft draft) async =>
      throw StateError('disk unavailable');
}

class _DelayedDraftStore extends ShareIdentificationDraftStore {
  final Completer<CommunityShareDraft?> pending;
  _DelayedDraftStore(this.pending);
  @override
  Future<CommunityShareDraft?> load() => pending.future;
}
