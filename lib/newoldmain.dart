import 'package:flutter/material.dart';
import 'package:cvbotremote/serial.dart';
import 'package:cvbotremote/socket.dart';
import 'dart:async';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

void main() {
  runApp(const ReceiverApp());
}

class ReceiverApp extends StatelessWidget {
  const ReceiverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receiver App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ReceiverPage(),
    );
  }
}

class ReceiverPage extends StatefulWidget {
  const ReceiverPage({super.key});

  @override
  State<ReceiverPage> createState() => _ReceiverPageState();
}

class _ReceiverPageState extends State<ReceiverPage> {
  late WebSocketService webSocketService;
  late StreamSubscription<String> _messageSubscription;
  String _lastMessage = '';
  late SerialService serialService;
  bool _isSerialInitialized = false;
  final TextEditingController _ipController = TextEditingController();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    webSocketService = WebSocketService();
    serialService = SerialService();
    _initializeSerialService();
  }

  Future<void> _initializeSerialService() async {
    try {
      bool initializationSuccessful = await serialService.initialize();
      if (initializationSuccessful) {
        setState(() {
          _isSerialInitialized = true;
        });
      } else {
        _logger.e('SerialService initialization failed');
      }
    } catch (e) {
      _logger.e('Failed to initialize SerialService: $e');
    }
  }

  Future<void> _connectToWebSocket() async {
    String ipAddress = _ipController.text;
    try {
      await webSocketService.connect(ipAddress);
      setState(() {
        _isConnected = true;
      });
      _initializeWebSocket();
    } catch (e, stackTrace) {
      _logger.e('Failed to connect to WebSocket server: $e');
      _logger.e('Stack trace: $stackTrace');
      setState(() {
        _isConnected = false;
      });
    }
  }

  void _initializeWebSocket() {
    _messageSubscription = webSocketService.messages.listen(
      (message) {
        setState(() {
          _lastMessage = message;
        });
        // Send the message to the serial output
        if (_isSerialInitialized) {
          serialService.sendSerial(_lastMessage);
        }
      },
      onError: (error) {
        _logger.e('Error receiving WebSocket message: $error');
      },
      onDone: () {
        _logger.i('WebSocket stream is done');
      },
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    webSocketService.close();
    serialService.closePort();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receiver App')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Socket server IP',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: _connectToWebSocket,
                  child: const Icon(Icons.check),
                ),
              ],
            ),
          ),
          if (_isConnected)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Receiver Page"),
                  Text("Last message: $_lastMessage"),
                ],
              ),
            ),
          if (!_isConnected)
            const Text("Please connect to the WebSocket server first"),
        ],
      ),
    );
  }
}
