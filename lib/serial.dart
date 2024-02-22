//serial.dart

import 'package:usb_serial/usb_serial.dart';
import 'dart:typed_data';
import 'package:logger/logger.dart';

class SerialService {
  late UsbPort _port;
  final Logger _logger = Logger();

  Future<bool> initialize() async {
    try {
      List<UsbDevice> devices = await UsbSerial.listDevices();
      if (devices.isNotEmpty) {
        _port = (await devices[0].create())!;
        bool openResult = await _port.open();
        if (!openResult) {
          _logger.e("Failed to open");
          return false;
        }
        await _port.setDTR(true);
        await _port.setRTS(true);
        _port.setPortParameters(112500, UsbPort.DATABITS_8, UsbPort.STOPBITS_1,
            UsbPort.PARITY_NONE);
        return true;
      }
    } catch (e) {
      _logger.e('Error initializing USB serial communication: $e');
      return false;
    }
    return false;
  }

  Future<void> sendSerial(String message) async {
    try {
      Uint8List data = Uint8List.fromList(message.codeUnits);
      await _port.write(data);
      _logger.d('Message sent: $message');
    } catch (e) {
      _logger.e('Failed to send message');
    }
  }

  void closePort() {
    _port.close();
    _logger.d('Port closed');
  }
}
