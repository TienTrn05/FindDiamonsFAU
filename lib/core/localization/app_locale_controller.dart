import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_translations.dart';

class AppLocaleController extends ChangeNotifier {
  static const preferenceKey = 'app_language';
  Locale? locale;
  bool saving = false;
  bool _disposed = false;

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final code = preferences.getString(preferenceKey);
      if (!_disposed && AppTranslations.languageCodes.contains(code)) {
        locale = Locale(code!);
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Unable to load app language: $error');
    }
  }

  Future<void> select(String code) async {
    if (saving || !AppTranslations.languageCodes.contains(code)) return;
    saving = true;
    if (!_disposed) notifyListeners();
    try {
      await AppTranslations.load(Locale(code));
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setString(preferenceKey, code)) {
        throw StateError('Unable to save app language');
      }
      if (!_disposed) locale = Locale(code);
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class AppLanguageScope extends InheritedNotifier<AppLocaleController> {
  const AppLanguageScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLanguageScope>()?.notifier;
}
