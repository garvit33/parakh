import 'camera_analysis_result.dart';
import 'device_reading.dart';
import 'ph_analysis_result.dart';

class CompleteTestEvidence {
  const CompleteTestEvidence({
    required this.id,
    required this.nirReading,
    required this.cameraResult,
    required this.phResult,
    required this.createdAt,
  });

  final String id;
  final DeviceReading nirReading;
  final CameraAnalysisResult cameraResult;
  final PhAnalysisResult phResult;
  final DateTime createdAt;

  bool get isFullyValidated {
    return cameraResult.isValidated &&
        phResult.isValidated &&
        nirReading.scanSource != 'simulated-prototype';
  }

  bool get usesSimulatedData {
    return nirReading.scanSource == 'simulated-prototype' ||
        cameraResult.analysisSource == 'simulated-prototype' ||
        phResult.analysisSource == 'simulated-prototype';
  }

  factory CompleteTestEvidence.prototype({
    required String sampleId,
    required String feedType,
  }) {
    final createdAt = DateTime.now();

    return CompleteTestEvidence(
      id: createdAt.microsecondsSinceEpoch.toString(),
      nirReading: DeviceReading.demo(sampleId: sampleId, feedType: feedType),
      cameraResult: CameraAnalysisResult.prototype(imageSource: 'not-captured'),
      phResult: PhAnalysisResult.prototype(
        feedType: feedType,
        imageSource: 'not-captured',
      ),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nirReading': nirReading.toJson(),
      'cameraResult': cameraResult.toJson(),
      'phResult': phResult.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'isFullyValidated': isFullyValidated,
      'usesSimulatedData': usesSimulatedData,
    };
  }

  factory CompleteTestEvidence.fromJson(Map<String, dynamic> json) {
    final nirJson = json['nirReading'];
    final cameraJson = json['cameraResult'];
    final phJson = json['phResult'];

    return CompleteTestEvidence(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      nirReading: DeviceReading.fromJson(
        nirJson is Map
            ? Map<String, dynamic>.from(nirJson)
            : <String, dynamic>{},
      ),
      cameraResult: CameraAnalysisResult.fromJson(
        cameraJson is Map
            ? Map<String, dynamic>.from(cameraJson)
            : <String, dynamic>{},
      ),
      phResult: PhAnalysisResult.fromJson(
        phJson is Map ? Map<String, dynamic>.from(phJson) : <String, dynamic>{},
      ),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
