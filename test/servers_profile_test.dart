import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roblox/common/widgets/voxel_character.dart';
import 'package:roblox/core/theme/app_theme.dart';
import 'package:roblox/features/servers/data/servers_repository.dart';
import 'package:roblox/features/servers/models/server_catalog.dart';
import 'package:roblox/features/servers/presentation/server_profile_header.dart';
import 'package:roblox/features/servers/presentation/server_username_dialog.dart';
import 'package:roblox/features/servers/presentation/servers_page.dart';

const _previewKey = ValueKey('servers-profile-preview');

class _Servers implements ServersRepository {
  final pending = Completer<ServerCatalog>();

  @override
  Future<ServerCatalog> load() => pending.future;

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

Future<void> _capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_PREVIEWS'] != 'true') return;
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/images/block_landscape.png'),
      tester.element(find.byKey(_previewKey)),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_previewKey),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('output/previews').create(recursive: true);
      await File('output/previews/$name.png').writeAsBytes(
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  setUpAll(() async {
    for (final font in [
      ('Monocraft', 'assets/fonts/Monocraft-Regular.ttf'),
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
    ]) {
      await (FontLoader(font.$1)..addFont(rootBundle.load(font.$2))).load();
    }
  });

  testWidgets(
    'profile is full width, centered and stays above scrolling data',
    (tester) async {
      final repository = await _mount(tester);
      final header = find.byType(ServerProfileHeader);
      expect(find.text('Tap here...'), findsOneWidget);
      expect(find.byType(VoxelCharacter), findsOneWidget);
      expect(tester.getSize(header), const Size(414, 64));
      expect(tester.getCenter(find.text('Tap here...')).dx, 207);
      final head = find.byType(VoxelCharacter);
      expect(tester.getSize(head), const Size(48, 48));
      expect(tester.getRect(head).right, 398);

      repository.complete();
      await tester.pumpAndSettle();
      final list = find.byKey(const PageStorageKey('server-list'));
      expect(tester.getRect(list).top, tester.getRect(header).bottom);
      expect(tester.getRect(find.byKey(const ValueKey('server-0'))).left, 0);
      expect(
        tester.getCenter(find.text('10/100').first).dy,
        closeTo(tester.getCenter(find.text('#1')).dy, 0.1),
      );
      await _capture(tester, 'servers-profile-header');
      await tester.drag(list, const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(tester.getRect(header).top, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Done hides keyboard; only OK saves; Cancel preserves username', (
    tester,
  ) async {
    final repository = await _mount(tester);
    repository.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-username-header')));
    await tester.pumpAndSettle();
    final input = find.byKey(const ValueKey('server-username-input'));
    await tester.enterText(input, 'JAAJs');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(ServerUsernameDialog), findsOneWidget);
    final panel = find
        .descendant(
          of: find.byType(ServerUsernameDialog),
          matching: find.byType(Material),
        )
        .first;
    expect(tester.getSize(panel).width, 232);
    expect(
      (await SharedPreferences.getInstance()).getString('minecraft_username'),
      isNull,
    );
    await _capture(tester, 'servers-profile-dialog');
    await tester.tap(find.byKey(const ValueKey('server-username-save')));
    await tester.pumpAndSettle();
    expect(find.byType(ServerUsernameDialog), findsNothing);
    expect(find.text('JAAJs'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('minecraft_username'),
      'JAAJs',
    );

    await tester.tap(find.byKey(const ValueKey('server-username-header')));
    await tester.pumpAndSettle();
    await tester.enterText(input, 'OtherUser');
    await tester.tap(find.byKey(const ValueKey('server-username-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('JAAJs'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('minecraft_username'),
      'JAAJs',
    );

    await tester.tap(find.byKey(const ValueKey('server-username-header')));
    await tester.pumpAndSettle();
    await tester.enterText(input, '');
    await tester.tap(find.byKey(const ValueKey('server-username-save')));
    await tester.pumpAndSettle();
    expect(find.text('Tap here...'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('minecraft_username'),
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('username dialog fits a small screen with the keyboard open', (
    tester,
  ) async {
    final repository = await _mount(tester, width: 320);
    repository.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-username-header')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final button = tester.getRect(
      find.byKey(const ValueKey('server-username-save')),
    );
    expect(button.bottom, lessThanOrEqualTo(296));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('server-username-cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(ServerUsernameDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
