import 'package:flutter/services.dart';
import 'package:untitled/widgets/app_card_grid.dart';
import 'package:untitled/widgets/app_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/theme/app_theme.dart';
import 'package:untitled/widgets/app_action_bar.dart';
import 'package:untitled/widgets/app_notice.dart';
import 'package:untitled/widgets/app_selection_card.dart';
import 'package:untitled/widgets/app_hero_card.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  testWidgets(
    'selection press responds and reduced motion removes scaling animation',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      var selected = false;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: AppSelectionCard(
              selected: false,
              onTap: () => selected = true,
              child: const Text('Chọn danh mục'),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppSelectionCard)),
      );
      await tester.pump(const Duration(milliseconds: 120));
      final animation = tester.widget<AnimatedScale>(
        find.byType(AnimatedScale),
      );
      expect(animation.duration, Duration.zero);
      expect(animation.scale, .98);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(selected, isTrue);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    testWidgets('hero supports Vietnamese at large text size on $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        app(
          const Scaffold(
            body: AppContent(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: AppHeroCard(
                  title: 'Kẻ mạo danh',
                  subtitle: 'Cùng bạn bè khám phá bí mật trong từng lời nói.',
                  icon: Icons.theater_comedy_outlined,
                  prominent: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(
        find.text('Cùng bạn bè khám phá bí mật trong từng lời nói.'),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('footer clears keyboard once and leaves content scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    tester.view.padding = const FakeViewPadding(bottom: 20);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ListView(children: const [TextField()]),
          bottomNavigationBar: AppActionBar(
            child: FilledButton(onPressed: () {}, child: const Text('Save')),
          ),
        ),
      ),
    );
    final button = find.widgetWithText(FilledButton, 'Save');
    expect(tester.getBottomRight(button).dy, lessThanOrEqualTo(812 - 240));
    expect(tester.getTopLeft(button).dy, greaterThan(400));
    expect(button.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selection wraps large labels and exposes selected/disabled state',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const Scaffold(
            body: SingleChildScrollView(
              child: AppSelectionCard(
                selected: true,
                onTap: null,
                child: Text(
                  'A long selected category that wraps without clipping',
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(AppSelectionCard)),
        matchesSemantics(
          isSelected: true,
          hasSelectedState: true,
          hasEnabledState: true,
          isEnabled: false,
          isButton: true,
          label: 'A long selected category that wraps without clipping',
        ),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('error notice announces error and invokes recovery', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: AppNotice(
            message: 'Unable to save',
            error: true,
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextButton));
    expect(retries, 1);
    expect(find.text('Unable to save'), findsOneWidget);
  });
  testWidgets(
    'keyboard focus is visible and selection activates without a pointer',
    (tester) async {
      var selections = 0;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: AppSelectionCard(
              selected: false,
              onTap: () => selections++,
              child: const Text('Category'),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final shape =
          tester.widget<Card>(find.byType(Card)).shape!
              as RoundedRectangleBorder;
      expect(shape.side.width, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selections, 1);
      final semantics = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    },
  );

  for (final config in [
    (320.0, 1.0, true),
    (375.0, 1.0, false),
    (375.0, 2.0, true),
    (1024.0, 1.0, false),
  ]) {
    testWidgets('cards adapt at width ${config.$1}, text scale ${config.$2}', (
      tester,
    ) async {
      tester.view.physicalSize = Size(config.$1, 1000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = config.$2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        app(
          const Scaffold(
            body: AppContent(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: AppCardGrid(
                  children: [
                    SizedBox(
                      key: Key('first'),
                      height: 80,
                      child: Text('First'),
                    ),
                    SizedBox(
                      key: Key('second'),
                      height: 120,
                      child: Text('Second'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final first = tester.getRect(find.byKey(const Key('first')));
      final second = tester.getRect(find.byKey(const Key('second')));
      expect(second.top > first.top, config.$3);
      expect(first.width, lessThanOrEqualTo(640));
      expect(second.right, lessThanOrEqualTo(config.$1));
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('large text and keyboard preserve footer and form at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        app(
          Scaffold(
            appBar: AppBar(title: const Text('Question')),
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                TextField(decoration: InputDecoration(labelText: 'Answer')),
              ],
            ),
            bottomNavigationBar: AppActionBar(
              child: FilledButton(
                onPressed: () {},
                child: const Text('Submit answer'),
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'Submit answer');
      expect(
        tester.getBottomRight(button).dy,
        lessThanOrEqualTo(size.height - 180),
      );
      expect(button.hitTestable(), findsOneWidget);
      expect(find.byType(TextField).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
