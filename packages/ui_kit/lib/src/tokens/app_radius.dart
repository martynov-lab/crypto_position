import 'package:flutter/painting.dart';

abstract final class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xl = 20;
  static const double full = 999;

  static final smallRadius = BorderRadius.circular(small);
  static final mediumRadius = BorderRadius.circular(medium);
  static final largeRadius = BorderRadius.circular(large);
  static final xlRadius = BorderRadius.circular(xl);
  static final fullRadius = BorderRadius.circular(full);
}
