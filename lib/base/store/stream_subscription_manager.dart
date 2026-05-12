import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';

extension AutoCloseStreamSubscriptionExtension<T> on StreamSubscription<T> {
  StreamSubscription<T> manageBy(StreamSubscriptionManager manager) {
    manager.add(this);
    return this;
  }
}

extension AutoCloseStreamSinkExtension<T> on BehaviorSubject<T> {
  BehaviorSubject<T> manageBy(StreamSubscriptionManager manager) {
    manager.addSink(this);
    return this;
  }
}

extension AutoClosePublishSubjectExtension<T> on PublishSubject<T> {
  PublishSubject<T> manageBy(StreamSubscriptionManager manager) {
    manager.addSink(this);
    return this;
  }
}

extension AutoCloseChangeNotifierExtension on ChangeNotifier {
  void manageBy(StreamSubscriptionManager manager) {
    manager.addListenable(this);
  }
}

class StreamSubscriptionManager {
  final List<StreamSubscription> subscriptions = [];
  final List<StreamSink> sinks = [];
  final List<ChangeNotifier> changeNotifiers = [];

  void add(StreamSubscription subscription) {
    subscriptions.add(subscription);
  }

  void addSink(StreamSink sink) {
    sinks.add(sink);
  }

  void addListenable(ChangeNotifier changeNotifier) {
    changeNotifiers.add(changeNotifier);
  }

  void cancelAll() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    for (final sink in sinks) {
      sink.close();
    }
    for (final changeNotifier in changeNotifiers) {
      changeNotifier.dispose();
    }
    subscriptions.clear();
    sinks.clear();
    changeNotifiers.clear();
  }
}
