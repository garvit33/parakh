import 'device_reading.dart';

class NutritionValues {
  const NutritionValues({
    required this.moisture,
    required this.protein,
    required this.fiber,
    required this.fat,
    required this.ash,
  });

  final double moisture;
  final double protein;
  final double fiber;
  final double fat;
  final double ash;

  factory NutritionValues.fromReading(DeviceReading reading) {
    return NutritionValues(
      moisture: reading.moisture,
      protein: reading.protein,
      fiber: reading.fiber,
      fat: reading.fat,
      ash: reading.ash,
    );
  }

  factory NutritionValues.fromJson(Map<String, dynamic> json) {
    return NutritionValues(
      moisture: _readDouble(json['moisture']),
      protein: _readDouble(json['protein']),
      fiber: _readDouble(json['fiber']),
      fat: _readDouble(json['fat']),
      ash: _readDouble(json['ash']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moisture': moisture,
      'protein': protein,
      'fiber': fiber,
      'fat': fat,
      'ash': ash,
    };
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CalibrationRecord {
  const CalibrationRecord({
    required this.id,
    required this.reading,
    required this.calibrationVersion,
    required this.status,
    required this.createdAt,
    this.referenceValues,
    this.laboratoryName,
    this.validatedAt,
    this.notes,
  });

  static const String pendingStatus = 'pending';
  static const String validatedStatus = 'validated';
  static const String rejectedStatus = 'rejected';

  final String id;
  final DeviceReading reading;
  final NutritionValues? referenceValues;
  final String calibrationVersion;
  final String status;
  final String? laboratoryName;
  final DateTime createdAt;
  final DateTime? validatedAt;
  final String? notes;

  bool get isValidated {
    return status == validatedStatus && referenceValues != null;
  }

  NutritionValues get predictedValues {
    return NutritionValues.fromReading(reading);
  }

  Map<String, double> get absoluteErrors {
    final reference = referenceValues;

    if (reference == null) return {};

    final predicted = predictedValues;

    return {
      'moisture': (predicted.moisture - reference.moisture).abs(),
      'protein': (predicted.protein - reference.protein).abs(),
      'fiber': (predicted.fiber - reference.fiber).abs(),
      'fat': (predicted.fat - reference.fat).abs(),
      'ash': (predicted.ash - reference.ash).abs(),
    };
  }

  Map<String, double> get percentageErrors {
    final reference = referenceValues;

    if (reference == null) return {};

    final errors = absoluteErrors;

    return {
      'moisture': _percentageError(errors['moisture']!, reference.moisture),
      'protein': _percentageError(errors['protein']!, reference.protein),
      'fiber': _percentageError(errors['fiber']!, reference.fiber),
      'fat': _percentageError(errors['fat']!, reference.fat),
      'ash': _percentageError(errors['ash']!, reference.ash),
    };
  }

  factory CalibrationRecord.pending({
    required String id,
    required DeviceReading reading,
    required String calibrationVersion,
  }) {
    return CalibrationRecord(
      id: id,
      reading: reading,
      calibrationVersion: calibrationVersion,
      status: pendingStatus,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reading': reading.toJson(),
      'referenceValues': referenceValues?.toJson(),
      'calibrationVersion': calibrationVersion,
      'status': status,
      'laboratoryName': laboratoryName,
      'createdAt': createdAt.toIso8601String(),
      'validatedAt': validatedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory CalibrationRecord.fromJson(Map<String, dynamic> json) {
    final referenceJson = json['referenceValues'];

    return CalibrationRecord(
      id: json['id']?.toString() ?? '',
      reading: DeviceReading.fromJson(
        Map<String, dynamic>.from(json['reading'] as Map),
      ),
      referenceValues: referenceJson is Map
          ? NutritionValues.fromJson(Map<String, dynamic>.from(referenceJson))
          : null,
      calibrationVersion:
          json['calibrationVersion']?.toString() ?? 'prototype-v1',
      status: json['status']?.toString() ?? pendingStatus,
      laboratoryName: json['laboratoryName']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      validatedAt: DateTime.tryParse(json['validatedAt']?.toString() ?? ''),
      notes: json['notes']?.toString(),
    );
  }

  static double _percentageError(double absoluteError, double referenceValue) {
    if (referenceValue == 0) return 0;
    return (absoluteError / referenceValue.abs()) * 100;
  }
}
