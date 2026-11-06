import 'package:ecolens/controllers/community_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/community_fake.dart';

void main() {
  test(
    'paginates published records without duplicating and resets filters',
    () async {
      final repository = CommunityFake()
        ..items = List.generate(21, (n) => fixture(id: '$n'));
      final c = CommunityController(repository);
      await c.load();
      expect(c.items.length, 20);
      expect(c.hasMore, true);
      await c.load();
      expect(c.items.length, 21);
      expect(c.hasMore, false);
      c.species = 'missing';
      await c.load(reset: true);
      expect(c.items, isEmpty);
      expect(c.hasMore, false);
      c.dispose();
    },
  );
  test('failed page preserves records and can be retried', () async {
    final repository = CommunityFake()
      ..items = List.generate(21, (n) => fixture(id: '$n'));
    final c = CommunityController(repository);
    await c.load();
    repository.fail = true;
    await c.load();
    expect(c.items.length, 20);
    expect(c.error, 'Falha de rede');
    repository.fail = false;
    await c.load();
    expect(c.items.length, 21);
    expect(c.error, isNull);
    c.dispose();
  });
}
