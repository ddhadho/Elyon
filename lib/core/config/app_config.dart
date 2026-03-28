import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConfig {
  static const _storage = FlutterSecureStorage();

  static const _keyHost      = 'daemon_host';
  static const _keyPort      = 'daemon_port';
  static const _keyToken     = 'daemon_token';
  static const _keyOwnerName = 'owner_name';

  final String host;
  final int    port;
  final String token;
  final String ownerName;

  const AppConfig({
    required this.host,
    required this.port,
    required this.token,
    required this.ownerName,
  });

  String get baseUrl => 'http://$host:$port';
  String get wsUrl   => 'ws://$host:$port/ws';

  // ── Read ────────────────────────────────────────────────────────────────

  static Future<AppConfig?> load() async {
    final host  = await _storage.read(key: _keyHost);
    final token = await _storage.read(key: _keyToken);

    // Only host and token are required — ownerName falls back gracefully
    if (host == null || token == null) return null;

    return AppConfig(
      host:      host,
      port:      int.tryParse(await _storage.read(key: _keyPort) ?? '') ?? 7000,
      token:     token,
      ownerName: await _storage.read(key: _keyOwnerName) ?? '2red2blue',
    );
  }

  static Future<String?> getDaemonUrl() async {
    final host    = await _storage.read(key: _keyHost);
    final portStr = await _storage.read(key: _keyPort);
    if (host == null) return null;
    final port = int.tryParse(portStr ?? '') ?? 7000;
    return 'http://$host:$port';
  }

  static Future<String?> getToken() async =>
      _storage.read(key: _keyToken);

  static Future<String?> getOwnerName() async =>
      _storage.read(key: _keyOwnerName);

  // Consistent with load() — only host and token are required
  static Future<bool> isConfigured() async {
    final host  = await _storage.read(key: _keyHost);
    final token = await _storage.read(key: _keyToken);
    return host != null && host.isNotEmpty &&
           token != null && token.isNotEmpty;
  }

  // ── Write ───────────────────────────────────────────────────────────────

  static Future<void> save({
    required String daemonUrl,
    required String token,
    String ownerName = '2red2blue', // optional — set later from settings
  }) async {
    final uri = Uri.tryParse(daemonUrl);
    await _storage.write(key: _keyHost,      value: uri?.host ?? daemonUrl);
    await _storage.write(key: _keyPort,      value: (uri?.port != 0 ? uri?.port ?? 7000 : 7000).toString());
    await _storage.write(key: _keyToken,     value: token.trim());
    await _storage.write(key: _keyOwnerName, value: ownerName.trim());
  }

  static Future<void> saveOwnerName(String name) async =>
      _storage.write(key: _keyOwnerName, value: name.trim());

  static Future<void> clear() async => _storage.deleteAll();
}