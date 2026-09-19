import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';

enum ActivationSubmissionResult { accepted, rejected, uncertain }

abstract interface class ActivationSubmissionClient {
  Future<ActivationSubmissionResult> submit({
    required ProviderConfiguration configuration,
    required String envelopeXdr,
  });
}

final class DirectActivationSubmissionClient
    implements ActivationSubmissionClient {
  DirectActivationSubmissionClient({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<ActivationSubmissionResult> submit({
    required ProviderConfiguration configuration,
    required String envelopeXdr,
  }) async {
    try {
      final http.Response response = await _client
          .post(
            configuration.endpoint.replace(
              pathSegments: <String>[
                ...configuration.endpoint.pathSegments.where(
                  (String value) => value.isNotEmpty,
                ),
                'transactions',
              ],
              query: null,
              fragment: null,
            ),
            headers: <String, String>{
              'accept': 'application/json',
              'api-key': configuration.apiKey,
              'content-type': 'application/x-www-form-urlencoded',
            },
            body: <String, String>{'tx': envelopeXdr},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ActivationSubmissionResult.accepted;
      }
      if (response.statusCode >= 400 &&
          response.statusCode < 500 &&
          response.statusCode != 408 &&
          response.statusCode != 429) {
        return ActivationSubmissionResult.rejected;
      }
      return ActivationSubmissionResult.uncertain;
    } on TimeoutException {
      return ActivationSubmissionResult.uncertain;
    } catch (_) {
      return ActivationSubmissionResult.uncertain;
    }
  }
}
