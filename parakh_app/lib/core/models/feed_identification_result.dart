class FeedPrediction {
  const FeedPrediction({required this.feedType, required this.confidence});

  final String feedType;
  final double confidence;

  Map<String, dynamic> toJson() {
    return {'feedType': feedType, 'confidence': confidence};
  }

  factory FeedPrediction.fromJson(Map<String, dynamic> json) {
    return FeedPrediction(
      feedType: json['feedType']?.toString() ?? 'Unknown',
      confidence: _readDouble(json['confidence']) ?? 0,
    );
  }

  static double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());

    return null;
  }
}

class FeedIdentificationResult {
  const FeedIdentificationResult({
    required this.id,
    required this.imageSource,
    required this.analysisSource,
    required this.modelVersion,
    required this.imageQuality,
    required this.predictions,
    required this.createdAt,
    required this.isValidated,
    required this.requiresFarmerConfirmation,
  });

  final String id;
  final String imageSource;
  final String analysisSource;
  final String modelVersion;
  final String imageQuality;
  final List<FeedPrediction> predictions;
  final DateTime createdAt;
  final bool isValidated;
  final bool requiresFarmerConfirmation;

  FeedPrediction? get bestPrediction {
    if (predictions.isEmpty) return null;

    final sortedPredictions = [...predictions]
      ..sort((first, second) => second.confidence.compareTo(first.confidence));

    return sortedPredictions.first;
  }

  bool get hasUsablePrediction {
    final prediction = bestPrediction;

    return prediction != null &&
        prediction.confidence >= 0.60 &&
        imageQuality == 'acceptable';
  }

  factory FeedIdentificationResult.modelNotConnected({
    required String imageSource,
  }) {
    return FeedIdentificationResult(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imageSource: imageSource,
      analysisSource: 'model-not-connected',
      modelVersion: 'not-installed',
      imageQuality: 'not-verified',
      predictions: const [],
      createdAt: DateTime.now(),
      isValidated: false,
      requiresFarmerConfirmation: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageSource': imageSource,
      'analysisSource': analysisSource,
      'modelVersion': modelVersion,
      'imageQuality': imageQuality,
      'predictions': predictions
          .map((prediction) => prediction.toJson())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'isValidated': isValidated,
      'requiresFarmerConfirmation': requiresFarmerConfirmation,
    };
  }

  factory FeedIdentificationResult.fromJson(Map<String, dynamic> json) {
    final rawPredictions = json['predictions'];

    return FeedIdentificationResult(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      imageSource: json['imageSource']?.toString() ?? 'unknown',
      analysisSource: json['analysisSource']?.toString() ?? 'unknown',
      modelVersion: json['modelVersion']?.toString() ?? 'unknown',
      imageQuality: json['imageQuality']?.toString() ?? 'unknown',
      predictions: rawPredictions is List
          ? rawPredictions
                .whereType<Map>()
                .map(
                  (prediction) => FeedPrediction.fromJson(
                    Map<String, dynamic>.from(prediction),
                  ),
                )
                .toList()
          : const [],
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isValidated: json['isValidated'] as bool? ?? false,
      requiresFarmerConfirmation:
          json['requiresFarmerConfirmation'] as bool? ?? true,
    );
  }
}
