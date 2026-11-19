import 'package:flutter/material.dart';

import 'package:earnings_predictor/models/input_field.dart';

/// A labelled text field with a hint underneath and, for categories, a menu of the allowed values.
class LabelledTextField extends StatelessWidget {
  const LabelledTextField({
    super.key,
    required this.field,
    required this.controller,
    this.isLast = false,
  });

  final InputField field;
  final TextEditingController controller;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: field.numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.hint,
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
        suffixIcon: field.options.isEmpty ? null : _optionsMenu(),
      ),
    );
  }

  Widget _optionsMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.arrow_drop_down),
      tooltip: 'Choose ${field.label}',
      onSelected: (value) => controller.text = value,
      itemBuilder: (context) => [
        for (final option in field.options) PopupMenuItem<String>(value: option, child: Text(option)),
      ],
    );
  }
}
