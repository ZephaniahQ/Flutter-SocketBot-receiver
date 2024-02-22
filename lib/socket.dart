//socket.dart
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  late IOWebSocketChannel _channel;

  Future<void> connect(String url) async {
    _channel = IOWebSocketChannel.connect(url);
  }

  Future<void> sendMessage(String message) async {
    _channel.sink.add(message);
  }

  Stream<String> get messages {
    return _channel.stream.cast<String>();
    //_channel.stream.map((message) => message as String);
  }

  void close() {
    _channel.sink.close();
  }
}
