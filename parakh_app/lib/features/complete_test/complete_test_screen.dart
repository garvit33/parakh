import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/camera_analysis_result.dart';
import '../../core/storage/latest_analysis_storage.dart';
import '../../core/models/device_reading.dart';
import '../../core/models/feed_reference_profile.dart';
import '../../core/models/feed_test_result.dart';
import '../../core/storage/test_history_storage.dart';
import '../../core/theme/parakh_colors.dart';

class CompleteTestScreen extends StatefulWidget {
  const CompleteTestScreen({
    required this.isHindi,
    required this.isDeviceConnected,
    super.key,
  });

  final bool isHindi;
  final bool isDeviceConnected;

  @override
  State<CompleteTestScreen> createState() => _CompleteTestScreenState();
}

class _CompleteTestScreenState extends State<CompleteTestScreen> {
  String _selectedFeed = 'Maize Silage';
  int _activeStep = -1;
  bool _isRunning = false;
  bool _showResult = false;
  FeedTestResult? _latestResult;
  final List<bool> _completedSteps = [false, false, false, false];
  final TestHistoryStorage _historyStorage = TestHistoryStorage();
  final TextEditingController _sampleIdController = TextEditingController();
  final TextEditingController _batchIdController = TextEditingController();
  final LatestAnalysisStorage _latestAnalysisStorage = LatestAnalysisStorage();

  String _text(String english, String hindi) {
    return widget.isHindi ? hindi : english;
  }

  @override
  void initState() {
    super.initState();
    _loadIdentifiedFeed();
  }

  Future<void> _loadIdentifiedFeed() async {
    final preferences = await SharedPreferences.getInstance();
    final identifiedFeed = preferences.getString('identifiedFeedType');

    if (!mounted || identifiedFeed == null) return;

    final supportedFeeds = {
      'Maize Silage',
      'Wheat Straw',
      'Green Fodder',
      'Concentrate Feed',
      'Cattle Feed Pellets',
    };

    if (!supportedFeeds.contains(identifiedFeed)) return;

    setState(() {
      _selectedFeed = identifiedFeed;
    });
  }

  List<int> _nutritionRiskLevels(DeviceReading reading) {
    final profile = FeedReferenceProfile.forFeed(reading.feedType);

    if (profile == null) {
      return const [2];
    }

    return [
      profile.moisture.riskLevel(reading.moisture),
      profile.protein.riskLevel(reading.protein),
      profile.fiber.riskLevel(reading.fiber),
      profile.fat.riskLevel(reading.fat),
      profile.ash.riskLevel(reading.ash),
    ];
  }

  int _nutritionRisk(DeviceReading reading) {
    final levels = _nutritionRiskLevels(reading);

    if (levels.contains(2)) return 2;
    if (levels.contains(1)) return 1;
    return 0;
  }

  int _prototypeScore(DeviceReading reading) {
    final penalty = _nutritionRiskLevels(reading).fold<int>(
      0,
      (total, level) =>
          total +
          (level == 2
              ? 20
              : level == 1
              ? 8
              : 0),
    );

    return (100 - penalty).clamp(0, 100);
  }

  String _nutritionStatus(DeviceReading reading) {
    switch (_nutritionRisk(reading)) {
      case 2:
        return 'Needs review';
      case 1:
        return 'Caution';
      default:
        return 'Within prototype range';
    }
  }

  String _cameraImpurityStatus(CameraAnalysisResult? result) {
    if (result == null) return 'Not analysed';

    const categories = ['sand_or_soil', 'stones', 'mould', 'foreign_material'];

    final detected = <String>[];

    for (final category in categories) {
      final finding = result.findingFor(category);
      final level = finding?.level;

      if (level != null &&
          level != 'not_detected' &&
          level != 'none' &&
          level != 'low') {
        detected.add('$category: $level');
      }
    }

    if (detected.isEmpty) {
      return 'No major visible impurity detected';
    }

    return detected.join(', ');
  }

