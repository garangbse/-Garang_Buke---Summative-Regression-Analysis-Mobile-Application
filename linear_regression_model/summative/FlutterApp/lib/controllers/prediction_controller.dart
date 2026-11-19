import 'package:flutter/material.dart';

import 'package:earnings_predictor/constants/input_fields.dart';
import 'package:earnings_predictor/models/prediction_result.dart';
import 'package:earnings_predictor/services/api_exception.dart';
import 'package:earnings_predictor/services/prediction_service.dart';
import 'package:earnings_predictor/utils/input_parser.dart';

enum PredictionStatus { idle, loading, success, error }

/// Holds the text of every field and the state of the page. The widgets only display it.
class PredictionController extends ChangeNotifier {
  PredictionController({PredictionService? service}) : _service = service ?? PredictionService();

  final PredictionService _service;

  /// One controller per input field, found by the field's key.
  final Map<String, TextEditingController> textControllers = {
    for (final field in allInputFields) field.key: TextEditingController(),
  };

  PredictionStatus _status = PredictionStatus.idle;
  PredictionResult? _result;
  String _errorMessage = '';
  bool _disposed = false;

  PredictionStatus get status => _status;
  PredictionResult? get result => _result;
  String get errorMessage => _errorMessage;
  bool get isLoading => _status == PredictionStatus.loading;

  /// The request body. Empty fields are left out, so the API answers "This field is required" for them.
  Map<String, dynamic> buildInputs() {
    final inputs = <String, dynamic>{};
    for (final field in allInputFields) {
      final text = textControllers[field.key]!.text.trim();
      if (text.isNotEmpty) inputs[field.key] = InputParser.parse(field, text);
    }
    return inputs;
  }

  Future<void> predict() async {
    if (isLoading) return;
    _status = PredictionStatus.loading;
    _notify();

    try {
      _result = await _service.predict(buildInputs());
      _status = PredictionStatus.success;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _status = PredictionStatus.error;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _status = PredictionStatus.error;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final controller in textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
