import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LocalStorage {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<bool?> readBool(String key);

  Future<void> writeBool(String key, bool value);

  Future<void> remove(String key);
}

class SharedPreferencesLocalStorage implements LocalStorage {
  const SharedPreferencesLocalStorage(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<String?> readString(String key) async => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<bool?> readBool(String key) async => _preferences.getBool(key);

  @override
  Future<void> writeBool(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }
}

class InMemoryLocalStorage implements LocalStorage {
  final Map<String, Object> _values = <String, Object>{};

  @override
  Future<String?> readString(String key) async {
    final value = _values[key];
    return value is String ? value : null;
  }

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<bool?> readBool(String key) async {
    final value = _values[key];
    return value is bool ? value : null;
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}
