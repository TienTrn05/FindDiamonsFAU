import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/common/widgets/digging_pickaxe.dart';
import 'package:roblox/core/models/search_record.dart';
import 'package:roblox/features/find/bloc/find_bloc.dart';
import 'package:roblox/features/find/data/find_repository.dart';
import 'package:roblox/features/find/models/find_catalog.dart';

const _catalog = FindCatalog(
  title: 'Find Diamonds!',
  help: '',
  versions: [GameVersion(id: 'test', label: 'Test version')],
  ores: [OreOption(id: 'diamond', name: 'Diamond')],
  positions: [],
);
final _record = SearchRecord(
  id: 'test',
  seed: 'test',
  playerX: 0,
  playerZ: 0,
  version: 'Test version',
  oreId: 'diamond',
  oreName: 'Diamond',
  positions: [],
  createdAt: DateTime(2026),
);

class _PendingRepository implements FindRepository {
  final result = Completer<SearchRecord>();
  int requests = 0;
  @override
  Future<FindCatalog> load() async => _catalog;
  @override
  Future<SearchRecord> search(FindQuery query) {
    requests++;
    return result.future;
  }
}

void main() {
  test(
    'a new search randomly unlocks one or two items and records that count',
    () async {
      final repository = JsonFindRepository(random: math.Random(42));
      final catalog = await repository.load();
      final counts = <int>{};
      for (var index = 0; index < 30; index++) {
        final record = await repository.search(
          FindQuery(
            x: 0,
            z: 0,
            seed: '$index',
            version: catalog.versions.first,
            ore: catalog.ores.first,
          ),
        );
        expect(record.revealedCount, inInclusiveRange(1, 2));
        expect(
          SearchRecord.fromJson(record.toJson()).revealedCount,
          record.revealedCount,
        );
        counts.add(record.revealedCount);
      }
      expect(counts, {1, 2});
    },
  );

  testWidgets(
    'digging stays visible for 1.1 seconds with an immediate result',
    (tester) async {
      final repository = _PendingRepository()..result.complete(_record);
      final bloc = FindBloc(repository);
      addTearDown(bloc.dispose);
      await bloc.load();
      final result = bloc.search(x: 0, z: 0, seed: 'test');
      await tester.pump(const Duration(milliseconds: 1000));
      expect(bloc.searching, isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      expect(await result, same(_record));
      expect(bloc.searching, isFalse);
    },
  );

  testWidgets('digging waits for the server and prevents repeated requests', (
    tester,
  ) async {
    final repository = _PendingRepository();
    final bloc = FindBloc(repository);
    addTearDown(bloc.dispose);
    await bloc.load();
    final result = bloc.search(x: -10, z: 20, seed: 'test');
    expect(await bloc.search(x: 0, z: 0, seed: 'duplicate'), isNull);
    expect(repository.requests, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(bloc.searching, isTrue);
    repository.result.complete(_record);
    expect(await result, same(_record));
    expect(bloc.searching, isFalse);
  });

  testWidgets('server errors reset digging and disposal cancels the timer', (
    tester,
  ) async {
    final repository = _PendingRepository();
    final bloc = FindBloc(repository);
    await bloc.load();
    final result = bloc.search(x: 0, z: 0, seed: 'test');
    final expectation = expectLater(result, throwsStateError);
    repository.result.completeError(StateError('offline'));
    await tester.pump(const Duration(milliseconds: 1100));
    await expectation;
    expect(bloc.searching, isFalse);
    bloc.dispose();

    final pending = _PendingRepository();
    final disposed = FindBloc(pending);
    await disposed.load();
    final completion = disposed.search(x: 0, z: 0, seed: 'test');
    disposed.dispose();
    pending.result.complete(_record);
    await completion;
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pickaxe geometry moves between frames and honors reduced motion',
    (tester) async {
      const capture = ValueKey('pickaxe');
      Widget preview({bool reducedMotion = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reducedMotion),
          child: const Center(
            child: RepaintBoundary(
              key: capture,
              child: SizedBox(width: 240, height: 210, child: DiggingPickaxe()),
            ),
          ),
        ),
      );
      await tester.pumpWidget(preview());
      Future<Uint8List> pixels() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(capture),
        );
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data!.buffer.asUint8List();
      }

      final initial = await tester.runAsync(pixels);
      await tester.pump(const Duration(milliseconds: 180));
      final moved = await tester.runAsync(pixels);
      expect(listEquals(initial, moved), isFalse);
      expect(
        find.descendant(
          of: find.byType(DiggingPickaxe),
          matching: find.byType(Image),
        ),
        findsNothing,
      );
      await tester.pumpWidget(preview(reducedMotion: true));
      await tester.pumpAndSettle();
      final stopped = await tester.runAsync(pixels);
      await tester.pump(const Duration(milliseconds: 180));
      expect(listEquals(stopped, await tester.runAsync(pixels)), isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
