import 'package:untitled/models/game_setup.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/main.dart';
import 'package:untitled/models/content.dart';
import '../../data/fixtures.dart';

class GatedMemoryStorage extends MemoryStorage {
  Completer<void>? gate;
  @override
  Future<void> write(JsonMap data) async {
    await gate?.future;
    await super.write(data);
  }
}

void main() {
  late ContentRepository content;
  late SetupStore store;
  late MemoryStorage file;
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    FetchContentPage? fetch,
    MemoryStorage? cache,
    bool load = true,
    bool english = false,
    MemoryStorage? setupFile,
  }) async {
    content = ContentRepository(
      cache: cache ?? MemoryStorage(),
      fetchPage: fetch ?? (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
    );
    file = setupFile ?? MemoryStorage();
    store = SetupStore(content: content, file: file);
    addTearDown(content.dispose);
    addTearDown(store.dispose);
    await store.restore();
    if (load) await content.load();
    container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(content),
        setupStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    if (english) {
      container.read(StoreProvider.app).setLocale(const Locale('en'));
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(english ? 'Start' : 'Bắt đầu'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final target = text == 'Danh mục' || text == 'Categories'
        ? find.byKey(const Key('categoryPicker'))
        : text.startsWith('Category ')
        ? find.widgetWithText(OutlinedButton, text)
        : find.text(text);
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        180,
        scrollable: find.byType(Scrollable).first,
      );
    }
    final finder = target.last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final english in [false, true]) {
    testWidgets(
      'image switch is Family word only and remembers choice (english=$english)',
      (tester) async {
        final disk = GatedMemoryStorage();
        await pump(tester, english: english, setupFile: disk);
        final label = english ? 'Show images' : 'Hiển thị ảnh';
        final toggle = find.widgetWithText(SwitchListTile, label);
        expect(toggle, findsNothing);
        await tap(tester, english ? 'Categories' : 'Danh mục');
        await tap(tester, english ? 'Family mode' : 'Chế độ gia đình');
        expect(tester.widget<SwitchListTile>(toggle).value, false);
        await tap(tester, label);
        expect(tester.widget<SwitchListTile>(toggle).value, true);
        expect(store.setup.value.family, false);
        expect(store.setup.value.showWordImages, false);
        final before = disk.writes;
        disk.gate = Completer<void>();
        await tester.tap(
          find.widgetWithText(FilledButton, english ? 'Confirm' : 'Xác nhận'),
        );
        await tester.pump();
        expect(tester.widget<SwitchListTile>(toggle).onChanged, null);
        disk.gate!.complete();
        await store.pendingWrites;
        await tester.pumpAndSettle();
        expect(disk.writes, before + 1);
        expect(store.setup.value.family, true);
        expect(store.setup.value.showWordImages, true);
        expect(toggle, findsNothing);
        await store.setGameType('question');
        await tester.pumpAndSettle();
        expect(store.setup.value.family, false);
        await tap(tester, english ? 'Categories' : 'Danh mục');
        expect(find.byType(SegmentedButton<bool>), findsNothing);
        expect(toggle, findsNothing);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await store.setGameType('word');
        await tap(tester, english ? 'Categories' : 'Danh mục');
        await tap(tester, english ? 'Family mode' : 'Chế độ gia đình');
        expect(tester.widget<SwitchListTile>(toggle).value, true);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(store.setup.value.family, false);
      },
    );
  }

  testWidgets(
    'create, discard, select, confirm, autosave, manage, rename and delete',
    (tester) async {
      await pump(tester, english: true);
      await tap(tester, 'Players');
      await tester.enterText(
        find.byKey(const ValueKey('name-0-player-1')),
        'Draft player',
      );
      await tap(tester, 'Unsaved game');
      await tap(tester, 'Save as a list…');
      await tester.enterText(find.byType(TextFormField).last, '  Friends  ');
      await tap(tester, 'Save');
      expect(store.setup.value.activePresetId, null);
      expect(
        store.setup.value.presets.single.setup.players.first.name,
        'Draft player',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, 'Discard');
      expect(store.setup.value.players.first.name, 'Player 1');
      expect(store.setup.value.presets.single.name, 'Friends');
      await tap(tester, 'Players');
      await tap(tester, 'Unsaved game');
      await tap(tester, 'Friends');
      await tap(tester, 'Confirm');
      expect(store.setup.value.players.first.name, 'Draft player');
      expect(store.setup.value.activePresetId, 'preset-1');
      await tap(tester, 'Imposters know each other');
      expect(store.setup.value.presets.single.setup.knowEachOther, true);
      await tap(tester, 'Players');
      await tester.enterText(
        find.byType(TextFormField).first,
        'Keep this draft',
      );
      await tap(tester, 'Friends');
      await tap(tester, 'Manage lists');
      expect(
        find.text('In use', findRichText: true),
        findsNothing,
      ); // association is part of the count subtitle
      expect(find.textContaining('In use'), findsOneWidget);
      await tap(tester, 'Friends');
      expect(find.text('Saved rules'), findsOneWidget);
      expect(store.setup.value.activePresetId, 'preset-1');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('List actions'));
      await tester.pumpAndSettle();
      await tap(tester, 'Details');
      expect(find.text('Saved rules'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('List actions'));
      await tester.pumpAndSettle();
      await tap(tester, 'Rename');
      await tester.enterText(find.byType(TextFormField).last, 'Team');
      await tap(tester, 'Save');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Team'), findsOneWidget);
      expect(find.text('Keep this draft'), findsOneWidget);
      await tap(tester, 'Team');
      await tap(tester, 'Manage lists');
      await tester.tap(find.byTooltip('List actions'));
      await tester.pumpAndSettle();
      await tap(tester, 'Delete');
      await tap(tester, 'Cancel');
      expect(store.setup.value.presets, hasLength(1));
      await tester.tap(find.byTooltip('List actions'));
      await tester.pumpAndSettle();
      await tap(tester, 'Delete');
      await tap(tester, 'Delete');
      expect(store.setup.value.presets, isEmpty);
      expect(store.setup.value.activePresetId, null);
      expect(
        find.textContaining('Return to the player editor'),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Unsaved game'), findsOneWidget);
      await tap(tester, 'Confirm');
      expect(store.setup.value.players.first.name, 'Keep this draft');
      expect(store.setup.value.presets, isEmpty);
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'preset and editor failures retain input; duplicate names and unsaved selection',
    (tester) async {
      await pump(tester, english: true);
      await tap(tester, 'Players');
      await tap(tester, 'Unsaved game');
      await tap(tester, 'Save as a list…');
      await tap(tester, 'Save');
      expect(
        find.text('Use a non-empty name that is not already taken.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField).last, 'Friends');
      file.failWrite = true;
      await tap(tester, 'Save');
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      file.failWrite = false;
      await tap(tester, 'Save');
      await tap(tester, 'Friends');
      await tap(tester, 'Save as a list…');
      await tester.enterText(find.byType(TextFormField).last, ' friends ');
      await tap(tester, 'Save');
      expect(
        find.text('Use a non-empty name that is not already taken.'),
        findsOneWidget,
      );
      await tap(tester, 'Cancel');
      await tap(tester, 'Friends');
      await tap(tester, 'Unsaved game');
      expect(store.setup.value.presets, hasLength(1));
      file.failWrite = true;
      await tap(tester, 'Confirm');
      expect(find.text('Edit player names'), findsOneWidget);
      file.failWrite = false;
      await tap(tester, 'Confirm');
      expect(store.setup.value.activePresetId, null);
    },
  );

  testWidgets(
    'small editor and preset dialogs handle keyboard and text scale two',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester, english: true);
      await tap(tester, 'Players');
      await tap(tester, 'Unsaved game');
      await tap(tester, 'Manage lists');
      expect(
        find.textContaining('Return to the player editor'),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, 'Unsaved game');
      await tap(tester, 'Save as a list…');
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Team');
      await tap(tester, 'Save');
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Team'), findsOneWidget);
      semantics.dispose();
      await tap(tester, 'Team');
      await tap(tester, 'Manage lists');
      await tester.tap(find.byTooltip('List actions'));
      await tester.pumpAndSettle();
      await tap(tester, 'Details');
      await tap(tester, 'Saved rules');
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'pending writes block duplicate confirmation and conflicting actions',
    (tester) async {
      final disk = GatedMemoryStorage();
      await pump(tester, english: true, setupFile: disk);
      await tap(tester, 'Players');
      await tap(tester, 'Unsaved game');
      await tap(tester, 'Save as a list…');
      await tester.enterText(find.byType(TextFormField).last, 'Team');
      disk.gate = Completer<void>();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        null,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(store.setup.value.presets, isEmpty);
      disk.gate!.complete();
      await tester.pumpAndSettle();
      expect(store.setup.value.presets, hasLength(1));
      await tap(tester, 'Confirm');
      await tap(tester, 'Imposters');
      await tap(tester, 'Random');
      disk.gate = Completer<void>();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm'))
            .onPressed,
        null,
      );
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      disk.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(store.setup.value.presets.single.setup.randomImposters, true);
    },
  );

  testWidgets(
    'selecting groups changes only draft; dismissal and unsaved preserve values',
    (tester) async {
      await pump(tester, english: true);
      final original = store.setup.value;
      final first = await store.createPreset('First', original);
      final small = original.copyWith(
        players: original.players
            .take(3)
            .map((p) => SetupPlayer(p.id, 'Guest'))
            .toList(),
        nextPlayerId: 4,
        randomImposters: true,
        showCategory: true,
        knowEachOther: true,
      );
      await store.createPreset('Small', small);
      await store.confirmDraft(original, first);
      await tester.pumpAndSettle();
      await tap(tester, 'Players');
      await tap(tester, 'First');
      await tap(tester, 'Small');
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(store.setup.value.activePresetId, first);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, 'Discard');
      expect(store.setup.value.players, hasLength(4));
      await tap(tester, 'Players');
      await tap(tester, 'First');
      await tap(tester, 'Small');
      await tap(tester, 'Small');
      await tap(tester, 'Unsaved game');
      await tap(tester, 'Confirm');
      expect(store.setup.value.activePresetId, null);
      expect(
        store.setup.value.players.map((p) => p.name),
        everyElement('Guest'),
      );
      expect(store.setup.value.nextPlayerId, 4);
      expect(store.setup.value.randomImposters, true);
      expect(
        store.setup.value.presets.first.setup.rosterJson(),
        original.rosterJson(),
      );
      await tap(tester, 'Players');
      await tap(tester, 'Unsaved game');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Unsaved game'), findsOneWidget);
      await tap(tester, 'Confirm');
      expect(store.setup.value.players, hasLength(3));
    },
  );

  for (final type in ['word', 'question']) {
    testWidgets(
      'fixed imposter plus/minus boundaries and mode switching in $type',
      (tester) async {
        await pump(tester, english: true);
        await store.setGameType(type);
        for (final n in [3, 4, 5, 6, 7]) {
          await store.setPlayerCount(n);
          await tester.pumpAndSettle();
          await tap(tester, 'Imposters');
          final plus = find.byWidgetPredicate(
            (w) => w is IconButton && w.tooltip == 'More imposters',
          );
          final minus = find.byWidgetPredicate(
            (w) => w is IconButton && w.tooltip == 'Fewer imposters',
          );
          final max = (n - 1) ~/ 2;
          expect(
            find.byKey(const Key('imposterLimitWarning')),
            max == 1 ? findsOneWidget : findsNothing,
          );
          expect(
            find.text(
              'At least 5 players are needed to choose more than 1 imposter.',
            ),
            max == 1 ? findsOneWidget : findsNothing,
          );
          expect(tester.widget<IconButton>(minus).onPressed, null);
          for (var value = 1; value < max; value++) {
            expect(tester.widget<IconButton>(plus).onPressed, isNotNull);
            await tester.tap(plus);
            await tester.pumpAndSettle();
            expect(
              find.descendant(
                of: find.byType(BottomSheet),
                matching: find.text('${value + 1}'),
              ),
              findsOneWidget,
            );
          }
          expect(tester.widget<IconButton>(plus).onPressed, null);
          await tap(tester, 'Random');
          expect(plus, findsNothing);
          await tap(tester, 'Fixed');
          expect(
            find.descendant(
              of: find.byType(BottomSheet),
              matching: find.text('$max'),
            ),
            findsOneWidget,
          );
          for (var value = max; value > 1; value--) {
            await tester.tap(minus);
            await tester.pumpAndSettle();
            expect(
              find.descendant(
                of: find.byType(BottomSheet),
                matching: find.text('${value - 1}'),
              ),
              findsOneWidget,
            );
          }
          expect(tester.widget<IconButton>(minus).onPressed, null);
          await tap(tester, 'Confirm');
          expect(store.setup.value.imposters, 1);
        }
      },
    );
  }

  testWidgets('roster edits validate, reorder, cancel and persist', (
    tester,
  ) async {
    await pump(tester, english: true);
    await tap(tester, 'Players');
    await tester.enterText(find.byKey(const ValueKey('name-0-player-1')), '  ');
    await tester.pumpAndSettle();
    expect(find.text('Enter a name.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm'))
          .onPressed,
      null,
    );
    await tester.enterText(
      find.byKey(const ValueKey('name-0-player-1')),
      '  Alex  ',
    );
    await tester.tap(find.byTooltip('Move down').first);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tap(tester, 'Cancel');
    expect(store.setup.value.players.first.name, 'Player 1');
    await tap(tester, 'Confirm');
    expect(store.setup.value.players[1].name, 'Alex');
    expect(store.setup.value.players[1].id, 'player-1');
    await tap(tester, 'Players');
    await tester.tap(find.byTooltip('Remove player').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove player'), findsNWidgets(3));
    await tester.scrollUntilVisible(
      find.text('Add player'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tap(tester, 'Add player');
    await tap(tester, 'Confirm');
    expect(store.setup.value.players, hasLength(4));
    expect(store.setup.value.players.last.id, 'player-5');
    await tap(tester, 'Players');
    await tester.enterText(find.byType(TextFormField).first, 'Unsaved');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tap(tester, 'Discard');
    expect(store.setup.value.players.any((p) => p.name == 'Unsaved'), false);
    expect(file.data!['players'], hasLength(4));
  });

  testWidgets('imposter sheet cancel/confirm and rule switches', (
    tester,
  ) async {
    await pump(tester, english: true);
    await store.setPlayerCount(7);
    await tester.pumpAndSettle();
    await tap(tester, 'Imposters');
    await tester.tap(find.byTooltip('More imposters'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(store.setup.value.imposters, 1);
    await tap(tester, 'Imposters');
    await tester.tap(find.byTooltip('More imposters'));
    await tester.pumpAndSettle();
    await tap(tester, 'Confirm');
    expect(store.setup.value.imposters, 2);
    await tap(tester, 'Imposters');
    await tap(tester, 'Random');
    await tap(tester, 'Confirm');
    expect(store.setup.value.randomImposters, true);
    await tap(tester, 'Imposters');
    await tap(tester, 'Imposters never start');
    await tap(tester, 'Confirm');
    for (final label in [
      'Show category to imposters',
      'Imposters know each other',
    ]) {
      await tap(tester, label);
    }
    expect(store.setup.value.imposterNotFirst, true);
    expect(store.setup.value.showCategory, true);
    expect(store.setup.value.knowEachOther, true);
  });

  testWidgets(
    'landing opens setup; picker cancel discards and confirm commits',
    (tester) async {
      await pump(tester);
      expect(find.text('4'), findsOneWidget);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('4 người chơi'), findsOneWidget);
      semantics.dispose();
      expect(find.byType(Switch), findsNWidgets(2));
      expect(find.byIcon(Icons.settings), findsNothing);
      final player = tester.getRect(find.text('Người chơi'));
      final imposter = tester.getRect(find.text('Kẻ mạo danh'));
      expect(player.center.dy, imposter.center.dy);
      expect(player.center.dx, lessThan(imposter.center.dx));
      expect(find.text('3 từ phù hợp'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Bắt đầu ván chơi'),
            )
            .onPressed,
        isNotNull,
      );
      await tap(tester, 'Danh mục');
      await tap(tester, 'Category b');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(store.setup.value.categoryIds, isEmpty);
      await tap(tester, 'Danh mục');
      await tap(tester, 'Category b');
      await tap(tester, 'Xác nhận');
      expect(store.setup.value.categoryIds, {'b'});
      expect(find.text('1 từ phù hợp'), findsOneWidget);
      await tap(tester, 'Danh mục');
      await tap(tester, 'Chế độ gia đình');
      expect(store.setup.value.categoryIds, {'b'});
      expect(find.textContaining('Đã bỏ danh mục'), findsOneWidget);
      expect(find.text('Category b'), findsNothing);
      await tap(tester, 'Xác nhận');
      expect(store.setup.value.categoryIds, isEmpty);
      expect(find.text('2 từ phù hợp'), findsOneWidget);
      await tap(tester, 'Danh mục');
      expect(find.text('Category b'), findsNothing);
      await tap(tester, 'Category a');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(store.setup.value.categoryIds, isEmpty);
    },
  );

  testWidgets('player card opens roster and saved count follows roster', (
    tester,
  ) async {
    await pump(tester, english: true);
    expect(find.text('Edit player names'), findsNothing);
    await tap(tester, 'Players');
    expect(find.text('Edit player names'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byTooltip('Fewer players'), findsNothing);
    expect(find.byTooltip('More players'), findsNothing);
    await tester.tap(find.byTooltip('Remove player').first);
    await tester.pumpAndSettle();
    for (final button in tester.widgetList<IconButton>(
      find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Remove player',
      ),
    )) {
      expect(button.onPressed, null);
    }
    await tap(tester, 'Confirm');
    expect(store.setup.value.players.length, 3);
    expect(find.bySemanticsLabel('3 players'), findsOneWidget);

    await tap(tester, 'Players');

    await tap(tester, 'Add player');
    await tap(tester, 'Confirm');
    expect(find.bySemanticsLabel('4 players'), findsOneWidget);
    await tap(tester, 'Players');
    await tester.tap(find.byTooltip('Remove player').first);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tap(tester, 'Discard');
    expect(find.bySemanticsLabel('4 players'), findsOneWidget);

    await store.setPlayerCount(100);
    await tester.pumpAndSettle();
    await tap(tester, 'Players');
    await tester.scrollUntilVisible(
      find.text('Add player'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Add player'))
          .onPressed,
      null,
    );
    await tap(tester, 'Confirm');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tap(tester, 'Start');
    expect(find.text('100'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('100 players'), findsOneWidget);
    semantics.dispose();
    expect(find.text('Word game'), findsOneWidget);
    expect(find.text('Imposters'), findsOneWidget);
  });

  testWidgets('saving fewer players clamps the displayed imposter count', (
    tester,
  ) async {
    await pump(tester, english: true);
    await store.setPlayerCount(5);
    await store.setRules(imposters: 2);
    await tester.pumpAndSettle();
    await tap(tester, 'Players');
    await tester.tap(find.byTooltip('Remove player').first);
    await tester.pumpAndSettle();
    await tap(tester, 'Confirm');
    expect(find.bySemanticsLabel('4 players'), findsOneWidget);
    expect(find.bySemanticsLabel('Imposters: 1'), findsOneWidget);
    expect(store.setup.value.imposters, 1);
  });

  testWidgets(
    'refresh is accessible, disabled while syncing, keeps offline play and revalidates categories',
    (tester) async {
      var data = fixture();
      Completer<List<JsonMap>>? gate;
      await pump(
        tester,
        english: true,
        fetch: (t, l, f, e) async {
          if (gate != null) return gate.future;
          return fixturePage(data, t, l, f, e);
        },
      );
      await store.setCategories({'b'});
      gate = Completer<List<JsonMap>>();
      await tester.tap(find.byTooltip('Refresh content'));
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.refresh))
            .onPressed,
        null,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Start game'),
            )
            .onPressed,
        isNotNull,
      );
      gate.completeError(const SocketException('offline'));
      await content.load();
      await tester.pump();
      expect(content.cached.value, true);
      expect(content.loadFailed.value, true);
      gate = null;
      data = fixture();
      (data['words'] as List).removeWhere((w) => w['category_id'] == 'b');
      await tester.tap(find.byTooltip('Refresh content'));
      await content.load();
      await store.pendingWrites;
      await tester.pumpAndSettle();
      expect(store.setup.value.categoryIds, isEmpty);
      expect(content.cached.value, false);
      expect(content.loadFailed.value, false);
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.refresh))
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('loading, error and retry without cache', (tester) async {
    var offline = true;
    final gate = Completer<List<JsonMap>>();
    await pump(
      tester,
      load: false,
      english: true,
      fetch: (t, l, f, e) async {
        if (offline) return gate.future;
        return fixturePage(fixture(), t, l, f, e);
      },
    );
    final pending = content.load();
    await tester.pump();
    expect(find.text('Loading Vietnamese content…'), findsOneWidget);
    gate.completeError(const SocketException('offline'));
    await pending;
    await tester.pumpAndSettle();
    expect(
      find.text('Content could not be refreshed. Please retry.'),
      findsOneWidget,
    );
    offline = false;
    await tap(tester, 'Retry');
    expect(find.text('3 eligible words'), findsOneWidget);
  });

  testWidgets('offline cache, empty family mode and persistence retry', (
    tester,
  ) async {
    final data = fixture();
    for (final c in data['categories'] as List) {
      c.remove('is_family_friendly');
    }
    await pump(
      tester,
      english: true,
      cache: MemoryStorage(data),
      fetch: (t, l, f, e) async => throw const SocketException('offline'),
    );
    expect(find.text('Using saved content.'), findsOneWidget);
    file.failWrite = true;
    await tap(tester, 'Categories');
    await tap(tester, 'Family mode');
    expect(
      find.text(
        'No family categories have content yet. Choose All categories or try again later.',
      ),
      findsOneWidget,
    );
    await tap(tester, 'Confirm');
    expect(store.setup.value.family, false);
    expect(
      find.text('Setup could not be saved. Your changes are still here.'),
      findsOneWidget,
    );
    file.failWrite = false;
    await tap(tester, 'Confirm');
    expect(store.writeFailed.value, false);
    expect(file.data!['mode'], 'family');
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Start game'))
          .onPressed,
      null,
    );
  });

  testWidgets('unreadable settings require retry', (tester) async {
    await pump(tester, english: true);
    file.failRead = true;
    await store.restore();
    await tester.pumpAndSettle();
    expect(
      find.text('Saved setup could not be read. Retry to continue.'),
      findsOneWidget,
    );
    expect(find.text('Reset setup'), findsNothing);
    expect(store.readFailed.value, true);
    expect(file.writes, 0);
    file.failRead = false;
    await tap(tester, 'Retry');
    expect(store.readFailed.value, false);
  });

  testWidgets(
    'content replacement while picking shows removed selection and confirms All',
    (tester) async {
      await pump(tester, english: true);
      await tap(tester, 'Categories');
      await tap(tester, 'Category b');
      final data = fixture();
      (data['words'] as List).removeWhere((w) => w['category_id'] == 'b');
      content.snapshot.value = ContentSnapshot.fromJson(data, 'vi');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Unavailable categories were removed.'),
        findsOneWidget,
      );
      await tap(tester, 'Confirm');
      expect(store.setup.value.categoryIds, isEmpty);
      expect(find.text('All categories'), findsOneWidget);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    testWidgets(
      'large text keeps setup, sheet and adaptive picker usable at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pump(tester);
        await tap(tester, 'Người chơi');
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('name-0-player-1')),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(
          find.byKey(const ValueKey('name-0-player-1')),
          '  An  ',
        );
        await tester.pumpAndSettle();
        await tap(tester, 'Xác nhận');
        expect(store.setup.value.players.first.name, 'An');
        await tap(tester, 'Kẻ mạo danh');
        await tap(tester, 'Ngẫu nhiên');
        await tap(tester, 'Xác nhận');
        expect(store.setup.value.randomImposters, true);
        await tester.scrollUntilVisible(
          find.text('Người chơi'),
          -180,
          scrollable: find.byType(Scrollable).first,
        );
        await tap(tester, 'Người chơi');
        await tap(tester, 'Xác nhận');
        await tap(tester, 'Danh mục');
        await tap(tester, 'Category a');
        await tap(tester, 'Xác nhận');
        await tester.scrollUntilVisible(
          find.text('Bắt đầu ván chơi'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final buttonRect = tester.getRect(
          find.widgetWithText(FilledButton, 'Bắt đầu ván chơi'),
        );
        expect(buttonRect.top, greaterThanOrEqualTo(0));
        expect(buttonRect.bottom, lessThanOrEqualTo(size.height));
        expect(tester.takeException(), null);
      },
    );
  }
}
