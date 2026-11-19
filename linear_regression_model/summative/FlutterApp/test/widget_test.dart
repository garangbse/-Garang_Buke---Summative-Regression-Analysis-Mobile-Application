import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:earnings_predictor/app.dart';
import 'package:earnings_predictor/constants/input_fields.dart';

void main() {
  testWidgets('one text field per model input, a Predict button and a display area', (tester) async {
    await tester.pumpWidget(const EarningsApp());

    expect(allInputFields.length, 10);
    expect(find.byType(TextFormField), findsNWidgets(allInputFields.length));
    expect(find.text('Predict'), findsOneWidget);
    expect(find.byKey(const Key('result_area')), findsOneWidget);
  });
}
