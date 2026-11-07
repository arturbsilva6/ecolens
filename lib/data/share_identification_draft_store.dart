import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/community_share_draft.dart';

/// One local checkpoint, written and awaited BEFORE leaving for account access.
/// Separate from history, favorites and the SDK's session/PKCE storage.
class ShareIdentificationDraftStore {
  static const storageKey = 'ecolens_share_auth_draft_v1';
  static const lifetime = Duration(hours: 24);
  static const _maxEncodedLength = 8 * 1024 * 1024;
  final SharedPreferencesAsync? preferences;
  final DateTime Function() _now;

  ShareIdentificationDraftStore({this.preferences, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  SharedPreferencesAsync get _preferences =>
      preferences ?? SharedPreferencesAsync();

  Future<void> save(CommunityShareDraft draft) async {
    final encoded = jsonEncode({
      'version': 1,
      'saved_at': _now().toIso8601String(),
      'draft': draft.toJson(),
    });
    if (encoded.length > _maxEncodedLength) {
      throw const FormatException('Sharing draft too large');
    }
    await _preferences.setString(storageKey, encoded);
  }

  Future<CommunityShareDraft?> load() async {
    final encoded = await _preferences.getString(storageKey);
    if (encoded == null) return null;
    try {
      if (encoded.length > _maxEncodedLength) throw const FormatException();
      final data = jsonDecode(encoded) as Map<String, dynamic>;
      final savedAt = DateTime.parse(data['saved_at'] as String);
      final age = _now().difference(savedAt);
      if (data['version'] != 1 || age > lifetime || age.isNegative) {
        throw const FormatException('Expired sharing checkpoint');
      }
      return CommunityShareDraft.fromJson(
        data['draft'] as Map<String, dynamic>,
      );
    } on FormatException {
      await clear();
      return null;
    } on TypeError {
      await clear();
      return null;
    } on ArgumentError {
      await clear();
      return null;
    }
  }

  Future<void> clear() => _preferences.remove(storageKey);
}
