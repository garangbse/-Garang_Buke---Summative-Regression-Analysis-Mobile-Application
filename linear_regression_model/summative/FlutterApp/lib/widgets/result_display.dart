import 'package:flutter/material.dart';

import 'package:earnings_predictor/controllers/prediction_controller.dart';
import 'package:earnings_predictor/models/prediction_result.dart';
import 'package:earnings_predictor/theme/app_theme.dart';
import 'package:earnings_predictor/utils/formatters.dart';

/// The display area. In the same place it shows instructions, a waiting message,
/// the predicted value, or a readable error message.
class ResultDisplay extends StatelessWidget {
  const ResultDisplay({
    super.key,
    required this.status,
    this.result,
    this.errorMessage = '',
  });

  final PredictionStatus status;
  final PredictionResult? result;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('result_area'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(color: _background(colors), borderRadius: BorderRadius.circular(12)),
      child: _content(context, colors),
    );
  }

  Color _background(ColorScheme colors) {
    switch (status) {
      case PredictionStatus.success:
        return colors.primaryContainer;
      case PredictionStatus.error:
        return colors.errorContainer;
      case PredictionStatus.idle:
      case PredictionStatus.loading:
        return Colors.grey.shade200;
    }
  }

  Widget _content(BuildContext context, ColorScheme colors) {
    switch (status) {
      case PredictionStatus.idle:
        return const Text('Fill in all the fields and press Predict.');
      case PredictionStatus.loading:
        return const Row(
          children: [
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(width: 12),
            Expanded(child: Text('Contacting the server. After a pause the first request can take up to a minute.')),
          ],
        );
      case PredictionStatus.success:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Predicted monthly earnings'),
            const SizedBox(height: 4),
            Text(
              formatRwf(result?.monthlyCashRwf ?? 0),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('An estimate based on survey data, not a guaranteed salary.'),
          ],
        );
      case PredictionStatus.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please check your input',
                style: TextStyle(fontWeight: FontWeight.bold, color: colors.onErrorContainer)),
            const SizedBox(height: 4),
            Text(errorMessage, style: TextStyle(color: colors.onErrorContainer)),
          ],
        );
    }
  }
}
