import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../core/theme/parakh_colors.dart';
import '../device/device_connection_screen.dart';
import '../analysis/nir_analysis_screen.dart';
import '../ph_analysis/ph_analysis_screen.dart';
import '../complete_test/complete_test_screen.dart';
import '../history/history_screen.dart';
import '../advice/advice_screen.dart';
import '../settings/settings_screen.dart';
import '../animal_profile/animal_profile_screen.dart';
import '../storage_monitoring/storage_monitoring_screen.dart';
import '../sakhi/sakhi_assistant_screen.dart';
import '../../core/models/feed_test_result.dart';
import '../../core/storage/test_history_storage.dart';
import '../../core/services/parakh_bluetooth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.isHindi, super.key});
  final bool isHindi;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool _isHindi;
  bool _isDeviceConnected = false;
  bool _isDemoMode = false;
  final ParakhBluetoothService _bluetoothService =
      ParakhBluetoothService.instance;
  StreamSubscription<bool>? _deviceConnectionSubscription;
  final GlobalKey _headerControlsTutorialKey = GlobalKey();
  final GlobalKey _deviceTutorialKey = GlobalKey();
  final GlobalKey _nirTutorialKey = GlobalKey();
  final GlobalKey _phTutorialKey = GlobalKey();
  final GlobalKey _animalProfileTutorialKey = GlobalKey();
  final GlobalKey _storageTutorialKey = GlobalKey();
  final GlobalKey _completeTestTutorialKey = GlobalKey();
  final GlobalKey _sakhiTutorialKey = GlobalKey();
  final GlobalKey _navigationTutorialKey = GlobalKey();
  final TestHistoryStorage _testHistoryStorage = TestHistoryStorage();
  List<FeedTestResult> _recentTests = [];
  bool _isLoadingRecentTests = true;
  TutorialCoachMark? _tutorialCoachMark;
  final SpeechToText _wakeSpeech = SpeechToText();
  Timer? _wakeRestartTimer;
  bool _wakeModeEnabled = false;
  bool _wakeSpeechAvailable = false;
  bool _isOpeningSakhi = false;
  final ScrollController _homeScrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _isDeviceConnected = _bluetoothService.isConnected;
    _deviceConnectionSubscription = _bluetoothService.connectionChanges.listen((
      connected,
    ) {
      if (!mounted) return;
      setState(() {
        _isDeviceConnected = connected;
      });
    });
    _isHindi = widget.isHindi;
    _loadDemoMode();
    _loadWakeMode();
    _loadRecentTests();
    _scheduleFirstTutorial();
  }

  Future<void> _loadDemoMode() async {
    final preferences = await SharedPreferences.getInstance();
    final enabled = preferences.getBool('demoMode') ?? false;
    if (!mounted) return;
    setState(() {
      _isDemoMode = enabled;
    });
  }

  String _text(String english, String hindi) {
    return _isHindi ? hindi : english;
  }

  Future<void> _toggleLanguage() async {
    final newLanguage = !_isHindi;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('language', newLanguage ? 'hi' : 'en');
    if (!mounted) return;
    setState(() {
      _isHindi = newLanguage;
    });
    if (_wakeModeEnabled) {
      _wakeRestartTimer?.cancel();
      if (_wakeSpeech.isListening) {
        await _wakeSpeech.stop();
      }
      if (mounted) {
        await _startWakeListening();
      }
    }
  }

  Future<void> _openSakhi() async {
    if (_isOpeningSakhi) return;
    _isOpeningSakhi = true;
    _wakeRestartTimer?.cancel();
    if (_wakeSpeech.isListening) {
      await _wakeSpeech.stop();
    }
    if (!mounted) {
      _isOpeningSakhi = false;
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SakhiAssistantScreen(isHindi: _isHindi),
      ),
    );
    _isOpeningSakhi = false;
    if (mounted && _wakeModeEnabled) {
      await _startWakeListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              controller: _homeScrollController,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildWelcomeCard(),
                const SizedBox(height: 22),
                _buildSectionTitle(_text('Device status', 'डिवाइस की स्थिति')),
                const SizedBox(height: 12),
                _buildDeviceCard(),
                const SizedBox(height: 24),
                _buildSectionTitle(
                  _text('Start an analysis', 'जाँच शुरू करें'),
                ),
                const SizedBox(height: 12),
                _buildAnalysisGrid(),
                const SizedBox(height: 24),
                _buildRecentTests(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: _sakhiTutorialKey,
        onPressed: _openSakhi,
        backgroundColor: ParakhColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 5,
        icon: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset('assets/images/sakhi.png', fit: BoxFit.cover),
          ),
        ),
        label: Text(
          _text('Ask Sakhi', 'सखी से पूछें'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ParakhColors.forestGreen,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 27),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PARAKH',
                style: TextStyle(
                  color: ParakhColors.forestGreen,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                _text(
                  'Better Feed, Healthier Herds',
                  'बेहतर चारा, स्वस्थ पशुधन',
                ),
                style: const TextStyle(
                  color: Color(0xFF667268),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Row(
          key: _headerControlsTutorialKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: _wakeModeEnabled
                  ? _text('Disable Hey Sakhi', 'हे सखी बंद करें')
                  : _text('Enable Hey Sakhi', 'हे सखी चालू करें'),
              onPressed: _toggleWakeMode,
              icon: Icon(
                _wakeModeEnabled
                    ? (_wakeSpeech.isListening
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded)
                    : Icons.mic_off_rounded,
                color: _wakeModeEnabled && _wakeSpeechAvailable
                    ? ParakhColors.forestGreen
                    : const Color(0xFF7A847D),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: _toggleLanguage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDE5DA)),
                ),
                child: Text(
                  _isHindi ? 'EN' : 'हिं',
                  style: const TextStyle(
                    color: ParakhColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _loadRecentTests() async {
    final results = await _testHistoryStorage.getResults();
    if (!mounted) return;
    setState(() {
      _recentTests = results.take(3).toList();
      _isLoadingRecentTests = false;
    });
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => HistoryScreen(isHindi: _isHindi)),
    );
    if (!mounted) return;
    await _loadRecentTests();
  }

  String _formatRecentTestDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]}, '
        '$hour:$minute $period';
  }

  Future<void> _loadWakeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final enabled = preferences.getBool('sakhiWakeModeEnabled') ?? false;
    if (!mounted) return;
    setState(() {
      _wakeModeEnabled = enabled;
    });
    if (enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startWakeListening();
        }
      });
    }
  }

  Future<void> _toggleWakeMode() async {
    final enabled = !_wakeModeEnabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('sakhiWakeModeEnabled', enabled);
    if (!mounted) return;
    setState(() {
      _wakeModeEnabled = enabled;
    });
    if (enabled) {
      await _startWakeListening();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Wake mode enabled. Say “Hey Sakhi”.',
              'वेक मोड चालू है। “हे सखी” कहें।',
            ),
          ),
          backgroundColor: ParakhColors.forestGreen,
        ),
      );
    } else {
      _wakeRestartTimer?.cancel();
      await _wakeSpeech.stop();
      if (!mounted) return;
      setState(() {
        _wakeSpeechAvailable = false;
      });
    }
  }

  Future<void> _startWakeListening() async {
    if (!_wakeModeEnabled || _isOpeningSakhi || _wakeSpeech.isListening) {
      return;
    }
    final available = await _wakeSpeech.initialize(
      onStatus: _handleWakeStatus,
      onError: (error) {
        debugPrint('Sakhi wake listener error: $error');
        _scheduleWakeRestart();
      },
    );
    if (!mounted) return;
    setState(() {
      _wakeSpeechAvailable = available;
    });
    if (!available || !_wakeModeEnabled || _isOpeningSakhi) {
      return;
    }
    await _wakeSpeech.listen(
      onResult: _handleWakeResult,
      listenOptions: SpeechListenOptions(
        localeId: _isHindi ? 'hi_IN' : 'en_IN',
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _handleWakeStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _scheduleWakeRestart();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _scheduleWakeRestart() {
    _wakeRestartTimer?.cancel();
    if (!_wakeModeEnabled || _isOpeningSakhi) return;
    _wakeRestartTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _startWakeListening();
      }
    });
  }

  void _handleWakeResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.toLowerCase().trim();
    if (words.isEmpty) return;
    final wakeDetected =
        words.contains('hey sakhi') ||
        words.contains('hi sakhi') ||
        words.contains('hello sakhi') ||
        words.contains('हे सखी') ||
        words.contains('हाय सखी');
    if (wakeDetected) {
      _openSakhi();
    }
  }

  Future<void> _scheduleFirstTutorial() async {
    final preferences = await SharedPreferences.getInstance();
    final completed = preferences.getBool('homeTutorialCompleted') ?? false;
    if (!mounted || completed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showHomeTutorial();
    });
  }

  Future<void> _saveTutorialCompletion() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('homeTutorialCompleted', true);
  }

  Future<void> _scrollToCompleteTestAndContinue() async {
    final targetContext = _completeTestTutorialKey.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOut,
        alignment: 0.45,
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    if (!mounted) return;
    _tutorialCoachMark?.next();
  }

  void _showHomeTutorial() {
    final targets = <TargetFocus>[
      _tutorialTarget(
        id: 'header_controls',
        key: _headerControlsTutorialKey,
        title: _text('Voice assistant and language', 'वॉइस सहायक और भाषा'),
        description: _text(
          'Use the microphone to enable Hey Sakhi, and use the language button to switch between English and Hindi.',
          'हे सखी चालू करने के लिए माइक्रोफोन और अंग्रेजी एवं हिंदी बदलने के लिए भाषा बटन का उपयोग करें।',
        ),
        align: ContentAlign.bottom,
        showBack: false,
      ),
      _tutorialTarget(
        id: 'device',
        key: _deviceTutorialKey,
        title: _text('Connect the device', 'डिवाइस कनेक्ट करें'),
        description: _text(
          'Connect the Parakh portable device before starting a real NIR scan.',
          'वास्तविक NIR स्कैन शुरू करने से पहले परख पोर्टेबल डिवाइस कनेक्ट करें।',
        ),
        align: ContentAlign.bottom,
      ),
      _tutorialTarget(
        id: 'animal_profile',
        key: _animalProfileTutorialKey,
        title: _text('Add the animal profile', 'पशु प्रोफाइल जोड़ें'),
        description: _text(
          'Add the animal type, breed, stage and production goal before interpreting feed suitability.',
          'चारे की उपयुक्तता समझने से पहले पशु का प्रकार, नस्ल, अवस्था और उत्पादन लक्ष्य जोड़ें।',
        ),
        align: ContentAlign.top,
      ),
      _tutorialTarget(
        id: 'nir',
        key: _nirTutorialKey,
        title: _text('Run an NIR feed scan', 'NIR चारा स्कैन करें'),
        description: _text(
          'Use this option for camera screening and spectral feed analysis.',
          'कैमरा स्क्रीनिंग और स्पेक्ट्रल चारा विश्लेषण के लिए इस विकल्प का उपयोग करें।',
        ),
        align: ContentAlign.bottom,
      ),
      _tutorialTarget(
        id: 'ph',
        key: _phTutorialKey,
        title: _text('Test the pH strip', 'pH स्ट्रिप जाँचें'),
        description: _text(
          'Photograph the prepared pH strip under clear, neutral lighting.',
          'तैयार pH स्ट्रिप की साफ और सामान्य रोशनी में तस्वीर लें।',
        ),
        align: ContentAlign.bottom,
      ),
      _tutorialTarget(
        id: 'storage',
        key: _storageTutorialKey,
        title: _text('Review storage conditions', 'भंडारण स्थिति देखें'),
        description: _text(
          'Use Storage Monitor to screen temperature, humidity and storage risks.',
          'तापमान, आर्द्रता और भंडारण जोखिम देखने के लिए भंडारण निगरानी का उपयोग करें।',
        ),
        align: ContentAlign.top,
        onNext: _scrollToCompleteTestAndContinue,
      ),
      _tutorialTarget(
        id: 'complete_test',
        key: _completeTestTutorialKey,
        title: _text('Review the complete test', 'संपूर्ण जाँच देखें'),
        description: _text(
          'This section combines the available NIR, camera and pH evidence.',
          'यह भाग उपलब्ध NIR, कैमरा और pH परिणामों को एक साथ दिखाता है।',
        ),
        align: ContentAlign.top,
      ),
      _tutorialTarget(
        id: 'sakhi',
        key: _sakhiTutorialKey,
        title: _text('Ask Sakhi for help', 'सखी से सहायता लें'),
        description: _text(
          'Open Sakhi for bilingual guidance, voice questions and spoken answers.',
          'द्विभाषी मार्गदर्शन, आवाज में प्रश्न और बोले गए उत्तर के लिए सखी खोलें।',
        ),
        align: ContentAlign.top,
      ),
      _tutorialTarget(
        id: 'navigation',
        key: _navigationTutorialKey,
        title: _text('Explore Parakh', 'परख के विकल्प देखें'),
        description: _text(
          'Use this bar to open Home, History, Advice and Settings. The tutorial can be replayed from Settings.',
          'होम, इतिहास, सुझाव और सेटिंग्स खोलने के लिए इस पट्टी का उपयोग करें। ट्यूटोरियल सेटिंग्स से दोबारा चलाया जा सकता है।',
        ),
        align: ContentAlign.top,
        isLast: true,
      ),
    ];
    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF10251A),
      opacityShadow: 0.88,
      paddingFocus: 8,
      pulseEnable: true,
      textSkip: _text('SKIP', 'छोड़ें'),
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
      onFinish: () {
        _saveTutorialCompletion();
      },
      onSkip: () {
        _saveTutorialCompletion();
        return true;
      },
    );
    _tutorialCoachMark!.show(context: context);
  }

  TargetFocus _tutorialTarget({
    required String id,
    required GlobalKey key,
    required String title,
    required String description,
    required ContentAlign align,
    bool showBack = true,
    bool isLast = false,
    VoidCallback? onNext,
  }) {
    return TargetFocus(
      identify: id,
      keyTarget: key,
      shape: ShapeLightFocus.RRect,
      radius: 16,
      paddingFocus: 6,
      enableOverlayTab: false,
      enableTargetTab: false,
      contents: [
        TargetContent(
          align: align,
          child: _tutorialContent(
            title: title,
            description: description,
            showBack: showBack,
            isLast: isLast,
            onNext: onNext,
          ),
        ),
      ],
    );
  }

  Widget _tutorialContent({
    required String title,
    required String description,
    required bool showBack,
    required bool isLast,
    VoidCallback? onNext,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 330),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF174D35),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF435149),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showBack)
                TextButton(
                  onPressed: () => _tutorialCoachMark?.previous(),
                  child: Text(_text('Back', 'पीछे')),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => _tutorialCoachMark?.skip(),
                child: Text(_text('Skip', 'छोड़ें')),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: () {
                  if (isLast) {
                    _tutorialCoachMark?.finish();
                  } else if (onNext != null) {
                    onNext();
                  } else {
                    _tutorialCoachMark?.next();
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: ParakhColors.forestGreen,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isLast ? _text('Finish', 'पूरा करें') : _text('Next', 'आगे'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF174D35), Color(0xFF2F7650)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24174D35),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text('Namaste!', 'नमस्ते!'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _text(
                    'Check your feed quality and receive useful recommendations.',
                    'चारे की गुणवत्ता जाँचें और उपयोगी सुझाव प्राप्त करें।',
                  ),
                  style: const TextStyle(
                    color: Color(0xFFE4F0E7),
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0x24FFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              size: 38,
              color: Color(0xFFF1C75B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF1B2B21),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Future<void> _disconnectPortableDevice() async {
    try {
      await _bluetoothService.disconnect();
      if (!mounted) return;
      setState(() {
        _isDeviceConnected = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'PARAKH-01 disconnected successfully.',
              'PARAKH-01 सफलतापूर्वक डिस्कनेक्ट हो गया।',
            ),
          ),
          backgroundColor: const Color(0xFF6F796F),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Unable to disconnect the device.',
              'डिवाइस को डिस्कनेक्ट नहीं किया जा सका।',
            ),
          ),
          backgroundColor: const Color(0xFFB75B4A),
        ),
      );
    }
  }

  Widget _buildDeviceCard() {
    return Container(
      key: _deviceTutorialKey,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE2E9DF)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.bluetooth_rounded,
              color: ParakhColors.forestGreen,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text('Parakh portable device', 'परख पोर्टेबल डिवाइस'),
                  style: const TextStyle(
                    color: Color(0xFF243128),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isDeviceConnected
                      ? _text('Connected', 'कनेक्टेड')
                      : _text('Not connected', 'कनेक्ट नहीं है'),
                  style: TextStyle(
                    color: _isDeviceConnected
                        ? const Color(0xFF32834C)
                        : const Color(0xFF8A6257),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: _isDeviceConnected
                ? _disconnectPortableDevice
                : () async {
                    final connected = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) =>
                            DeviceConnectionScreen(isHindi: _isHindi),
                      ),
                    );
                    if (!mounted || connected != true) return;
                    setState(() {
                      _isDeviceConnected = true;
                    });
                  },
            style: FilledButton.styleFrom(
              backgroundColor: _isDeviceConnected
                  ? const Color(0xFFB75B4A)
                  : ParakhColors.forestGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            ),
            child: Text(
              _isDeviceConnected
                  ? _text('Disconnect', 'डिस्कनेक्ट करें')
                  : _text('Connect', 'कनेक्ट करें'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 13,
      mainAxisSpacing: 13,
      mainAxisExtent: 155,
      children: [
        _analysisCard(
          key: _nirTutorialKey,
          icon: Icons.sensors_rounded,
          title: _text('NIR Feed Scan', 'NIR चारा स्कैन'),
          subtitle: _text(
            'Camera and spectral scan',
            'कैमरा और स्पेक्ट्रल स्कैन',
          ),
          color: const Color(0xFF2F7650),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NirAnalysisScreen(
                  isHindi: _isHindi,
                  isDeviceConnected: _isDeviceConnected || _isDemoMode,
                ),
              ),
            );
          },
        ),
        _analysisCard(
          key: _phTutorialKey,
          icon: Icons.science_rounded,
          title: _text('pH Test', 'pH जाँच'),
          subtitle: _text(
            'Scan a pH test strip',
            'pH टेस्ट स्ट्रिप स्कैन करें',
          ),
          color: const Color(0xFF3D70A8),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PhAnalysisScreen(isHindi: _isHindi),
              ),
            );
          },
        ),
        _analysisCard(
          key: _animalProfileTutorialKey,
          icon: Icons.pets_rounded,
          title: _text('Animal Profile', 'पशु प्रोफाइल'),
          subtitle: _text('Animal, breed and goal', 'पशु, नस्ल और लक्ष्य'),
          color: const Color(0xFF8063A6),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AnimalProfileScreen(isHindi: _isHindi),
              ),
            );
          },
        ),
        _analysisCard(
          key: _storageTutorialKey,
          icon: Icons.warehouse_rounded,
          title: _text('Storage Monitor', 'भंडारण निगरानी'),
          subtitle: _text(
            'Storage-condition screening',
            'भंडारण स्थिति की जाँच',
          ),
          color: const Color(0xFF9A6815),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StorageMonitoringScreen(isHindi: _isHindi),
              ),
            );
          },
        ),
        _analysisCard(
          key: _completeTestTutorialKey,
          icon: Icons.assignment_turned_in_rounded,
          title: _text('Complete Test', 'संपूर्ण जाँच'),
          subtitle: _text('Review combined evidence', 'संयुक्त परिणाम देखें'),
          color: const Color(0xFFD17B3F),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CompleteTestScreen(
                  isHindi: _isHindi,
                  isDeviceConnected: _isDeviceConnected || _isDemoMode,
                ),
              ),
            );
            if (!mounted) return;
            await _loadRecentTests();
          },
        ),
      ],
    );
  }

  Widget _analysisCard({
    Key? key,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      key: key,
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFE2E9DF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF243128),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF788079), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTests() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE2E9DF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSectionTitle(_text('Recent tests', 'हाल की जाँच')),
              ),
              TextButton(
                onPressed: _openHistory,
                child: Text(
                  _text('View all', 'सभी देखें'),
                  style: const TextStyle(
                    color: ParakhColors.forestGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingRecentTests)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: CircularProgressIndicator(
                color: ParakhColors.forestGreen,
                strokeWidth: 2.5,
              ),
            )
          else if (_recentTests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: Color(0xFFAAB4AA),
                    size: 35,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _text('No tests recorded yet', 'अभी कोई जाँच दर्ज नहीं है'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF747E76),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_recentTests.length, (index) {
              final result = _recentTests[index];
              return Column(
                children: [
                  if (index > 0) const Divider(height: 22),
                  _buildRecentTestRow(result),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecentTestRow(FeedTestResult result) {
    final isLowRisk = result.riskLevel.toUpperCase() == 'LOW';
    final accentColor = isLowRisk
        ? const Color(0xFF32834C)
        : const Color(0xFFB75B4A);
    final accentBackground = isLowRisk
        ? const Color(0xFFE3F1E6)
        : const Color(0xFFFFECE7);
    return InkWell(
      onTap: _openHistory,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${result.score}',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.feedType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF26342B),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    result.sampleId == 'Not provided'
                        ? _formatRecentTestDate(result.createdAt)
                        : '${result.sampleId} • '
                              '${_formatRecentTestDate(result.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7B847D),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.testType} • ${result.riskLevel} RISK',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9BA49D)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return NavigationBar(
      key: _navigationTutorialKey,
      selectedIndex: 0,
      onDestinationSelected: (index) async {
        if (index == 1) {
          await _openHistory();
          return;
        }
        if (index == 2) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AdviceScreen(isHindi: _isHindi),
            ),
          );
          return;
        }
        if (index == 3) {
          final selectedLanguage = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => SettingsScreen(
                isHindi: _isHindi,
                isDeviceConnected: _isDeviceConnected || _isDemoMode,
              ),
            ),
          );
          if (!mounted) return;
          if (selectedLanguage != null) {
            setState(() {
              _isHindi = selectedLanguage;
            });
          }
          await _loadDemoMode();
          await _scheduleFirstTutorial();
        }
      },
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFDDEDE1),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: _text('Home', 'होम'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.history_rounded),
          label: _text('History', 'इतिहास'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.lightbulb_outline_rounded),
          label: _text('Advice', 'सुझाव'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          label: _text('Settings', 'सेटिंग्स'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _deviceConnectionSubscription?.cancel();
    _wakeRestartTimer?.cancel();
    _wakeSpeech.stop();
    _homeScrollController.dispose();
    super.dispose();
  }
}
