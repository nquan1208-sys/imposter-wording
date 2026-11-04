import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/widgets/app_selection_card.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/config/app_config.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/data/scoped_json_file.dart';
import 'package:untitled/data/hive_local_storage.dart';
import 'package:untitled/data/local_json_store.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/main.dart';
import 'package:untitled/models/game_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Local anonymous content, setup, disk restart and offline recovery',
    (tester) async {
      AppConfig.current = await AppConfig.load();
      await Supabase.initialize(
        url: AppConfig.current.supabaseUrl,
        publishableKey: AppConfig.current.supabasePublishableKey,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: false,
          detectSessionInUri: false,
          localStorage: EmptyLocalStorage(),
        ),
      );
      final directory = await Directory(
        (await getApplicationSupportDirectory()).path,
      ).createTemp('phase2-smoke-');
      ScopedJsonFile file(String name) => ScopedJsonFile(
        environment: AppConfig.current.environment,
        backendUrl: AppConfig.current.supabaseUrl,
        locale: 'vi',
        name: name,
        directory: () async => directory,
      );
      await file('setup').write(GameSetup.defaults().toJson());
      var storage = HiveLocalStorage(directory: () async => directory);
      LocalJsonStore local(String name) => storage.scoped(
        environment: AppConfig.current.environment,
        backendUrl: AppConfig.current.supabaseUrl,
        locale: 'vi',
        name: name,
      );
      final content = ContentRepository(
        fetchPage: SupabaseContentSource(Supabase.instance.client).fetch,
        cache: local('snapshot'),
      );
      final store = SetupStore(content: content, file: local('setup'));
      await content.load();
      await store.restore();
      expect(content.loadFailed.value, false);
      expect(content.cacheWarning.value, false);
      final totalWords = content.eligibleWords(family: false).length;
      expect(
        totalWords,
        greaterThan(0),
        reason: 'Local dataset needs a published Vietnamese word',
      );
      final category = store.categoryCounts(family: false).keys.first;
      final selectedWords = store
          .eligibleWords(family: false, categoryIds: {category.id})
          .length;
      final nextPlayerCount = store.setup.value.players.length + 1;
      expect(Supabase.instance.client.auth.currentSession, null);
      Future<void> tap(Finder target) async {
        if (target.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            target,
            200,
            maxScrolls: 150,
            scrollable: find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                )
                .first,
          );
        }
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      var container = ProviderContainer(
        overrides: [
          contentRepositoryProvider('vi').overrideWithValue(content),
          setupStoreProvider.overrideWithValue(store),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );
      await tester.pumpAndSettle();
      await tap(find.text('Bắt đầu'));
      final l = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );
      expect(find.text(l.wordCount(totalWords)), findsOneWidget);
      await tap(find.byKey(const Key('categoryPicker')));
      await tap(find.widgetWithText(AppSelectionCard, category.name));
      await tap(find.widgetWithText(FilledButton, l.confirm));
      expect(store.setup.value.categoryIds, {category.id});
      expect(find.text(l.wordCount(selectedWords)), findsOneWidget);
      await tap(find.text(l.players));
      await tap(find.text(l.addPlayer));
      await tap(find.widgetWithText(FilledButton, l.confirm));
      await store.save();
      expect(store.setup.value.players.length, nextPlayerCount);
      expect(store.setup.value.categoryIds, {category.id});
      final playerIds = store.setup.value.players.map((p) => p.id).toList();
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      store.dispose();
      content.dispose();

      await storage.close();
      storage = HiveLocalStorage(directory: () async => directory);

      final offline = ContentRepository(
        cache: local('snapshot'),
        fetchPage: (t, l, f, e) async =>
            throw const SocketException('simulated offline'),
      );
      final restored = SetupStore(content: offline, file: local('setup'));
      await offline.load();
      await restored.restore();
      expect(restored.setup.value.players.map((p) => p.id), playerIds);
      expect(restored.setup.value.categoryIds, {category.id});
      expect(offline.cached.value, true);
      expect(offline.loadFailed.value, true);
      container = ProviderContainer(
        overrides: [
          contentRepositoryProvider('vi').overrideWithValue(offline),
          setupStoreProvider.overrideWithValue(restored),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );
      await tester.pumpAndSettle();
      await tap(find.text(l.start));
      expect(find.text('$nextPlayerCount'), findsOneWidget);
      expect(find.text(l.wordCount(selectedWords)), findsOneWidget);
      expect(find.text(l.cachedContent), findsOneWidget);
      await tap(find.byKey(const Key('categoryPicker')));
      await tap(find.text(l.familyCategories));
      await tap(find.widgetWithText(FilledButton, l.confirm));
      expect(restored.setup.value.family, true);
      final familyCategoryIds = restored
          .categoryCounts(family: true)
          .keys
          .map((c) => c.id)
          .toSet();
      expect(
        restored.setup.value.categoryIds,
        {category.id}.intersection(familyCategoryIds),
      );
      final familyWords = restored
          .eligibleWords(
            family: true,
            categoryIds: restored.setup.value.categoryIds,
          )
          .length;
      expect(find.text(l.wordCount(familyWords)), findsOneWidget);
      await restored.save();
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      restored.dispose();
      offline.dispose();
      await storage.close();
      await directory.delete(recursive: true);
    },
  );
}
