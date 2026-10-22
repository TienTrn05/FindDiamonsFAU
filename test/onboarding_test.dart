import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/common/widgets/app_loading_page.dart';
import 'package:roblox/core/responsive/app_layout.dart';
import 'package:roblox/core/theme/app_text_styles.dart';
import 'package:roblox/core/theme/app_theme.dart';
import 'package:roblox/features/onboarding/data/tracking_permission_service.dart';
import 'package:roblox/features/onboarding/models/subscription_plan.dart';
import 'package:roblox/features/onboarding/presentation/onboarding_flow.dart';
import 'package:roblox/features/onboarding/presentation/paywall.dart';

class _FakeTrackingPermission extends TrackingPermissionService {
  _FakeTrackingPermission({
    this.initialStatus = TrackingStatus.notDetermined,
    this.pending,
    this.failStatus = false,
    this.failRequest = false,
  });

  final TrackingStatus initialStatus;
  final Future<TrackingStatus>? pending;
  final bool failStatus;
  final bool failRequest;
  int requests = 0;

  @override
  Future<TrackingStatus> get status async {
    if (failStatus) throw StateError('unavailable');
    return initialStatus;
  }

  @override
  Future<TrackingStatus> request() async {
    requests++;
    if (failRequest) throw StateError('unavailable');
    return pending ?? TrackingStatus.denied;
  }
}

const _captureKey = ValueKey('capture');

