import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/features/root/enums/navigation_bottom_tab_enum.dart';

class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(StoreProvider.counter);
    final appStore = ref.watch(StoreProvider.app);
    final appLocale = ref.watch(AppService.localization);
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SignalBuilder(
              builder: (ctx) {
                final isHomeTab = appStore.selectedBottomTab.value.isHome;
                return Text(
                  'You have pushed the button this many times: '
                  '${store.counter.value} (home tab active: $isHomeTab)',
                );
              },
            ),
            Text(appLocale.helloWorld),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          store.increment();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
