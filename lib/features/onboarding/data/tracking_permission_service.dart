import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

export 'package:app_tracking_transparency/app_tracking_transparency.dart'
    show TrackingStatus;

/// ATT is an iOS permission. Android ad consent belongs to the ads SDK/CMP,
/// and must not be inferred from this service or from pressing Continue.
class TrackingPermissionService {
  const TrackingPermissionService();

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<TrackingStatus> get status async {
    if (!_supported) return TrackingStatus.notSupported;
    return AppTrackingTransparency.trackingAuthorizationStatus;
  }

  Future<TrackingStatus> request() async {
    final current = await status;
    if (current != TrackingStatus.notDetermined) return current;
    return AppTrackingTransparency.requestTrackingAuthorization();
  }
}
