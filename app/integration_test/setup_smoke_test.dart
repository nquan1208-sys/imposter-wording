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
      expect(content.eligibleWords(family: false).length, 1);
      expect(content.eligibleWords(family: true), isEmpty);
      expect(Supabase.instance.client.auth.currentSession, null);
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
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();
      expect(find.text('1 từ phù hợp'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('Đồ ăn Việt Nam'), findsOneWidget);
      expect(find.text('Nhân vật hư cấu'), findsNothing);
      await tester.tap(find.text('Đồ ăn Việt Nam'));
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Người chơi'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Thêm người chơi'));
      await tester.tap(find.text('Thêm người chơi'));
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      await store.save();
      expect(store.setup.value.players.length, 5);
      expect(store.setup.value.categoryIds.length, 1);
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
      expect(restored.setup.value.categoryIds.length, 1);
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
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);
      expect(find.text('1 từ phù hợp'), findsOneWidget);
      expect(find.text('Đang dùng nội dung đã lưu.'), findsOneWidget);
      await tester.tap(find.text('Gia đình'));
      await tester.pumpAndSettle();
      expect(find.text('0 từ phù hợp'), findsOneWidget);
      expect(restored.setup.value.categoryIds, isEmpty);
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
