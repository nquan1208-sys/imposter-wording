import 'package:untitled/models/content.dart';

abstract interface class LocalJsonStore {
  Future<JsonMap?> read();
  Future<void> write(JsonMap data);
}
