import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/ph_analysis_result.dart';

class PhAnalysisAiService {
  PhAnalysisAiService()
    : _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: _responseSchema,
        ),
      );

  final GenerativeModel _model;

  static final Schema _responseSchema = Schema.object(
    properties: {
      'estimatedPh': Schema.number(),
      'confidence': Schema.number(),
      'stripQuality': Schema.enumString(
        enumValues: ['acceptable', 'poor', 'unusable'],
      ),
      'referenceChartStatus': Schema.enumString(
        enumValues: ['visible', 'unreadable', 'not_visible'],
      ),
    },
  );

  static const String _prompt = '''
You are a visual pH-strip screening assistant for the Parakh livestock-feed
application.

Inspect the photograph of a reacted pH test strip beside its printed colour
reference chart.

Rules:
1. Estimate pH only by comparing the reacted strip colour with the visible
   reference chart in the same photograph.
2. estimatedPh must be between 0.0 and 14.0.
3. confidence must be between 0.0 and 1.0.
4. Use stripQuality "acceptable" only when the reacted strip and reference
   chart are both clear, well-lit and readable.
5. Use stripQuality "poor" when comparison is possible but lighting,
   shadows, glare, blur or perspective reduce reliability.
6. Use stripQuality "unusable" when no pH strip is visible, the strip is
   unreacted, the colour chart is absent/unreadable, or comparison is not
   reasonably possible.
7. When stripQuality is "unusable", return estimatedPh 0.0 and confidence 0.0.
8. Do not estimate pH from the appearance of feed, liquid, packaging,
   handwritten text or printed labels alone.
9. This is a visual estimate, not a calibrated laboratory measurement.
''';

  Future<PhAnalysisResult> analyse({
    required Uint8List imageBytes,
    required String imageSource,
    required String feedType,
  }) async {
    if (imageBytes.isEmpty) {
      throw const FormatException('The selected pH image is empty.');
    }

    final response = await _model.generateContent([
      Content.multi([
        TextPart(_prompt),
        InlineDataPart(_detectMimeType(imageBytes), imageBytes),
      ]),
    ]);

    final responseText = response.text;

    if (responseText == null || responseText.trim().isEmpty) {
      throw const FormatException('Firebase AI returned an empty pH response.');
    }

    final decoded = jsonDecode(responseText);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Firebase AI returned an invalid pH response.',
      );
    }

    final stripQuality = decoded['stripQuality']?.toString();
    final referenceChartStatus = decoded['referenceChartStatus']?.toString();

    if (!const {'acceptable', 'poor', 'unusable'}.contains(stripQuality)) {
      throw const FormatException('Invalid pH strip-quality result.');
    }

    if (!const {
      'visible',
      'unreadable',
      'not_visible',
    }.contains(referenceChartStatus)) {
      throw const FormatException('Invalid pH reference-chart result.');
    }

    final rawEstimatedPh = decoded['estimatedPh'];
    final rawConfidence = decoded['confidence'];

    if (rawEstimatedPh is! num || rawConfidence is! num) {
      throw const FormatException('The pH estimate or confidence is missing.');
    }

    final isUsable =
        stripQuality != 'unusable' && referenceChartStatus == 'visible';

    final estimatedPh = isUsable
        ? rawEstimatedPh.toDouble().clamp(0.0, 14.0).toDouble()
        : 0.0;

    final confidence = isUsable
        ? rawConfidence.toDouble().clamp(0.0, 1.0).toDouble()
        : 0.0;

    return PhAnalysisResult(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      feedType: feedType,
      estimatedPh: estimatedPh,
      imageSource: imageSource,
      analysisSource: 'firebase-ai-logic',
      modelVersion: 'gemini-3.8-flash',
      calibrationChartVersion: referenceChartStatus == 'visible'
          ? 'visual-reference-in-image'
          : 'reference-not-available',
      stripQuality: isUsable ? stripQuality! : 'unusable',
      samplePreparation: 'user-prepared-not-verified',
      createdAt: DateTime.now(),
      confidence: confidence,
      isValidated: false,
    );
  }

  String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }

    return 'image/jpeg';
  }
}
