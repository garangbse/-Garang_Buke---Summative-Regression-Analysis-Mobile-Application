import 'package:flutter/material.dart';

import 'package:earnings_predictor/screens/predict_screen.dart';
import 'package:earnings_predictor/theme/app_theme.dart';

/// Root widget: sets the theme and shows the one and only page.
class EarningsApp extends StatelessWidget {
  const EarningsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Earnings Predictor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const PredictScreen(),
    );
  }
}
