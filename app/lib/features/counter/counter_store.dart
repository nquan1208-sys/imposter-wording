import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/store/auto_dispose_manager.dart';
import 'package:untitled/base/store/store_base.dart';

class CounterStore extends StoreBase {
  final _autoDisposeManager = AutoDisposeManager();

  late final counter = signal(0).manageBy(_autoDisposeManager);

  CounterStore(Ref ref) {
    effect(() {
      debugPrint('counter changed: ${counter.value}');
    }).manageBy(_autoDisposeManager);
  }

  void increment() {
    counter.value++;
  }

  @override
  void dispose() {
    _autoDisposeManager.cancelAll();
    super.dispose();
  }
}
