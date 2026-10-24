class DeviceReading {
  const DeviceReading({
    required this.device,
    required this.sampleId,
    required this.feedType,
    required this.moisture,
    required this.protein,
    required this.fiber,
    required this.fat,
    required this.ash,
    required this.ph,
    required this.temperature,
    required this.status,
    required this.receivedAt,
    this.spectralChannels = const {},
    this.firmwareVersion = 'unknown',
    this.scanSource = 'device',
    this.scanQuality = 'unknown',
    this.integrationTimeMs,
    this.sensorGain,
    this.calibrationVersion = 'unvalidated',
  });

  final String device;
  final String sampleId;
  final String feedType;

  final double moisture;
  final double protein;
  final double fiber;
  final double fat;
  final double ash;
  final double ph;
  final double temperature;

  final String status;
  final DateTime receivedAt;
  final Map<String, double> spectralChannels;
  final String firmwareVersion;
  final String scanSource;
  final String scanQuality;
  final int? integrationTimeMs;
  final double? sensorGain;
  final String calibrationVersion;

  bool get isSimulated => scanSource == 'simulated' || status == 'simulated';
  bool get hasSpectralData => spectralChannels.isNotEmpty;
  bool get isComplete {
    final normalizedStatus = status.toLowerCase();
    return normalizedStatus == 'complete' || normalizedStatus == 'simulated';
  }

  factory DeviceReading.fromJson(Map<String, dynamic> json) {
    return DeviceReading(
      device: _readString(json, 'device', fallback: 'PARAKH-01'),
      sampleId: _readString(json, 'sampleId', fallback: 'Unknown'),
      feedType: _readString(json, 'feedType', fallback: 'Unknown feed'),
      moisture: _readDouble(json, 'moisture'),
      protein: _readDouble(json, 'protein'),
      fiber: _readDouble(json, 'fiber'),
      fat: _readDouble(json, 'fat'),
      ash: _readDouble(json, 'ash'),
      ph: _readDouble(json, 'ph'),
      temperature: _readDouble(json, 'temperature'),
      status: _readString(json, 'status', fallback: 'complete'),
      receivedAt: _readDateTime(json, 'receivedAt'),
      spectralChannels: _readSpectralChannels(json, 'spectralChannels'),
      firmwareVersion: _readString(
        json,
        'firmwareVersion',
        fallback: 'unknown',
      ),
      scanSource: _readString(json, 'scanSource', fallback: 'device'),
      scanQuality: _readString(json, 'scanQuality', fallback: 'unknown'),
      integrationTimeMs: _readNullableInt(json, 'integrationTimeMs'),
      sensorGain: _readNullableDouble(json, 'sensorGain'),
      calibrationVersion: _readString(
        json,
        'calibrationVersion',
        fallback: 'unvalidated',
      ),
    );
  }
  factory DeviceReading.demo({
    String sampleId = 'S001',
    String feedType = 'Maize Silage',
  }) {
    final ({
      double moisture,
      double protein,
      double fiber,
      double fat,
      double ash,
      double ph,
      double temperature,
    })
    values = switch (feedType) {
      'Wheat Straw' => (
        moisture: 11.2,
        protein: 4.5,
        fiber: 38.0,
        fat: 1.8,
        ash: 8.4,
        ph: 6.8,
        temperature: 27.0,
      ),
      'Green Fodder' => (
        moisture: 78.0,
        protein: 13.2,
        fiber: 28.0,
        fat: 2.7,
        ash: 9.0,
        ph: 6.3,
        temperature: 26.5,
      ),
      'Concentrate Feed' => (
        moisture: 10.8,
        protein: 19.0,
        fiber: 13.5,
        fat: 4.2,
        ash: 7.8,
        ph: 6.5,
        temperature: 27.2,
      ),
      'Cattle Feed Pellets' => (
        moisture: 10.5,
        protein: 18.5,
        fiber: 12.0,
        fat: 4.0,
        ash: 7.5,
        ph: 6.4,
        temperature: 27.0,
      ),
      _ => (
        moisture: 66.0,
        protein: 8.5,
        fiber: 25.0,
        fat: 3.2,
        ash: 6.5,
        ph: 4.2,
        temperature: 27.5,
      ),
    };

    return DeviceReading(
      device: 'PARAKH-DEMO',
      sampleId: sampleId,
      feedType: feedType,
      moisture: values.moisture,
      protein: values.protein,
      fiber: values.fiber,
      fat: values.fat,
      ash: values.ash,
      ph: values.ph,
      temperature: values.temperature,
      status: 'simulated',
      receivedAt: DateTime.now(),
      spectralChannels: const {},
      firmwareVersion: 'demo-1.0',
      scanSource: 'simulated',
      scanQuality: 'demo',
      integrationTimeMs: null,
      sensorGain: null,
      calibrationVersion: 'prototype-rules-v1',
    );
  }
  DeviceReading withNutrientPrediction({
    required double protein,
    required double fiber,
    required double fat,
    required String calibrationVersion,
  }) {
    return DeviceReading(
      device: device,
      sampleId: sampleId,
      feedType: feedType,
      moisture: moisture,
      protein: protein,
      fiber: fiber,
      fat: fat,
      ash: ash,
      ph: ph,
      temperature: temperature,
      status: status,
      receivedAt: receivedAt,
      spectralChannels: spectralChannels,
      firmwareVersion: firmwareVersion,
      scanSource: scanSource,
      scanQuality: scanQuality,
      integrationTimeMs: integrationTimeMs,
      sensorGain: sensorGain,
      calibrationVersion: calibrationVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': device,
      'sampleId': sampleId,
      'feedType': feedType,
      'moisture': moisture,
      'protein': protein,
      'fiber': fiber,
      'fat': fat,
      'ash': ash,
      'ph': ph,
      'temperature': temperature,
      'status': status,
      'receivedAt': receivedAt.toIso8601String(),
      'spectralChannels': spectralChannels,
      'firmwareVersion': firmwareVersion,
      'scanSource': scanSource,
      'scanQuality': scanQuality,
      'integrationTimeMs': integrationTimeMs,
      'sensorGain': sensorGain,
      'calibrationVersion': calibrationVersion,
    };
  }

  static String _readString(
    Map<String, dynamic> json,
    String key, {
    required String fallback,
  }) {
    final value = json[key];

    if (value == null) {
      return fallback;
    }

    final convertedValue = value.toString().trim();

    return convertedValue.isEmpty ? fallback : convertedValue;
  }

  static double _readDouble(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim()) ?? 0;
    }

    return 0;
  }

  static Map<String, double> _readSpectralChannels(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];

    if (value is! Map) {
      return const {};
    }

    final channels = <String, double>{};

    value.forEach((channel, reading) {
      if (reading is num) {
        channels[channel.toString()] = reading.toDouble();
      } else if (reading is String) {
        final converted = double.tryParse(reading.trim());

        if (converted != null) {
          channels[channel.toString()] = converted;
        }
      }
    });

    return channels;
  }

  static int? _readNullableInt(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());

    return null;
  }

  static double? _readNullableDouble(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());

    return null;
  }

  static DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }
}
