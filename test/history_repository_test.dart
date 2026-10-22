import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/core/models/search_record.dart';
import 'package:roblox/features/history/data/history_repository.dart';
import 'package:roblox/features/history/data/history_store_io.dart';

import 'support/memory_history_store.dart';

SearchRecord _record(String id, {int day = 1}) => SearchRecord(
  id: id,
  seed: '-9223372036854775808',
  playerX: -30,
  playerZ: 120,
  version: '1.20 Bedrock',
  oreId: 'copper',
  oreName: 'Copper',
  positions: const [
    OrePosition(x: 32, y: -54, z: 152, count: 3),
    OrePosition(x: 9, y: -41, z: 148, count: 9),
  ],
  createdAt: DateTime.utc(2026, 10, day),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'JSON file restores complete digging results and persists deletion',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'roblox-history-',
      );
      addTearDown(() => directory.delete(recursive: true));
      HistoryFileStore storage() =>
          HistoryFileStore(directory: () async => directory);
      final repository = JsonHistoryRepository(store: storage());
      final record = _record('first');
      await repository.add(record);

      final file = File('${directory.path}/history.json');
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(json['schemaVersion'], 1);
      expect(json['searches'], [record.toJson()]);

      final restarted = JsonHistoryRepository(store: storage());
      final restored = (await restarted.load()).searches.single;
      expect(restored.toJson(), record.toJson());
      expect(restored.positions.first.count, 3);
      await restarted.remove(record.id);
      expect(
        (await JsonHistoryRepository(store: storage()).load()).searches,
        isEmpty,
      );
    },
  );

  test(
    'concurrent changes retain every record and sort newest first',
    () async {
      final store = MemoryHistoryStore();
      final repository = JsonHistoryRepository(store: store);
      await Future.wait([
        repository.add(_record('old', day: 1)),
        repository.add(_record('new', day: 3)),
        repository.add(_record('middle', day: 2)),
        repository.remove('old'),
      ]);
      // Updating the same search does not produce a duplicate card.
      await repository.add(_record('middle', day: 2));
      final restarted = JsonHistoryRepository(store: store);
      expect((await restarted.load()).searches.map((item) => item.id), [
        'new',
        'middle',
      ]);
    },
  );

  test(
    'write failure is reported, keeps session results and permits retry',
    () async {
      final store = MemoryHistoryStore()..failWrite = true;
      final repository = JsonHistoryRepository(store: store);
      await expectLater(repository.add(_record('first')), throwsStateError);
      expect((await repository.load()).searches.single.id, 'first');
      expect(store.json, isNull);
      store.failWrite = false;
      await repository.add(_record('second', day: 2));
      expect(
        (await JsonHistoryRepository(store: store).load()).searches.length,
        2,
      );
    },
  );

  test(
    'corrupt JSON is reported without overwriting the saved document',
    () async {
      final store = MemoryHistoryStore()..json = '{broken';
      final repository = JsonHistoryRepository(store: store);
      await expectLater(repository.load(), throwsFormatException);
      await expectLater(
        repository.add(_record('first')),
        throwsFormatException,
      );
      expect(store.json, '{broken');
      store.json = null;
      await repository.add(_record('first'));
      expect((await repository.load()).searches.single.id, 'first');
    },
  );
}
