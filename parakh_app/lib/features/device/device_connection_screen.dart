import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/parakh_bluetooth_service.dart';
import '../../core/theme/parakh_colors.dart';

class DeviceConnectionScreen extends StatefulWidget {
  const DeviceConnectionScreen({required this.isHindi, super.key});

  final bool isHindi;

  @override
  State<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  final ParakhBluetoothService _bluetoothService =
      ParakhBluetoothService.instance;

  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isConnected = false;

  BtcDevice? _parakhDevice;
  String? _connectionError;

  String _text(String english, String hindi) {
    return widget.isHindi ? hindi : english;
  }

  @override
  void initState() {
    super.initState();
    _isConnected = _bluetoothService.isConnected;
  }

  Future<bool> _requestBluetoothPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    final scanStatus = statuses[Permission.bluetoothScan];
    final connectStatus = statuses[Permission.bluetoothConnect];

    final granted =
        scanStatus?.isGranted == true && connectStatus?.isGranted == true;

    if (granted) {
      return true;
    }

    final permanentlyDenied =
        scanStatus?.isPermanentlyDenied == true ||
        connectStatus?.isPermanentlyDenied == true;

    if (permanentlyDenied) {
      await openAppSettings();
    }

    if (mounted) {
      setState(() {
        _connectionError = _text(
          permanentlyDenied
              ? 'Allow Nearby devices permission from PARAKH app settings, then try again.'
              : 'Nearby devices permission is required to connect to PARAKH-01.',
          permanentlyDenied
              ? 'PARAKH ऐप सेटिंग से Nearby devices अनुमति दें, फिर दोबारा प्रयास करें।'
              : 'PARAKH-01 से कनेक्ट करने के लिए Nearby devices अनुमति आवश्यक है।',
        );
      });
    }

