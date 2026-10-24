import 'dart:async';
import 'dart:convert';

import '../models/device_reading.dart';

class DeviceDataService {
  final StreamController<DeviceReading> _readingController =
      StreamController<DeviceReading>.broadcast();

  String _incomingBuffer = '';

  Stream<DeviceReading> get readings => _readingController.stream;

  void processIncomingChunk(String chunk) {
    _incomingBuffer += chunk;

    while (_incomingBuffer.contains('\n')) {
      final separatorIndex = _incomingBuffer.indexOf('\n');

      final completeMessage = _incomingBuffer
          .substring(0, separatorIndex)
          .trim();

      _incomingBuffer = _incomingBuffer.substring(separatorIndex + 1);

      if (completeMessage.isEmpty) {
        continue;
      }

      final reading = tryParseMessage(completeMessage);

      if (reading != null) {
        _readingController.add(reading);
      }
    }
  }

  DeviceReading? tryParseMessage(String message) {
    try {
      final decoded = jsonDecode(message);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return DeviceReading.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<DeviceReading> generateDemoReading({
    required String sampleId,
    required String feedType,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final reading = DeviceReading.demo(sampleId: sampleId, feedType: feedType);

    _readingController.add(reading);

    return reading;
  }

  String buildCommand(String command, {Map<String, dynamic>? parameters}) {
    final message = <String, dynamic>{'command': command, ...?parameters};

    return '${jsonEncode(message)}\n';
  }

  String buildStartScanCommand({
    required String sampleId,
    required String feedType,
  }) {
    return buildCommand(
      'START_SCAN',
      parameters: {'sampleId': sampleId, 'feedType': feedType},
    );
  }

  String buildStatusCommand() {
    return buildCommand('GET_STATUS');
  }

  String buildStopCommand() {
    return buildCommand('STOP_SCAN');
  }

  void resetBuffer() {
    _incomingBuffer = '';
  }

  Future<void> dispose() async {
    await _readingController.close();
  }
}
