import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/store/auto_dispose_manager.dart';
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

    test('locale defaults to Vietnamese and updates', () {
      final store = createStore();

      expect(store.locale, isA<Signal<Locale>>());
      expect(store.locale.value, const Locale('vi'));

      store.setLocale(const Locale('en'));

      expect(store.locale.value, const Locale('en'));
    });

    test('dispose() disposes owned locale signal', () {
      final store = createStore();
      final locale = store.locale;

      store.dispose();

      expect(locale.disposed, isTrue);
    });
  });
}
