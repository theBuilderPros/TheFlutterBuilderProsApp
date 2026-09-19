import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/configuration_metadata_store.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

abstract interface class ConfigurationStore {
  Future<void> savePending(ProviderConfiguration configuration);

  Future<ProviderConfiguration?> readPending();

  Future<ProviderConfiguration?> readActive();

  Future<ProviderConfigurationStatus> readStatus();

  Future<void> promotePending(DateTime checkedAt);

  Future<void> discardPending();
}

final class ProtectedConfigurationStore implements ConfigurationStore {
  ProtectedConfigurationStore({
    FlutterSecureStorage? secureStorage,
    ConfigurationMetadataStore? metadataStore,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _metadataStore =
           metadataStore ?? PreferencesConfigurationMetadataStore();

  static const String _pendingConfigurationKey =
      'rewards.provider.configuration.pending.v1';
  static const String _activeConfigurationKey =
      'rewards.provider.configuration.active.v1';

  final FlutterSecureStorage _secureStorage;
  final ConfigurationMetadataStore _metadataStore;

  @override
  Future<void> savePending(ProviderConfiguration configuration) async {
    final String? previousMetadata = await _metadataStore.read();
    try {
      await _secureStorage.write(
        key: _pendingConfigurationKey,
        value: configuration.encodeProtected(),
      );
      final ProviderConfigurationStatus? previousStatus = _decodeStatus(
        previousMetadata,
      );
      if (previousStatus?.state != ProviderConfigurationState.ready) {
        await _metadataStore.write(
          _encodeStatus(
            configuration: configuration,
            state: ProviderConfigurationState.pendingVerification,
          ),
        );
      }
    } catch (_) {
      await _secureStorage.delete(key: _pendingConfigurationKey);
      await _restoreMetadata(previousMetadata);
      rethrow;
    }
  }

  @override
  Future<ProviderConfiguration?> readPending() async {
    final String? raw = await _secureStorage.read(
      key: _pendingConfigurationKey,
    );
    if (raw == null) {
      return null;
    }
    return ProviderConfiguration.decodeProtected(raw);
  }

  @override
  Future<ProviderConfiguration?> readActive() async {
    final String? raw = await _secureStorage.read(key: _activeConfigurationKey);
    return raw == null ? null : ProviderConfiguration.decodeProtected(raw);
  }

  @override
  Future<ProviderConfigurationStatus> readStatus() async {
    final ProviderConfigurationStatus? status = _decodeStatus(
      await _metadataStore.read(),
    );
    if (status == null) {
      return const ProviderConfigurationStatus.notConfigured();
    }

    final String requiredKey = status.state == ProviderConfigurationState.ready
        ? _activeConfigurationKey
        : _pendingConfigurationKey;
    if (!await _secureStorage.containsKey(key: requiredKey)) {
      return const ProviderConfigurationStatus.notConfigured();
    }
    return status;
  }

  @override
  Future<void> promotePending(DateTime checkedAt) async {
    final String? candidate = await _secureStorage.read(
      key: _pendingConfigurationKey,
    );
    if (candidate == null) {
      throw StateError('No pending provider configuration exists.');
    }
    final ProviderConfiguration configuration =
        ProviderConfiguration.decodeProtected(candidate);
    final String? previousActive = await _secureStorage.read(
      key: _activeConfigurationKey,
    );
    final String? previousMetadata = await _metadataStore.read();

    try {
      await _secureStorage.write(
        key: _activeConfigurationKey,
        value: candidate,
      );
      await _metadataStore.write(
        _encodeStatus(
          configuration: configuration,
          state: ProviderConfigurationState.ready,
          checkedAt: checkedAt,
        ),
      );
      await _secureStorage.delete(key: _pendingConfigurationKey);
    } catch (_) {
      if (previousActive == null) {
        await _secureStorage.delete(key: _activeConfigurationKey);
      } else {
        await _secureStorage.write(
          key: _activeConfigurationKey,
          value: previousActive,
        );
      }
      await _restoreMetadata(previousMetadata);
      rethrow;
    }
  }

  @override
  Future<void> discardPending() async {
    await _secureStorage.delete(key: _pendingConfigurationKey);
    final ProviderConfigurationStatus? status = _decodeStatus(
      await _metadataStore.read(),
    );
    if (status?.state == ProviderConfigurationState.pendingVerification) {
      await _metadataStore.clear();
    }
  }

  String _encodeStatus({
    required ProviderConfiguration configuration,
    required ProviderConfigurationState state,
    DateTime? checkedAt,
  }) => jsonEncode(<String, Object>{
    'state': state.name,
    'environment': configuration.environment.name,
    'version': configuration.version,
    'endpoint_host': configuration.endpoint.host,
    if (checkedAt != null) 'last_checked_at': checkedAt.toIso8601String(),
  });

  ProviderConfigurationStatus? _decodeStatus(String? raw) {
    if (raw == null) {
      return null;
    }
    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      return ProviderConfigurationStatus(
        state: ProviderConfigurationState.values.byName(
          json['state'] as String,
        ),
        environment: ProviderEnvironment.values.byName(
          json['environment'] as String,
        ),
        version: json['version'] as int,
        endpointHost: json['endpoint_host'] as String,
        lastCheckedAt: json['last_checked_at'] == null
            ? null
            : DateTime.parse(json['last_checked_at'] as String).toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _restoreMetadata(String? previousMetadata) async {
    if (previousMetadata == null) {
      await _metadataStore.clear();
    } else {
      await _metadataStore.write(previousMetadata);
    }
  }
}
