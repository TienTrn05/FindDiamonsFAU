import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/features/onboarding/data/tracking_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app_tracking_transparency');
  const service = TrackingPermissionService();
  final calls = <String>[];
  var status = TrackingStatus.notDetermined;

  setUp(() {
    calls.clear();
    status = TrackingStatus.notDetermined;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'getTrackingAuthorizationStatus') {
            return status.index;
          }
          if (call.method == 'requestTrackingAuthorization') {
            return TrackingStatus.denied.index;
          }
          throw MissingPluginException();
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('iOS reads permission without displaying the prompt', () async {
    expect(await service.status, TrackingStatus.notDetermined);
    expect(calls, ['getTrackingAuthorizationStatus']);
  });

  test('iOS Continue invokes native ATT and returns its decision', () async {
    expect(await service.request(), TrackingStatus.denied);
    expect(calls, [
      'getTrackingAuthorizationStatus',
      'requestTrackingAuthorization',
    ]);
  });

  for (final existing in [
    TrackingStatus.authorized,
    TrackingStatus.denied,
    TrackingStatus.restricted,
    TrackingStatus.notSupported,
  ]) {
    test('does not request ATT again for $existing', () async {
      status = existing;
      expect(await service.request(), existing);
      expect(calls, ['getTrackingAuthorizationStatus']);
    });
  }

  for (final platform in [TargetPlatform.android, TargetPlatform.windows]) {
    test('$platform never invokes the iOS plugin or grants tracking', () async {
      debugDefaultTargetPlatformOverride = platform;
      expect(await service.status, TrackingStatus.notSupported);
      expect(await service.request(), TrackingStatus.notSupported);
      expect(calls, isEmpty);
    });
  }
}
