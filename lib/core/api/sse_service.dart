import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

enum SseEventKind {
  stateChanged,
  powerCut,
  powerRestored,
  commandConfirmed,
  commandFailed,
  heartbeat,
  unknown,
}

class SseEvent {
  final SseEventKind kind;
  final Map<String, dynamic> data;
  const SseEvent(this.kind, this.data);
}

class SseService {
  SseService._();
  static final SseService instance = SseService._();

  final _controller = StreamController<SseEvent>.broadcast();
  Stream<SseEvent> get events => _controller.stream;

  StreamSubscription? _sub;
  Timer? _heartbeatTimer;
  bool _running = false;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    await _connect();
  }

  void stop() {
    _running = false;
    _heartbeatTimer?.cancel();
    _sub?.cancel();
    _sub = null;
  }

  Future<void> _connect() async {
    final url   = await AppConfig.getDaemonUrl();
    final token = await AppConfig.getToken();
    if (url == null || token == null) return;

    try {
      final request = http.Request('GET', Uri.parse('$url/stream'));
      request.headers['Authorization']  = 'Bearer $token';
      request.headers['Accept']         = 'text/event-stream';
      request.headers['Cache-Control']  = 'no-cache';

      final client   = http.Client();
      final response = await client.send(request);

      _resetHeartbeatTimer();

      String buffer = '';
      _sub = response.stream
          .transform(utf8.decoder)
          .listen(
        (chunk) {
          _resetHeartbeatTimer();
          buffer += chunk;
          // SSE messages are separated by double newlines
          while (buffer.contains('\n\n')) {
            final idx     = buffer.indexOf('\n\n');
            final message = buffer.substring(0, idx);
            buffer        = buffer.substring(idx + 2);
            final parsed  = _parseMessage(message);
            if (parsed != null) _controller.add(parsed);
          }
        },
        onError: (_) { client.close(); _scheduleReconnect(); },
        onDone:  ()  { client.close(); _scheduleReconnect(); },
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _resetHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer(const Duration(seconds: 60), () {
      _sub?.cancel();
      _scheduleReconnect();
    });
  }

  void _scheduleReconnect() {
    if (!_running) return;
    Future.delayed(const Duration(seconds: 5), _connect);
  }

  SseEvent? _parseMessage(String message) {
    String? eventType;
    String? dataLine;

    for (final line in message.split('\n')) {
      if (line.startsWith('event:')) {
        eventType = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLine = line.substring(5).trim();
      }
    }

    if (eventType == null) return null;

    final kind = switch (eventType) {
      'state_changed'     => SseEventKind.stateChanged,
      'power_cut'         => SseEventKind.powerCut,
      'power_restored'    => SseEventKind.powerRestored,
      'command_confirmed' => SseEventKind.commandConfirmed,
      'command_failed'    => SseEventKind.commandFailed,
      'heartbeat'         => SseEventKind.heartbeat,
      _                   => SseEventKind.unknown,
    };

    Map<String, dynamic> data = {};
    try {
      if (dataLine != null && dataLine.isNotEmpty) {
        data = jsonDecode(dataLine) as Map<String, dynamic>;
      }
    } catch (_) {}

    return SseEvent(kind, data);
  }
}
