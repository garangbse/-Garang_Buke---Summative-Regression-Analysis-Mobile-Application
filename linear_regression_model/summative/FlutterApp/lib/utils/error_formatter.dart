import 'package:earnings_predictor/constants/input_fields.dart';

/// Turns the API's validation errors (HTTP 422) into short readable lines such as
/// "Age (years): Input should be less than or equal to 35".
class ErrorFormatter {
  static String fromDetail(dynamic detail) {
    if (detail is List) {
      final lines = <String>[];
      for (final item in detail) {
        if (item is Map) {
          final location = item['loc'];
          final key = (location is List && location.isNotEmpty) ? location.last.toString() : '';
          final label = _labelFor(key);
          final message = _friendly((item['msg'] ?? 'Invalid value').toString());
          lines.add(label.isEmpty ? message : '$label: $message');
        }
      }
      if (lines.isNotEmpty) return lines.join('\n');
    }
    return detail.toString();
  }

  static String _labelFor(String key) {
    for (final field in allInputFields) {
      if (field.key == key) return field.label;
    }
    return '';
  }

  static String _friendly(String message) {
    final text = message.replaceFirst('Value error, ', '');
    if (text == 'Field required') return 'This field is required';
    if (text.startsWith('Input should be a valid integer')) return 'Enter a whole number';
    if (text.startsWith('Input should be a valid number')) return 'Enter a number';
    if (text.startsWith('Extra inputs are not permitted')) return 'Not a valid input';
    return text;
  }
}
