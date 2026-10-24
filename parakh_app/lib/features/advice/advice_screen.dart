import 'package:flutter/material.dart';

import '../../core/theme/parakh_colors.dart';
import '../../core/models/feed_recommendation.dart';
import '../../core/models/feed_test_result.dart';
import '../../core/services/offline_recommendation_service.dart';
import '../../core/storage/test_history_storage.dart';
import '../../core/services/ai_error_handler.dart';
import '../../core/services/feed_recommendation_ai_service.dart';

class AdviceScreen extends StatefulWidget {
  const AdviceScreen({required this.isHindi, super.key});

  final bool isHindi;

  @override
  State<AdviceScreen> createState() => _AdviceScreenState();
}

class _AdviceScreenState extends State<AdviceScreen> {
  String _selectedCategory = 'All';
  final TestHistoryStorage _historyStorage = TestHistoryStorage();
  final OfflineRecommendationService _recommendationService =
      const OfflineRecommendationService();
      final FeedRecommendationAiService _aiRecommendationService =
    FeedRecommendationAiService();

FeedTestResult? _latestCompleteTest;
bool _isEnhancingWithAi = false;

  FeedRecommendation? _personalizedRecommendation;
  bool _isLoadingRecommendation = true;

  String _text(String english, String hindi) {
    return widget.isHindi ? hindi : english;
  }

  @override
  void initState() {
    super.initState();
    _loadLatestRecommendation();
  }

  Future<void> _loadLatestRecommendation() async {
    setState(() {
      _isLoadingRecommendation = true;
    });

    final results = await _historyStorage.getResults();

    FeedTestResult? latestCompleteTest;

    for (final result in results) {
      if (result.testType == 'Complete Test') {
        latestCompleteTest = result;
        break;
      }
    }

    if (!mounted) return;

    setState(() {
  _latestCompleteTest = latestCompleteTest;
  _personalizedRecommendation = latestCompleteTest == null
      ? null
      : _recommendationService.generate(latestCompleteTest);
  _isLoadingRecommendation = false;
  _isEnhancingWithAi = false;
});
  }

