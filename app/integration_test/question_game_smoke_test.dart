import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/data/hive_local_storage.dart';
import 'package:untitled/data/local_json_store.dart';
import 'package:untitled/features/question_game/question_game_screen.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/main.dart';
import 'package:untitled/models/game_setup.dart';
import '../test/data/fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final family in [false, true]) {
    testWidgets('cached question flow, replay and exit (family: $family)', (
      tester,
    ) async {
      final root = await (await getApplicationSupportDirectory()).createTemp(
        'question-smoke-',
      );
      var storage = HiveLocalStorage(directory: () async => root);
      LocalJsonStore local(String name) => storage.scoped(
        environment: 'local',
        backendUrl: 'http://localhost:54321',
        locale: 'vi',
        name: name,
      );
      final data = fixture();
      data['categories'][3]['is_family_friendly'] = true;
      await local('snapshot').write(data);
      await local('setup').write(
        GameSetup.defaults()
            .copyWith(gameType: 'question', family: family)
            .toJson(),
      );
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
      Future<void> tap(Finder target) async {
        if (target.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            target,
            200,
            maxScrolls: 150,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );
      await tester.pumpAndSettle();
      await tap(find.text('Bắt đầu'));
      await tap(find.widgetWithText(FilledButton, 'Bắt đầu ván chơi'));
      final session = tester
          .widget<QuestionGameScreen>(find.byType(QuestionGameScreen))
          .session;
      for (final p in session.setup.players) {
        await tap(find.byKey(ValueKey(p.id)));
        expect(find.text(session.prompt.imposterQuestion), findsNothing);
        expect(find.text(session.prompt.civilianQuestion), findsNothing);
        await tap(find.text('Nhấn để hiển thị'));
        await tester.enterText(
          find.byKey(const Key('privateAnswer')),
          '  ${p.name} answer  ',
        );
        await tester.pumpAndSettle();
        await tap(find.widgetWithText(FilledButton, 'Gửi câu trả lời'));
      }
      expect(find.text(session.prompt.civilianQuestion), findsOneWidget);
      await tap(find.widgetWithText(FilledButton, 'Bắt đầu vòng'));
      expect(find.text(session.prompt.imposterQuestion), findsNothing);
      for (final p in session.setup.players) {
        final answer = find.text('${p.name} answer');
        await tester.scrollUntilVisible(
          answer,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(answer, findsOneWidget);
      }
      await tap(find.widgetWithText(FilledButton, 'Tìm kẻ giả mạo'));
      await tester.scrollUntilVisible(
        find.text(session.prompt.imposterQuestion),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(session.prompt.imposterQuestion), findsOneWidget);
      final previous = setup.setup.value.toJson();
      await tap(find.widgetWithText(FilledButton, 'Chơi lại'));
      expect(setup.setup.value.toJson(), previous);
      await tap(find.widgetWithText(FilledButton, 'Bắt đầu ván chơi'));
      expect(
        identical(
          tester
              .widget<QuestionGameScreen>(find.byType(QuestionGameScreen))
              .session,
          session,
        ),
        false,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(find.widgetWithText(TextButton, 'Kết thúc ván'));
      expect(find.byType(QuestionGameScreen), findsNothing);
    });
  }
}
