/// One input variable of the model, as shown on the page.
class InputField {
  const InputField({
    required this.key,
    required this.label,
    required this.hint,
    this.numeric = false,
    this.options = const [],
  });

  /// Name of the variable in the API request (for example `a04`).
  final String key;

  /// Text shown above the field.
  final String label;

  /// Short help text shown under the field (range or how to fill it in).
  final String hint;

  /// True for numbers (age, hours, ...). Other fields are text.
  final bool numeric;

  /// Allowed values of a categorical field. They are offered in a menu, but the user may also type.
  final List<String> options;
}

/// A group of fields shown together in a card.
class InputSection {
  const InputSection({required this.title, required this.fields});

  final String title;
  final List<InputField> fields;
}
