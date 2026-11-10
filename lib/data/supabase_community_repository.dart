import 'package:flutter/services.dart';

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/sighting.dart';
import '../services/supabase_service.dart';
import 'community_repository.dart';

class SupabaseCommunityRepository implements CommunityRepository {
  static const bucket = 'community-photos';
  final Future<SupabaseClient> Function() clientProvider;
  SupabaseCommunityRepository({
    Future<SupabaseClient> Function()? clientProvider,
  }) : clientProvider =
           clientProvider ?? SupabaseService.instance.requireClient;

  @override
  Future<List<Municipality>> municipalities() async =>
      (jsonDecode(
            await rootBundle.loadString('assets/data/sp_municipalities.json'),
          ) as List)
          .map((e) => Municipality.fromJson(e as Map<String, dynamic>))
          .toList();

  @override
  Future<String?> accountId() async {
    final session = (await clientProvider()).auth.currentSession;
    final user = session?.user;
    return session == null ||
            session.isExpired ||
            user == null ||
            user.isAnonymous
        ? null
        : user.id;
  }

  Future<String> _requireAccount() async {
    final id = await accountId();
    if (id == null) {
      throw const CommunityFailure(
        'Entre com uma conta cadastrada para publicar. Sessão anônima não permite publicar.',
      );
    }
    return id;
  }

  @override
  Future<List<Sighting>> page({
    int offset = 0,
    String? municipalityId,
    String species = '',
    bool mine = false,
  }) async {
    try {
      final client = await clientProvider();
      var query = client.from('community_sightings').select();
      if (mine) {
        query = query.eq('owner_id', await _requireAccount());
      } else {
        query = query.eq('status', 'published');
      }
      if (municipalityId != null) {
        query = query.eq('municipality_id', municipalityId);
      }
      if (species.trim().isNotEmpty) {
        // Escape LIKE wildcards; PostgREST handles URL encoding of the value.
        final value = species
            .trim()
            .replaceAll('\\', '\\\\')
            .replaceAll('%', '\\%')
            .replaceAll('_', '\\_');
        query = query.ilike('species_label', '%$value%');
      }
      final rows = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range(offset, offset + 19);
      return rows.map(Sighting.fromJson).toList();
    } catch (e) {
      throw _safe(e);
    }
  }

  @override
  Future<Uint8List> photo(String path) async {
    try {
      return await (await clientProvider()).storage.from(bucket).download(path);
    } catch (e) {
      throw _safe(e);
    }
  }

  @override
  Future<Sighting> create(SightingDraft draft, Uint8List sanitizedPhoto) async {
    try {
      final owner = await _requireAccount();
      final client = await clientProvider();
      final id = const Uuid().v4();
      final path = '$owner/$id/photo.png';
      // Persist draft before upload. Any uncertain result remains recoverable in
      // "Meus registros". Never delete on an ambiguous publish response.
      try {
        await client.from('community_sightings').insert({
          'id': id,
          'owner_id': owner,
          'photo_path': path,
          ...draft.toJson(),
          'status': 'draft',
        });
        await client.storage
            .from(bucket)
            .uploadBinary(
              path,
              sanitizedPhoto,
              fileOptions: const FileOptions(
                contentType: 'image/png',
                upsert: false,
              ),
            );
        final row = await client
            .from('community_sightings')
            .update({'status': 'published'})
            .eq('id', id)
            .select()
            .single();
        return Sighting.fromJson(row);
      } catch (e) {
        if (e is PostgrestException &&
            ['42P01', 'PGRST205', '42703'].contains(e.code)) {
          throw _safe(e);
        }
        if (e is PostgrestException &&
            e.message.contains('ECOLENS_DAILY_LIMIT')) {
          throw const CommunityFailure(
            'Você atingiu o limite de 10 publicações por dia. Tente novamente amanhã.',
          );
        }
        throw const CommunityPublicationUncertain();
      }
    } catch (e) {
      throw _safe(e);
    }
  }

  @override
  Future<void> update(Sighting sighting, SightingDraft draft) async {
    try {
      await _requireAccount();
      await (await clientProvider())
          .from('community_sightings')
          .update(draft.toJson())
          .eq('id', sighting.id)
          .select()
          .single();
    } catch (e) {
      throw _safe(e);
    }
  }

  @override
  Future<void> delete(Sighting sighting) async {
    try {
      await _requireAccount();
      final client = await clientProvider();
      // Hide first, remove object via Storage API, then remove row. This is
      // retryable if any response is lost, without leaving a public broken image.
      final rows = await client
          .from('community_sightings')
          .update({'status': 'deleting'})
          .eq('id', sighting.id)
          .select('id');
      if (rows.isEmpty) {
        throw const CommunityFailure(
          'Registro indisponível ou sem permissão. Atualize a lista.',
        );
      }
      await client.storage.from(bucket).remove([sighting.photoPath]);
      await client.from('community_sightings').delete().eq('id', sighting.id);
    } catch (e) {
      throw _safe(e, deleting: true);
    }
  }

  @override
  Future<void> report(
    Sighting sighting,
    ReportReason reason,
    String details,
  ) async {
    try {
      await _requireAccount();
      await (await clientProvider()).rpc(
        'report_sighting',
        params: {
          'p_sighting': sighting.id,
          'p_reason': reason.code,
          'p_details': details.trim(),
        },
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('ECOLENS_REPORT_LIMIT')) {
        throw const CommunityFailure(
          'Você já enviou muitas denúncias hoje. Tente novamente amanhã.',
        );
      }
      if (e.message.contains('ECOLENS_OWN_SIGHTING')) {
        throw const CommunityFailure('Não é possível denunciar o próprio registro.');
      }
      if (e.message.contains('ECOLENS_LOGIN_REQUIRED')) {
        throw const CommunityFailure('Entre na sua conta para denunciar.');
      }
      throw _safe(e);
    } catch (e) {
      throw _safe(e);
    }
  }

  CommunityFailure _safe(Object error, {bool deleting = false}) {
    if (error is CommunityFailure) return error;
    if (error is PostgrestException &&
        ['42P01', 'PGRST205', '42703'].contains(error.code)) {
      return const CommunityFailure(
        'Comunidade ainda não configurada no servidor. Aplique a migração descrita em docs/community-map.md.',
      );
    }
    if (error is StateError) {
      return const CommunityFailure(
        'Serviços online não configurados ou indisponíveis. Confira SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY e tente novamente.',
      );
    }
    return CommunityFailure(
      deleting
          ? 'Exclusão não confirmada. O registro pode estar oculto com limpeza pendente. Atualize Meus registros e tente excluir novamente.'
          : 'Não foi possível concluir. Confira sua conexão, conta e configuração de Comunidade no servidor e tente novamente.',
    );
  }
}
