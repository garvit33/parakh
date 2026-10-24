import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/camera_analysis_result.dart';

class ImpurityClassifierService {
  ImpurityClassifierService({this.confidenceThreshold = 0.60});

  final double confidenceThreshold;

  Interpreter? _interpreter;
  List<String> _labels = const [];

  Future<void> load() async {
    _interpreter ??= await Interpreter.fromAsset(
      'assets/models/parakh_impurity_classifier.tflite',
    );

    final labelsText = await rootBundle.loadString(
      'assets/models/impurity_labels.txt',
    );

    _labels = labelsText
        .split('\n')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);

    if (_labels.length != 5) {
      throw const FormatException(
        'The impurity model must contain exactly five labels.',
      );
    }
  }

  Future<CameraAnalysisResult> analyse({
    required Uint8List imageBytes,
    required String imageSource,
  }) async {
    await load();

    final decoded = img.decodeImage(imageBytes);

    if (decoded == null) {
      throw const FormatException('The selected feed image is invalid.');
    }

    final resized = img.copyResize(decoded, width: 224, height: 224);

    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);

          return <double>[
            pixel.r.toDouble(),
            pixel.g.toDouble(),
            pixel.b.toDouble(),
          ];
        }),
      ),
    );

    final output = [List<double>.filled(_labels.length, 0)];

    _interpreter!.run(input, output);

    var bestIndex = 0;

    for (var index = 1; index < output.first.length; index++) {
      if (output.first[index] > output.first[bestIndex]) {
        bestIndex = index;
      }
    }

    final predictedLabel = _labels[bestIndex];
    final confidence = output.first[bestIndex].clamp(0.0, 1.0).toDouble();

    return CameraAnalysisResult(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imageSource: imageSource,
      analysisSource: 'offline-tflite',
      modelVersion: 'parakh-impurity-v1',
      imageQuality: 'acceptable',
      findings: [
        _finding(
          category: 'sand_or_soil',
          predictedLabel: predictedLabel,
          confidence: confidence,
        ),
        _finding(
          category: 'stones',
          predictedLabel: predictedLabel,
          confidence: confidence,
        ),
        _finding(
          category: 'mould',
          predictedLabel: predictedLabel,
          confidence: confidence,
        ),
        _finding(
          category: 'foreign_material',
          predictedLabel: predictedLabel,
          confidence: confidence,
        ),
      ],
      createdAt: DateTime.now(),
      overallConfidence: confidence,
      isValidated: false,
    );
  }

  CameraFinding _finding({
    required String category,
    required String predictedLabel,
    required double confidence,
  }) {
    if (predictedLabel == 'clean' || predictedLabel != category) {
      return CameraFinding(
        category: category,
        level: 'not_detected',
        confidence: predictedLabel == 'clean' ? confidence : null,
      );
    }

    final String level;

    if (confidence < confidenceThreshold) {
      level = 'possible';
    } else if (confidence >= 0.85) {
      level = 'high';
    } else if (confidence >= 0.72) {
      level = 'medium';
    } else {
      level = 'low';
    }

    return CameraFinding(
      category: category,
      level: level,
      confidence: confidence,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
