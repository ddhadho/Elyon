import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Thin wrapper around the 2red2blue daemon REST API.
/// All methods throw [DioException] on network failure.
class RestClient {
  final Dio _dio;

  RestClient(AppConfig config)
      : _dio = Dio(
          BaseOptions(
            baseUrl: config.baseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            headers: {
              'Authorization': 'Bearer ${config.token}',
              'Content-Type': 'application/json',
            },
          ),
        );

  /// GET /state — full device state map
  Future<Map<String, dynamic>> fetchState() async {
    final response = await _dio.get<Map<String, dynamic>>('/state');
    return response.data!;
  }

  /// GET /devices — device metadata (name, kind, writable)
  Future<List<dynamic>> fetchDevices() async {
    final response = await _dio.get<List<dynamic>>('/devices');
    return response.data!;
  }

  /// POST /command — send a manual command to a device
  Future<Map<String, dynamic>> sendCommand({
    required String deviceId,
    required String attribute,
    required String value,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/command',
      data: {
        'device_id': deviceId,
        'attribute': attribute,
        'value':     value,
      },
    );
    return response.data!;
  }

  /// GET /commands — pending and recent commands
  Future<List<dynamic>> fetchCommands() async {
    final response = await _dio.get<List<dynamic>>('/commands');
    return response.data!;
  }

  /// GET /rules — active rules + in-flight actions
  Future<Map<String, dynamic>> fetchRules() async {
    final response = await _dio.get<Map<String, dynamic>>('/rules');
    return response.data!;
  }

  /// GET /reconciliation — last boot reconciliation report
  Future<Map<String, dynamic>> fetchReconciliation() async {
    final response = await _dio.get<Map<String, dynamic>>('/reconciliation');
    return response.data!;
  }

  /// GET /conflicts — rule conflicts
  Future<List<dynamic>> fetchConflicts() async {
    final response = await _dio.get<List<dynamic>>('/conflicts');
    return response.data!;
  }
}