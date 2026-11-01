import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/common/widgets/app_loading_page.dart';
import 'package:roblox/common/widgets/wave_loading_text.dart';
import 'package:roblox/core/localization/app_translations.dart';
import 'package:roblox/core/theme/app_theme.dart';
import 'package:roblox/features/onboarding/presentation/tutorial_pages.dart';
import 'package:roblox/features/servers/presentation/server_profile_header.dart';
import 'package:roblox/features/servers/presentation/server_username_dialog.dart';

Widget _app(Widget child, {String language = 'vi', double textScale = 1}) =>
    MaterialApp(
      theme: AppTheme.dark,
      locale: Locale(language),
      supportedLocales: AppTranslations.supportedLocales,
      localizationsDelegates: const [
        AppTranslations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

void main() {
  setUpAll(() async {
    for (final locale in AppTranslations.supportedLocales) {
      await AppTranslations.load(locale);
    }
    for (final font in [
      ('Monocraft', 'assets/fonts/Monocraft-Regular.ttf'),
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
    ]) {
      await (FontLoader(font.$1)..addFont(rootBundle.load(font.$2))).load();
    }
  });

  testWidgets('username dialog follows language changes and preserves input', (
    tester,
  ) async {
    const dialog = ServerUsernameDialog(username: 'Steve_01');
    await tester.pumpWidget(_app(dialog));
    await tester.pump();
    expect(find.text('Nhập tên người chơi Minecraft'), findsOneWidget);
    expect(find.text('Hủy'), findsOneWidget);
    expect(find.text('Đồng ý'), findsOneWidget);
    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.controller!.text, 'Steve_01');
    await tester.enterText(find.byType(TextField), 'Alex_02');

    await tester.pumpWidget(_app(dialog, language: 'en'));
    await tester.pump();
    expect(find.text('Enter your Minecraft username'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(input.controller!.text, 'Alex_02');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'profile prompt and tooltip translate while usernames stay intact',
    (tester) async {
      await tester.pumpWidget(
        _app(ServerProfileHeader(username: null, onTap: () {})),
      );
      await tester.pump();
      expect(find.text('Nhấn vào đây...'), findsOneWidget);
      await tester.pumpWidget(
        _app(ServerProfileHeader(username: null, compact: true, onTap: () {})),
      );
      expect(find.byTooltip('Nhấn vào đây...'), findsOneWidget);
      await tester.pumpWidget(
        _app(ServerProfileHeader(username: 'Steve_01', onTap: () {})),
      );
      expect(find.text('Steve_01'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'animated loading text translates and fits a small enlarged screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(const AppLoadingPage(), textScale: 2));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.bySemanticsLabel('Vui lòng chờ...'), findsOneWidget);
      final characters = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(WaveLoadingText),
          matching: find.byType(Text),
        ),
      );
      expect(characters.map((text) => text.data).join(), 'Vui lòng chờ...');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(_app(const AppLoadingPage(), language: 'en'));
      await tester.pump();
      expect(find.bySemanticsLabel('Please wait...'), findsOneWidget);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final locale in AppTranslations.supportedLocales) {
    testWidgets(
      'tutorial translations fit a small screen in ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final page in const [
          TutorialPageOne(),
          TutorialPageTwo(),
          TutorialPageThree(),
        ]) {
          await tester.pumpWidget(_app(page, language: locale.languageCode));
          await tester.pump();
          final translations = await AppTranslations.load(locale);
          final heading = switch (page) {
            TutorialPageOne() => 'Find your bearings',
            TutorialPageTwo() => 'Choose your treasure',
            _ => 'Follow the coordinates',
          };
          expect(find.text(translations.trans(heading)), findsOneWidget);
          if (page is TutorialPageOne && locale.languageCode == 'vi') {
            expect(
              find.textContaining('tìm mã thế giới và tọa độ hiện tại'),
              findsOneWidget,
            );
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '$locale: ${page.runtimeType}',
          );
        }
      },
    );
  }
}
