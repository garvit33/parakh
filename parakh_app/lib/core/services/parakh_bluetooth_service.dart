import 'dart:async';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:flutter/foundation.dart';

import '../models/device_reading.dart';
import 'device_data_service.dart';

class ParakhBluetoothService {
  ParakhBluetoothService._();

  static final ParakhBluetoothService instance = ParakhBluetoothService._();

  final FlutterClassicBluetooth _bluetooth = FlutterClassicBluetooth();
  final DeviceDataService _deviceDataService = DeviceDataService();

  BtcConnection? _connection;
  StreamSubscription<String>? _lineSubscription;

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionChanges => _connectionController.stream;

  Stream<DeviceReading> get readings => _deviceDataService.readings;

  bool get isConnected => _connection?.isConnected ?? false;

  Future<List<BtcDevice>> getPairedParakhDevices() async {
    if (!await _bluetooth.isSupported()) {
      throw StateError('Bluetooth Classic is not supported on this phone.');
    }

    if (!await _bluetooth.isEnabled()) {
      throw StateError('Turn on Bluetooth before connecting.');
    }

    final devices = await _bluetooth.getPairedDevices();

    return devices.where((device) {
      return device.displayName.trim().toUpperCase().startsWith('PARAKH');
    }).toList();
  }

  Future<void> connect(BtcDevice device) async {
    await disconnect();

    final connection = await _bluetooth.connect(
      address: device.address,
      uuid: BtcUuid.spp,
      secure: true,
      timeout: const Duration(seconds: 15),
    );

    _connection = connection;

    _lineSubscription = connection.input.lines().listen(
      (line) {
        final message = line.trim();

        if (message.isEmpty) return;

        _deviceDataService.processIncomingChunk('$message\n');
      },
      onError: (Object error) {
  debugPrint('PARAKH Bluetooth input error: $error');
  _markDisconnected();
},
onDone: () {
  debugPrint('PARAKH Bluetooth input stream closed.');
  _markDisconnected();
},
    );

    _connectionController.add(true);
  }

  Future<void> sendCommand(String command) async {
    final connection = _connection;

    if (connection == null || !connection.isConnected) {
      throw StateError('PARAKH-01 is not connected.');
    }

    await connection.output.writeLine(command);
    await connection.output.allSent;
  }

  Future<void> requestStatus() {
    return sendCommand('GET_STATUS');
  }

  Future<void> startScan({required String sampleId, required String feedType}) {
    return sendCommand(
      '{"command":"START_SCAN",'
      '"sampleId":"$sampleId",'
      '"feedType":"$feedType"}',
    );
  }

  Future<void> stopScan() {
    return sendCommand('STOP_SCAN');
  }

  Future<void> disconnect() async {
    await _lineSubscription?.cancel();
    _lineSubscription = null;

    final connection = _connection;
    _connection = null;

    if (connection != null) {
      try {
        await connection.finish();
      } catch (_) {
        try {
          await connection.close();
        } catch (_) {
          // The connection may already be closed.
        }
      } finally {
        connection.dispose();
      }
    }

    _deviceDataService.resetBuffer();
    _connectionController.add(false);
  }

  void _markDisconnected() {
    _connection = null;
    _deviceDataService.resetBuffer();
    _connectionController.add(false);
  }
}
