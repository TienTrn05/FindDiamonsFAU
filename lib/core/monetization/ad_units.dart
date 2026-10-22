import 'package:flutter/foundation.dart';

enum AdPlacement { banner, interstitial, native, appOpen }

abstract final class AdUnits {
  static String id(AdPlacement placement) {
    final android = defaultTargetPlatform == TargetPlatform.android;
    if (kDebugMode) {
      return switch (placement) {
        AdPlacement.appOpen =>
          android
              ? 'ca-app-pub-3940256099942544/9257395921'
              : 'ca-app-pub-3940256099942544/5575463023',
        AdPlacement.banner =>
          android
              ? 'ca-app-pub-3940256099942544/9214589741'
              : 'ca-app-pub-3940256099942544/2435281174',
        AdPlacement.interstitial =>
          android
              ? 'ca-app-pub-3940256099942544/1033173712'
              : 'ca-app-pub-3940256099942544/4411468910',
        AdPlacement.native =>
          android
              ? 'ca-app-pub-3940256099942544/2247696110'
              : 'ca-app-pub-3940256099942544/3986624511',
      };
    }
    return switch (placement) {
      AdPlacement.appOpen =>
        android
            ? const String.fromEnvironment('ADMOB_APP_OPEN_ANDROID')
            : const String.fromEnvironment('ADMOB_APP_OPEN_IOS'),
      AdPlacement.banner =>
        android
            ? const String.fromEnvironment('ADMOB_BANNER_ANDROID')
            : const String.fromEnvironment('ADMOB_BANNER_IOS'),
      AdPlacement.interstitial =>
        android
            ? const String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID')
            : const String.fromEnvironment('ADMOB_INTERSTITIAL_IOS'),
      AdPlacement.native =>
        android
            ? const String.fromEnvironment('ADMOB_NATIVE_ANDROID')
            : const String.fromEnvironment('ADMOB_NATIVE_IOS'),
    };
  }
}
