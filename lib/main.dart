import 'package:flutter/material.dart';
import 'package:cvbotremote/serial.dart';
import 'package:cvbotremote/socket.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Import the toast package

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
        // Initialize WebSocket service after serial service is initialized
        webSocketService = WebSocketService();
      } else {
        _logger.e('SerialService initialization failed');
        Fluttertoast.showToast(
            msg: 'SerialService initialization failed',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    } catch (e) {
      _logger.e('Failed to initialize SerialService: $e');
      Fluttertoast.showToast(
          msg: 'Failed to initialize SerialService: $e',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  Future<void> _connectToWebSocket() async {
    String ipAddress = 'ws://${_ipController.text}/receive';
    try {
      await webSocketService.connect(ipAddress);
      setState(() {
        _isConnected = true;
      });
      _initializeWebSocket();

      // Show a toast message for successful connection
      Fluttertoast.showToast(
        msg: 'Successfully connected to the WebSocket server',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green, // Use green color for success
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to connect to WebSocket server: $e');
      Fluttertoast.showToast(
        msg:
            'Failed to connect to WebSocket server: $e\nStack Trace: $stackTrace',
        toastLength: Toast
            .LENGTH_LONG, // Use LONG toast length to accommodate the stack trace
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
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
        } else {
          Fluttertoast.showToast(
              msg: 'Serial service not initialized',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
        }
      },
      onError: (error) {
        _logger.e('Error receiving WebSocket message: $error');
        Fluttertoast.showToast(
            msg: 'Error receiving WebSocket message: $error',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
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
                      labelText: 'Enter Socket server address',
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
          // Button to manually reinitialize the serial service
          ElevatedButton(
            onPressed: () {
              _initializeSerialService().then((_) {
                setState(() {
                  _isSerialInitialized = true;
                });
              }).catchError((e) {
                _logger.e('Failed to reinitialize SerialService: $e');
                Fluttertoast.showToast(
                    msg: 'Failed to reinitialize SerialService: $e',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0);
              });
            },
            child: const Text('Reinitialize Serial Service'),
          ),
        ],
      ),
    );
  }
}
