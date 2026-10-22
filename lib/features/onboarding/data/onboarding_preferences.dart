import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPreferences {
  static const seenKey = 'onboarding_seen';
  static const completedKey = 'onboarding_completed';

  Future<bool> isSeen() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getBool(seenKey) ?? false) ||
        (preferences.getBool(completedKey) ?? false);
  }

  Future<void> markSeen() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(seenKey, true);
    if (!saved) throw StateError('Unable to save onboarding seen state');
  }

  Future<void> complete() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(completedKey, true);
  }
}
