import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../widgets/eco_avatar.dart';

/// Nome e avatar que a pessoa escolheu mostrar nos avistamentos.
class PublicProfile {
  final String userId;
  final String displayName;
  final String avatar;

  const PublicProfile({
    required this.userId,
    required this.displayName,
    required this.avatar,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> row) => PublicProfile(
    userId: row['user_id'] as String,
    displayName: row['display_name'] as String,
    avatar: row['avatar'] as String,
  );

  /// Mesmas regras da tabela: 2 a 30 caracteres, sem controles nem < >.
  static String? nameError(String value) {
    final name = value.trim();
    if (name.length < 2 || name.length > 30) {
      return 'Use um nome de 2 a 30 caracteres.';
    }
    if (RegExp(r'[\x00-\x1F\x7F<>]').hasMatch(name)) {
      return 'O nome não pode ter os sinais < e >.';
    }
    return null;
  }
}

abstract class PublicProfileRepository {
  Future<PublicProfile?> fetch(String userId);
  Future<PublicProfile?> mine();
  Future<PublicProfile> save(String displayName, String avatar);
  Future<void> remove();
}

class SupabasePublicProfileRepository implements PublicProfileRepository {
  final Future<SupabaseClient> Function() _client;

  SupabasePublicProfileRepository({
    Future<SupabaseClient> Function()? clientProvider,
  }) : _client = clientProvider ?? SupabaseService.instance.requireClient;

  static const _table = 'public_profiles';
  static const _columns = 'user_id,display_name,avatar';

  @override
  Future<PublicProfile?> fetch(String userId) async {
    final client = await _client();
    final row = await client
        .from(_table)
        .select(_columns)
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : PublicProfile.fromJson(row);
  }

  String _currentUser(SupabaseClient client) {
    final user = client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('Entre na sua conta para editar o perfil público.');
    }
    return user.id;
  }

  @override
  Future<PublicProfile?> mine() async {
    final client = await _client();
    return fetch(_currentUser(client));
  }

  @override
  Future<PublicProfile> save(String displayName, String avatar) async {
    final error = PublicProfile.nameError(displayName);
    if (error != null) throw ArgumentError(error);
    if (!EcoAvatars.isValid(avatar)) throw ArgumentError('Avatar inválido.');
    final client = await _client();
    final row = await client
        .from(_table)
        .upsert({
          'user_id': _currentUser(client),
          'display_name': displayName.trim(),
          'avatar': avatar,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select(_columns)
        .single();
    return PublicProfile.fromJson(row);
  }

  @override
  Future<void> remove() async {
    final client = await _client();
    await client.from(_table).delete().eq('user_id', _currentUser(client));
  }
}
