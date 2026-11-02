import 'package:flutter/material.dart';

class AppEdgeInsets {
  AppEdgeInsets._();

  static EdgeInsets pageFor(BuildContext context) => EdgeInsets.symmetric(
    horizontal: MediaQuery.sizeOf(context).width <= 360 ? 16 : 24,
    vertical: 24,
  );

  static const all4 = EdgeInsets.all(4);
  static const all8 = EdgeInsets.all(8);
  static const all16 = EdgeInsets.all(16);
  static const all24 = EdgeInsets.all(24);
  static const h16 = EdgeInsets.symmetric(horizontal: 16);
  static const v16 = EdgeInsets.symmetric(vertical: 16);
  static const page = EdgeInsets.symmetric(horizontal: 16, vertical: 24);
  static const horizontal24 = EdgeInsets.symmetric(horizontal: 24);
  static const vertical8 = EdgeInsets.symmetric(vertical: 8);
  static const vertical12 = EdgeInsets.symmetric(vertical: 12);
}
