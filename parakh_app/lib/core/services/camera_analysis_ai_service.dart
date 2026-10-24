import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/camera_analysis_result.dart';

class CameraAnalysisAiService {
  CameraAnalysisAiService()
    : _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: _responseSchema,
        ),
      );

  final GenerativeModel _model;

  static const Set<String> _categories = {
    'sand_or_soil',
    'stones',
    'mould',
    'foreign_material',
  };

  static const Set<String> _levels = {
    'not_detected',
    'possible',
    'low',
    'medium',
    'high',
  };

  static final Schema _responseSchema = Schema.object(
    properties: {
      'imageQuality': Schema.enumString(enumValues: ['acceptable', 'poor']),
      'overallConfidence': Schema.number(),
      'findings': Schema.array(
        items: Schema.object(
          properties: {
            'category': Schema.enumString(
              enumValues: [
                'sand_or_soil',
                'stones',
                'mould',
                'foreign_material',
              ],
            ),
            'level': Schema.enumString(
              enumValues: ['not_detected', 'possible', 'low', 'medium', 'high'],
            ),
            'confidence': Schema.number(),
          },
        ),
      ),
    },
  );

  static const String _prompt = '''
You are a visual screening assistant for the Parakh livestock-feed application.

Inspect only what is visibly present in the supplied feed photograph.

Return exactly one finding for each category:
1. sand_or_soil
2. stones
3. mould
4. foreign_material

Allowed levels:
- not_detected: no visible indicator is observed
- possible: the image contains an uncertain visual indicator
- low: a small visible amount is present
- medium: a noticeable visible amount is present
- high: a large visible amount is present

Rules:
1. Confidence values must be between 0.0 and 1.0.
2. Set imageQuality to poor if the photograph is blurred, dark, obstructed,
   too distant, or does not clearly show the feed.
3. If image quality is poor, use possible rather than making a confident
   contamination claim.
4. Mould means only clearly visible mould-like growth or patches.
5. Do not claim detection of toxins, microbes, chemicals, pesticides,
   nutritional composition, moisture, or anything invisible.
6. Natural variation in feed colour must not automatically be called mould.
7. Do not identify normal feed particles as stones or foreign material.
8. This is visual screening only, not laboratory validation.
''';

  Future<CameraAnalysisResult> analyse({
    required Uint8List imageBytes,
    required String imageSource,
  }) async {
    if (imageBytes.isEmpty) {
      throw const FormatException('The selected image is empty.');
    }

    final response = await _model.generateContent([
      Content.multi([
        TextPart(_prompt),
        InlineDataPart(_detectMimeType(imageBytes), imageBytes),
      ]),
    ]);

    final responseText = response.text;

    if (responseText == null || responseText.trim().isEmpty) {
      throw const FormatException(
        'Firebase AI returned an empty camera-analysis response.',
      );
    }

    final decoded = jsonDecode(responseText);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Firebase AI returned an invalid camera-analysis response.',
      );
    }

    final rawFindings = decoded['findings'];

    if (rawFindings is! List) {
      throw const FormatException('Camera findings are missing.');
    }

    final findingsByCategory = <String, CameraFinding>{};

    for (final rawFinding in rawFindings) {
      if (rawFinding is! Map) continue;

      final category = rawFinding['category']?.toString();
      final level = rawFinding['level']?.toString();
      final rawConfidence = rawFinding['confidence'];

      if (category == null ||
          level == null ||
          !_categories.contains(category) ||
          !_levels.contains(level)) {
        continue;
      }

      final confidence = rawConfidence is num
          ? rawConfidence.toDouble().clamp(0.0, 1.0).toDouble()
          : 0.0;

      findingsByCategory[category] = CameraFinding(
        category: category,
        level: level,
        confidence: confidence,
      );
    }

    if (!findingsByCategory.keys.toSet().containsAll(_categories)) {
      throw const FormatException(
        'Firebase AI did not return all required camera findings.',
      );
    }

    final rawOverallConfidence = decoded['overallConfidence'];
    final overallConfidence = rawOverallConfidence is num
        ? rawOverallConfidence.toDouble().clamp(0.0, 1.0).toDouble()
        : 0.0;

    final imageQuality = decoded['imageQuality'] == 'acceptable'
        ? 'acceptable'
        : 'poor';

    return CameraAnalysisResult(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imageSource: imageSource,
      analysisSource: 'firebase-ai-logic',
      modelVersion: 'gemini-3.8-flash',
      imageQuality: imageQuality,
      findings: [
        findingsByCategory['sand_or_soil']!,
        findingsByCategory['stones']!,
        findingsByCategory['mould']!,
        findingsByCategory['foreign_material']!,
      ],
      createdAt: DateTime.now(),
      overallConfidence: overallConfidence,
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
