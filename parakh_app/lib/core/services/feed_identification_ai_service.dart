import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/feed_identification_result.dart';

class FeedIdentificationAiService {
  FeedIdentificationAiService()
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
      'imageQuality': Schema.enumString(enumValues: ['acceptable', 'poor']),
      'predictions': Schema.array(
        items: Schema.object(
          properties: {
            'feedType': Schema.enumString(
              enumValues: [
                'Maize Silage',
                'Wheat Straw',
                'Green Fodder',
                'Concentrate Feed',
                'Cattle Feed Pellets',
                'Unknown',
              ],
            ),
            'confidence': Schema.number(),
          },
        ),
      ),
    },
  );

  static const String _prompt = '''
You are a visual feed-identification assistant for the Parakh livestock
feed-screening application.

Inspect the supplied photograph and classify only the feed that is clearly
visible.

Allowed labels:
- Maize Silage
- Wheat Straw
- Green Fodder
- Concentrate Feed
- Cattle Feed Pellets
- Unknown

Instructions:
1. Return up to three predictions, ordered from highest to lowest confidence.
2. Confidence must be between 0.0 and 1.0.
3. Use "Unknown" when the image does not clearly show livestock feed.
4. Set imageQuality to "poor" when the image is blurred, dark, obstructed,
   too distant, or does not provide enough visible detail.
5. Do not infer nutrition, safety, contamination, moisture, or laboratory
   quality from appearance.
6. Do not treat packaging text as definitive proof of the feed.
''';

  Future<FeedIdentificationResult> analyse({
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
      throw const FormatException('Firebase AI returned an empty response.');
    }

    final decoded = jsonDecode(responseText);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Firebase AI returned an invalid response.');
    }

    final imageQuality = decoded['imageQuality'] == 'acceptable'
        ? 'acceptable'
        : 'poor';

    final predictionData = decoded['predictions'];
    final predictions = <FeedPrediction>[];

    if (predictionData is List) {
      for (final item in predictionData.take(3)) {
        if (item is! Map) continue;

        final feedType = item['feedType']?.toString();
        final rawConfidence = item['confidence'];

        if (feedType == null || !_allowedFeedTypes.contains(feedType)) {
          continue;
        }

        final confidence = rawConfidence is num
            ? rawConfidence.toDouble().clamp(0.0, 1.0).toDouble()
            : 0.0;

        predictions.add(
          FeedPrediction(feedType: feedType, confidence: confidence),
        );
      }
    }

    predictions.sort(
      (first, second) => second.confidence.compareTo(first.confidence),
    );

    if (predictions.isEmpty) {
      predictions.add(const FeedPrediction(feedType: 'Unknown', confidence: 0));
    }

    return FeedIdentificationResult(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imageSource: imageSource,
      analysisSource: 'firebase-ai-logic',
      modelVersion: 'gemini-3.8-flash',
      imageQuality: imageQuality,
      predictions: predictions,
      createdAt: DateTime.now(),
      isValidated: false,
      requiresFarmerConfirmation: true,
    );
  }

  static const Set<String> _allowedFeedTypes = {
    'Maize Silage',
    'Wheat Straw',
    'Green Fodder',
    'Concentrate Feed',
    'Cattle Feed Pellets',
    'Unknown',
  };

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
