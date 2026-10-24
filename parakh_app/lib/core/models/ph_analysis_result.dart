class PhAnalysisResult {
  const PhAnalysisResult({
    required this.id,
    required this.feedType,
    required this.estimatedPh,
    required this.imageSource,
    required this.analysisSource,
    required this.modelVersion,
    required this.calibrationChartVersion,
    required this.stripQuality,
    required this.samplePreparation,
    required this.createdAt,
    this.confidence,
    this.isValidated = false,
  });

  final String id;
  final String feedType;
  final double estimatedPh;
  final String imageSource;
  final String analysisSource;
  final String modelVersion;
  final String calibrationChartVersion;
  final String stripQuality;
  final String samplePreparation;
  final DateTime createdAt;
  final double? confidence;
  final bool isValidated;

  factory PhAnalysisResult.prototype({
    required String feedType,
    required String imageSource,
  }) {
    return PhAnalysisResult(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      feedType: feedType,
      estimatedPh: 4.3,
      imageSource: imageSource,
      analysisSource: 'simulated-prototype',
      modelVersion: 'ph-placeholder-v1',
      calibrationChartVersion: 'not-calibrated',
      stripQuality: 'not-verified',
      samplePreparation: 'not-recorded',
      createdAt: DateTime.now(),
      confidence: null,
      isValidated: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feedType': feedType,
      'estimatedPh': estimatedPh,
      'imageSource': imageSource,
      'analysisSource': analysisSource,
      'modelVersion': modelVersion,
      'calibrationChartVersion': calibrationChartVersion,
      'stripQuality': stripQuality,
      'samplePreparation': samplePreparation,
      'createdAt': createdAt.toIso8601String(),
      'confidence': confidence,
      'isValidated': isValidated,
    };
  }

  factory PhAnalysisResult.fromJson(Map<String, dynamic> json) {
    return PhAnalysisResult(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      feedType: json['feedType']?.toString() ?? 'Unknown feed',
      estimatedPh: _readDouble(json['estimatedPh']) ?? 0,
      imageSource: json['imageSource']?.toString() ?? 'unknown',
      analysisSource: json['analysisSource']?.toString() ?? 'unknown',
      modelVersion: json['modelVersion']?.toString() ?? 'unknown',
      calibrationChartVersion:
          json['calibrationChartVersion']?.toString() ?? 'not-calibrated',
      stripQuality: json['stripQuality']?.toString() ?? 'not-verified',
      samplePreparation:
          json['samplePreparation']?.toString() ?? 'not-recorded',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      confidence: _readDouble(json['confidence']),
      isValidated: json['isValidated'] as bool? ?? false,
    );
  }

  static double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());

    return null;
  }
}
