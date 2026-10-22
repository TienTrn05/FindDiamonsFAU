import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Shared SDK initialization, consent and exclusive ownership of full-screen ads.
class AdsRuntime extends ChangeNotifier {
  AdsRuntime({this.enabled = true, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final bool enabled;
  final DateTime Function() _now;
  Future<bool>? _preparing;
  Future<void>? _initializing;
  bool _consentChecked = false;
  bool _disposed = false;
  Object? _fullscreenOwner;
  DateTime? lastFullscreenClosedAt;
  int privacyRevision = 0;

  static bool get platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  bool get available => enabled && platformSupported && !_disposed;
  bool get fullscreenBusy => _fullscreenOwner != null;

  bool beginFullscreen(Object owner) {
    if (!available || fullscreenBusy) return false;
    _fullscreenOwner = owner;
    notifyListeners();
    return true;
  }

  void endFullscreen(Object owner, {required bool wasShown}) {
    if (_disposed || !identical(_fullscreenOwner, owner)) return;
    _fullscreenOwner = null;
    if (wasShown) lastFullscreenClosedAt = _now();
    notifyListeners();
  }

  Future<bool> prepare({required bool Function() canShowConsent}) {
    if (!available) return Future.value(false);
    return _preparing ??= _prepare(canShowConsent).whenComplete(() {
      _preparing = null;
    });
  }

  Future<bool> _prepare(bool Function() canShowConsent) async {
    try {
      if (!kDebugMode && !_consentChecked) {
        final consent = Completer<void>();
        ConsentInformation.instance.requestConsentInfoUpdate(
          ConsentRequestParameters(),
          () async {
            try {
              if (!_disposed && canShowConsent()) {
                await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
              }
            } catch (error) {
              debugPrint('Ad consent form unavailable: $error');
            } finally {
              if (!consent.isCompleted) consent.complete();
            }
          },
          (_) {
            if (!consent.isCompleted) consent.complete();
          },
        );
        await consent.future;
        _consentChecked = true;
      }
      if (_disposed) return false;
      if (!kDebugMode && !await ConsentInformation.instance.canRequestAds()) {
        _consentChecked = false;
        return false;
      }
      await (_initializing ??= MobileAds.instance.initialize().then(
        (_) {},
      )).timeout(const Duration(seconds: 15));
      return !_disposed;
    } catch (error) {
      debugPrint('Ads SDK unavailable: $error');
      _initializing = null;
      return false;
    }
  }

  Future<bool> privacyOptionsRequired() async =>
      available &&
      !kDebugMode &&
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;

  Future<void> showPrivacyOptions() async {
    final closed = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error == null) {
        closed.complete();
      } else {
        closed.completeError(StateError(error.message));
      }
    });
    await closed.future;
    _consentChecked = false;
    if (!_disposed) {
      privacyRevision++;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
