import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/features/servers/bloc/servers_bloc.dart';
import 'package:roblox/features/servers/data/servers_repository.dart';
import 'package:roblox/features/servers/models/server_catalog.dart';

ServerCatalog snapshot(int revision, int players) => ServerCatalog(
  banner: '',
  fetchedAt: DateTime.fromMillisecondsSinceEpoch(revision),
  servers: [
    ServerItem.fromApiJson({
      'id': 'one',
      'name': 'Server',
      'online': true,
      'playersOnline': players,
      'playersMax': 3000,
    }, rank: 1),
  ],
);

class _Updates implements RefreshableServersRepository {
  var value = snapshot(1, 100);
  Object? error;
  @override
  Future<ServerCatalog> load() async {
    if (error != null) throw error!;
    return value;
  }

  @override
  Future<ServerCatalog> refresh() => load();
}

void main() {
  test(
    'unchanged revision does not preload or notify UI; new revision commits only after media is ready',
    () async {
      final source = _Updates();
      final old = source.value;
      final mediaReady = Completer<void>();
      var preparations = 0;
      final bloc = ServersBloc(
        source,
        initialData: old,
        prepare: (_) {
          preparations++;
          return mediaReady.future;
        },
      );
      addTearDown(bloc.dispose);
      var notifications = 0;
      bloc.addListener(() => notifications++);
      source.value = snapshot(1, 200);
      await bloc.checkForUpdates();
      expect(notifications, 0);
      expect(preparations, 0);
      expect(identical(bloc.data, old), isTrue);
      source.value = snapshot(0, 10);
      await bloc.checkForUpdates();
      expect(notifications, 0);
      expect(identical(bloc.data, old), isTrue);
      source.value = snapshot(2, 250);
      final pending = bloc.checkForUpdates();
      await Future<void>.delayed(Duration.zero);
      expect(bloc.data!.servers.first.currentPlayers, 100);
      expect(bloc.loading, isFalse);
      expect(notifications, 0);
      mediaReady.complete();
      await pending;
      expect(bloc.data!.servers.first.currentPlayers, 250);
      expect(notifications, 1);
      source.error = StateError('connection interrupted');
      await bloc.checkForUpdates();
      expect(bloc.data!.servers.first.currentPlayers, 250);
      expect(notifications, 1);
    },
  );
  test(
    'failed image preparation and disposing during a request retain the old snapshot',
    () async {
      final source = _Updates();
      final old = source.value;
      final bloc = ServersBloc(
        source,
        initialData: old,
        prepare: (_) async => throw StateError('image interrupted'),
      );
      source.value = snapshot(2, 300);
      await bloc.checkForUpdates();
      expect(identical(bloc.data, old), isTrue);
      bloc.dispose();
      await bloc.checkForUpdates();
    },
  );
}
