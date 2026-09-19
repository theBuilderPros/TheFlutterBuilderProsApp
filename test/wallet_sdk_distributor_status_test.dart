import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';
import 'package:the_builder_pros/wallet_sdk/src/transport/distributor_status_client.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

void main() {
  test(
    'loads account and fee status directly with provider authentication',
    () async {
      final List<http.Request> requests = <http.Request>[];
      final DirectDistributorStatusClient client =
          DirectDistributorStatusClient(
            client: MockClient((http.Request request) async {
              requests.add(request);
              if (request.url.path.endsWith('/fee_stats')) {
                return _json(<String, Object>{
                  'fee_charged': <String, String>{'p95': '250'},
                });
              }
              return _json(<String, Object>{
                'account_id': 'GACCOUNT',
                'sequence': '12345',
                'subentry_count': 2,
                'balances': <Object>[
                  <String, String>{
                    'asset_type': 'native',
                    'balance': '20.0000000',
                    'selling_liabilities': '1.0000000',
                  },
                  <String, String>{
                    'asset_type': 'credit_alphanum12',
                    'balance': '250.0000000',
                    'selling_liabilities': '25.0000000',
                  },
                ],
              });
            }),
          );

      final DistributorLedgerStatus result = await client.load(
        configuration: _configuration,
        accountId: 'GACCOUNT',
      );

      expect(
        requests.map((request) => request.url.path),
        containsAll(<String>['/accounts/GACCOUNT', '/fee_stats']),
      );
      expect(
        requests.every((request) => request.headers['api-key'] == 'key'),
        isTrue,
      );
      expect(result.nativeBalance, 20);
      expect(result.nativeSellingLiabilities, 1);
      expect(result.nonNativeSpendableBalances, <double>[225]);
      expect(result.sequence, '12345');
      expect(result.feeP95Stroops, 250);
    },
  );

  test('maps malformed and unsuccessful responses to a safe failure', () async {
    for (final http.Response response in <http.Response>[
      http.Response('missing', 404),
      _json(<String, Object>{'bad': true}),
    ]) {
      final DirectDistributorStatusClient client =
          DirectDistributorStatusClient(
            client: MockClient((_) async => response),
          );
      await expectLater(
        client.load(configuration: _configuration, accountId: 'GACCOUNT'),
        throwsA(
          isA<WalletSdkException>()
              .having(
                (WalletSdkException error) => error.code,
                'code',
                WalletSdkFailureCode.distributorAccountUnavailable,
              )
              .having(
                (WalletSdkException error) => error.safeMessage,
                'safeMessage',
                isNot(contains('missing')),
              ),
        ),
      );
    }
  });
}

final ProviderConfiguration _configuration = ProviderConfiguration(
  endpoint: Uri.parse('https://xlm.nownodes.io'),
  apiKey: 'key',
  environment: ProviderEnvironment.production,
  version: 1,
);

http.Response _json(Map<String, Object> value) => http.Response(
  jsonEncode(value),
  200,
  headers: <String, String>{'content-type': 'application/json'},
);
