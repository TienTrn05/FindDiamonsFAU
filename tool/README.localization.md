# App language

`AppText` translates visible app text through `context.tr(source)`. Use
`context.tr(source, args: {'name': value})` for validators, tooltips and
parameterized labels. Keep user input, server addresses and proper names out of
translation catalogs.

The eight offline catalogs are generated from `localization_catalog.tsv` (a
pipe-separated authoring table, ordered en/es/pt/tr/fr/de/id/vi):

```sh
python tool/build_translations.py
flutter test test/app_translations_test.dart
```

When changing app-owned English source text, update the corresponding source
column and its translations together. English and unknown data fall back to
their original values. Templates retain numeric values, seeds and addresses.

`AppLocaleController` persists `app_language`. `MyApp` supplies its locale to
MaterialApp and Flutter's Material/Cupertino localization delegates. With no
saved preference, Flutter resolves a supported device language. Language changes
retain route and form state. iOS declares all eight languages in Info.plist;
the same Dart catalogs run on Android. Flags are bundled PNG assets, not emoji
or network images. Their source is documented under `assets/images/flags/`.

Translation tests cover catalog parity, placeholders and data preservation.
Navigation tests exercise switching, all main tabs and persistence using both
Android and iOS target configurations. They also check long labels on a small
screen. A native iOS build still requires macOS/Xcode.
