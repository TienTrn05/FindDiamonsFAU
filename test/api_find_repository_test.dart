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
    var polls = 0;
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/api/versions') {
        request.response.write(
          jsonEncode({
            'java': ['26.1', '1.16'],
            'bedrock': ['1.21.2', '1.21', '1.20'],
          }),
        );
      } else if (request.uri.path == '/api/ores') {
        request.response.write(
          jsonEncode({
            'ores': [
              {'id': 'diamond', 'name': 'Diamond', 'availableFrom': '1.16'},
              {'id': 'copper', 'name': 'Copper', 'availableFrom': '1.21.1'},
              {'id': 'iron', 'name': 'Iron', 'availableFrom': '1.16'},
            ],
          }),
        );
      } else if (request.uri.path == '/api/plan') {
        plan =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        request.response.statusCode = HttpStatus.accepted;
        request.response.write(
          jsonEncode({'jobId': 'job-1', 'status': 'queued'}),
        );
      } else if (request.uri.path == '/api/plan/jobs/job-1') {
        polls++;
        request.response.write(
          jsonEncode(
            polls == 1
                ? {'jobId': 'job-1', 'status': 'running'}
                : {
                    'jobId': 'job-1',
                    'status': 'succeeded',
                    'result': {
                      'oreName': 'Iron',
                      'points': [
                        {'x': 12, 'y': -54, 'z': 30, 'distance': 5},
                      ],
                    },
                  },
          ),
        );
      }
      await request.response.close();
    });
    final repository = ApiFindRepository(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
      pollInterval: const Duration(milliseconds: 1),
    );
    final bloc = FindBloc(repository);
    addTearDown(bloc.dispose);
    await bloc.load();
    expect(bloc.data!.versions.map((v) => v.id), [
      'java_26.1',
      'java_1.16',
      'bedrock_1.21.2',
      'bedrock_1.21',
      'bedrock_1.20',
    ]);
    bloc.selectVersion('java_1.16');
    expect(bloc.availableOres.map((ore) => ore.id), ['diamond', 'iron']);
    bloc.selectVersion('bedrock_1.21');
    expect(bloc.availableOres.map((ore) => ore.id), ['diamond', 'iron']);
    expect(bloc.version.label, '1.21 Bedrock Edition');
    bloc.selectVersion('bedrock_1.21.2');
    expect(bloc.availableOres.map((ore) => ore.id), [
      'diamond',
      'copper',
      'iron',
    ]);
    bloc.selectOre('iron');
    final record = await repository.search(
      FindQuery(x: 0, z: 0, seed: '42', version: bloc.version, ore: bloc.ore),
    );
    expect(plan!['edition'], 'bedrock');
    expect(plan!['version'], '1.21.2');
    expect(plan!['ore'], 'iron');
    expect(polls, 2);
    expect(record.oreName, 'Iron');
    expect(record.positions.single.x, 12);
    expect(record.positions.single.y, -54);
    expect(record.positions.single.z, 30);
  });

  test('surfaces a failed job error', () async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/api/plan') {
        await utf8.decoder.bind(request).join();
        request.response.statusCode = HttpStatus.accepted;
        request.response.write(
          jsonEncode({'jobId': 'job-2', 'status': 'queued'}),
        );
      } else if (request.uri.path == '/api/plan/jobs/job-2') {
        request.response.write(
          jsonEncode({
            'jobId': 'job-2',
            'status': 'failed',
            'error': 'Unsupported world version',
          }),
        );
      }
      await request.response.close();
    });
    final repository = ApiFindRepository(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
      pollInterval: const Duration(milliseconds: 1),
    );
    final query = FindQuery(
      x: 0,
      z: 0,
      seed: '42',
      version: const GameVersion(
        id: 'java_1.20',
        label: '1.20 Java Edition',
        apiVersion: '1.20',
      ),
      ore: const OreOption(id: 'diamond', name: 'Diamond'),
    );
    await expectLater(
      repository.search(query),
      throwsA(
        isA<HttpException>().having(
          (error) => error.message,
          'message',
          'Unsupported world version',
        ),
      ),
    );
  });
}
