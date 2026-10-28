import 'package:untitled/widgets/app_selection_card.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/data/scoped_json_file.dart';
import 'package:untitled/data/hive_local_storage.dart';
import 'package:untitled/data/local_json_store.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/features/word_game/word_game_screen.dart';
import 'package:untitled/main.dart';
import 'package:untitled/models/game_setup.dart';
import '../test/data/fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final advanced in [false, true]) {
    testWidgets(
      'disk cache offline game, vote, replay and return to setup (advanced: $advanced)',
      (tester) async {
        final root = await (await getApplicationSupportDirectory()).createTemp(
          'word-game-smoke-',
        );
        ScopedJsonFile file(String name) => ScopedJsonFile(
          environment: 'local',
          backendUrl: 'http://localhost:54321',
          locale: 'vi',
          name: name,
          directory: () async => root,
        );
        await file('snapshot').write(fixture());
        final initial = advanced
            ? GameSetup(
                players: List.generate(
                  5,
                  (i) => SetupPlayer('player-${i + 1}', 'Guest ${i + 1}'),
                ),
                nextPlayerId: 6,
                imposters: 2,
                imposterNotFirst: true,
                showCategory: true,
                knowEachOther: true,
              )
            : GameSetup.defaults();
        await file('setup').write(initial.toJson());
        var storage = HiveLocalStorage(directory: () async => root);
        LocalJsonStore local(String name) => storage.scoped(
          environment: 'local',
          backendUrl: 'http://localhost:54321',
          locale: 'vi',
          name: name,
        );
        expect(await local('snapshot').read(), fixture());
        expect(await local('setup').read(), initial.toJson());
        await storage.close();
        storage = HiveLocalStorage(directory: () async => root);
        final content = ContentRepository(
          cache: local('snapshot'),
          fetchPage: (t, l, f, e) async =>
              throw const SocketException('simulated offline'),
        );
        final setup = SetupStore(content: content, file: local('setup'));
        final container = ProviderContainer(
          overrides: [
            contentRepositoryProvider('vi').overrideWithValue(content),
            setupStoreProvider.overrideWithValue(setup),
          ],
        );
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          container.dispose();
          setup.dispose();
          content.dispose();
          await setup.pendingWrites;
          await storage.close();
          await root.delete(recursive: true);
        });
        await content.load();
        await setup.restore();
        expect(content.cached.value, true);
        expect(content.loadFailed.value, true);
        Future<void> tap(String text) async {
          if (find.text(text).evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              find.text(text),
              200,
              maxScrolls: 150,
              scrollable: find.byType(Scrollable).first,
            );
          }
          await tester.ensureVisible(find.text(text).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text(text).last);
          await tester.pumpAndSettle();
        }

        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const MyApp()),
        );
        await tester.pumpAndSettle();
        await tap('Bắt đầu');
        await tap('Bắt đầu ván chơi');
        final first = tester
            .widget<WordGameScreen>(find.byType(WordGameScreen))
            .session;
        for (final p in first.setup.players) {
          await tap(p.name);
          expect(find.text(first.prompt.text), findsNothing);
          await tap('Nhấn để hiển thị');
          expect(
            find.text(first.prompt.text),
            first.imposterIds.contains(p.id) ? findsNothing : findsOneWidget,
          );
          await tap('Hiểu rồi!');
        }
        await tap('Thông báo kết quả');
        expect(first.imposterIds, hasLength(advanced ? 2 : 1));
        if (advanced) {
          expect(first.imposterIds.contains(first.startingPlayerId), false);
        }
        for (final player in first.setup.players.where(
          (p) => first.imposterIds.contains(p.id),
        )) {
          await tap(player.name);
        }
        await tap('Xác nhận');
        expect(find.text('Nhóm chiến thắng!'), findsOneWidget);
        final previousSetup = setup.setup.value.toJson();
        await tap('Chơi lại');
        expect(find.text('Thiết lập trò chơi'), findsOneWidget);
        expect(find.byType(WordGameScreen), findsNothing);
        expect(setup.setup.value.toJson(), previousSetup);
        await tap('Bắt đầu ván chơi');
        expect(
          tester.widget<WordGameScreen>(find.byType(WordGameScreen)).session,
          isNot(same(first)),
        );
        expect(
          find.textContaining('0 / ${initial.players.length}'),
          findsOneWidget,
        );
        expect(find.text('Người chơi'), findsOneWidget);
        for (final p in first.setup.players) {
          final card = find.byKey(ValueKey(p.id));
          if (card.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              card,
              200,
              scrollable: find.byType(Scrollable).first,
            );
          }
          expect(tester.widget<AppSelectionCard>(card).onTap, isNotNull);
        }
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tap('Kết thúc ván');
        expect(find.text('Thiết lập trò chơi'), findsOneWidget);
        expect(setup.setup.value.players, hasLength(initial.players.length));
        expect(tester.takeException(), null);
      },
    );
  }
}
