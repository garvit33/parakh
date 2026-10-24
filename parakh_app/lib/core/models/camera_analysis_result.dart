class CameraFinding {
  const CameraFinding({
    required this.category,
    required this.level,
    this.confidence,
  });

  final String category;
  final String level;
  final double? confidence;

  Map<String, dynamic> toJson() {
    return {'category': category, 'level': level, 'confidence': confidence};
  }

  factory CameraFinding.fromJson(Map<String, dynamic> json) {
    return CameraFinding(
      category: json['category']?.toString() ?? 'unknown',
      level: json['level']?.toString() ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

class CameraAnalysisResult {
  const CameraAnalysisResult({
    required this.id,
    required this.imageSource,
    required this.analysisSource,
    required this.modelVersion,
    required this.imageQuality,
    required this.findings,
    required this.createdAt,
    this.overallConfidence,
    this.isValidated = false,
  });

  final String id;
  final String imageSource;
  final String analysisSource;
  final String modelVersion;
  final String imageQuality;
  final List<CameraFinding> findings;
  final DateTime createdAt;
  final double? overallConfidence;
  final bool isValidated;

  factory CameraAnalysisResult.prototype({required String imageSource}) {
    return CameraAnalysisResult(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imageSource: imageSource,
      analysisSource: 'simulated-prototype',
      modelVersion: 'camera-rules-v1',
      imageQuality: 'not-verified',
      overallConfidence: null,
      isValidated: false,
      createdAt: DateTime.now(),
      findings: const [
        CameraFinding(category: 'sand_or_soil', level: 'possible'),
        CameraFinding(category: 'stones', level: 'not_detected'),
        CameraFinding(category: 'mould', level: 'not_detected'),
        CameraFinding(category: 'foreign_material', level: 'low'),
      ],
    );
  }

  CameraFinding? findingFor(String category) {
    for (final finding in findings) {
      if (finding.category == category) {
        return finding;
      }
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageSource': imageSource,
      'analysisSource': analysisSource,
      'modelVersion': modelVersion,
      'imageQuality': imageQuality,
      'findings': findings.map((finding) => finding.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'overallConfidence': overallConfidence,
      'isValidated': isValidated,
    };
  }

  factory CameraAnalysisResult.fromJson(Map<String, dynamic> json) {
    final rawFindings = json['findings'];

    return CameraAnalysisResult(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      imageSource: json['imageSource']?.toString() ?? 'unknown',
      analysisSource: json['analysisSource']?.toString() ?? 'unknown',
      modelVersion: json['modelVersion']?.toString() ?? 'unknown',
      imageQuality: json['imageQuality']?.toString() ?? 'unknown',
      findings: rawFindings is List
          ? rawFindings
                .whereType<Map>()
                .map(
                  (finding) => CameraFinding.fromJson(
                    Map<String, dynamic>.from(finding),
                  ),
                )
                .toList()
          : const [],
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      overallConfidence: (json['overallConfidence'] as num?)?.toDouble(),
      isValidated: json['isValidated'] as bool? ?? false,
    );
  }
}
