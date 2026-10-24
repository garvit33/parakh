import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

class ParakhNutrientPrediction {
  const ParakhNutrientPrediction({
    required this.protein,
    required this.fat,
    required this.fibre,
    required this.rawProtein,
    required this.rawFat,
    required this.rawFibre,
    required this.referenceMatch,
    required this.reachedModelBoundary,
  });

  final double protein;
  final double fat;
  final double fibre;
  final double rawProtein;
  final double rawFat;
  final double rawFibre;
  final double referenceMatch;
  final bool reachedModelBoundary;
}

class ParakhPlsPredictor {
  ParakhPlsPredictor._({
    required this.channels,
    required this.xMean,
    required this.xScale,
    required this.coefficients,
    required this.intercept,
    required this.outputMinimum,
    required this.outputMaximum,
    required this.referenceMeansNormalized,
    required this.trainingSpectraNormalized,
    required this.referenceDistanceScale,
  });

  final List<String> channels;
  final List<double> xMean;
  final List<double> xScale;
  final List<List<double>> coefficients;
  final List<double> intercept;
  final List<double> outputMinimum;
  final List<double> outputMaximum;
  final List<List<double>> referenceMeansNormalized;
  final List<List<double>> trainingSpectraNormalized;
  final double referenceDistanceScale;

  static Future<ParakhPlsPredictor> load({
    String assetPath = 'assets/models/parakh_pls_model.json',
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    List<double> doubles(String key) =>
        (json[key] as List).map((value) => (value as num).toDouble()).toList();

    return ParakhPlsPredictor._(
      channels: (json['channels'] as List).cast<String>(),
      xMean: doubles('xMean'),
      xScale: doubles('xScale'),
      coefficients: (json['coefficients'] as List)
          .map(
            (row) => (row as List)
                .map((value) => (value as num).toDouble())
                .toList(),
          )
          .toList(),
      intercept: doubles('intercept'),
      outputMinimum: doubles('outputMinimum'),
      outputMaximum: doubles('outputMaximum'),
      referenceMeansNormalized:
          (json['referenceMeansNormalized'] as Map<String, dynamic>).values
              .map(
                (row) => (row as List)
                    .map((value) => (value as num).toDouble())
                    .toList(),
              )
              .toList(),
      trainingSpectraNormalized: (json['trainingSpectraNormalized'] as List)
          .map(
            (row) => (row as List)
                .map((value) => (value as num).toDouble())
                .toList(),
          )
          .toList(),
      referenceDistanceScale: (json['referenceDistanceScale'] as num)
          .toDouble(),
    );
  }

  ParakhNutrientPrediction predict({
    required Map<String, num> spectralChannels,
  }) {
    final clear = spectralChannels['Clear']?.toDouble();
    if (clear == null || clear <= 0) {
      throw ArgumentError('A positive Clear reading is required.');
    }

    final standardized = <double>[];
    for (var index = 0; index < channels.length; index++) {
      final raw = spectralChannels[channels[index]]?.toDouble();
      if (raw == null) {
        throw ArgumentError('Missing spectral channel ${channels[index]}.');
      }
      final normalized = raw / clear;
      standardized.add((normalized - xMean[index]) / xScale[index]);
    }

    final result = List<double>.from(intercept);
    for (var feature = 0; feature < standardized.length; feature++) {
      for (var target = 0; target < result.length; target++) {
        result[target] += standardized[feature] * coefficients[feature][target];
      }
    }

    final rawResult = List<double>.from(result);
    var reachedModelBoundary = false;

    for (var target = 0; target < result.length; target++) {
      if (result[target] < outputMinimum[target] ||
          result[target] > outputMaximum[target]) {
        reachedModelBoundary = true;
      }
      result[target] = result[target]
          .clamp(outputMinimum[target], outputMaximum[target])
          .toDouble();
    }

    final referenceMatch = _referenceMatch(standardized);
    if (referenceMatch < 30.0) {
      reachedModelBoundary = true;
    }

    return ParakhNutrientPrediction(
      protein: result[0],
      fat: result[1],
      fibre: result[2],
      rawProtein: rawResult[0],
      rawFat: rawResult[1],
      rawFibre: rawResult[2],
      referenceMatch: referenceMatch,
      reachedModelBoundary: reachedModelBoundary,
    );
  }

  double _referenceMatch(List<double> standardized) {
    if (trainingSpectraNormalized.isEmpty || referenceDistanceScale <= 0) {
      return 0;
    }

    var nearestDistance = double.infinity;
    for (final spectrum in trainingSpectraNormalized) {
      var squaredDistance = 0.0;
      for (var index = 0; index < standardized.length; index++) {
        final trainingStandardized =
            (spectrum[index] - xMean[index]) / xScale[index];
        final difference = standardized[index] - trainingStandardized;
        squaredDistance += difference * difference;
      }
      final distance = math.sqrt(squaredDistance / standardized.length);
      if (distance < nearestDistance) nearestDistance = distance;
    }

    final scaledDistance = nearestDistance / referenceDistanceScale;
    return (100 * math.exp(-0.5 * scaledDistance * scaledDistance)).clamp(
      0.0,
      100.0,
    );
  }
}
