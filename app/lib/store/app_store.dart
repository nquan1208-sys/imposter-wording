import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/store/auto_dispose_manager.dart';
import 'package:untitled/base/store/store_base.dart';

class AppStore extends StoreBase {
  static const defaultLocale = Locale('vi');

  final Ref ref;
  final _autoDisposeManager = AutoDisposeManager();

  // ponytail: in-memory only; persisted language picker lands in phase 11
  late final locale = signal(defaultLocale).manageBy(_autoDisposeManager);

  AppStore(this.ref);

  void setLocale(Locale value) {
    locale.value = value;
  }

  @override
  void dispose() {
    _autoDisposeManager.cancelAll();
    super.dispose();
  }
}
