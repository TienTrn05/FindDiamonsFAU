import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppTranslations {
  const AppTranslations(this.locale, this.messages);
  final Locale locale;
  final Map<String, String> messages;

  static const languageCodes = ['en', 'es', 'pt', 'tr', 'fr', 'de', 'id', 'vi'];
  static const supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('pt'),
    Locale('tr'),
    Locale('fr'),
    Locale('de'),
    Locale('id'),
    Locale('vi'),
  ];
  static const delegate = _TranslationsDelegate();
  static final _cache = <String, AppTranslations>{};

  static Future<AppTranslations> load(Locale locale) async {
    final code = languageCodes.contains(locale.languageCode)
        ? locale.languageCode
        : 'en';
    if (_cache.containsKey(code)) return _cache[code]!;
    if (code == 'en') return const AppTranslations(Locale('en'), {});
    final json =
        jsonDecode(await rootBundle.loadString('assets/l10n/$code.json'))
            as Map<String, dynamic>;
    return _cache[code] = AppTranslations(
      Locale(code),
      json.cast<String, String>(),
    );
  }

  String trans(String source) {
    final exact = messages[source];
    if (exact != null) return exact;
    for (final entry in messages.entries) {
      final placeholders = RegExp(
        r'\{([a-zA-Z]+)\}',
      ).allMatches(entry.key).toList();
      if (placeholders.isEmpty) continue;
      final pattern = StringBuffer('^');
      var offset = 0;
      for (final placeholder in placeholders) {
        pattern.write(
          RegExp.escape(entry.key.substring(offset, placeholder.start)),
        );
        pattern.write('(.+?)');
        offset = placeholder.end;
      }
      pattern.write('${RegExp.escape(entry.key.substring(offset))}\$');
      final match = RegExp(pattern.toString()).firstMatch(source);
      if (match == null) continue;
      var result = entry.value;
      for (var i = 0; i < placeholders.length; i++) {
        final name = placeholders[i].group(1)!;
        final value = match.group(i + 1)!;
        result = result.replaceAll(
          '{$name}',
          name == 'ore' ? (messages[value] ?? value) : value,
        );
      }
      return result;
    }
    return source;
  }

  static AppTranslations of(BuildContext context) =>
      Localizations.of<AppTranslations>(context, AppTranslations) ??
      const AppTranslations(Locale('en'), {});
}

class _TranslationsDelegate extends LocalizationsDelegate<AppTranslations> {
  const _TranslationsDelegate();
  @override
  bool isSupported(Locale locale) =>
      AppTranslations.languageCodes.contains(locale.languageCode);
  @override
  Future<AppTranslations> load(Locale locale) {
    if (locale.languageCode == 'en') {
      return SynchronousFuture(const AppTranslations(Locale('en'), {}));
    }
    final cached = AppTranslations._cache[locale.languageCode];
    return cached != null
        ? SynchronousFuture(cached)
        : AppTranslations.load(locale);
  }

  @override
  bool shouldReload(_TranslationsDelegate old) => false;
}

extension TranslateContext on BuildContext {
  String tr(String source, {Map<String, String> args = const {}}) {
    var result = AppTranslations.of(this).trans(source);
    for (final entry in args.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }
}
