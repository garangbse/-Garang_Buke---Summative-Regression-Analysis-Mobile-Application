import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true);
}

/// Spacing used everywhere so that the layout stays aligned and consistent.
class AppSpacing {
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
  static const double fieldGap = 14;
}
