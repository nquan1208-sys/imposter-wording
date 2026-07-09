// Widget tests covering SignalBuilder-driven UI updates:
// - CounterScreen rebuilding when the counter signal changes.
// - A SignalBuilder reading multiple signals rebuilding when either changes.
// - A SignalBuilder correctly stopping tracking of a conditionally-unread signal.
// - RootScreen / AppBottomNavigationBar updating on selectedBottomTab change.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:untitled/features/root/root_screen.dart';
import 'package:untitled/main.dart';

void main() {
  testWidgets(
    'SignalBuilder rebuilds CounterScreen when counter signal changes',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);

      await tester.tap(find.text('To counter'));
      await tester.pumpAndSettle();

      expect(find.textContaining('this many times: 0'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.textContaining('this many times: 1'), findsOneWidget);
      expect(find.textContaining('this many times: 0'), findsNothing);
    },
  );

  testWidgets(
    'SignalBuilder reading multiple signals rebuilds on either changing',
    (WidgetTester tester) async {
      final counterA = signal(0);
      final counterB = signal(100);

      await tester.pumpWidget(
        MaterialApp(
          home: SignalBuilder(
            builder: (context) => Text('${counterA.value}-${counterB.value}'),
          ),
        ),
      );

      expect(find.text('0-100'), findsOneWidget);

      counterA.value = 1;
      await tester.pump();
      expect(find.text('1-100'), findsOneWidget);

      counterB.value = 200;
      await tester.pump();
      expect(find.text('1-200'), findsOneWidget);
    },
  );

  testWidgets(
    'SignalBuilder stops tracking a conditionally-unread signal',
    (WidgetTester tester) async {
      final flag = signal(true);
      final tracked = signal(0);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SignalBuilder(
            builder: (context) {
              buildCount++;
              if (flag.value) {
                return Text('tracked: ${tracked.value}');
              }
              return const Text('untracked');
            },
          ),
        ),
      );

      expect(find.text('tracked: 0'), findsOneWidget);
      final buildCountAfterFirstBuild = buildCount;

      flag.value = false;
      await tester.pump();

      expect(find.text('untracked'), findsOneWidget);
      final buildCountAfterFlagFlip = buildCount;
      expect(buildCountAfterFlagFlip, greaterThan(buildCountAfterFirstBuild));

      // tracked is no longer read on this branch, so further changes to it
      // must not trigger another rebuild.
      tracked.value = 999;
      await tester.pump();

      expect(buildCount, buildCountAfterFlagFlip);
    },
  );

  testWidgets(
    'AppBottomNavigationBar/RootScreen update on selectedBottomTab change',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: RootScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.text('Settings Screen'), findsNothing);
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        0,
      );

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Settings Screen'), findsOneWidget);
      expect(find.text('Home Screen'), findsNothing);
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        1,
      );
    },
  );
}
