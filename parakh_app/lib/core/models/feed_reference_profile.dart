class MetricReferenceBand {
  const MetricReferenceBand({
    required this.goodMin,
    required this.goodMax,
    required this.cautionMin,
    required this.cautionMax,
  });

  final double goodMin;
  final double goodMax;
  final double cautionMin;
  final double cautionMax;

  int riskLevel(double value) {
    if (value >= goodMin && value <= goodMax) return 0;
    if (value >= cautionMin && value <= cautionMax) return 1;
    return 2;
  }
}

class FeedReferenceProfile {
  const FeedReferenceProfile({
    required this.feedType,
    required this.referenceLabel,
    required this.moisture,
    required this.protein,
    required this.fiber,
    required this.fat,
    required this.ash,
  });

  final String feedType;
  final String referenceLabel;
  final MetricReferenceBand moisture;
  final MetricReferenceBand protein;
  final MetricReferenceBand fiber;
  final MetricReferenceBand fat;
  final MetricReferenceBand ash;

  static FeedReferenceProfile? forFeed(String feedType) {
    return switch (feedType) {
      'Maize Silage' => maizeSilage,
      'Wheat Straw' => wheatStraw,
      'Green Fodder' => greenFodder,
      'Concentrate Feed' => concentrateFeed,
      'Cattle Feed Pellets' => cattleFeedPellets,
      _ => null,
    };
  }

  static const maizeSilage = FeedReferenceProfile(
    feedType: 'Maize Silage',
    referenceLabel: 'Prototype silage screening bands',
    moisture: MetricReferenceBand(
      goodMin: 60,
      goodMax: 72,
      cautionMin: 55,
      cautionMax: 75,
    ),
    protein: MetricReferenceBand(
      goodMin: 7,
      goodMax: 10,
      cautionMin: 5,
      cautionMax: 12,
    ),
    fiber: MetricReferenceBand(
      goodMin: 20,
      goodMax: 30,
      cautionMin: 15,
      cautionMax: 35,
    ),
    fat: MetricReferenceBand(
      goodMin: 2,
      goodMax: 5,
      cautionMin: 1,
      cautionMax: 6,
    ),
    ash: MetricReferenceBand(
      goodMin: 4,
      goodMax: 8,
      cautionMin: 3,
      cautionMax: 10,
    ),
  );

  static const wheatStraw = FeedReferenceProfile(
    feedType: 'Wheat Straw',
    referenceLabel: 'Prototype dry-fodder screening bands',
    moisture: MetricReferenceBand(
      goodMin: 8,
      goodMax: 14,
      cautionMin: 5,
      cautionMax: 18,
    ),
    protein: MetricReferenceBand(
      goodMin: 3,
      goodMax: 6,
      cautionMin: 2,
      cautionMax: 8,
    ),
    fiber: MetricReferenceBand(
      goodMin: 30,
      goodMax: 45,
      cautionMin: 25,
      cautionMax: 50,
    ),
    fat: MetricReferenceBand(
      goodMin: 1,
      goodMax: 3,
      cautionMin: 0.5,
      cautionMax: 4,
    ),
    ash: MetricReferenceBand(
      goodMin: 5,
      goodMax: 12,
      cautionMin: 3,
      cautionMax: 15,
    ),
  );

  static const greenFodder = FeedReferenceProfile(
    feedType: 'Green Fodder',
    referenceLabel: 'Prototype green-fodder screening bands',
    moisture: MetricReferenceBand(
      goodMin: 70,
      goodMax: 85,
      cautionMin: 60,
      cautionMax: 90,
    ),
    protein: MetricReferenceBand(
      goodMin: 8,
      goodMax: 18,
      cautionMin: 5,
      cautionMax: 22,
    ),
    fiber: MetricReferenceBand(
      goodMin: 20,
      goodMax: 35,
      cautionMin: 15,
      cautionMax: 40,
    ),
    fat: MetricReferenceBand(
      goodMin: 1,
      goodMax: 5,
      cautionMin: 0.5,
      cautionMax: 7,
    ),
    ash: MetricReferenceBand(
      goodMin: 5,
      goodMax: 15,
      cautionMin: 3,
      cautionMax: 18,
    ),
  );

  static const concentrateFeed = FeedReferenceProfile(
    feedType: 'Concentrate Feed',
    referenceLabel: 'Prototype concentrate-feed screening bands',
    moisture: MetricReferenceBand(
      goodMin: 8,
      goodMax: 13,
      cautionMin: 5,
      cautionMax: 15,
    ),
    protein: MetricReferenceBand(
      goodMin: 16,
      goodMax: 22,
      cautionMin: 12,
      cautionMax: 25,
    ),
    fiber: MetricReferenceBand(
      goodMin: 8,
      goodMax: 18,
      cautionMin: 5,
      cautionMax: 22,
    ),
    fat: MetricReferenceBand(
      goodMin: 2,
      goodMax: 6,
      cautionMin: 1,
      cautionMax: 8,
    ),
    ash: MetricReferenceBand(
      goodMin: 5,
      goodMax: 10,
      cautionMin: 3,
      cautionMax: 12,
    ),
  );
  static const cattleFeedPellets = FeedReferenceProfile(
    feedType: 'Cattle Feed Pellets',
    referenceLabel: 'Prototype compound-pellet screening bands',
    moisture: MetricReferenceBand(
      goodMin: 8,
      goodMax: 13,
      cautionMin: 5,
      cautionMax: 15,
    ),
    protein: MetricReferenceBand(
      goodMin: 16,
      goodMax: 22,
      cautionMin: 12,
      cautionMax: 25,
    ),
    fiber: MetricReferenceBand(
      goodMin: 8,
      goodMax: 18,
      cautionMin: 5,
      cautionMax: 22,
    ),
    fat: MetricReferenceBand(
      goodMin: 2,
      goodMax: 6,
      cautionMin: 1,
      cautionMax: 8,
    ),
    ash: MetricReferenceBand(
      goodMin: 5,
      goodMax: 10,
      cautionMin: 3,
      cautionMax: 12,
    ),
  );
}
