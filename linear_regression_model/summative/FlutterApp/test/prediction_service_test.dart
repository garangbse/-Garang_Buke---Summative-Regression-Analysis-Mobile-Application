import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:earnings_predictor/services/api_exception.dart';
import 'package:earnings_predictor/services/prediction_service.dart';

void main() {
  test('returns the predicted value when the API answers 200', () async {
    final service = PredictionService(
      baseUrl: 'http://test',
      client: MockClient((request) async => http.Response(
          jsonEncode({'predicted_monthly_cash_rwf': 53936.14, 'currency': 'RWF', 'model': 'RandomForestRegressor'}),
          200)),
    );

    final result = await service.predict({'a04': 29});

    expect(result.monthlyCashRwf, 53936.14);
  });

  test('turns a 422 validation answer into a readable message', () async {
    final service = PredictionService(
      baseUrl: 'http://test',
      client: MockClient((request) async => http.Response(
          jsonEncode({
            'detail': [
              {'loc': ['body', 'a04'], 'msg': 'Input should be less than or equal to 35', 'type': 'less_than_equal'},
              {'loc': ['body', 'd08'], 'msg': 'Field required', 'type': 'missing'},
            ]
          }),
          422)),
    );

    expect(
      () => service.predict({'a04': 99}),
      throwsA(isA<ApiException>().having(
        (e) => e.message,
        'message',
        allOf(
          contains('Age (years): Input should be less than or equal to 35'),
          contains('Contract duration: This field is required'),
        ),
      )),
    );
  });
}
