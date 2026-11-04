// Widget tests covering SignalBuilder-driven UI updates:
// - A SignalBuilder reading multiple signals rebuilding when either changes.
// - A SignalBuilder correctly stopping tracking of a conditionally-unread signal.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals_flutter/signals_flutter.dart';

void main() {
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

  testWidgets('SignalBuilder stops tracking a conditionally-unread signal', (
    WidgetTester tester,
  ) async {
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
  });
}
