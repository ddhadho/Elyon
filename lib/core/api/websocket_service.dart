import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../models/device_state.dart';

/// Connects to the daemon's /ws endpoint and emits device state snapshots.
/// The daemon pushes a full snapshot every 2 seconds.
/// Reconnects automatically on disconnect.
class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  WebSocketChannel? _channel;
  StreamController<Map<String, DeviceState>>? _controller;
  bool _running = false;

  Stream<Map<String, DeviceState>> get stateStream {
    _controller ??= StreamController<Map<String, DeviceState>>.broadcast(
      onListen: _connect,
      onCancel: _disconnect,
    );
    return _controller!.stream;
  }

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _connect();
  }

  void stop() {
    _running = false;
    _disconnect();
  }

  void _connect() async {
    final url = await AppConfig.getDaemonUrl();
    if (url == null) return;
    final wsUrl = '${url.replaceFirst('http', 'ws')}/ws';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone:  _scheduleReconnect,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      if (json.containsKey('devices')) {
        final stateMap = DeviceState.mapFromJson(
          json['devices'] as Map<String, dynamic>,
        );
        _controller?.add(stateMap);
      }
    } catch (_) {}
  }

  void _scheduleReconnect() {
    if (!_running) return;
    Future.delayed(const Duration(seconds: 3), () {
      if (_controller?.hasListener ?? false) _connect();
    });
  }

  void _disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}