import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Singleton Dio client.
/// Reads daemon URL and bearer token from AppConfig on every request
/// via the auth interceptor — so it always uses the current credentials.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ))
    ..interceptors.add(_AuthInterceptor())
    ..interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => print('[Smarthome HTTP] $o'),
    ));

  // ── State ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getState() async {
    final r = await _get('/state');
    return r.data as Map<String, dynamic>;
  }

  // ── Devices ────────────────────────────────────────────────────────────

  Future<List<dynamic>> getDevices() async {
    final r = await _get('/devices');
    return r.data as List<dynamic>;
  }

  // ── Commands ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> postCommand({
    required String deviceId,
    required String attribute,
    required String value,
  }) async {
    final r = await _post('/command', {
      'device_id': deviceId,
      'attribute': attribute,
      'value': value,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getCommands() async {
    final r = await _get('/commands');
    return r.data as List<dynamic>;
  }

  // ── Events ─────────────────────────────────────────────────────────────

  Future<List<dynamic>> getEvents({String? deviceId, int limit = 200}) async {
    final params = <String, dynamic>{'limit': limit};
    if (deviceId != null) params['device_id'] = deviceId;
    final r = await _get('/events', queryParameters: params);
    return r.data as List<dynamic>;
  }

  // ── Rules ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getRules() async {
    final r = await _get('/rules');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postRule(Map<String, dynamic> rule) async {
    final r = await _post('/rules', rule);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putRule(
      String id, Map<String, dynamic> rule) async {
    final r = await _put('/rules/$id', rule);
    return r.data as Map<String, dynamic>;
  }

  Future<void> enableRule(String id) => _post('/rules/$id/enable', {});
  Future<void> disableRule(String id) => _post('/rules/$id/disable', {});

  // ── Conflicts + Reconciliation ─────────────────────────────────────────

  Future<List<dynamic>> getConflicts() async {
    final r = await _get('/conflicts');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getReconciliation() async {
    final r = await _get('/reconciliation');
    return r.data as Map<String, dynamic>;
  }

  // ── HA discovery ───────────────────────────────────────────────────────

  Future<List<dynamic>> getHaEntities() async {
    final r = await _get('/ha/entities');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> postDevice(Map<String, dynamic> body) async {
    final r = await _post('/devices', body);
    return r.data as Map<String, dynamic>;
  }

  // ── Internals ──────────────────────────────────────────────────────────

  Future<Response> _get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final base = await _baseUrl();
    return _dio.get('$base$path', queryParameters: queryParameters);
  }

  Future<Response> _post(String path, dynamic data) async {
    final base = await _baseUrl();
    return _dio.post('$base$path', data: data);
  }

  Future<Response> _put(String path, dynamic data) async {
    final base = await _baseUrl();
    return _dio.put('$base$path', data: data);
  }

  Future<String> _baseUrl() async {
    final url = await AppConfig.getDaemonUrl();
    if (url == null || url.isEmpty) {
      throw StateError('Daemon URL not configured');
    }
    return url;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await AppConfig.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Surface 401 so callers can redirect to connection screen
    handler.next(err);
  }
}