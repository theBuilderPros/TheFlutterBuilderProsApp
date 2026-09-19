import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';
import 'package:the_builder_pros/wallet_sdk/src/default_wallet_sdk.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/activation_submission_store.dart';
import 'package:the_builder_pros/wallet_sdk/src/transport/activation_submission_client.dart';
import 'package:the_builder_pros/wallet_sdk/src/transport/activation_reconciliation_client.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

void main() {
  final ProviderConfiguration configuration = ProviderConfiguration(
    endpoint: Uri.parse('https://xlm.nownodes.io'),
    apiKey: 'secret-key',
    environment: ProviderEnvironment.test,
    version: 1,
  );

  test(
    'submits one form-encoded envelope with provider authentication',
    () async {
      int calls = 0;
      final DirectActivationSubmissionClient client =
          DirectActivationSubmissionClient(
            client: MockClient((http.Request request) async {
              calls++;
              expect(request.url.path, '/transactions');
              expect(request.headers['api-key'], 'secret-key');
              expect(request.bodyFields['tx'], 'AAAA');
              return http.Response('{"hash":"ignored"}', 200);
            }),
          );

      expect(
        await client.submit(configuration: configuration, envelopeXdr: 'AAAA'),
        ActivationSubmissionResult.accepted,
      );
      expect(calls, 1);
    },
  );

  test('separates definite rejection from uncertain submission', () async {
    final DirectActivationSubmissionClient rejected =
        DirectActivationSubmissionClient(
          client: MockClient((_) async => http.Response('private detail', 400)),
        );
    final DirectActivationSubmissionClient uncertain =
        DirectActivationSubmissionClient(
          client: MockClient((_) async => http.Response('private detail', 503)),
        );

    expect(
      await rejected.submit(configuration: configuration, envelopeXdr: 'AAAA'),
      ActivationSubmissionResult.rejected,
    );
    expect(
      await uncertain.submit(configuration: configuration, envelopeXdr: 'AAAA'),
      ActivationSubmissionResult.uncertain,
    );
  });

  test('does not resubmit a durably recorded response', () async {
    final _MemorySubmissionStore store = _MemorySubmissionStore(
      const ActivationSubmissionRecord(
        responseId: 'RES-TEST-01',
        transactionHash: 'abc',
        status: ActivationSubmissionStatus.uncertain,
      ),
    );
    final _CountingSubmissionClient client = _CountingSubmissionClient();
    final ActivationOutcome outcome = await DefaultWalletSdk(
      activationSubmissionStore: store,
      activationSubmissionClient: client,
    ).approveActivation('RES-TEST-01');

    expect(outcome.state, ActivationOutcomeState.uncertain);
    expect(client.calls, 0);
  });

  test('reconciles transaction and expected Rewards balance', () async {
    final DirectActivationReconciliationClient client =
        DirectActivationReconciliationClient(
          client: MockClient((http.Request request) async {
            if (request.url.path.startsWith('/transactions/')) {
              return http.Response('{"successful":true}', 200);
            }
            return http.Response(
              '{"account_id":"GBUILDER","balances":['
              '{"asset_code":"REWARD","asset_issuer":"GISSUER",'
              '"balance":"1.0000000"}]}',
              200,
            );
          }),
        );

    expect(
      await client.reconcile(
        configuration: configuration,
        transactionHash: 'abc',
        builderAccount: 'GBUILDER',
        assetCode: 'REWARD',
        assetIssuer: 'GISSUER',
        minimumRewards: 1,
      ),
      ActivationReconciliationResult.verified,
    );
  });
}

final class _MemorySubmissionStore implements ActivationSubmissionStore {
  _MemorySubmissionStore(this.record);

  ActivationSubmissionRecord? record;

  @override
  Future<ActivationSubmissionRecord?> read() async => record;

  @override
  Future<void> write(ActivationSubmissionRecord value) async => record = value;

  @override
  Future<void> clear() async => record = null;
}

final class _CountingSubmissionClient implements ActivationSubmissionClient {
  int calls = 0;

  @override
  Future<ActivationSubmissionResult> submit({
    required ProviderConfiguration configuration,
    required String envelopeXdr,
  }) async {
    calls++;
    return ActivationSubmissionResult.accepted;
  }
}
