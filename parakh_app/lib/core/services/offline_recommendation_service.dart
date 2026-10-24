import '../models/feed_recommendation.dart';
import '../models/feed_reference_profile.dart';
import '../models/feed_test_result.dart';

class OfflineRecommendationService {
  const OfflineRecommendationService();

  FeedRecommendation generate(FeedTestResult result) {
    final actionsEnglish = <String>[];
    final actionsHindi = <String>[];
    final warningsEnglish = <String>[];
    final warningsHindi = <String>[];

    final profile = FeedReferenceProfile.forFeed(result.feedType);

    var priority = 'normal';

    if (profile == null) {
      priority = 'review';
      warningsEnglish.add(
        'No reference profile is available for ${result.feedType}.',
      );
      warningsHindi.add(
        '${result.feedType} के लिए संदर्भ प्रोफाइल उपलब्ध नहीं है।',
      );
    } else {
      _addMetricGuidance(
        nameEnglish: 'Moisture',
        nameHindi: 'नमी',
        value: result.moisture,
        band: profile.moisture,
        lowActionEnglish: 'Moisture is below the prototype range. Check sample preparation and confirm using a calibrated method.',
        lowActionHindi: 'नमी प्रोटोटाइप सीमा से कम है। नमूना तैयारी जाँचें और कैलिब्रेटेड विधि से पुष्टि करें।',
        highActionEnglish: 'Moisture is above the prototype range. Protect the feed from rain, improve ventilation and inspect for heating or mould.',
        highActionHindi: 'नमी प्रोटोटाइप सीमा से अधिक है। चारे को बारिश से बचाएँ, हवा की व्यवस्था सुधारें और गर्माहट या फफूंद जाँचें।',
        actionsEnglish: actionsEnglish,
        actionsHindi: actionsHindi,
        onRisk: () => priority = _raisePriority(priority, 'review'),
      );

      _addMetricGuidance(
        nameEnglish: 'Protein',
        nameHindi: 'प्रोटीन',
        value: result.protein,
        band: profile.protein,
        lowActionEnglish: 'Protein is below the prototype range. Ask a livestock nutrition expert about balancing the ration with a suitable protein source.',
        lowActionHindi: 'प्रोटीन प्रोटोटाइप सीमा से कम है। उपयुक्त प्रोटीन स्रोत से राशन संतुलित करने के लिए पशु पोषण विशेषज्ञ से सलाह लें।',
        highActionEnglish: 'Protein is above the prototype range. Confirm the reading before changing the ration.',
        highActionHindi: 'प्रोटीन प्रोटोटाइप सीमा से अधिक है। राशन बदलने से पहले रीडिंग की पुष्टि करें।',
        actionsEnglish: actionsEnglish,
        actionsHindi: actionsHindi,
        onRisk: () => priority = _raisePriority(priority, 'review'),
      );

      _addMetricGuidance(
        nameEnglish: 'Fibre',
        nameHindi: 'फाइबर',
        value: result.fiber,
        band: profile.fiber,
        lowActionEnglish: 'Fibre is below the prototype range. Confirm the sample and review the complete ration.',
        lowActionHindi: 'फाइबर प्रोटोटाइप सीमा से कम है। नमूने की पुष्टि करें और पूरे राशन की समीक्षा करें।',
        highActionEnglish: 'Fibre is above the prototype range. Chop coarse fodder and seek advice before changing the ration.',
        highActionHindi: 'फाइबर प्रोटोटाइप सीमा से अधिक है। मोटे चारे को काटें और राशन बदलने से पहले सलाह लें।',
        actionsEnglish: actionsEnglish,
        actionsHindi: actionsHindi,
        onRisk: () => priority = _raisePriority(priority, 'review'),
      );

      _addMetricGuidance(
        nameEnglish: 'Fat',
        nameHindi: 'वसा',
        value: result.fat,
        band: profile.fat,
        lowActionEnglish: 'Fat is below the prototype range. Confirm the reading and review ration balance with an expert.',
        lowActionHindi: 'वसा प्रोटोटाइप सीमा से कम है। रीडिंग की पुष्टि करें और विशेषज्ञ से राशन संतुलन की समीक्षा कराएँ।',
        highActionEnglish: 'Fat is above the prototype range. Do not add more fat supplements without expert advice.',
        highActionHindi: 'वसा प्रोटोटाइप सीमा से अधिक है। विशेषज्ञ सलाह के बिना अतिरिक्त वसा पूरक न मिलाएँ।',
        actionsEnglish: actionsEnglish,
        actionsHindi: actionsHindi,
        onRisk: () => priority = _raisePriority(priority, 'review'),
      );

      _addMetricGuidance(
        nameEnglish: 'Ash',
        nameHindi: 'राख',
        value: result.ash,
        band: profile.ash,
        lowActionEnglish: 'Ash is below the prototype range. Confirm the reading using a calibrated test.',
        lowActionHindi: 'राख प्रोटोटाइप सीमा से कम है। कैलिब्रेटेड जाँच से रीडिंग की पुष्टि करें।',
        highActionEnglish: 'Ash is above the prototype range. Inspect the feed for soil, sand or mineral contamination.',
        highActionHindi: 'राख प्रोटोटाइप सीमा से अधिक है। मिट्टी, रेत या खनिज संदूषण के लिए चारे की जाँच करें।',
        actionsEnglish: actionsEnglish,
        actionsHindi: actionsHindi,
        onRisk: () => priority = _raisePriority(priority, 'review'),
      );
    }

    final impurityStatus = result.impurityStatus.toLowerCase();

    if (impurityStatus.contains('mould') ||
        impurityStatus.contains('high') ||
        impurityStatus.contains('unsafe')) {
      priority = 'urgent';
      warningsEnglish.add(
        'Possible serious contamination was reported. Separate the sample and do not feed it until professionally assessed.',
      );
      warningsHindi.add(
        'संभावित गंभीर संदूषण मिला है। नमूने को अलग रखें और विशेषज्ञ जाँच तक पशु को न खिलाएँ।',
      );
    } else if (impurityStatus.contains('unverified') ||
        impurityStatus.contains('not analysed')) {
      priority = _raisePriority(priority, 'review');
      warningsEnglish.add(
        'Visible impurities have not been reliably confirmed.',
      );
      warningsHindi.add(
        'दिखाई देने वाली अशुद्धियों की विश्वसनीय पुष्टि नहीं हुई है।',
      );
    }

    if (result.phValue <= 0) {
      warningsEnglish.add('A usable pH result is not available.');
      warningsHindi.add('उपयोग योग्य pH परिणाम उपलब्ध नहीं है।');
    }

    if (result.dataSource == 'simulated-prototype') {
      priority = _raisePriority(priority, 'review');
      warningsEnglish.add(
        'This recommendation uses simulated prototype readings.',
      );
      warningsHindi.add(
        'यह सुझाव सिम्युलेटेड प्रोटोटाइप रीडिंग का उपयोग करता है।',
      );
    }

    if (!result.isLaboratoryValidated) {
      warningsEnglish.add(
        'The result is not laboratory validated and must not be used as the sole feeding decision.',
      );
      warningsHindi.add(
        'यह परिणाम प्रयोगशाला द्वारा सत्यापित नहीं है और इसे अकेले चारा खिलाने के निर्णय का आधार न बनाएँ।',
      );
    }

    if (actionsEnglish.isEmpty) {
      actionsEnglish.add(
        'No major issue was identified within the prototype reference bands. Continue routine visual inspection and safe storage.',
      );
      actionsHindi.add(
        'प्रोटोटाइप संदर्भ सीमाओं में कोई बड़ी समस्या नहीं मिली। नियमित दृश्य जाँच और सुरक्षित भंडारण जारी रखें।',
      );
    }

    return FeedRecommendation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      testResultId: result.id,
      priority: priority,
      summaryEnglish: _summaryEnglish(result, priority),
      summaryHindi: _summaryHindi(result, priority),
      actionsEnglish: actionsEnglish,
      actionsHindi: actionsHindi,
      warningsEnglish: warningsEnglish,
      warningsHindi: warningsHindi,
      recommendationSource: 'offline-rules',
      modelVersion: 'recommendation-rules-v1',
      createdAt: DateTime.now(),
      isValidated: false,
    );
  }

  void _addMetricGuidance({
    required String nameEnglish,
    required String nameHindi,
    required double? value,
    required MetricReferenceBand band,
    required String lowActionEnglish,
    required String lowActionHindi,
    required String highActionEnglish,
    required String highActionHindi,
    required List<String> actionsEnglish,
    required List<String> actionsHindi,
    required void Function() onRisk,
  }) {
    if (value == null) return;

    final risk = band.riskLevel(value);

    if (risk == 0) return;

    onRisk();

    if (value < band.goodMin) {
      actionsEnglish.add('$nameEnglish: $lowActionEnglish');
      actionsHindi.add('$nameHindi: $lowActionHindi');
    } else {
      actionsEnglish.add('$nameEnglish: $highActionEnglish');
      actionsHindi.add('$nameHindi: $highActionHindi');
    }
  }

  String _raisePriority(String current, String requested) {
    const levels = {'normal': 0, 'review': 1, 'urgent': 2};

    return (levels[requested] ?? 0) > (levels[current] ?? 0)
        ? requested
        : current;
  }

  String _summaryEnglish(FeedTestResult result, String priority) {
    return switch (priority) {
      'urgent' =>
        'The ${result.feedType} sample needs urgent contamination review.',
      'review' =>
        'The ${result.feedType} sample needs confirmation before a feeding decision.',
      _ =>
        'The ${result.feedType} sample is within the available prototype screening ranges.',
    };
  }

  String _summaryHindi(FeedTestResult result, String priority) {
    return switch (priority) {
      'urgent' => '${result.feedType} नमूने की तुरंत संदूषण जाँच आवश्यक है।',
      'review' =>
        '${result.feedType} नमूने से चारा खिलाने का निर्णय लेने से पहले पुष्टि आवश्यक है।',
      _ =>
        '${result.feedType} नमूना उपलब्ध प्रोटोटाइप स्क्रीनिंग सीमाओं में है।',
    };
  }
}
