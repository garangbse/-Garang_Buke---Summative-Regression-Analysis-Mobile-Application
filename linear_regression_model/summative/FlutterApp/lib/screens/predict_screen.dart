import 'package:flutter/material.dart';

import 'package:earnings_predictor/constants/input_fields.dart';
import 'package:earnings_predictor/controllers/prediction_controller.dart';
import 'package:earnings_predictor/theme/app_theme.dart';
import 'package:earnings_predictor/widgets/labelled_text_field.dart';
import 'package:earnings_predictor/widgets/predict_button.dart';
import 'package:earnings_predictor/widgets/result_display.dart';
import 'package:earnings_predictor/widgets/section_card.dart';

/// The only page of the app: inputs, the Predict button and the display area, from top to bottom.
class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  final PredictionController _controller = PredictionController();
  final GlobalKey _resultKey = GlobalKey();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onPredict() async {
    FocusScope.of(context).unfocus();
    await _controller.predict();
    // The display area is below the form, so bring it into view.
    final resultContext = _resultKey.currentContext;
    if (mounted && resultContext != null) {
      Scrollable.ensureVisible(resultContext, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastKey = allInputFields.last.key;
    return Scaffold(
      appBar: AppBar(title: const Text('Young Employee Earnings Predictor')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter the details of a young employee (aged 18 to 35) to estimate their monthly cash earnings in RWF.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  for (final section in inputSections) ...[
                    SectionCard(
                      title: section.title,
                      children: [
                        for (final field in section.fields)
                          LabelledTextField(
                            field: field,
                            controller: _controller.textControllers[field.key]!,
                            isLast: field.key == lastKey,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.medium),
                  ],
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => PredictButton(
                      isLoading: _controller.isLoading,
                      onPressed: _onPredict,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  Container(
                    key: _resultKey,
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) => ResultDisplay(
                        status: _controller.status,
                        result: _controller.result,
                        errorMessage: _controller.errorMessage,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
