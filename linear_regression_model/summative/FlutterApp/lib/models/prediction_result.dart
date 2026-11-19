/// The answer of POST /predict.
class PredictionResult {
  const PredictionResult({required this.monthlyCashRwf, required this.model});

  final double monthlyCashRwf;
  final String model;

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      monthlyCashRwf: (json['predicted_monthly_cash_rwf'] as num).toDouble(),
      model: (json['model'] ?? '').toString(),
    );
  }
}
