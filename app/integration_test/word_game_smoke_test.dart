import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/data/scoped_json_file.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/features/word_game/word_game_screen.dart';
import 'package:untitled/main.dart';
import 'package:untitled/models/game_setup.dart';
import '../test/data/fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('disk cache offline game, vote, replay and return to setup', (
    tester,
  ) async {
    final root = await (await getApplicationSupportDirectory()).createTemp(
      'phase3-smoke-',
    );
    ScopedJsonFile file(String name) => ScopedJsonFile(
      environment: 'local',
      backendUrl: 'http://localhost:54321',
      locale: 'vi',
      name: name,
      directory: () async => root,
    );
    await file('snapshot').write(fixture());
    await file('setup').write(GameSetup.defaults().toJson());
    final content = ContentRepository(
      cache: file('snapshot'),
      fetchPage: (t, l, f, e) async =>
          throw const SocketException('simulated offline'),
    );
    final setup = SetupStore(content: content, file: file('setup'));
    final container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(content),
        setupStoreProvider.overrideWithValue(setup),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      setup.dispose();
      content.dispose();
      await root.delete(recursive: true);
    });
    await content.load();
    await setup.restore();
    expect(content.cached.value, true);
    expect(content.loadFailed.value, true);
    Future<void> tap(String text) async {
      await tester.ensureVisible(find.text(text).last);
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
        p.id == first.imposterId ? findsNothing : findsOneWidget,
      );
      await tap('Hiểu rồi!');
    }
    await tap('Thông báo kết quả');
    await tap(
      first.setup.players.firstWhere((p) => p.id == first.imposterId).name,
    );
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
    expect(find.textContaining('0 / 4'), findsOneWidget);
    expect(find.text('Người chơi'), findsOneWidget);
    for (final p in first.setup.players) {
      expect(
        tester.widget<TextButton>(find.byKey(ValueKey(p.id))).onPressed,
        isNotNull,
      );
    }
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tap('Kết thúc ván');
    expect(find.text('Thiết lập trò chơi'), findsOneWidget);
    expect(setup.setup.value.players, hasLength(4));
    expect(tester.takeException(), null);
  });
}
