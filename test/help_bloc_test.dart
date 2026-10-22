import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/features/help/bloc/help_bloc.dart';
import 'package:roblox/features/help/data/help_repository.dart';

void main() {
  test(
    'restore blocks repeated requests until the pending result finishes',
    () async {
      final pending = Completer<bool>();
      var requests = 0;
      final bloc = HelpBloc(
        const JsonHelpRepository(),
        onRestore: () {
          requests++;
          return pending.future;
        },
      );
      addTearDown(bloc.dispose);

      final first = bloc.restore();
      expect(bloc.restoring, isTrue);
      expect(await bloc.restore(), isNull);
      expect(requests, 1);
      pending.complete(true);
      expect(await first, 'Purchases restored.');
      expect(bloc.restoring, isFalse);
    },
  );

  test('restore failure allows another attempt', () async {
    var requests = 0;
    final bloc = HelpBloc(
      const JsonHelpRepository(),
      onRestore: () async {
        if (requests++ == 0) throw StateError('offline');
        return false;
      },
    );
    addTearDown(bloc.dispose);

    expect(
      await bloc.restore(),
      'Unable to restore purchases. Please try again.',
    );
    expect(bloc.restoring, isFalse);
    expect(await bloc.restore(), 'No active purchases were found.');
    expect(requests, 2);
  });
}
