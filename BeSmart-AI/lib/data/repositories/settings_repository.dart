import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _keyModelReady = 'model_ready';
  static const _keyActiveModelId = 'active_model_id';
  static const _keyStoredSha256 = 'stored_sha256';
  static const _keyTemperature = 'temperature';
  static const _keyMaxTokens = 'max_tokens';
  static const _keySystemPrompt = 'system_prompt';

  bool get isModelReady => _prefs.getBool(_keyModelReady) ?? false;

  Future<void> setModelReady(bool value) =>
      _prefs.setBool(_keyModelReady, value);

  String? get activeModelId => _prefs.getString(_keyActiveModelId);

  Future<void> setActiveModelId(String id) =>
      _prefs.setString(_keyActiveModelId, id);

  String? get storedSha256 => _prefs.getString(_keyStoredSha256);

  Future<void> setStoredSha256(String hash) =>
      _prefs.setString(_keyStoredSha256, hash);

  double get temperature => _prefs.getDouble(_keyTemperature) ?? 0.7;

  Future<void> setTemperature(double value) =>
      _prefs.setDouble(_keyTemperature, value);

  int get maxTokens => _prefs.getInt(_keyMaxTokens) ?? 512;

  Future<void> setMaxTokens(int value) => _prefs.setInt(_keyMaxTokens, value);

  String get systemPrompt =>
      _prefs.getString(_keySystemPrompt) ??
      'Tu es un assistant IA utile, concis et bienveillant. Réponds en français sauf demande contraire.';
}