  List<_AdviceItem> get _adviceItems {
    return [
      _AdviceItem(
        category: 'Nutrition',
        icon: Icons.egg_alt_rounded,
        color: const Color(0xFF2F7650),
        titleEnglish: 'Low protein',
        titleHindi: 'कम प्रोटीन',
        descriptionEnglish: 'Low-protein feed may not adequately support growth or milk production.',
        descriptionHindi: 'कम प्रोटीन वाला चारा वृद्धि या दूध उत्पादन के लिए पर्याप्त नहीं हो सकता।',
        actionsEnglish: const [
          'Mix the ration with a suitable protein-rich feed source.',
          'Use good-quality legume fodder where locally available.',
          'Balance the complete ration with help from a livestock nutrition expert.',
        ],
        actionsHindi: const [
          'राशन में उपयुक्त प्रोटीन युक्त चारा मिलाएँ।',
          'स्थानीय रूप से उपलब्ध अच्छी गुणवत्ता वाला दलहनी चारा उपयोग करें।',
          'पशु पोषण विशेषज्ञ की सहायता से पूरे राशन को संतुलित करें।',
        ],
      ),
      _AdviceItem(
        category: 'Nutrition',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF3D70A8),
        titleEnglish: 'Excess moisture',
        titleHindi: 'अधिक नमी',
        descriptionEnglish: 'Excess moisture can encourage spoilage and reduce safe storage time.',
        descriptionHindi: 'अधिक नमी खराब होने का जोखिम बढ़ा सकती है और सुरक्षित भंडारण अवधि घटा सकती है।',
        actionsEnglish: const [
          'Keep the feed covered and protected from rain.',
          'Improve drainage and ventilation around the storage area.',
          'Use wet feed quickly and inspect it for heating or mould.',
        ],
        actionsHindi: const [
          'चारे को ढककर रखें और बारिश से बचाएँ।',
          'भंडारण क्षेत्र के आसपास जल निकासी और हवा की व्यवस्था सुधारें।',
          'गीले चारे का जल्दी उपयोग करें और गर्माहट या फफूंद की जाँच करें।',
        ],
      ),
      _AdviceItem(
        category: 'Nutrition',
        icon: Icons.grass_rounded,
        color: const Color(0xFF708B43),
        titleEnglish: 'High fibre',
        titleHindi: 'अधिक फाइबर',
        descriptionEnglish: 'Very fibrous feed may be harder to digest and can reduce nutrient intake.',
        descriptionHindi: 'बहुत अधिक रेशेदार चारा पचने में कठिन हो सकता है और पोषक तत्वों का सेवन घटा सकता है।',
        actionsEnglish: const [
          'Chop coarse fodder into suitable pieces.',
          'Mix it with better-quality green fodder or concentrate.',
          'Avoid sudden changes in the animal ration.',
        ],
        actionsHindi: const [
          'मोटे चारे को उपयुक्त आकार में काटें।',
          'इसे अच्छी गुणवत्ता वाले हरे चारे या कंसन्ट्रेट के साथ मिलाएँ।',
          'पशु के राशन में अचानक बदलाव न करें।',
        ],
      ),
      _AdviceItem(
        category: 'pH',
        icon: Icons.science_rounded,
        color: const Color(0xFF8063A6),
        titleEnglish: 'Abnormal pH',
        titleHindi: 'असामान्य pH',
        descriptionEnglish: 'An unexpected pH can indicate poor fermentation, contamination or an incorrect test procedure.',
        descriptionHindi: 'अप्रत्याशित pH खराब किण्वन, संदूषण या गलत जाँच प्रक्रिया का संकेत हो सकता है।',
        actionsEnglish: const [
          'Repeat the test with a fresh strip and clean reference water.',
          'Check the strip under neutral lighting.',
          'Do not feed suspicious silage until it is assessed by an expert.',
        ],
        actionsHindi: const [
          'नई स्ट्रिप और साफ संदर्भ पानी से जाँच दोबारा करें।',
          'सामान्य रोशनी में स्ट्रिप का रंग जाँचें।',
          'संदिग्ध साइलेज को विशेषज्ञ की जाँच तक पशु को न खिलाएँ।',
        ],
      ),
      _AdviceItem(
        category: 'Contamination',
        icon: Icons.landscape_rounded,
        color: const Color(0xFFD17B3F),
        titleEnglish: 'Sand or soil contamination',
        titleHindi: 'रेत या मिट्टी का संदूषण',
        descriptionEnglish: 'Soil contamination reduces feed cleanliness and may introduce harmful material.',
        descriptionHindi: 'मिट्टी का संदूषण चारे की स्वच्छता घटाता है और हानिकारक पदार्थ ला सकता है।',
        actionsEnglish: const [
          'Sieve the dry feed before feeding.',
          'Remove the visibly contaminated portion.',
          'Keep harvested fodder away from bare soil.',
        ],
        actionsHindi: const [
          'सूखे चारे को खिलाने से पहले छानें।',
          'दिखाई देने वाला दूषित भाग हटा दें।',
          'कटे हुए चारे को खुली मिट्टी से दूर रखें।',
        ],
      ),
      _AdviceItem(
        category: 'Contamination',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFB75B4A),
        titleEnglish: 'Visible mould',
        titleHindi: 'दिखाई देने वाली फफूंद',
        descriptionEnglish: 'Mouldy feed can be unsafe. Camera analysis cannot confirm the presence of toxins.',
        descriptionHindi: 'फफूंद लगा चारा असुरक्षित हो सकता है। कैमरा विश्लेषण विषैले पदार्थों की पुष्टि नहीं कर सकता।',
        actionsEnglish: const [
          'Separate the suspicious feed from the remaining stock.',
          'Do not simply mix visibly mouldy feed into clean feed.',
          'Seek veterinary or feed-laboratory advice before use.',
        ],
        actionsHindi: const [
          'संदिग्ध चारे को बाकी भंडार से अलग करें।',
          'फफूंद लगे चारे को साफ चारे में मिलाकर उपयोग न करें।',
          'उपयोग से पहले पशु चिकित्सक या चारा प्रयोगशाला की सलाह लें।',
        ],
      ),
      _AdviceItem(
        category: 'Storage',
        icon: Icons.warehouse_rounded,
        color: const Color(0xFF55706C),
        titleEnglish: 'Safe feed storage',
        titleHindi: 'सुरक्षित चारा भंडारण',
        descriptionEnglish: 'Correct storage helps prevent moisture, insects, mould and nutrient loss.',
        descriptionHindi: 'सही भंडारण नमी, कीड़ों, फफूंद और पोषक तत्वों की हानि को रोकने में मदद करता है।',
        actionsEnglish: const [
          'Use a clean, dry, shaded and well-ventilated storage area.',
          'Keep feed bags above the floor and away from walls.',
          'Use older feed first and inspect stock regularly.',
        ],
        actionsHindi: const [
          'साफ, सूखी, छायादार और हवादार जगह का उपयोग करें।',
          'चारे की बोरियों को फर्श से ऊपर और दीवारों से दूर रखें।',
          'पुराने चारे का पहले उपयोग करें और भंडार की नियमित जाँच करें।',
        ],
      ),
    ];
  }
  Future<void> _enhanceRecommendationWithAi() async {
  final testResult = _latestCompleteTest;
  final baseline = _personalizedRecommendation;

  if (testResult == null || baseline == null || _isEnhancingWithAi) {
    return;
  }

  setState(() {
    _isEnhancingWithAi = true;
  });

  try {
    final enhanced = await _aiRecommendationService.enhance(
      result: testResult,
      baseline: baseline,
    );

    if (!mounted) return;

    setState(() {
      _personalizedRecommendation = enhanced;
      _isEnhancingWithAi = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            'AI-enhanced guidance is ready.',
            'AI द्वारा बेहतर मार्गदर्शन तैयार है।',
          ),
        ),
        backgroundColor: ParakhColors.forestGreen,
      ),
    );
  } catch (error) {
    debugPrint('Recommendation AI failed: $error');

    final failure = AiFailure.fromError(error);

    if (!mounted) return;

    setState(() {
      _isEnhancingWithAi = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure.localizedMessage(isHindi: widget.isHindi),
        ),
        backgroundColor: const Color(0xFFB75B4A),
      ),
    );
  }
}

  List<_AdviceItem> get _filteredItems {
    if (_selectedCategory == 'All') {
      return _adviceItems;
    }

    return _adviceItems
        .where((item) => item.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F2),
        surfaceTintColor: Colors.transparent,
        title: Text(
          _text('Farmer Advice', 'किसान सुझाव'),
          style: const TextStyle(
            color: Color(0xFF1B2B21),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildPersonalizedRecommendation(),
                const SizedBox(height: 18),
                _buildCategorySelector(),
                const SizedBox(height: 17),
                ..._filteredItems.map(_buildAdviceCard),
                const SizedBox(height: 5),
                _buildDisclaimer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF174D35), Color(0xFF2F7650)],
        ),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          Container(
            width: 61,
            height: 61,
            decoration: const BoxDecoration(
              color: Color(0x24FFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFFF1C75B),
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(
                    'Practical feed guidance',
                    'व्यावहारिक चारा मार्गदर्शन',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _text(
                    'Available without internet',
                    'इंटरनेट के बिना भी उपलब्ध',
                  ),
                  style: const TextStyle(
                    color: Color(0xFFDDEBE1),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedRecommendation() {
    if (_isLoadingRecommendation) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final recommendation = _personalizedRecommendation;

    if (recommendation == null) {
      return Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0E8DD)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF708078),
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              _text(
                'Complete a feed test to receive personalized guidance.',
                'व्यक्तिगत सुझाव प्राप्त करने के लिए संपूर्ण चारा जाँच पूरी करें।',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF566158),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadLatestRecommendation,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_text('Check again', 'फिर से जाँचें')),
            ),
          ],
        ),
      );
    }

    final actions = widget.isHindi
        ? recommendation.actionsHindi
        : recommendation.actionsEnglish;

    final warnings = widget.isHindi
        ? recommendation.warningsHindi
        : recommendation.warningsEnglish;

    final summary = widget.isHindi
        ? recommendation.summaryHindi
        : recommendation.summaryEnglish;

    final priorityColor = switch (recommendation.priority) {
      'urgent' => const Color(0xFFB54435),
      'review' => const Color(0xFFC48526),
      _ => const Color(0xFF32834C),
    };

    final priorityLabel = switch (recommendation.priority) {
      'urgent' => _text('Urgent review', 'तुरंत समीक्षा'),
      'review' => _text('Needs confirmation', 'पुष्टि आवश्यक'),
      _ => _text('Routine guidance', 'सामान्य मार्गदर्शन'),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: priorityColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: priorityColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(
                        'Personalized feed guidance',
                        'व्यक्तिगत चारा मार्गदर्शन',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF26342B),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      priorityLabel,
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadLatestRecommendation,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: _text('Refresh', 'रीफ्रेश'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            summary,
            style: const TextStyle(
              color: Color(0xFF465249),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _text('Recommended actions', 'सुझाए गए कदम'),
              style: const TextStyle(
                color: Color(0xFF26342B),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: ParakhColors.forestGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        action,
                        style: const TextStyle(
                          color: Color(0xFF4C5A50),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1CF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: warnings
                    .map(
                      (warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• $warning',
                          style: const TextStyle(
                            color: Color(0xFF795315),
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
  recommendation.recommendationSource == 'firebase-ai-logic'
      ? _text(
          'Source: Firebase AI + offline safety rules • Not laboratory validated',
          'स्रोत: Firebase AI + ऑफलाइन सुरक्षा नियम • प्रयोगशाला द्वारा सत्यापित नहीं',
        )
      : _text(
          'Source: Offline rules • Not laboratory validated',
          'स्रोत: ऑफलाइन नियम • प्रयोगशाला द्वारा सत्यापित नहीं',
        ),
  style: const TextStyle(
    color: Color(0xFF7A847D),
    fontSize: 10,
    fontWeight: FontWeight.w600,
  ),
),
            
        ],
      ),
    );
  }

  

  Widget _buildCategorySelector() {
    const categories = ['All', 'Nutrition', 'pH', 'Contamination', 'Storage'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final selected = _selectedCategory == category;

          final label = switch (category) {
            'All' => _text('All', 'सभी'),
            'Nutrition' => _text('Nutrition', 'पोषण'),
            'pH' => 'pH',
            'Contamination' => _text('Contamination', 'संदूषण'),
            'Storage' => _text('Storage', 'भंडारण'),
            _ => category,
          };

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: ChoiceChip(
              selected: selected,
              label: Text(label),
              selectedColor: const Color(0xFFDCEDE1),

              labelStyle: TextStyle(
                color: selected
                    ? ParakhColors.forestGreen
                    : const Color(0xFF566158),
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(
                color: selected
                    ? const Color(0xFFA8CBB2)
                    : const Color(0xFFDCE4DA),
              ),
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdviceCard(_AdviceItem item) {
    final title = widget.isHindi ? item.titleHindi : item.titleEnglish;
    final description = widget.isHindi
        ? item.descriptionHindi
        : item.descriptionEnglish;
    final actions = widget.isHindi ? item.actionsHindi : item.actionsEnglish;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(item.icon, color: item.color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF26342B),
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          item.category,
          style: TextStyle(
            color: item.color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              description,
              style: const TextStyle(
                color: Color(0xFF667169),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 13),
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, color: item.color, size: 18),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      action,
                      style: const TextStyle(
                        color: Color(0xFF3E4B42),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECE7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFB75B4A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _text(
                'These are general recommendations. For serious contamination, illness or ration planning, consult a veterinarian or qualified livestock nutrition expert.',
                'ये सामान्य सुझाव हैं। गंभीर संदूषण, बीमारी या राशन योजना के लिए पशु चिकित्सक या योग्य पशु पोषण विशेषज्ञ से सलाह लें।',
              ),
              style: const TextStyle(
                color: Color(0xFF8F493B),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceItem {
  const _AdviceItem({
    required this.category,
    required this.icon,
    required this.color,
    required this.titleEnglish,
    required this.titleHindi,
    required this.descriptionEnglish,
    required this.descriptionHindi,
    required this.actionsEnglish,
    required this.actionsHindi,
  });

  final String category;
  final IconData icon;
  final Color color;
  final String titleEnglish;
  final String titleHindi;
  final String descriptionEnglish;
  final String descriptionHindi;
  final List<String> actionsEnglish;
  final List<String> actionsHindi;
}