    return false;
  }

  Future<void> _scanForDevices() async {
    final permissionGranted = await _requestBluetoothPermissions();

    if (!permissionGranted) {
      return;
    }
    if (_isScanning || _isConnecting) return;

    setState(() {
      _isScanning = true;
      _parakhDevice = null;
      _connectionError = null;
      _isConnected = _bluetoothService.isConnected;
    });

    try {
      final devices = await _bluetoothService.getPairedParakhDevices();

      if (!mounted) return;

      setState(() {
        _isScanning = false;
        _parakhDevice = devices.isEmpty ? null : devices.first;

        if (devices.isEmpty) {
          _connectionError = _text(
            'PARAKH-01 was not found in paired devices. Pair it from Android Bluetooth settings first.',
            'पेयर किए गए डिवाइस में PARAKH-01 नहीं मिला। पहले इसे Android Bluetooth सेटिंग से पेयर करें।',
          );
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isScanning = false;
        _connectionError = error.toString();
      });
    }
  }

  Future<void> _connectDevice() async {
    final device = _parakhDevice;

    if (device == null || _isConnecting) return;

    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });

    try {
      await _bluetoothService.connect(device);

      if (!_bluetoothService.isConnected) {
        throw StateError(
          'The Bluetooth connection closed immediately after connecting.',
        );
      }

      if (!mounted) return;

      setState(() {
        _isConnecting = false;
        _isConnected = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'PARAKH-01 connected successfully.',
              'PARAKH-01 सफलतापूर्वक कनेक्ट हो गया।',
            ),
          ),
          backgroundColor: ParakhColors.forestGreen,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _connectionError = error.toString();
      });
    }
  }

  Future<void> _disconnectDevice() async {
    try {
      await _bluetoothService.disconnect();
    } catch (_) {
      // The connection may already be closed.
    }

    if (!mounted) return;

    setState(() {
      _isConnected = false;
      _connectionError = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text('PARAKH-01 disconnected.', 'PARAKH-01 डिस्कनेक्ट हो गया।'),
        ),
        backgroundColor: const Color(0xFF6F796F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F2),
        surfaceTintColor: Colors.transparent,
        title: Text(
          _text('Connect device', 'डिवाइस कनेक्ट करें'),
          style: const TextStyle(
            color: Color(0xFF1B2B21),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                _buildConnectionIllustration(),
                const SizedBox(height: 24),
                Text(
                  _text(
                    'Connect your Parakh device',
                    'अपने परख डिवाइस को कनेक्ट करें',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1B2B21),
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  _text(
                    'Pair PARAKH-01 in Android settings, then connect from this screen.',
                    'Android सेटिंग में PARAKH-01 को पेयर करें, फिर इस स्क्रीन से कनेक्ट करें।',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6F796F),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                _buildInstructionCard(),
                const SizedBox(height: 22),
                _buildScanButton(),
                const SizedBox(height: 18),
                if (_isScanning) _buildScanningCard(),
                if (_parakhDevice != null && !_isScanning) _buildDeviceCard(),
                if (_connectionError != null) ...[
                  const SizedBox(height: 14),
                  _buildErrorCard(),
                ],
                const SizedBox(height: 20),
                _buildOfflineNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionIllustration() {
    return Center(
      child: Container(
        width: 126,
        height: 126,
        decoration: const BoxDecoration(
          color: Color(0xFFE1EEE4),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.bluetooth_searching_rounded,
              color: ParakhColors.forestGreen,
              size: 62,
            ),
            Positioned(
              right: 13,
              bottom: 15,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _isConnected
                      ? const Color(0xFF49A465)
                      : const Color(0xFFF1C75B),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF5F7F2), width: 4),
                ),
                child: Icon(
                  _isConnected ? Icons.check_rounded : Icons.power_settings_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: Column(
        children: [
          _instructionRow(
            number: '1',
            text: _text(
              'Switch on the Parakh device.',
              'परख डिवाइस चालू करें।',
            ),
          ),
          const SizedBox(height: 16),
          _instructionRow(
            number: '2',
            text: _text(
              'Pair PARAKH-01 in Android Bluetooth settings.',
              'Android Bluetooth सेटिंग में PARAKH-01 को पेयर करें।',
            ),
          ),
          const SizedBox(height: 16),
          _instructionRow(
            number: '3',
            text: _text(
              'Close any Bluetooth Terminal app before connecting.',
              'कनेक्ट करने से पहले Bluetooth Terminal ऐप बंद करें।',
            ),
          ),
          const SizedBox(height: 16),
          _instructionRow(
            number: '4',
            text: _text(
              'Tap scan and connect to PARAKH-01.',
              'स्कैन दबाएँ और PARAKH-01 से कनेक्ट करें।',
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionRow({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFE1EEE4),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: ParakhColors.forestGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF344039),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: _isScanning || _isConnecting || _isConnected
            ? null
            : _scanForDevices,
        style: FilledButton.styleFrom(
          backgroundColor: ParakhColors.forestGreen,
          disabledBackgroundColor: const Color(0xFF9DB5A5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: Icon(
          _isScanning ? Icons.bluetooth_searching_rounded : Icons.radar_rounded,
        ),
        label: Text(
          _isScanning
              ? _text('Scanning...', 'स्कैन हो रहा है...')
              : _text('Find paired device', 'पेयर डिवाइस खोजें'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildScanningCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(
              color: ParakhColors.forestGreen,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _text(
                'Checking paired Bluetooth devices...',
                'पेयर किए गए Bluetooth डिवाइस खोजे जा रहे हैं...',
              ),
              style: const TextStyle(
                color: Color(0xFF344039),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard() {
    final device = _parakhDevice;

    if (device == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _isConnected
              ? const Color(0xFF72AF83)
              : const Color(0xFFE0E8DD),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE1EEE4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.developer_board_rounded,
              color: ParakhColors.forestGreen,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.displayName.isEmpty ? 'PARAKH-01' : device.displayName,
                  style: const TextStyle(
                    color: Color(0xFF26342B),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isConnected
                      ? _text('Connected', 'कनेक्टेड')
                      : _text('Paired and available', 'पेयर और उपलब्ध'),
                  style: TextStyle(
                    color: _isConnected
                        ? ParakhColors.forestGreen
                        : const Color(0xFF6F796F),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (_isConnecting)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: ParakhColors.forestGreen,
                strokeWidth: 3,
              ),
            )
          else
            OutlinedButton(
              onPressed: _isConnected ? _disconnectDevice : _connectDevice,
              style: OutlinedButton.styleFrom(
                foregroundColor: _isConnected
                    ? const Color(0xFFB45545)
                    : ParakhColors.forestGreen,
                side: BorderSide(
                  color: _isConnected
                      ? const Color(0xFFD9A49C)
                      : ParakhColors.forestGreen,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isConnected
                    ? _text('Disconnect', 'डिस्कनेक्ट')
                    : _text('Connect', 'कनेक्ट'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECE8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9B8AE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB75B4A),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _connectionError!,
              style: const TextStyle(
                color: Color(0xFF8C4035),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineNote() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E4),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF9A6815),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _text(
                'The HC-05 connection works offline. Wi-Fi is not required for a device scan.',
                'HC-05 कनेक्शन ऑफलाइन काम करता है। डिवाइस स्कैन के लिए Wi-Fi आवश्यक नहीं है।',
              ),
              style: const TextStyle(
                color: Color(0xFF795315),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
