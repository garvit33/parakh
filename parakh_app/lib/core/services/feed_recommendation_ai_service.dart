import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/feed_recommendation.dart';
import '../models/feed_test_result.dart';

class FeedRecommendationAiService {
  FeedRecommendationAiService()
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
      'priority': Schema.enumString(enumValues: ['normal', 'review', 'urgent']),
      'summaryEnglish': Schema.string(),
      'summaryHindi': Schema.string(),
      'actionsEnglish': Schema.array(items: Schema.string()),
      'actionsHindi': Schema.array(items: Schema.string()),
      'warningsEnglish': Schema.array(items: Schema.string()),
      'warningsHindi': Schema.array(items: Schema.string()),
    },
  );

  static const String _prompt = '''
You are the bilingual recommendation assistant for Parakh, a livestock-feed
screening application.

Generate concise, practical farmer guidance using only the supplied test data
and offline baseline recommendation.

Safety rules:
1. Treat all camera, pH and NIR outputs as screening evidence, not laboratory
   proof.
2. Never claim that a feed is completely safe.
3. Never diagnose animal illness or prescribe medicine.
4. Never provide exact ration quantities, supplement doses or treatment doses.
5. Never invent a measurement that is missing, simulated or unverified.
6. When data is missing, simulated, conflicting or unvalidated, clearly say
   that confirmation is required.
7. Possible mould, serious contamination or unsafe findings must have urgent
   priority and advise separating the sample until expert assessment.
8. Recommend a veterinarian, qualified livestock nutrition expert or feed
   laboratory when professional confirmation is appropriate.
9. Provide matching English and Hindi content.
10. Return at most five actions and four warnings in each language.
11. Do not mention Firebase, Gemini, prompts, JSON or internal software.
''';

  Future<FeedRecommendation> enhance({
    required FeedTestResult result,
    required FeedRecommendation baseline,
  }) async {
    final input = {
      'testResult': result.toJson(),
      'offlineBaseline': baseline.toJson(),
    };

    final response = await _model.generateContent([
      Content.text('$_prompt\n\nScreening data:\n${jsonEncode(input)}'),
    ]);

    final responseText = response.text;

    if (responseText == null || responseText.trim().isEmpty) {
      throw const FormatException(
        'Firebase AI returned an empty recommendation.',
      );
    }

    final decoded = jsonDecode(responseText);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Firebase AI returned an invalid recommendation.',
      );
    }

    final priority = _readPriority(decoded['priority']);

    final summaryEnglish = _readRequiredString(
      decoded['summaryEnglish'],
      'English summary',
    );

    final summaryHindi = _readRequiredString(
      decoded['summaryHindi'],
      'Hindi summary',
    );

    final actionsEnglish = _readStringList(
      decoded['actionsEnglish'],
      maximumItems: 5,
    );

    final actionsHindi = _readStringList(
      decoded['actionsHindi'],
      maximumItems: 5,
    );

    final warningsEnglish = _readStringList(
      decoded['warningsEnglish'],
      maximumItems: 4,
    );

    final warningsHindi = _readStringList(
      decoded['warningsHindi'],
      maximumItems: 4,
    );

    if (actionsEnglish.isEmpty || actionsHindi.isEmpty) {
      throw const FormatException(
        'Firebase AI returned incomplete recommendation actions.',
      );
    }

    _ensureSafetyWarning(
      warningsEnglish,
      'This is screening guidance and is not laboratory validated.',
    );

    _ensureSafetyWarning(
      warningsHindi,
      'यह स्क्रीनिंग मार्गदर्शन है और प्रयोगशाला द्वारा सत्यापित नहीं है।',
    );

    return FeedRecommendation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      testResultId: result.id,
      priority: _higherPriority(priority, baseline.priority),
      summaryEnglish: summaryEnglish,
      summaryHindi: summaryHindi,
      actionsEnglish: actionsEnglish,
      actionsHindi: actionsHindi,
      warningsEnglish: warningsEnglish,
      warningsHindi: warningsHindi,
      recommendationSource: 'firebase-ai-logic',
      modelVersion: 'gemini-3.8-flash',
      createdAt: DateTime.now(),
      isValidated: false,
    );
  }

  String _readPriority(dynamic value) {
    final priority = value?.toString();

    if (priority == 'normal' || priority == 'review' || priority == 'urgent') {
      return priority!;
    }

    return 'review';
  }

  String _readRequiredString(dynamic value, String fieldName) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      throw FormatException('$fieldName is missing.');
    }

    return text;
  }

  List<String> _readStringList(dynamic value, {required int maximumItems}) {
    if (value is! List) return [];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .take(maximumItems)
        .toList();
  }

  void _ensureSafetyWarning(List<String> warnings, String warning) {
    final alreadyIncluded = warnings.any(
      (item) =>
          item.toLowerCase().contains('laboratory') ||
          item.contains('प्रयोगशाला'),
    );

    if (!alreadyIncluded) {
      warnings.add(warning);
    }
  }

  String _higherPriority(String first, String second) {
    const levels = {'normal': 0, 'review': 1, 'urgent': 2};

    return (levels[first] ?? 1) >= (levels[second] ?? 1) ? first : second;
  }
}