  Future<void> _startCompleteTest() async {
    if (!widget.isDeviceConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Connect the Parakh device before starting the complete test.',
              'संपूर्ण जाँच शुरू करने से पहले परख डिवाइस कनेक्ट करें।',
            ),
          ),
          backgroundColor: const Color(0xFFB75B4A),
        ),
      );
      return;
    }

    setState(() {
      _isRunning = true;
      _showResult = false;
      _activeStep = 0;

      for (var i = 0; i < _completedSteps.length; i++) {
        _completedSteps[i] = false;
      }
    });

    for (var i = 0; i < _completedSteps.length; i++) {
      if (!mounted) return;

      setState(() {
        _activeStep = i;
      });

      await Future<void>.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      setState(() {
        _completedSteps[i] = true;
      });
    }

    if (!mounted) return;

    final completedAt = DateTime.now();
    final enteredSampleId = _sampleIdController.text.trim();
    final enteredBatchId = _batchIdController.text.trim();

    final sampleId = enteredSampleId.isEmpty
        ? 'SAMPLE-${completedAt.millisecondsSinceEpoch}'
        : enteredSampleId;

    final batchId = enteredBatchId.isEmpty
        ? 'BATCH-${completedAt.millisecondsSinceEpoch}'
        : enteredBatchId;
    final preferences = await SharedPreferences.getInstance();

    final animalType = preferences.getString('animalType') ?? 'Not provided';
    final animalBreed = preferences.getString('animalBreed') ?? 'Not provided';
    final productionGoal =
        preferences.getString('productionGoal') ?? 'Not provided';

    final storedNir = await _latestAnalysisStorage.getNirReading(
      feedType: _selectedFeed,
    );

    final cameraResult = await _latestAnalysisStorage.getCameraResult(
      feedType: _selectedFeed,
    );

    final phResult = await _latestAnalysisStorage.getPhResult(
      feedType: _selectedFeed,
    );

    final nirReading =
        storedNir ??
        DeviceReading.demo(sampleId: sampleId, feedType: _selectedFeed);

    final missingModules = <String>[
      if (storedNir == null) 'NIR',
      if (cameraResult == null) 'camera',
      if (phResult == null) 'pH',
    ];

    final score = _prototypeScore(nirReading);
    final nutritionStatus = _nutritionStatus(nirReading);
    final impurityStatus = _cameraImpurityStatus(cameraResult);

    final usesSimulatedNir =
        storedNir == null || nirReading.scanSource == 'simulated-prototype';

    final hasAllEvidence = missingModules.isEmpty;

    final isFullyValidated =
        hasAllEvidence &&
        !usesSimulatedNir &&
        cameraResult!.isValidated &&
        phResult!.isValidated;

    final dataSource = usesSimulatedNir
        ? 'simulated-prototype'
        : hasAllEvidence
        ? 'combined-screening'
        : 'partial-analysis';

    final missingText = missingModules.isEmpty
        ? 'All available module results were combined.'
        : 'Missing modules: ${missingModules.join(', ')}.';

    final missingTextHindi = missingModules.isEmpty
        ? 'सभी उपलब्ध मॉड्यूल परिणामों को जोड़ा गया है।'
        : 'अनुपलब्ध मॉड्यूल: ${missingModules.join(', ')}।';

    final result = FeedTestResult(
      id: completedAt.microsecondsSinceEpoch.toString(),
      feedType: _selectedFeed,
      testType: 'Complete Test',
      score: score,
      riskLevel: isFullyValidated ? 'SCREENED' : 'UNVERIFIED',
      phValue: phResult?.estimatedPh ?? 0,
      nutritionStatus: nutritionStatus,
      impurityStatus: impurityStatus,
      recommendationEnglish:
          '$missingText This combined result is screening guidance only. Confirm suspicious or important feeding decisions using calibrated testing and qualified expert advice.',
      recommendationHindi:
          '$missingTextHindi यह संयुक्त परिणाम केवल स्क्रीनिंग मार्गदर्शन है। संदिग्ध या महत्वपूर्ण चारा निर्णय की पुष्टि कैलिब्रेटेड जाँच और योग्य विशेषज्ञ की सलाह से करें।',
      createdAt: completedAt,
      sampleId: nirReading.sampleId,
      batchId: batchId,
      animalType: animalType,
      animalBreed: animalBreed,
      productionGoal: productionGoal,
      dataSource: dataSource,
      deviceId: nirReading.device,
      firmwareVersion: nirReading.firmwareVersion,
      calibrationVersion: nirReading.calibrationVersion,
      moisture: nirReading.moisture,
      protein: nirReading.protein,
      fiber: nirReading.fiber,
      fat: nirReading.fat,
      ash: nirReading.ash,
      isLaboratoryValidated: isFullyValidated,
    );

    await _historyStorage.saveResult(result);

    if (!mounted) return;

    setState(() {
      _activeStep = -1;
      _isRunning = false;
      _latestResult = result;
      _showResult = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text('Result saved offline.', 'परिणाम ऑफलाइन सुरक्षित किया गया।'),
        ),
        backgroundColor: ParakhColors.forestGreen,
      ),
    );
  }

  @override
  void dispose() {
    _sampleIdController.dispose();
    _batchIdController.dispose();
    super.dispose();
  }

  void _resetTest() {
    _sampleIdController.clear();
    _batchIdController.clear();
    setState(() {
      _isRunning = false;
      _showResult = false;
      _latestResult = null;

      for (var i = 0; i < _completedSteps.length; i++) {
        _completedSteps[i] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F2),
        surfaceTintColor: Colors.transparent,
        title: Text(
          _text('Complete Feed Test', 'संपूर्ण चारा जाँच'),
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                if (!_showResult) ...[
                  _buildFeedSelector(),
                  const SizedBox(height: 18),
                  _buildTestSteps(),
                  const SizedBox(height: 21),
                  _buildStartButton(),
                ],
                if (_showResult) _buildFinalResult(),
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
          colors: [Color(0xFF4E386C), Color(0xFF8063A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0x24FFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFF0D98C),
              size: 32,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(
                    'Combined quality analysis',
                    'संयुक्त गुणवत्ता विश्लेषण',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _text(
                    'NIR, camera and pH findings are combined into one result.',
                    'NIR, कैमरा और pH परिणामों को एक संयुक्त नतीजे में बदला जाता है।',
                  ),
                  style: const TextStyle(
                    color: Color(0xFFE6DCEF),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedSelector() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _sampleIdController,
            enabled: !_isRunning,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: _text('Sample ID (optional)', 'नमूना आईडी (वैकल्पिक)'),
              hintText: 'Example: SAMPLE-001',
              prefixIcon: const Icon(Icons.qr_code_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _batchIdController,
            enabled: !_isRunning,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: _text('Batch ID (optional)', 'बैच आईडी (वैकल्पिक)'),
              hintText: 'Example: BATCH-2026-01',
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedFeed),
            initialValue: _selectedFeed,
            decoration: InputDecoration(
              labelText: _text('Feed type', 'चारे का प्रकार'),
              prefixIcon: const Icon(Icons.grass_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Maize Silage',
                child: Text('Maize Silage'),
              ),
              DropdownMenuItem(
                value: 'Wheat Straw',
                child: Text('Wheat Straw'),
              ),
              DropdownMenuItem(
                value: 'Green Fodder',
                child: Text('Green Fodder'),
              ),
              DropdownMenuItem(
                value: 'Concentrate Feed',
                child: Text('Concentrate Feed'),
              ),
              DropdownMenuItem(
                value: 'Cattle Feed Pellets',
                child: Text('Cattle Feed Pellets'),
              ),
            ],
            onChanged: _isRunning
                ? null
                : (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedFeed = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildTestSteps() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: Column(
        children: [
          _testStep(
            index: 0,
            icon: Icons.sensors_rounded,
            title: _text('NIR nutrient scan', 'NIR पोषक तत्व स्कैन'),
            subtitle: _text(
              'Moisture, protein, fibre, fat and ash',
              'नमी, प्रोटीन, फाइबर, वसा और राख',
            ),
            color: const Color(0xFF2F7650),
          ),
          _stepDivider(),
          _testStep(
            index: 1,
            icon: Icons.camera_alt_rounded,
            title: _text('Visual impurity check', 'दृश्य अशुद्धता जाँच'),
            subtitle: _text(
              'Sand, stones, mould and foreign material',
              'रेत, पत्थर, फफूंद और बाहरी पदार्थ',
            ),
            color: const Color(0xFFD17B3F),
          ),
          _stepDivider(),
          _testStep(
            index: 2,
            icon: Icons.science_rounded,
            title: _text('pH estimation', 'pH अनुमान'),
            subtitle: _text(
              'Camera-based strip colour reading',
              'कैमरा आधारित स्ट्रिप रंग जाँच',
            ),
            color: const Color(0xFF3D70A8),
          ),
          _stepDivider(),
          _testStep(
            index: 3,
            icon: Icons.hub_rounded,
            title: _text('Data fusion', 'डेटा फ्यूजन'),
            subtitle: _text(
              'Score, risk and recommendation',
              'स्कोर, जोखिम और सुझाव',
            ),
            color: const Color(0xFF8063A6),
          ),
        ],
      ),
    );
  }

  Widget _stepDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 22),
      child: Divider(height: 25),
    );
  }

  Widget _testStep({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final completed = _completedSteps[index];
    final active = _activeStep == index;

    return Row(
      children: [
        Container(
          width: 47,
          height: 47,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF26342B),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF7B847D), fontSize: 11),
              ),
            ],
          ),
        ),
        if (active)
          const SizedBox(
            width: 23,
            height: 23,
            child: CircularProgressIndicator(
              color: ParakhColors.forestGreen,
              strokeWidth: 3,
            ),
          )
        else
          Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: completed
                ? const Color(0xFF32834C)
                : const Color(0xFFB7C0B8),
          ),
      ],
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: _isRunning ? null : _startCompleteTest,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF8063A6),
          disabledBackgroundColor: const Color(0xFFB4A5C4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(
          _isRunning
              ? _text('Running complete test...', 'संपूर्ण जाँच जारी है...')
              : _text('Start complete test', 'संपूर्ण जाँच शुरू करें'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _nutritionStatusLabel(String status) {
    switch (status) {
      case 'Needs review':
        return _text('Needs review', 'समीक्षा आवश्यक');
      case 'Caution':
        return _text('Caution', 'सावधानी');
      case 'Within prototype range':
        return _text('Within prototype range', 'प्रोटोटाइप सीमा में');
      default:
        return status;
    }
  }

  Widget _buildFinalResult() {
    final result = _latestResult;

    if (result == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF795315), Color(0xFFB47B20)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.science_rounded,
                color: Color(0xFFFFE0A3),
                size: 47,
              ),
              const SizedBox(height: 10),
              Text(
                _text('Prototype combined result', 'प्रोटोटाइप संयुक्त परिणाम'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                result.feedType,
                style: const TextStyle(color: Color(0xFFFFE8BB)),
              ),
              const SizedBox(height: 17),
              Text(
                '${result.score}/100',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF66440F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _text('UNVERIFIED', 'असत्यापित'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _text(
                  'Prototype screening score—not a laboratory result',
                  'प्रोटोटाइप स्क्रीनिंग स्कोर—प्रयोगशाला परिणाम नहीं',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFE8BB),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildSummaryCard(),
        const SizedBox(height: 18),
        _buildRecommendation(),
        const SizedBox(height: 14),
        _buildOfflineSavedCard(),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _resetTest,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(_text('Start another test', 'नई जाँच शुरू करें')),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final result = _latestResult;

    if (result == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: Column(
        children: [
          _summaryRow(
            _text('NIR nutrition', 'NIR पोषण'),
            _nutritionStatusLabel(result.nutritionStatus),
            const Color(0xFFC48526),
          ),
          const Divider(height: 25),
          _summaryRow(
            _text('Camera findings', 'कैमरा निष्कर्ष'),
            _text('Not analysed', 'विश्लेषण नहीं हुआ'),
            const Color(0xFF8063A6),
          ),
          const Divider(height: 25),
          _summaryRow(
            _text('pH result', 'pH परिणाम'),
            _text(
              'Prototype ${result.phValue.toStringAsFixed(1)}',
              'प्रोटोटाइप ${result.phValue.toStringAsFixed(1)}',
            ),
            const Color(0xFF3D70A8),
          ),
          const Divider(height: 25),
          _summaryRow(
            _text('Overall validation', 'समग्र सत्यापन'),
            _text('Not validated', 'सत्यापित नहीं'),
            const Color(0xFFB75B4A),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF566158),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendation() {
    final result = _latestResult;

    if (result == null) {
      return const SizedBox.shrink();
    }

    final recommendation = widget.isHindi
        ? result.recommendationHindi
        : result.recommendationEnglish;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8C979)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFC48526)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text('Prototype guidance', 'प्रोटोटाइप मार्गदर्शन'),
                  style: const TextStyle(
                    color: Color(0xFF735B2E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  recommendation,
                  style: const TextStyle(
                    color: Color(0xFF735B2E),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _text(
                    'Camera AI and calibrated pH analysis are not connected in this prototype.',
                    'इस प्रोटोटाइप में कैमरा AI और कैलिब्रेटेड pH विश्लेषण कनेक्ट नहीं हैं।',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF8A6418),
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineSavedCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FA),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.offline_pin_rounded, color: Color(0xFF3D70A8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _text(
                'Result prepared for offline storage',
                'परिणाम ऑफलाइन सुरक्षित करने के लिए तैयार है',
              ),
              style: const TextStyle(
                color: Color(0xFF3D5E7C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
