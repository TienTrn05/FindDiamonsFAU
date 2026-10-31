import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roblox/features/maps/bloc/maps_bloc.dart';
import 'package:roblox/features/maps/data/api_maps_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'API versions are sorted and seeds filter by version and edition',
    () async {
      final previous = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previous);
      SharedPreferences.setMockInitialValues({});
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        final body = switch (request.uri.path) {
          '/api/versions' => {
            'java': ['1.19', '26.1', '1.21'],
            'bedrock': ['1.20', '1.19'],
          },
          '/api/seeds' => {
            'items': [
              {
                'id': 'j',
                'title': 'Java',
                'seed': '1',
                'edition': 'java',
                'version': '1.19',
              },
              {
                'id': 'b',
                'title': 'Bedrock',
                'seed': '2',
                'edition': 'bedrock',
                'version': '1.19',
              },
            ],
          },
          '/api/maps' => {
            'items': [
              {
                'id': 'multi',
                'title': 'Many tags',
                'edition': 'java',
                'category': 'parkour',
                'categories': ['challenge', 'minigame', 'challenge'],
              },
              {
                'id': 'horror',
                'title': 'Horror map',
                'edition': 'java',
                'category': 'horror',
              },
            ],
          },
          _ => {'items': []},
        };
        request.response.write(jsonEncode(body));
        await request.response.close();
      });
      final bloc = MapsBloc(
        ApiMapsRepository(
          baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
        ),
      );
      addTearDown(bloc.dispose);
      await bloc.load();
      for (final category in ['Parkour', 'Challenges', 'Mini game']) {
        bloc.selectCategory(category);
        expect(bloc.visible.map((item) => item.id), ['multi']);
      }
      bloc.selectCategory('Horror');
      expect(bloc.visible.map((item) => item.id), ['horror']);
      bloc.toggleFavourite('multi');
      bloc.selectCategory('Favourite');
      expect(bloc.visible.map((item) => item.id), ['multi']);
      expect(bloc.versionsFor('java'), ['26.1', '1.21', '1.19']);
      expect(bloc.versionsFor('bedrock'), ['1.20', '1.19']);
      bloc.selectCategory('Seeds');
      bloc.selectSeedVersion('1.19 Java');
      expect(bloc.visible.map((item) => item.id), ['j']);
      bloc.selectSeedVersion('1.19 Bedrock');
      expect(bloc.visible.map((item) => item.id), ['b']);
      bloc.selectSeedVersion('1.20 Bedrock');
      expect(bloc.visible, isEmpty);
    },
  );
}
