import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

final class ConfigurationPolicy {
  const ConfigurationPolicy();

  static const int _maximumEndpointLength = 2048;
  static const int _maximumApiKeyLength = 512;

  ProviderConfiguration validate(ProviderConfigurationInput input) {
    final String endpointValue = input.endpoint.trim();
    final String apiKey = input.apiKey.trim();
    final Uri? endpoint = Uri.tryParse(endpointValue);
    final bool isApprovedHost =
        endpoint != null &&
        (endpoint.host == 'nownodes.io' ||
            endpoint.host.endsWith('.nownodes.io'));

    if (endpointValue.isEmpty ||
        endpointValue.length > _maximumEndpointLength ||
        endpoint == null ||
        endpoint.scheme != 'https' ||
        endpoint.host.isEmpty ||
        !isApprovedHost ||
        (endpoint.path.isNotEmpty && endpoint.path != '/') ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        endpoint.userInfo.isNotEmpty ||
        (endpoint.hasPort && endpoint.port != 443) ||
        apiKey.isEmpty ||
        apiKey.length > _maximumApiKeyLength ||
        input.version < 1) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.invalidProviderConfiguration,
        safeMessage: 'Check the NOWNodes settings and try again.',
        canRetry: true,
      );
    }

    return ProviderConfiguration(
      endpoint: endpoint,
      apiKey: apiKey,
      environment: input.environment,
      version: input.version,
    );
  }
}
