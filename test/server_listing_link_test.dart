import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:roblox/core/network/api_config.dart';
import 'package:roblox/features/servers/models/server_catalog.dart';
import 'package:roblox/features/servers/presentation/servers_page.dart';

import 'support/fake_url_launcher.dart';

void main() {
  testWidgets('server listing link opens the backend page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final previous = UrlLauncherPlatform.instance;
    final launcher = FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = previous);
    await tester.pumpWidget(
      MaterialApp(
        home: ServersPage(
          initialCatalog: ServerCatalog(banner: '', servers: const []),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('list-your-server')));
    await tester.pump();
    expect(
      launcher.requests.single.$1,
      ApiConfig.baseUri.resolve('/mcstat.html').toString(),
    );
  });
}
