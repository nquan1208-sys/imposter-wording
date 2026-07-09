import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/store/auto_dispose_manager.dart';
import 'package:untitled/features/counter/counter_store.dart';
import 'package:untitled/features/root/enums/navigation_bottom_tab_enum.dart';
import 'package:untitled/store/app_store.dart';

void main() {
  group('AutoDisposeManager', () {
    test('disposes managed Signal instances on cancelAll', () {
      final manager = AutoDisposeManager();
      final s = signal(0).manageBy(manager);

      expect(s.disposed, isFalse);

      manager.cancelAll();

      expect(s.disposed, isTrue);
    });

    test('stops a managed effect disposer on cancelAll', () {
      final manager = AutoDisposeManager();
      final s = signal(0);
      var runCount = 0;

      effect(() {
        s.value;
        runCount++;
      }).manageBy(manager);

      expect(runCount, 1);

      s.value = 1;
      expect(runCount, 2);

      manager.cancelAll();

      s.value = 2;
      expect(runCount, 2, reason: 'effect must not fire after cancelAll');
    });
  });

  group('CounterStore', () {
    late ProviderContainer container;

    CounterStore createStore() {
      final provider = Provider<CounterStore>((ref) => CounterStore(ref));
      return container.read(provider);
    }

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('counter is a Signal and increments', () {
      final store = createStore();

      expect(store.counter, isA<Signal<int>>());
      expect(store.counter.value, 0);

      store.increment();

      expect(store.counter.value, 1);
    });

    test('effect fires on counter change and stops after dispose', () {
      final originalDebugPrint = debugPrint;
      final messages = <String>[];
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) messages.add(message);
      };
      addTearDown(() => debugPrint = originalDebugPrint);

      final store = createStore();
      final countAfterCreate = messages.length;

      store.increment();
      expect(
        messages.length,
        greaterThan(countAfterCreate),
        reason: 'effect should fire on counter change before dispose',
      );

      final countAfterIncrement = messages.length;
      store.dispose();

      expect(
        () => store.counter.value++,
        throwsA(isA<Object>()),
        reason: 'counter signal is disposed, further writes must not '
            'silently succeed',
      );
      expect(
        messages.length,
        countAfterIncrement,
        reason: 'effect must not fire for changes attempted after dispose',
      );
    });

    test('dispose() disposes owned signal', () {
      final store = createStore();

      expect(store.counter.disposed, isFalse);

      store.dispose();

      expect(store.counter.disposed, isTrue);
    });

    test('recreating a store after dispose yields fresh signal state', () {
      final store1 = createStore();
      store1.increment();
      store1.increment();
      expect(store1.counter.value, 2);
      store1.dispose();

      final store2 = createStore();

      expect(store2.counter.value, 0);
      expect(store2.counter.disposed, isFalse);
      expect(identical(store1.counter, store2.counter), isFalse);
    });
  });

  group('AppStore', () {
    late ProviderContainer container;

    AppStore createStore() {
      final provider = Provider<AppStore>((ref) => AppStore(ref));
      return container.read(provider);
    }

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('selectedBottomTab is a Signal and updates', () {
      final store = createStore();

      expect(store.selectedBottomTab, isA<Signal<NavigatorBottomTabEnum>>());
      expect(store.selectedBottomTab.value, NavigatorBottomTabEnum.home);

      store.onBottomTabChange(NavigatorBottomTabEnum.settings);

      expect(store.selectedBottomTab.value, NavigatorBottomTabEnum.settings);
    });
  });
}
