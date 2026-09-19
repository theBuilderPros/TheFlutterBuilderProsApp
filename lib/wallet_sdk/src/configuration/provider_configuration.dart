import 'dart:convert';

import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

final class ProviderConfiguration {
  const ProviderConfiguration({
    required this.endpoint,
    required this.apiKey,
    required this.environment,
    required this.version,
  });

  final Uri endpoint;
  final String apiKey;
  final ProviderEnvironment environment;
  final int version;

  String encodeProtected() => jsonEncode(<String, Object>{
    'endpoint': endpoint.toString(),
    'api_key': apiKey,
    'environment': environment.name,
    'version': version,
  });

  factory ProviderConfiguration.decodeProtected(String value) {
    final Map<String, dynamic> json = jsonDecode(value) as Map<String, dynamic>;
    return ProviderConfiguration(
      endpoint: Uri.parse(json['endpoint'] as String),
      apiKey: json['api_key'] as String,
      environment: ProviderEnvironment.values.byName(
        json['environment'] as String,
      ),
      version: json['version'] as int,
    );
  }
}
