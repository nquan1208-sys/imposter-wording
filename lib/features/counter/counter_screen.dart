import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/base/rx/obs_builder.dart';

class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(StoreProvider.counter);
    final appLocale = ref.watch(AppService.localization);
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ObsBuilder(
              streams: [store.counterSubject],
              builder: (ctx) {
                return Text(
                  'You have pushed the button this many times: ${store.counterSubject.value}',
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
