import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roblox/common/widgets/skin_head.dart';
import 'package:roblox/common/widgets/mining_neon_panel.dart';
import 'package:roblox/core/theme/app_colors.dart';
import 'package:roblox/core/theme/app_theme.dart';
import 'package:roblox/features/servers/data/servers_repository.dart';
import 'package:roblox/features/servers/models/server_catalog.dart';
import 'package:roblox/features/servers/presentation/server_profile_header.dart';
import 'package:roblox/features/servers/presentation/server_username_dialog.dart';
import 'package:roblox/features/servers/presentation/servers_page.dart';

const _previewKey = ValueKey('servers-profile-preview');

class _Servers implements ServersRepository {
  final pending = Completer<ServerCatalog>();
  var calls = 0;

  @override
  Future<ServerCatalog> load() {
    calls++;
    return pending.future;
  }

  void complete() => pending.complete(
    ServerCatalog(
      banner: 'Tap here...',
      servers: [
        for (var index = 0; index < 12; index++)
          ServerItem(
            id: '$index',
            rank: index + 1,
            name: 'Server $index',
            tags: const ['SMP', 'Survival'],
            online: 10,
            capacity: 100,
            address: 'play.example.com',
            status: 'online',
          ),
      ],
    ),
  );
}

class _RecoveringServers implements ServersRepository {
  int calls = 0;

  @override
  Future<ServerCatalog> load() async {
    calls++;
    return ServerCatalog(
      banner: '',
      liveStatusAvailable: calls > 1,
      servers: [
        ServerItem.fromApiJson({
          'id': 'live',
          'name': 'Live server',
          'online': calls > 1 ? true : null,
          'playersOnline': calls > 1 ? 1234 : null,
          'playersMax': calls > 1 ? 3000 : null,
        }, rank: 1),
      ],
    );
  }
}

class _VersionedServers implements RefreshableServersRepository {
  var calls = 0;
  var revision = 1;
  @override
  Future<ServerCatalog> load() async {
    calls++;
    return ServerCatalog(
      banner: '',
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(revision),
      servers: [
        ServerItem.fromApiJson({
          'id': 'versioned',
          'name': 'Versioned',
          'online': true,
          'playersOnline': revision * 100,
          'playersMax': 3000,
        }, rank: 1),
      ],
    );
  }

  @override
  Future<ServerCatalog> refresh() => load();
}

Future<_Servers> _mount(WidgetTester tester, {double width = 414}) async {
  tester.view.physicalSize = Size(width, 896);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _Servers();
  await tester.pumpWidget(
    RepaintBoundary(
      key: _previewKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(body: ServersPage(repository: repository)),
      ),
    ),
  );
  await tester.pump();
  return repository;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'minute synchronization updates only a new server revision and never depends on scrolling',
    (tester) async {
      final repository = _VersionedServers();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ServersPage(repository: repository)),
        ),
      );
      await tester.pumpAndSettle();
      final card = tester.element(
        find.byKey(const ValueKey('server-versioned')),
      );
      expect(find.text('100/3000'), findsOneWidget);
      await tester.drag(
        find.byKey(const PageStorageKey('server-list')),
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();
      expect(repository.calls, 1);
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
      expect(repository.calls, 2);
      expect(find.text('100/3000'), findsOneWidget);
      expect(
        identical(
          tester.element(find.byKey(const ValueKey('server-versioned'))),
          card,
        ),
        isTrue,
      );
      repository.revision = 2;
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
      expect(repository.calls, 3);
      expect(find.text('200/3000'), findsOneWidget);
      expect(
        identical(
          tester.element(find.byKey(const ValueKey('server-versioned'))),
          card,
        ),
        isTrue,
      );
      expect(find.byType(RefreshIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  setUpAll(() async {
    for (final font in [
      ('Monocraft', 'assets/fonts/Monocraft-Regular.ttf'),
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
    ]) {
      await (FontLoader(font.$1)..addFont(rootBundle.load(font.$2))).load();
    }
  });

  testWidgets('compact profile stays in the header while server data scrolls', (
    tester,
  ) async {
    final repository = await _mount(tester);
    final header = find.byType(ServerProfileHeader);
    expect(find.byTooltip('Tap here...'), findsNothing);
    expect(find.byType(SkinHead), findsOneWidget);
    expect(tester.getSize(header), const Size(40, 40));
    final before = tester.getRect(header);
    repository.complete();
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('server-list')),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(header), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'scrolling away and back retains the actual card element and data',
    (tester) async {
      final repository = await _mount(tester);
      repository.complete();
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('server-0'));
      final original = tester.element(card);
      final list = find.byKey(const PageStorageKey('server-list'));
      await tester.drag(list, const Offset(0, -1600));
      await tester.pumpAndSettle();
      // A normal lazy list would have disposed this element outside cacheExtent.
      expect(original.mounted, isTrue);
      await tester.drag(list, const Offset(0, 1600));
      await tester.pumpAndSettle();
      expect(identical(tester.element(card), original), isTrue);
      expect(repository.calls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pulling at the top never reloads the server page', (
    tester,
  ) async {
    final repository = _RecoveringServers();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: ServersPage(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('server-status-unavailable')),
      findsOneWidget,
    );
    expect(find.text('Unknown'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsNothing);
    expect(find.byKey(const ValueKey('refresh-servers')), findsNothing);
    await tester.drag(
      find.byKey(const PageStorageKey('server-list')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();
    expect(repository.calls, 1);
    expect(
      find.byKey(const ValueKey('server-status-unavailable')),
      findsOneWidget,
    );
    expect(find.text('Unknown'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('server borders stay colorful beyond the first five cards', (
    tester,
  ) async {
    final repository = await _mount(tester);
    repository.complete();
    await tester.pumpAndSettle();
    final accents = <Color>{};
    for (var i = 5; i < 12; i++) {
      final card = find.byKey(ValueKey('server-$i'));
      await tester.scrollUntilVisible(
        card,
        250,
        scrollable: find.descendant(
          of: find.byKey(const PageStorageKey('server-list')),
          matching: find.byType(Scrollable),
        ),
      );
      final panel = tester.widget<MiningNeonPanel>(
        find.ancestor(of: card, matching: find.byType(MiningNeonPanel)).first,
      );
      expect(panel.accent, isNot(AppColors.stone));
      accents.add(panel.accent);
    }
    expect(accents.length, greaterThanOrEqualTo(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile tap does not open the username dialog', (tester) async {
    final repository = await _mount(tester);
    repository.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-username-header')));
    await tester.pumpAndSettle();
    expect(find.byType(ServerUsernameDialog), findsNothing);
    expect(find.byKey(const ValueKey('server-username-input')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
