import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/features/servers/models/server_catalog.dart';
import 'package:roblox/features/servers/presentation/server_status.dart';

void main() {
  for (final state in [true, false, null]) {
    testWidgets('renders player count and explicit status for $state', (
      tester,
    ) async {
      final item = ServerItem.fromApiJson({
        'id': 'test',
        'name': 'Test',
        'online': state,
        'playersOnline': 0,
        'playersMax': 100,
      }, rank: 1);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ServerStatus(server: item)),
        ),
      );
      expect(find.text(state == true ? '0/100' : '\u2014'), findsOneWidget);
      expect(
        find.text(
          state == true
              ? 'Online'
              : state == false
              ? 'Offline'
              : 'Unknown',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
