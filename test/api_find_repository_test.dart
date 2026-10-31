import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/features/find/bloc/find_bloc.dart';
import 'package:roblox/features/find/data/api_find_repository.dart';
import 'package:roblox/features/find/models/find_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads both editions and sends the selected Bedrock version', () async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    Map<String, dynamic>? plan;
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/api/versions') {
        request.response.write(
          jsonEncode({
            'java': ['26.1', '1.16'],
            'bedrock': ['1.21', '1.20'],
          }),
        );
      } else if (request.uri.path == '/api/ores') {
        request.response.write(
          jsonEncode({
            'ores': [
              {'id': 'diamond', 'name': 'Diamond'},
            ],
          }),
        );
      } else {
        plan =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        request.response.write(jsonEncode({'points': []}));
      }
      await request.response.close();
    });
    final repository = ApiFindRepository(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
    );
    final bloc = FindBloc(repository);
    addTearDown(bloc.dispose);
    await bloc.load();
    expect(bloc.data!.versions.map((v) => v.id), [
      'java_26.1',
      'java_1.16',
      'bedrock_1.21',
      'bedrock_1.20',
    ]);
    bloc.selectVersion('bedrock_1.21');
    expect(bloc.version.label, '1.21 Bedrock Edition');
    await repository.search(
      FindQuery(x: 0, z: 0, seed: '42', version: bloc.version, ore: bloc.ore),
    );
    expect(plan!['edition'], 'bedrock');
    expect(plan!['version'], '1.21');
  });
}
