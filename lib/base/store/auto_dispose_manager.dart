import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

extension AutoCloseStreamSubscriptionExtension<T> on StreamSubscription<T> {
  StreamSubscription<T> manageBy(AutoDisposeManager manager) {
    manager.addDisposer(() => cancel());
    return this;
  }
}

extension AutoCloseChangeNotifierExtension on ChangeNotifier {
  void manageBy(AutoDisposeManager manager) {
    manager.addDisposer(dispose);
  }
}

extension AutoCloseSignalExtension<S extends ReadonlySignal<dynamic>> on S {
  S manageBy(AutoDisposeManager manager) {
    manager.addDisposer(dispose);
    return this;
  }
}

extension AutoCloseDisposerExtension on void Function() {
  void Function() manageBy(AutoDisposeManager manager) {
    manager.addDisposer(this);
    return this;
  }
}

class AutoDisposeManager {
  final List<void Function()> disposers = [];

  void addDisposer(void Function() disposer) {
    disposers.add(disposer);
  }

  void cancelAll() {
    for (final disposer in disposers) {
      disposer();
    }
    disposers.clear();
  }
}
