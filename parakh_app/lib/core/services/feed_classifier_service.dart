import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FeedClassification {
  const FeedClassification({
    required this.label,
    required this.confidence,
    required this.requiresManualConfirmation,
  });

  final String label;
  final double confidence;
  final bool requiresManualConfirmation;
}

class FeedClassifierService {
  FeedClassifierService({this.confidenceThreshold = 0.65});

  final double confidenceThreshold;
  Interpreter? _interpreter;
  List<String> _labels = const [];

  Future<void> load() async {
    _interpreter ??= await Interpreter.fromAsset(
      'assets/models/parakh_feed_classifier.tflite',
    );

    final labelsText = await rootBundle.loadString(
      'assets/models/feed_labels.txt',
    );
    _labels = labelsText
        .split('\n')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
  }

  Future<FeedClassification> classify(Uint8List imageBytes) async {
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

    final output = [List<double>.filled(_labels.length, 0.0)];
    _interpreter!.run(input, output);

    var bestIndex = 0;
    for (var index = 1; index < output.first.length; index++) {
      if (output.first[index] > output.first[bestIndex]) {
        bestIndex = index;
      }
    }

    final confidence = output.first[bestIndex];
    return FeedClassification(
      label: _labels[bestIndex],
      confidence: confidence,
      requiresManualConfirmation: confidence < confidenceThreshold,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
