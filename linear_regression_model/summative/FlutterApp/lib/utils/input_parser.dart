import 'package:earnings_predictor/models/input_field.dart';

class InputParser {
  /// Numbers are sent as numbers. Anything that is not a number is sent exactly as typed,
  /// so the API can reject it and explain the problem.
  static dynamic parse(InputField field, String text) {
    final value = text.trim();
    if (!field.numeric) return value;
    final whole = int.tryParse(value);
    if (whole != null) return whole;
    final decimal = double.tryParse(value);
    if (decimal != null && decimal.isFinite) return decimal; // "nan" or "infinity" are not numbers we can send
    return value;
  }
}
