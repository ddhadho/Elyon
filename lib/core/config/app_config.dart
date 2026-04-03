import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConfig {
  static const _storage = FlutterSecureStorage();

  static const _keyUrl      = 'daemon_url';   
  static const _keyToken     = 'daemon_token';
  static const _keyOwnerName = 'owner_name';

  final String url;
  final String token;
  final String ownerName;

  const AppConfig({
    required this.url,
    required this.token,
    required this.ownerName,
  });

  String get baseUrl => url;

  // ── Read ────────────────────────────────────────────────────────────────

  static Future<AppConfig?> load() async {
    final url   = await _storage.read(key: _keyUrl);
    final token = await _storage.read(key: _keyToken);
    if (url == null || token == null) return null;
    return AppConfig(
      url:       url,
      token:     token,
      ownerName: await _storage.read(key: _keyOwnerName) ?? '2red2blue',
    );
  }

  static Future<String?> getDaemonUrl() async =>
      _storage.read(key: _keyUrl);

  static Future<String?> getToken() async =>
      _storage.read(key: _keyToken);

  static Future<String?> getOwnerName() async =>
      _storage.read(key: _keyOwnerName);

  // Consistent with load() — only host and token are required
  static Future<bool> isConfigured() async {
    final url   = await _storage.read(key: _keyUrl);
    final token = await _storage.read(key: _keyToken);
    return url != null && url.isNotEmpty &&
          token != null && token.isNotEmpty;
  }

  // ── Write ───────────────────────────────────────────────────────────────

  static Future<void> save({
    required String daemonUrl,
    required String token,
    String ownerName = '2red2blue',
  }) async {
    await _storage.write(key: _keyUrl,       value: daemonUrl.trim());
    await _storage.write(key: _keyToken,     value: token.trim());
    await _storage.write(key: _keyOwnerName, value: ownerName.trim());
  }

  static Future<void> saveOwnerName(String name) async =>
      _storage.write(key: _keyOwnerName, value: name.trim());

  static Future<void> clear() async => _storage.deleteAll();
}