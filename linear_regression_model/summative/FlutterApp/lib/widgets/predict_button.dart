import 'package:flutter/material.dart';

/// The "Predict" button. It is disabled while a request is running.
class PredictButton extends StatelessWidget {
  const PredictButton({super.key, required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: const Text('Predict'),
      ),
    );
  }
}
