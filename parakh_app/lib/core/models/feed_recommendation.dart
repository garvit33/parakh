class FeedRecommendation {
  const FeedRecommendation({
    required this.id,
    required this.testResultId,
    required this.priority,
    required this.summaryEnglish,
    required this.summaryHindi,
    required this.actionsEnglish,
    required this.actionsHindi,
    required this.warningsEnglish,
    required this.warningsHindi,
    required this.recommendationSource,
    required this.modelVersion,
    required this.createdAt,
    this.isValidated = false,
  });

  final String id;
  final String testResultId;
  final String priority;

  final String summaryEnglish;
  final String summaryHindi;

  final List<String> actionsEnglish;
  final List<String> actionsHindi;

  final List<String> warningsEnglish;
  final List<String> warningsHindi;

  final String recommendationSource;
  final String modelVersion;
  final DateTime createdAt;
  final bool isValidated;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testResultId': testResultId,
      'priority': priority,
      'summaryEnglish': summaryEnglish,
      'summaryHindi': summaryHindi,
      'actionsEnglish': actionsEnglish,
      'actionsHindi': actionsHindi,
      'warningsEnglish': warningsEnglish,
      'warningsHindi': warningsHindi,
      'recommendationSource': recommendationSource,
      'modelVersion': modelVersion,
      'createdAt': createdAt.toIso8601String(),
      'isValidated': isValidated,
    };
  }

  factory FeedRecommendation.fromJson(Map<String, dynamic> json) {
    return FeedRecommendation(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      testResultId: json['testResultId']?.toString() ?? 'unknown',
      priority: json['priority']?.toString() ?? 'review',
      summaryEnglish:
          json['summaryEnglish']?.toString() ?? 'No recommendation available.',
      summaryHindi:
          json['summaryHindi']?.toString() ?? 'कोई सुझाव उपलब्ध नहीं है।',
      actionsEnglish: _readStringList(json['actionsEnglish']),
      actionsHindi: _readStringList(json['actionsHindi']),
      warningsEnglish: _readStringList(json['warningsEnglish']),
      warningsHindi: _readStringList(json['warningsHindi']),
      recommendationSource:
          json['recommendationSource']?.toString() ?? 'unknown',
      modelVersion: json['modelVersion']?.toString() ?? 'unknown',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isValidated: json['isValidated'] as bool? ?? false,
    );
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
