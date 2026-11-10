import 'package:flutter/foundation.dart';

import '../data/community_repository.dart';
import '../models/sighting.dart';
import '../data/blocked_authors_repository.dart';

class CommunityController extends ChangeNotifier {
  final CommunityRepository repository;

  /// Autores bloqueados neste aparelho; os registros deles não aparecem.
  final BlockedAuthorsRepository? blockedAuthors;
  CommunityController(this.repository, {this.blockedAuthors});
  Set<String> _blocked = const {};
  List<Sighting> items = [];
  List<Municipality> municipalities = [];
  String? accountId, municipalityId, error;
  String species = '';
  bool mine = false, loading = false, hasMore = true;
  int _revision = 0;
  bool _disposed = false;
  Municipality? municipality(String id) {
    for (final m in municipalities) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({bool reset = false}) async {
    if (loading && !reset) return;
    final revision = ++_revision;
    if (reset) {
      items = [];
      hasMore = true;
    }
    loading = true;
    error = null;
    _notify();
    try {
      if (municipalities.isEmpty) {
        municipalities = await repository.municipalities();
      }
      accountId = await repository.accountId();
      try {
        _blocked = await blockedAuthors?.load() ?? const {};
      } catch (_) {
        _blocked = const {};
      }
      final next = await repository.page(
        offset: items.length,
        municipalityId: municipalityId,
        species: species,
        mine: mine,
      );
      if (_disposed || revision != _revision) return;
      final ids = items.map((e) => e.id).toSet();
      items = [
        ...items,
        ...next.where(
          (e) => (mine || !_blocked.contains(e.ownerId)) && ids.add(e.id),
        ),
      ];
      hasMore = next.length == 20;
    } catch (e) {
      if (!_disposed && revision == _revision) {
        error = e is CommunityFailure
            ? e.message
            : 'Não foi possível carregar. Tente novamente.';
      }
    } finally {
      if (!_disposed && revision == _revision) {
        loading = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}
