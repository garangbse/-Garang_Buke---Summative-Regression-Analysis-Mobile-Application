import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:earnings_predictor/config/api_config.dart';
import 'package:earnings_predictor/models/prediction_result.dart';
import 'package:earnings_predictor/services/api_exception.dart';
import 'package:earnings_predictor/utils/error_formatter.dart';

/// Sends the inputs to POST /predict and returns the predicted value,
/// or throws an [ApiException] with a message that is ready to display.
class PredictionService {
  PredictionService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<PredictionResult> predict(Map<String, dynamic> inputs) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl${ApiConfig.predictPath}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(inputs),
          )
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException(
          'The server took too long to answer. A free server can need up to a minute to wake up, so please try again.');
    } on SocketException {
      throw const ApiException('Could not reach the server. Check your internet connection and try again.');
    } on http.ClientException {
      throw const ApiException('Could not reach the server. Check your internet connection and try again.');
    }

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      debugPrint('PREDICT UNREADABLE: code ${response.statusCode} body ${response.body}');
      throw ApiException('The server sent an answer that could not be read (code ${response.statusCode}).');
    }

    if (response.statusCode == 200 && body is Map<String, dynamic>) {
      return PredictionResult.fromJson(body);
    }
    if (response.statusCode == 422 && body is Map<String, dynamic>) {
      throw ApiException(ErrorFormatter.fromDetail(body['detail']));
    }
    debugPrint('PREDICT FAILED: code ${response.statusCode} body ${response.body}');
    throw ApiException('The server returned an unexpected answer (code ${response.statusCode}). Please try again.');
  }
}
