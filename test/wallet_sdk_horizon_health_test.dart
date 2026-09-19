import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';
import 'package:the_builder_pros/wallet_sdk/src/transport/horizon_health_client.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

void main() {
  final ProviderConfiguration testConfiguration = ProviderConfiguration(
    endpoint: Uri.parse('https://xlm.nownodes.io'),
    apiKey: 'test-api-key',
    environment: ProviderEnvironment.test,
    version: 1,
  );

  test('sends api-key and accepts matching Horizon health response', () async {
    late http.Request captured;
    final DirectHorizonHealthClient client = DirectHorizonHealthClient(
      client: MockClient((http.Request request) async {
        captured = request;
        return _healthResponse();
      }),
    );

    await client.check(testConfiguration);

    expect(captured.method, 'GET');
    expect(captured.url, Uri.parse('https://xlm.nownodes.io'));
    expect(captured.headers['api-key'], 'test-api-key');
    expect(captured.headers['accept'], 'application/json');
  });

  test('accepts a Horizon HAL JSON health response', () async {
    int requests = 0;
    final DirectHorizonHealthClient client = DirectHorizonHealthClient(
      client: MockClient((_) async {
        requests++;
        return _healthResponse(
          contentType: 'application/hal+json; charset=utf-8',
        );
      }),
      maximumAttempts: 1,
    );

    await client.check(testConfiguration);

    expect(requests, 1);
  });

  test('maps authorization and transient status codes safely', () async {
    final Map<int, WalletSdkFailureCode> cases = <int, WalletSdkFailureCode>{
      401: WalletSdkFailureCode.providerUnauthorized,
      403: WalletSdkFailureCode.providerUnauthorized,
      429: WalletSdkFailureCode.providerRateLimited,
      500: WalletSdkFailureCode.providerServiceUnavailable,
      503: WalletSdkFailureCode.providerServiceUnavailable,
    };

    for (final MapEntry<int, WalletSdkFailureCode> entry in cases.entries) {
      final DirectHorizonHealthClient client = DirectHorizonHealthClient(
        client: MockClient(
          (_) async => http.Response(
            'not exposed',
            entry.key,
            headers: <String, String>{'content-type': 'application/json'},
          ),
        ),
      );
      await expectLater(
        client.check(testConfiguration),
        throwsA(
          isA<WalletSdkException>()
              .having(
                (WalletSdkException error) => error.code,
                'code',
                entry.value,
              )
              .having(
                (WalletSdkException error) => error.safeMessage,
                'safeMessage',
                isNot(contains('not exposed')),
              ),
        ),
      );
    }
  });

  test(
    'rejects malformed, wrong-content, oversized, and wrong-network responses',
    () async {
      final List<({http.Response response, WalletSdkFailureCode code})> cases =
          <({http.Response response, WalletSdkFailureCode code})>[
            (
              response: http.Response(
                '{bad',
                200,
                headers: <String, String>{'content-type': 'application/json'},
              ),
              code: WalletSdkFailureCode.providerInvalidResponse,
            ),
            (
              response: http.Response(
                '<html></html>',
                200,
                headers: <String, String>{'content-type': 'text/html'},
              ),
              code: WalletSdkFailureCode.providerInvalidResponse,
            ),
            (
              response: http.Response(
                List<String>.filled(65, 'x').join(),
                200,
                headers: <String, String>{'content-type': 'application/json'},
              ),
              code: WalletSdkFailureCode.providerInvalidResponse,
            ),
            (
              response: _healthResponse(
                networkPassphrase:
                    'Public Global Stellar Network ; September 2015',
              ),
              code: WalletSdkFailureCode.providerNetworkMismatch,
            ),
          ];

      for (int index = 0; index < cases.length; index++) {
        final item = cases[index];
        final DirectHorizonHealthClient client = DirectHorizonHealthClient(
          client: MockClient((_) async => item.response),
          maximumResponseBytes: index == 2 ? 64 : 64 * 1024,
        );
        await expectLater(
          client.check(testConfiguration),
          throwsA(
            isA<WalletSdkException>().having(
              (WalletSdkException error) => error.code,
              'code',
              item.code,
            ),
          ),
        );
      }
    },
  );

  test('maps total timeout to a safe retryable failure', () async {
    final DirectHorizonHealthClient client = DirectHorizonHealthClient(
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return _healthResponse();
      }),
      totalTimeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      client.check(testConfiguration),
      throwsA(
        isA<WalletSdkException>()
            .having(
              (WalletSdkException error) => error.code,
              'code',
              WalletSdkFailureCode.providerTimeout,
            )
            .having(
              (WalletSdkException error) => error.canRetry,
              'canRetry',
              isTrue,
            ),
      ),
    );
  });

  test('retries transient failures with a bounded attempt count', () async {
    int calls = 0;
    final DirectHorizonHealthClient client = DirectHorizonHealthClient(
      client: MockClient((_) async {
        calls++;
        return calls < 3
            ? http.Response(
                'busy',
                503,
                headers: <String, String>{'content-type': 'application/json'},
              )
            : _healthResponse();
      }),
      retryBaseDelay: Duration.zero,
      random: Random(1),
      delay: (_) async {},
    );

    await client.check(testConfiguration);

    expect(calls, 3);
  });
}

http.Response _healthResponse({
  String networkPassphrase = 'Test SDF Network ; September 2015',
  String contentType = 'application/json; charset=utf-8',
}) => http.Response(
  jsonEncode(<String, Object>{
    'network_passphrase': networkPassphrase,
    'horizon_version': '2.33.0',
  }),
  200,
  headers: <String, String>{'content-type': contentType},
);
