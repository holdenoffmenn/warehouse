import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String url;
  late WebSocketChannel _channel;
  final _controller = StreamController<dynamic>();
  Timer? _reconnectTimer;

  WebSocketService(this.url) {
    _connect();
  }

  void _connect() {
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel.stream.listen(
          (message) {
        _controller.add(json.decode(message));
      },
      onError: (error) {
        print('WebSocket error: $error');
        _scheduleReconnect();
      },
      onDone: () {
        print('WebSocket connection closed');
        _scheduleReconnect();
      },
    );
  }

  void _scheduleReconnect() {
    if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
      _reconnectTimer = Timer(Duration(seconds: 5), () {
        _connect();
      });
    }
  }

  void sendMessage(String message) {
    _channel.sink.add(message);
  }

  Stream<dynamic> get messages => _controller.stream;

  void dispose() {
    _reconnectTimer?.cancel();
    _channel.sink.close();
    _controller.close();
  }
}