Future<void> _mount(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  Future<bool> Function(SubscriptionPlan)? onPurchase,
  Future<bool> Function()? onRestore,
  VoidCallback? onComplete,
  TrackingPermissionService? trackingPermission,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: RepaintBoundary(
        key: _captureKey,
        child: OnboardingFlow(
          trackingPermission: trackingPermission ?? _FakeTrackingPermission(),
          onPurchase: onPurchase,
          onRestore: onRestore,
          onComplete: onComplete,
        ),
      ),
    ),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_PREVIEWS'] != 'true') return;
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/images/adventurer.png'),
      tester.element(find.byKey(_captureKey)),
    );
  });
  await tester.pump();
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureKey),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('output/previews').create(recursive: true);
    await File(
      'output/previews/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _openTutorial(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pump();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final pixel = FontLoader(AppFonts.pixel)
      ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
    await pixel.load();
    final body = FontLoader(AppFonts.body)
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await body.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  for (final result in [TrackingStatus.authorized, TrackingStatus.denied]) {
    testWidgets('waits for native permission and continues after $result', (
      tester,
    ) async {
      final pending = Completer<TrackingStatus>();
      final permission = _FakeTrackingPermission(pending: pending.future);
      await _mount(tester, trackingPermission: permission);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();
      expect(permission.requests, 0);
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text('Step 1'), findsNothing);
      expect(permission.requests, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      pending.complete(result);
      await tester.pumpAndSettle();
      expect(find.text('Step 1'), findsOneWidget);
      expect(permission.requests, 1);
    });
  }

  for (final status in [
    TrackingStatus.authorized,
    TrackingStatus.denied,
    TrackingStatus.restricted,
    TrackingStatus.notSupported,
  ]) {
    testWidgets('skips permission explanation for $status', (tester) async {
      final permission = _FakeTrackingPermission(initialStatus: status);
      await _mount(tester, trackingPermission: permission);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
      expect(find.text('Our app wants to stay free for you'), findsNothing);
      expect(find.text('Step 1'), findsOneWidget);
      expect(permission.requests, 0);
    });
  }

  testWidgets('unavailable permission does not block onboarding', (
    tester,
  ) async {
    await _mount(
      tester,
      trackingPermission: _FakeTrackingPermission(failStatus: true),
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('Step 1'), findsOneWidget);
    // Remount with fresh state to exercise a failure after Continue.
    await tester.pumpWidget(const SizedBox.shrink());
    await _mount(
      tester,
      trackingPermission: _FakeTrackingPermission(failRequest: true),
    );
    await _openTutorial(tester);
    expect(find.text('Step 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing while permission is pending is safe', (tester) async {
    final pending = Completer<TrackingStatus>();
    await _mount(
      tester,
      trackingPermission: _FakeTrackingPermission(pending: pending.future),
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(TrackingStatus.denied);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('permission remains usable with large text on a short screen', (
    tester,
  ) async {
    final pending = Completer<TrackingStatus>();
    final permission = _FakeTrackingPermission(pending: pending.future);
    await _mount(
      tester,
      size: const Size(320, 390),
      textScale: 2,
      trackingPermission: permission,
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(permission.requests, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(TrackingStatus.denied);
    await tester.pump();
  });
  testWidgets('complete reference flow, check ores, choose plans, and exit', (
    tester,
  ) async {
    await _mount(tester);
    expect(find.byType(AppLoadingPage), findsOneWidget);
    await _capture(tester, '01-loading');
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    expect(find.text('Our app wants to stay free for you'), findsOneWidget);
    await _capture(tester, '02-consent');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1'), findsOneWidget);
    await _capture(tester, '03-step-one');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2'), findsOneWidget);
    await _capture(tester, '04-step-two');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 3'), findsOneWidget);
    final row = find.byKey(const ValueKey('ore-row-0'));
    expect(
      tester.getSemantics(row).getSemanticsData().flagsCollection.isChecked,
      ui.CheckedState.isTrue,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(row).getSemanticsData().flagsCollection.isChecked,
      ui.CheckedState.isFalse,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    await _capture(tester, '05-step-three');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Remove All Ads'), findsOneWidget);
    await _capture(tester, '06-offer');
    await tester.tap(find.text('View All Plans'));
    await tester.pumpAndSettle();
    await _capture(tester, '07-plans');
    await tester.tap(find.byKey(const ValueKey('plan-yearly')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('999.000/year. Renews yearly. Cancel anytime.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Purchase preview'), findsOneWidget);
    await tester.tap(find.byTooltip('Close paywall'));
    await tester.pumpAndSettle();
    expect(find.text('Ready to explore!'), findsOneWidget);
    await tester.tap(find.text('View tutorial'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paywall Back completes onboarding', (tester) async {
    var completed = false;
    await _mount(tester, onComplete: () => completed = true);
    await _openTutorial(tester);
    await tester.tap(find.text('SKIP'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close paywall'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets('swipe, skip, and verified purchase callback', (tester) async {
    SubscriptionPlan? purchased;
    var completed = false;
    await _mount(
      tester,
      onPurchase: (plan) async {
        purchased = plan;
        return true;
      },
      onComplete: () => completed = true,
    );
    await _openTutorial(tester);
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.text('Step 2'), findsOneWidget);
    await tester.tap(find.text('SKIP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View All Plans'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plan-monthly')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(purchased, SubscriptionPlan.monthly);
    expect(completed, isTrue);
  });

  testWidgets('billing failure and restore results remain recoverable', (
    tester,
  ) async {
    var complete = false;
    await _mount(
      tester,
      onPurchase: (_) async => throw StateError('offline'),
      onRestore: () async => true,
      onComplete: () => complete = true,
    );
    await _openTutorial(tester);
    await tester.tap(find.text('SKIP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Free Trial'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to connect. Please try again.'), findsOneWidget);
    expect(find.byType(Paywall), findsOneWidget);
    await tester.tap(find.text('Restore Purchases'));
    await tester.pumpAndSettle();
    expect(complete, isTrue);
  });

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    testWidgets('all screens fit $size without layout exceptions', (
      tester,
    ) async {
      await _mount(tester, size: size);
      await _openTutorial(tester);
      expect(
        tester.getSize(find.byType(PageView)).width,
        lessThanOrEqualTo(AppLayout.maxContentWidth),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('View All Plans'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close paywall'));
      await tester.pumpAndSettle();
      expect(find.text('Ready to explore!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
