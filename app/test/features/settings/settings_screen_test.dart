import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/main.dart';
import 'package:untitled/models/app_settings.dart';
import '../../data/fixtures.dart';
import '../../data/memory_app_settings_storage.dart';

void main() {
  late ContentRepository content;
  late SetupStore setup;
  late ProviderContainer container;
  late MemoryAppSettingsStorage appSettings;
  late MemoryStorage setupFile;
  final requestedLocales = <String>[];

  Future<void> pumpApp(
    WidgetTester tester, {
    AppSettings? savedSettings,
    bool failRead = false,
  }) async {
    requestedLocales.clear();
    content = ContentRepository(
      cache: MemoryStorage(),
      fetchPage: (table, locale, from, to) async {
        requestedLocales.add(locale);
        return fixturePage(fixture(), table, locale, from, to);
      },
    );
    final languages = fixtureLanguages();
    await languages.load();
    final english = ContentRepository(
      contentLocale: 'en',
      cache: MemoryStorage(),
      fetchPage: (t, l, f, e) => fixturePage(fixture(locale: 'en'), t, l, f, e),
    );
    await english.load();
    addTearDown(english.dispose);
    addTearDown(languages.dispose);
    setupFile = MemoryStorage();
    setup = SetupStore(
      content: content,
      file: setupFile,
      languages: languages,
      repositoryForLocale: (locale) => locale == 'en' ? english : content,
    );
    await content.load();
    await setup.restore();
    appSettings = MemoryAppSettingsStorage(
      settings: savedSettings,
      failRead: failRead,
    );
    container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(appSettings),
        contentRepositoryProvider('vi').overrideWithValue(content),
        setupStoreProvider.overrideWithValue(setup),
      ],
    );
    await container.read(StoreProvider.app).restore();
    addTearDown(() async {
      container.dispose();
      setup.dispose();
      content.dispose();
    });
    PackageInfo.setMockInitialValues(
      appName: 'Imposter',
      packageName: 'example.imposter',
      version: '4.2.2',
      buildNumber: '158',
      buildSignature: 'test',
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'one language changes interface and content and returns through settings',
    (tester) async {
      await pumpApp(tester);
      expect(find.text('Ngôn ngữ'), findsOneWidget);
      await openSettings(tester);

      await tester.tap(find.text('Ngôn ngữ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsOneWidget);
      expect(setup.setup.value.contentLocale, 'en');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('How to play').first);
      await tester.pumpAndSettle();
      expect(find.text('Set up the game'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);
      expect(setup.content.contentLocale, 'en');
    },
  );

  testWidgets('shows build and copies the complete local installation ID', (
    tester,
  ) async {
    const id = '0123456789abcdef0123456789abcdef';
    await pumpApp(
      tester,
      savedSettings: const AppSettings(uiLocale: 'vi', installationId: id),
    );
    await openSettings(tester);

    await tester.scrollUntilVisible(
      find.text('4.2.2 (158)'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('4.2.2 (158)'), findsOneWidget);
    expect(find.text('01234567…'), findsOneWidget);
    expect(find.text('ID cài đặt'), findsOneWidget);

    final clipboardCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') clipboardCalls.add(call);
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.scrollUntilVisible(
      find.text('ID cài đặt'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sao chép ID đầy đủ'));
    await tester.pumpAndSettle();

    expect(clipboardCalls.single.arguments, {'text': id});
    expect(find.text('Đã sao chép ID cài đặt.'), findsOneWidget);
    for (final label in ['Đánh giá ứng dụng', 'Gửi phản hồi']) {
      final tile = tester.widget<ListTile>(
        find
            .ancestor(of: find.text(label), matching: find.byType(ListTile))
            .first,
      );
      expect(tile.onTap, isNull);
      expect(tile.enabled, isFalse);
    }
  });

  testWidgets('failed locale write stays selected and can be retried', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSettings(tester);
    await tester.tap(find.text('Ngôn ngữ'));
    await tester.pumpAndSettle();
    setupFile.failWrite = true;

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Không thể lưu thiết lập. Các thay đổi vẫn được giữ trên màn hình.',
      ),
      findsOneWidget,
    );
    expect(find.text('English'), findsOneWidget);

    setupFile.failWrite = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(setup.setup.value.contentLocale, 'en');
    expect(find.text('Could not save'), findsNothing);
  });

  testWidgets(
    'installation ID cannot be copied before its first save succeeds',
    (tester) async {
      await pumpApp(tester);
      appSettings.failWrite = true;
      await openSettings(tester);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('ID cài đặt'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final copy = tester
          .widgetList<IconButton>(find.byType(IconButton))
          .firstWhere((button) => button.tooltip == 'Sao chép ID đầy đủ');
      expect(copy.onPressed, isNull);

      appSettings.failWrite = false;
      await tester.scrollUntilVisible(
        find.text('Thử lại'),
        -160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<IconButton>(find.byType(IconButton))
            .firstWhere((button) => button.tooltip == 'Sao chép ID đầy đủ')
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('settings remain usable on a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(tester);
    await openSettings(tester);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('ID cài đặt'),
      140,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Sao chép ID đầy đủ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
