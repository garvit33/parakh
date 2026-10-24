class FeedTestResult {
  const FeedTestResult({
    required this.id,
    required this.feedType,
    required this.testType,
    required this.score,
    required this.riskLevel,
    required this.phValue,
    required this.nutritionStatus,
    required this.impurityStatus,
    required this.recommendationEnglish,
    required this.recommendationHindi,
    required this.createdAt,
    this.sampleId = 'Not provided',
    this.batchId = 'Not provided',
    this.animalType = 'Not provided',
    this.animalBreed = 'Not provided',
    this.productionGoal = 'Not provided',
    this.dataSource = 'unknown',
    this.deviceId = 'unknown',
    this.firmwareVersion = 'unknown',
    this.calibrationVersion = 'unvalidated',
    this.moisture,
    this.protein,
    this.fiber,
    this.fat,
    this.ash,
    this.isLaboratoryValidated = false,
    this.disclaimerEnglish =
        'Screening guidance only. This is not a laboratory-certified result.',
    this.disclaimerHindi = 'यह केवल स्क्रीनिंग मार्गदर्शन है। यह प्रयोगशाला-प्रमाणित परिणाम नहीं है।',
  });

  final String id;
  final String feedType;
  final String testType;
  final int score;
  final String riskLevel;
  final double phValue;
  final String nutritionStatus;
  final String impurityStatus;
  final String recommendationEnglish;
  final String recommendationHindi;
  final DateTime createdAt;
  final String sampleId;
  final String batchId;
  final String animalType;
  final String animalBreed;
  final String productionGoal;

  final String dataSource;
  final String deviceId;
  final String firmwareVersion;
  final String calibrationVersion;

  final double? moisture;
  final double? protein;
  final double? fiber;
  final double? fat;
  final double? ash;

  final bool isLaboratoryValidated;
  final String disclaimerEnglish;
  final String disclaimerHindi;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feedType': feedType,
      'testType': testType,
      'score': score,
      'riskLevel': riskLevel,
      'phValue': phValue,
      'nutritionStatus': nutritionStatus,
      'impurityStatus': impurityStatus,
      'recommendationEnglish': recommendationEnglish,
      'recommendationHindi': recommendationHindi,
      'createdAt': createdAt.toIso8601String(),

      'sampleId': sampleId,
      'batchId': batchId,
      'animalType': animalType,
      'animalBreed': animalBreed,
      'productionGoal': productionGoal,
      'dataSource': dataSource,
      'deviceId': deviceId,
      'firmwareVersion': firmwareVersion,
      'calibrationVersion': calibrationVersion,
      'moisture': moisture,
      'protein': protein,
      'fiber': fiber,
      'fat': fat,
      'ash': ash,
      'isLaboratoryValidated': isLaboratoryValidated,
      'disclaimerEnglish': disclaimerEnglish,
      'disclaimerHindi': disclaimerHindi,
    };
  }

  factory FeedTestResult.fromJson(Map<String, dynamic> json) {
    return FeedTestResult(
      id: _readString(
        json,
        'id',
        fallback: DateTime.now().microsecondsSinceEpoch.toString(),
      ),
      feedType: _readString(json, 'feedType', fallback: 'Unknown feed'),
      testType: _readString(json, 'testType', fallback: 'Feed Test'),
      score: _readInt(json, 'score'),
      riskLevel: _readString(json, 'riskLevel', fallback: 'UNKNOWN'),
      phValue: _readDouble(json, 'phValue') ?? 0,
      nutritionStatus: _readString(
        json,
        'nutritionStatus',
        fallback: 'Not available',
      ),
      impurityStatus: _readString(
        json,
        'impurityStatus',
        fallback: 'Not available',
      ),
      recommendationEnglish: _readString(
        json,
        'recommendationEnglish',
        fallback: 'No recommendation available.',
      ),
      recommendationHindi: _readString(
        json,
        'recommendationHindi',
        fallback: 'कोई सुझाव उपलब्ध नहीं है।',
      ),
      createdAt: _readDateTime(json, 'createdAt'),
      sampleId: _readString(json, 'sampleId', fallback: 'Not provided'),
      batchId: _readString(json, 'batchId', fallback: 'Not provided'),
      animalType: _readString(json, 'animalType', fallback: 'Not provided'),
      animalBreed: _readString(json, 'animalBreed', fallback: 'Not provided'),
      productionGoal: _readString(
        json,
        'productionGoal',
        fallback: 'Not provided',
      ),
      dataSource: _readString(json, 'dataSource', fallback: 'unknown'),
      deviceId: _readString(json, 'deviceId', fallback: 'unknown'),
      firmwareVersion: _readString(
        json,
        'firmwareVersion',
        fallback: 'unknown',
      ),
      calibrationVersion: _readString(
        json,
        'calibrationVersion',
        fallback: 'unvalidated',
      ),
      moisture: _readDouble(json, 'moisture'),
      protein: _readDouble(json, 'protein'),
      fiber: _readDouble(json, 'fiber'),
      fat: _readDouble(json, 'fat'),
      ash: _readDouble(json, 'ash'),
      isLaboratoryValidated: json['isLaboratoryValidated'] as bool? ?? false,
      disclaimerEnglish: _readString(
        json,
        'disclaimerEnglish',
        fallback: 'Screening guidance only. This is not a laboratory-certified result.',
      ),
      disclaimerHindi: _readString(
        json,
        'disclaimerHindi',
        fallback: 'यह केवल स्क्रीनिंग मार्गदर्शन है। यह प्रयोगशाला-प्रमाणित परिणाम नहीं है।',
      ),
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    String key, {
    required String fallback,
  }) {
    final value = json[key]?.toString().trim();

    if (value == null || value.isEmpty) {
      return fallback;
    }

    return value;
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;

    return 0;
  }

  static double? _readDouble(Map<String, dynamic> json, String key) {
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
