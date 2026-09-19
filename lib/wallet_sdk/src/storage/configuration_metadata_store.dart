import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ConfigurationMetadataStore {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> clear();
}

final class PreferencesConfigurationMetadataStore
    implements ConfigurationMetadataStore {
  static const String preferenceKey =
      'rewards.provider.configuration.status.v1';

  @override
  Future<String?> read() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(preferenceKey);
  }

  @override
  Future<void> write(String value) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final bool saved = await preferences.setString(preferenceKey, value);
    if (!saved) {
      throw StateError('Configuration status was not persisted.');
    }
  }

  @override
  Future<void> clear() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(preferenceKey);
  }
}
