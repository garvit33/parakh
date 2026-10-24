import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/device_reading.dart';
import '../../core/services/parakh_bluetooth_service.dart';
import '../../core/models/calibration_record.dart';
import '../../core/storage/calibration_storage.dart';
import '../../core/models/feed_reference_profile.dart';
import '../../core/theme/parakh_colors.dart';
import '../../core/storage/latest_analysis_storage.dart';
import '../feed_identification/feed_identification_screen.dart';
import '../../core/services/parakh_pls_predictor.dart';
import '../animal_profile/animal_profile_screen.dart';

class NirAnalysisScreen extends StatefulWidget {
  const NirAnalysisScreen({
    required this.isHindi,
    required this.isDeviceConnected,
    super.key,
  });

  final bool isHindi;
  final bool isDeviceConnected;

  @override
  State<NirAnalysisScreen> createState() => _NirAnalysisScreenState();
}

class _NirAnalysisScreenState extends State<NirAnalysisScreen> {
  final TextEditingController _sampleIdController = TextEditingController();
  final ParakhBluetoothService _bluetoothService =
      ParakhBluetoothService.instance;
  late final Future<ParakhPlsPredictor> _plsPredictorFuture =
      ParakhPlsPredictor.load();
  final CalibrationStorage _calibrationStorage = CalibrationStorage();
  final FlutterTts _flutterTts = FlutterTts();
  final LatestAnalysisStorage _latestAnalysisStorage = LatestAnalysisStorage();
  String _selectedFeed = 'Concentrate Feed';
  bool _isScanning = false;
  bool _showResult = false;
  bool _visualScreeningCompleted = false;

  bool _hasAnimalProfile = false;

  bool _cameraScreeningSkipped = false;
  DeviceReading? _reading;
  double? _spectralReferenceMatch;
  bool _plsBoundaryReached = false;

  String _animalType = 'cow';
  String _animalBreed = 'Not sure';
  String _animalStage = 'lactating';
  String _productionGoal = 'maintenance';
  double? _animalWeight;
  double? _dailyMilkYield;
  double? _milkFatPercent;
  String _text(String english, String hindi) {
    return widget.isHindi ? hindi : english;
  }

  @override
  void initState() {
    super.initState();
    _configureVoice();
    _initialiseScan();
  }

  Future<void> _initialiseScan() async {
    await _loadAnimalProfile();
    await _loadNextSampleId();
  }

  Future<void> _loadNextSampleId() async {
    final preferences = await SharedPreferences.getInstance();
    final nextNumber = preferences.getInt('nextNirSampleNumber') ?? 1;

    if (!mounted) return;

    _sampleIdController.text = nextNumber.toString().padLeft(3, '0');
  }

  Future<void> _advanceSampleId() async {
    final preferences = await SharedPreferences.getInstance();
    final currentNumber = preferences.getInt('nextNirSampleNumber') ?? 1;
    final nextNumber = currentNumber + 1;

    await preferences.setInt('nextNirSampleNumber', nextNumber);

    if (!mounted) return;

    _sampleIdController.text = nextNumber.toString().padLeft(3, '0');
  }

  Future<void> _loadAnimalProfile() async {
    final preferences = await SharedPreferences.getInstance();

    final identifiedFeed = preferences.getString('identifiedFeedType');
    final animalType = preferences.getString('animalType') ?? 'cow';
    final animalBreed = preferences.getString('animalBreed') ?? 'Not sure';
    final animalStage = preferences.getString('animalStage') ?? 'lactating';
    final productionGoal =
        preferences.getString('productionGoal') ?? 'maintenance';

    final animalWeight = double.tryParse(
      preferences.getString('animalWeight') ?? '',
    );

    final dailyMilkYield = double.tryParse(
      preferences.getString('dailyMilkYield') ?? '',
    );

    final milkFatPercent = double.tryParse(
      preferences.getString('milkFatPercent') ?? '',
    );

    final hasSavedProfile =
        preferences.getBool('animalProfileCompleted') ??
        (animalBreed.trim().isNotEmpty &&
            animalBreed != 'Not sure' &&
            animalWeight != null &&
            animalWeight > 0);

    if (!mounted) return;

    setState(() {
      _animalType = animalType;
      _animalBreed = animalBreed;
      _animalStage = animalStage;
      _productionGoal = productionGoal;
      _animalWeight = animalWeight;
      _dailyMilkYield = dailyMilkYield;
      _milkFatPercent = milkFatPercent;
      _hasAnimalProfile = hasSavedProfile;

      if (identifiedFeed != null &&
          FeedReferenceProfile.forFeed(identifiedFeed) != null) {
        _selectedFeed = identifiedFeed;
      }
    });
  }

  Future<void> _configureVoice() async {
    await _flutterTts.setLanguage(widget.isHindi ? 'hi-IN' : 'en-IN');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _speak(String english, String hindi) async {
    await _flutterTts.stop();
    await _flutterTts.setLanguage(widget.isHindi ? 'hi-IN' : 'en-IN');
    await _flutterTts.speak(_text(english, hindi));
  }

  Future<bool> _openAnimalProfile() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AnimalProfileScreen(isHindi: widget.isHindi),
      ),
    );

    if (!mounted || saved != true) {
      return false;
    }

    await _loadAnimalProfile();

    if (!mounted) return false;

    return _hasAnimalProfile;
  }

  Future<bool> _completeVisualScreening() async {
    final identifiedFeed = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => FeedIdentificationScreen(isHindi: widget.isHindi),
      ),
    );

    if (!mounted || identifiedFeed == null) {
      return false;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('identifiedFeedType', identifiedFeed);

    if (!mounted) return false;

    setState(() {
      _selectedFeed = identifiedFeed;
      _visualScreeningCompleted = true;
      _cameraScreeningSkipped = false;
    });

    return true;
  }

  void _skipCameraScreening() {
    setState(() {
      _cameraScreeningSkipped = true;
      _visualScreeningCompleted = false;
    });
  }

  Future<void> _startScan() async {
    final messenger = ScaffoldMessenger.of(context);
    final focusScope = FocusScope.of(context);
    if (!_hasAnimalProfile) {
      final profileSaved = await _openAnimalProfile();

      if (!mounted) return;

      if (!profileSaved) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Please save the animal profile before starting the scan.',
                'स्कैन शुरू करने से पहले पशु प्रोफाइल सहेजें।',
              ),
            ),
            backgroundColor: const Color(0xFF9A6815),
          ),
        );
        return;
      }
    }

    if (!_visualScreeningCompleted && !_cameraScreeningSkipped) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Complete camera screening or tap Skip.',
              'कैमरा स्क्रीनिंग पूरी करें या छोड़ें दबाएँ।',
            ),
          ),
          backgroundColor: const Color(0xFF9A6815),
        ),
      );
      return;
    }
    /*if (!_visualScreeningCompleted) {
      final completed = await _completeVisualScreening();

      if (!mounted) return;

      if (!completed) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Complete the camera screening before the spectral scan.',
                'स्पेक्ट्रल स्कैन से पहले कैमरा स्क्रीनिंग पूरी करें।',
              ),
            ),
            backgroundColor: const Color(0xFF9A6815),
          ),
        );
        return;
      }
    }*/

    if (!mounted) return;

    if (!widget.isDeviceConnected) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Connect the Parakh device before starting.',
              'जाँच शुरू करने से पहले परख डिवाइस कनेक्ट करें।',
            ),
          ),
          backgroundColor: const Color(0xFFB75B4A),
        ),
      );
      return;
    }
    if (FeedReferenceProfile.forFeed(_selectedFeed) == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'This feed type does not have a validated reference profile yet. Select a supported feed type.',
              'इस चारे के प्रकार के लिए अभी मान्य संदर्भ प्रोफाइल उपलब्ध नहीं है। समर्थित चारे का प्रकार चुनें।',
            ),
          ),
          backgroundColor: const Color(0xFF9A6815),
        ),
      );
      return;
    }
    focusScope.unfocus();

    setState(() {
      _isScanning = true;
      _showResult = false;
      _reading = null;
      _spectralReferenceMatch = null;
      _plsBoundaryReached = false;
    });
    await HapticFeedback.heavyImpact();
    final enteredSampleId = _sampleIdController.text.trim();

    final sampleId = enteredSampleId.isEmpty
        ? (DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(
            5,
            '0',
          )
        : enteredSampleId;

    try {
      if (!_bluetoothService.isConnected) {
        throw StateError('PARAKH-01 Bluetooth connection was lost.');
      }

      // Start listening before sending the command so a fast response is not lost.
      final readingFuture = _bluetoothService.readings.firstWhere(
        (reading) => reading.sampleId == sampleId && reading.isComplete,
      );

      await _bluetoothService.startScan(
        sampleId: sampleId,
        feedType: _selectedFeed,
      );

      final reading = await readingFuture.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException(
            'The device did not return a scan within 20 seconds.',
          );
        },
      );
      if (!reading.hasSpectralData) {
        throw StateError(
          'The device response did not contain spectral channels.',
        );
      }

      final predictor = await _plsPredictorFuture;

      final prediction = predictor.predict(
        spectralChannels: reading.spectralChannels,
      );
      debugPrint('PARAKH RAW CHANNELS: ${reading.spectralChannels}');
      debugPrint(
        'PARAKH PLS: '
        'protein=${prediction.protein}, '
        'fat=${prediction.fat}, '
        'fibre=${prediction.fibre}',
      );
      final predictedReading = reading.withNutrientPrediction(
        protein: prediction.protein,
        fiber: prediction.fibre,
        fat: prediction.fat,
        calibrationVersion: 'pls-feed-mash-v0.1',
      );

      final calibrationRecord = CalibrationRecord.pending(
        id: '${predictedReading.sampleId}-${predictedReading.receivedAt.microsecondsSinceEpoch}',
        reading: predictedReading,
        calibrationVersion: predictedReading.calibrationVersion,
      );

      try {
        await _calibrationStorage.saveRecord(calibrationRecord);
      } catch (_) {
        // Calibration logging must not prevent the raw result from being viewed.
      }

      await _latestAnalysisStorage.saveNirReading(predictedReading);
      await _advanceSampleId();

      if (!mounted) return;

      setState(() {
        _reading = predictedReading;
        _spectralReferenceMatch = prediction.referenceMatch;
        _plsBoundaryReached = prediction.reachedModelBoundary;

        _isScanning = false;
        _showResult = true;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isScanning = false;
        _showResult = false;
        _reading = null;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(_text('Scan failed: $error', 'स्कैन विफल हुआ: $error')),
          backgroundColor: const Color(0xFFB75B4A),
        ),
      );
    }
  }

  void _resetScan() {
    setState(() {
      _showResult = false;
      _reading = null;
      _visualScreeningCompleted = false;
      _cameraScreeningSkipped = false;
    });
  }

  @override
  void dispose() {
    _sampleIdController.dispose();

    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F2),
        surfaceTintColor: Colors.transparent,
        title: Text(
          _text('NIR Analysis', 'NIR विश्लेषण'),
          style: const TextStyle(
            color: Color(0xFF1B2B21),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _text('Hear instructions', 'निर्देश सुनें'),
            icon: const Icon(Icons.volume_up_rounded),
            onPressed: () {
              _speak(
                'Place the feed sample inside the chamber. Close the chamber, then press and hold the scan button.',
                'चारे का नमूना चैम्बर में रखें। चैम्बर बंद करें, फिर स्कैन बटन को दबाकर रखें।',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                _buildDeviceStatus(),
                const SizedBox(height: 18),
                if (!_showResult) ...[
                  _buildAnimalProfileSetupCard(),
                  const SizedBox(height: 18),
                  _buildSampleForm(),
                  const SizedBox(height: 18),
                  _buildVisualScreeningCard(),
                  const SizedBox(height: 18),
                  _buildPreparationCard(),
                  const SizedBox(height: 22),
                  _buildScanButton(),
                ],
                if (_showResult) _buildResult(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceStatus() {
    final connected = widget.isDeviceConnected;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: connected ? const Color(0xFFE3F1E6) : const Color(0xFFFFECE7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            connected
                ? Icons.bluetooth_connected_rounded
                : Icons.bluetooth_disabled_rounded,
            color: connected
                ? const Color(0xFF32834C)
                : const Color(0xFFB75B4A),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              connected
                  ? _text(
                      'PARAKH-01 is ready for scanning',
                      'PARAKH-01 स्कैन के लिए तैयार है',
                    )
                  : _text(
                      'Parakh device is not connected',
                      'परख डिवाइस कनेक्ट नहीं है',
                    ),
              style: TextStyle(
                color: connected
                    ? const Color(0xFF28653B)
                    : const Color(0xFF8F493B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleForm() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text('Sample details', 'नमूने का विवरण'),
            style: const TextStyle(
              color: Color(0xFF1B2B21),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _sampleIdController,
            decoration: InputDecoration(
              labelText: _text('Sample ID', 'नमूना आईडी'),
              hintText: '001',
              helperText: _text(
                'Generated automatically. You can change it.',
                'स्वचालित रूप से बनाया गया है। आप इसे बदल सकते हैं।',
              ),
              prefixIcon: const Icon(Icons.qr_code_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (value) {
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

  Widget _buildAnimalProfileSetupCard() {
    final completed = _hasAnimalProfile;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFE3F1E6) : const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: completed ? const Color(0xFFC5DFC9) : const Color(0xFFEAD8A4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle_rounded : Icons.pets_rounded,
            color: completed
                ? const Color(0xFF32834C)
                : const Color(0xFF9A6815),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text('Animal profile', 'पशु प्रोफाइल'),
                  style: const TextStyle(
                    color: Color(0xFF26372D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  completed
                      ? _text(
                          '$_animalType • $_animalBreed • ${_productionGoalLabel()}',
                          '$_animalType • $_animalBreed • ${_productionGoalLabel()}',
                        )
                      : _text(
                          'Required for goal-based guidance',
                          'लक्ष्य आधारित मार्गदर्शन के लिए आवश्यक',
                        ),
                  style: const TextStyle(
                    color: Color(0xFF667169),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _isScanning ? null : _openAnimalProfile,
            child: Text(
              completed ? _text('Edit', 'बदलें') : _text('Add', 'जोड़ें'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualScreeningCard() {
    final completed = _visualScreeningCompleted;
    final skipped = _cameraScreeningSkipped;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFFE3F1E6)
            : skipped
            ? const Color(0xFFF0F2EF)
            : const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: completed
              ? const Color(0xFFC5DFC9)
              : skipped
              ? const Color(0xFFD9DFD8)
              : const Color(0xFFEAD8A4),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : skipped
                    ? Icons.fast_forward_rounded
                    : Icons.camera_alt_rounded,
                color: completed
                    ? const Color(0xFF32834C)
                    : skipped
                    ? const Color(0xFF667169)
                    : const Color(0xFF9A6815),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text('Camera feed screening', 'कैमरा चारा स्क्रीनिंग'),
                      style: const TextStyle(
                        color: Color(0xFF26372D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      completed
                          ? _text(
                              'Completed • $_selectedFeed',
                              'पूर्ण • $_selectedFeed',
                            )
                          : skipped
                          ? _text(
                              'Skipped for this sample',
                              'इस नमूने के लिए छोड़ा गया',
                            )
                          : _text(
                              'Optional visual impurity screening',
                              'वैकल्पिक दृश्य अशुद्धता स्क्रीनिंग',
                            ),
                      style: const TextStyle(
                        color: Color(0xFF667169),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isScanning ? null : _completeVisualScreening,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(
                    completed
                        ? _text('Retake', 'दोबारा लें')
                        : _text('Start camera', 'कैमरा शुरू करें'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: _isScanning ? null : _skipCameraScreening,
                child: Text(_text('Skip', 'छोड़ें')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlsModelStatusCard() {
    final match = _spectralReferenceMatch;

    if (match == null) {
      return const SizedBox.shrink();
    }

    final Color accent;
    final String matchLabel;

    if (match >= 80) {
      accent = const Color(0xFF2F7D4A);
      matchLabel = _text(
        'Close to trained references',
        'प्रशिक्षित संदर्भों के करीब',
      );
    } else if (match >= 50) {
      accent = const Color(0xFF9A6815);
      matchLabel = _text('Moderate reference match', 'मध्यम संदर्भ मिलान');
    } else {
      accent = const Color(0xFFB45545);
      matchLabel = _text(
        'Outside current reference range',
        'वर्तमान संदर्भ सीमा से बाहर',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.multiline_chart_rounded, color: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _text('Spectral reference match', 'स्पेक्ट्रल संदर्भ मिलान'),
                  style: const TextStyle(
                    color: Color(0xFF26372D),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${match.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            matchLabel,
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
          if (_plsBoundaryReached) ...[
            const SizedBox(height: 9),
            Text(
              _text(
                'One or more nutrient estimates reached the current model boundary.',
                'एक या अधिक पोषक अनुमान वर्तमान मॉडल सीमा तक पहुँच गए।',
              ),
              style: const TextStyle(
                color: Color(0xFF9A6815),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _text(
              'Prototype comparison with manufacturer-labelled feed references. This is not a laboratory accuracy score.',
              'निर्माता-लेबल वाले चारा संदर्भों से प्रोटोटाइप तुलना। यह प्रयोगशाला सटीकता स्कोर नहीं है।',
            ),
            style: const TextStyle(
              color: Color(0xFF7A847D),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFC48526)),
              const SizedBox(width: 9),
              Text(
                _text('Before scanning', 'स्कैन से पहले'),
                style: const TextStyle(
                  color: Color(0xFF735B2E),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _preparationStep(
            _text(
              'Spread the sample evenly in the test chamber.',
              'नमूने को टेस्ट चैम्बर में समान रूप से फैलाएँ।',
            ),
          ),
          _preparationStep(
            _text(
              'Keep the sample surface clean and still.',
              'नमूने की सतह साफ और स्थिर रखें।',
            ),
          ),
          _preparationStep(
            _text(
              'Close the chamber before starting.',
              'जाँच शुरू करने से पहले चैम्बर बंद करें।',
            ),
          ),
        ],
      ),
    );
  }

  Widget _preparationStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: CircleAvatar(radius: 3, backgroundColor: Color(0xFFC48526)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF735B2E),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    final buttonColor = _isScanning
        ? const Color(0xFF9DB5A5)
        : ParakhColors.forestGreen;

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: Material(
        color: buttonColor,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: _isScanning
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _text(
                          'Press and hold to start scanning.',
                          'स्कैन शुरू करने के लिए दबाकर रखें।',
                        ),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
          onLongPress: _isScanning
              ? null
              : () async {
                  await HapticFeedback.mediumImpact();
                  await _startScan();
                },
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isScanning)
                  const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                else
                  const Icon(Icons.touch_app_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  _isScanning
                      ? _text(
                          'Analysing sample...',
                          'नमूने की जाँच हो रही है...',
                        )
                      : _text(
                          'Hold to start NIR scan',
                          'NIR स्कैन के लिए दबाकर रखें',
                        ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<int> _readingRiskLevels(DeviceReading reading) {
    final profile = FeedReferenceProfile.forFeed(_selectedFeed);

    if (profile == null) {
      return const [];
    }

    final isPlsFeedMash = reading.calibrationVersion == 'pls-feed-mash-v0.1';

    if (isPlsFeedMash) {
      return [
        profile.protein.riskLevel(reading.protein),
        profile.fiber.riskLevel(reading.fiber),
        profile.fat.riskLevel(reading.fat),
      ];
    }

    return [
      profile.moisture.riskLevel(reading.moisture),
      profile.protein.riskLevel(reading.protein),
      profile.fiber.riskLevel(reading.fiber),
      profile.fat.riskLevel(reading.fat),
      profile.ash.riskLevel(reading.ash),
    ];
  }

  int _overallRisk(DeviceReading reading) {
    final levels = _readingRiskLevels(reading);

    if (levels.contains(2)) return 2;
    if (levels.contains(1)) return 1;
    return 0;
  }

  List<(String, int)> _scoreAdjustments(DeviceReading reading) {
    final adjustments = <(String, int)>[];
    final levels = _readingRiskLevels(reading);

    final isPlsFeedMash = reading.calibrationVersion == 'pls-feed-mash-v0.1';

    final metricLabels = isPlsFeedMash
        ? [
            _text(
              'Protein outside expected range',
              'प्रोटीन अपेक्षित सीमा से बाहर',
            ),
            _text(
              'Fibre outside expected range',
              'फाइबर अपेक्षित सीमा से बाहर',
            ),
            _text('Fat outside expected range', 'वसा अपेक्षित सीमा से बाहर'),
          ]
        : [
            _text(
              'Moisture outside expected range',
              'नमी अपेक्षित सीमा से बाहर',
            ),
            _text(
              'Protein outside expected range',
              'प्रोटीन अपेक्षित सीमा से बाहर',
            ),
            _text(
              'Fibre outside expected range',
              'फाइबर अपेक्षित सीमा से बाहर',
            ),
            _text('Fat outside expected range', 'वसा अपेक्षित सीमा से बाहर'),
            _text('Ash outside expected range', 'राख अपेक्षित सीमा से बाहर'),
          ];

    for (var index = 0; index < levels.length; index++) {
      final level = levels[index];

      if (level == 2) {
        adjustments.add((metricLabels[index], 20));
      } else if (level == 1) {
        adjustments.add((metricLabels[index], 8));
      }
    }

    switch (_productionGoal) {
      case 'weight_gain':
        if (reading.protein < 9) {
          adjustments.add((
            _text(
              'Protein below weight-gain target',
              'प्रोटीन वजन लक्ष्य से कम',
            ),
            8,
          ));
        }
        if (reading.fat < 3) {
          adjustments.add((
            _text(
              'Fat below energy indicator target',
              'वसा ऊर्जा संकेतक लक्ष्य से कम',
            ),
            5,
          ));
        }
        if (reading.fiber > 30) {
          adjustments.add((
            _text('Fibre above weight-gain target', 'फाइबर वजन लक्ष्य से अधिक'),
            5,
          ));
        }
        break;

      case 'milk_yield':
        if (reading.protein < 9) {
          adjustments.add((
            _text(
              'Protein below milk-yield target',
              'प्रोटीन दूध उत्पादन लक्ष्य से कम',
            ),
            10,
          ));
        }
        if (reading.fat < 3) {
          adjustments.add((
            _text(
              'Fat below energy indicator target',
              'वसा ऊर्जा संकेतक लक्ष्य से कम',
            ),
            4,
          ));
        }
        break;

      case 'milk_fat':
        if (reading.fiber < 25) {
          adjustments.add((
            _text('Fibre below milk-fat target', 'फाइबर दूध वसा लक्ष्य से कम'),
            10,
          ));
        }
        if (reading.fat < 3) {
          adjustments.add((
            _text(
              'Feed fat below prototype target',
              'चारे की वसा प्रोटोटाइप लक्ष्य से कम',
            ),
            5,
          ));
        }
        break;

      case 'maintenance':
        break;
    }

    if (_animalStage == 'lactating' && reading.protein < 8) {
      adjustments.add((
        _text(
          'Low protein for lactating stage',
          'दूध देने की अवस्था के लिए कम प्रोटीन',
        ),
        5,
      ));
    }

    return adjustments;
  }

  int _goalSuitabilityScore(DeviceReading reading) {
    final totalPenalty = _scoreAdjustments(reading)
        .fold<int>(0, (total, adjustment) => total + adjustment.$2);

    return (100 - totalPenalty).clamp(0, 100);
  }

  String _productionGoalLabel() {
    switch (_productionGoal) {
      case 'weight_gain':
        return _text('Weight gain', 'वजन बढ़ाना');
      case 'milk_yield':
        return _text('Milk yield', 'दूध उत्पादन');
      case 'milk_fat':
        return _text('Milk fat and SNF', 'दूध वसा और SNF');
      default:
        return _text('Maintenance', 'सामान्य रखरखाव');
    }
  }

  String _animalLabel() {
    return _animalType == 'buffalo'
        ? _text('Buffalo', 'भैंस')
        : _text('Cow', 'गाय');
  }

  String _stageLabel() {
    switch (_animalStage) {
      case 'growing':
        return _text('Growing', 'बढ़ता पशु');
      case 'pregnant':
        return _text('Pregnant', 'गर्भित');
      case 'dry':
        return _text('Dry period', 'शुष्क अवधि');
      default:
        return _text('Lactating', 'दूध देने वाला');
    }
  }

  Widget _profileChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2EC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ParakhColors.forestGreen),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF355743),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalContextCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pets_rounded, color: ParakhColors.forestGreen),
              const SizedBox(width: 9),
              Text(
                _text('Animal context', 'पशु की जानकारी'),
                style: const TextStyle(
                  color: Color(0xFF26372D),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${_animalLabel()} • $_animalBreed',
            style: const TextStyle(color: Color(0xFF667269), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _profileChip(Icons.flag_rounded, _productionGoalLabel()),
              _profileChip(Icons.timeline_rounded, _stageLabel()),
              if (_animalWeight != null)
                _profileChip(
                  Icons.monitor_weight_outlined,
                  '${_animalWeight!.toStringAsFixed(0)} kg',
                ),
              if (_animalStage == 'lactating' && _dailyMilkYield != null)
                _profileChip(
                  Icons.water_drop_outlined,
                  '${_dailyMilkYield!.toStringAsFixed(1)} L/day',
                ),
              if (_animalStage == 'lactating' && _milkFatPercent != null)
                _profileChip(
                  Icons.percent_rounded,
                  '${_milkFatPercent!.toStringAsFixed(1)}% milk fat',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreBreakdownRow({
    required String label,
    required String value,
    bool isFinal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF566158),
                fontSize: 13,
                fontWeight: isFinal ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isFinal
                  ? ParakhColors.forestGreen
                  : const Color(0xFF8F352C),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreExplanation(DeviceReading reading) {
    final adjustments = _scoreAdjustments(reading);
    final score = _goalSuitabilityScore(reading);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(
          Icons.calculate_outlined,
          color: ParakhColors.forestGreen,
        ),
        title: Text(
          _text('How was this score calculated?', 'यह स्कोर कैसे निकाला गया?'),
          style: const TextStyle(
            color: Color(0xFF26372D),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          _text(
            'View the prototype rules and deductions',
            'प्रोटोटाइप नियम और कटौती देखें',
          ),
          style: const TextStyle(color: Color(0xFF7A847D), fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          _scoreBreakdownRow(
            label: _text('Starting score', 'प्रारंभिक स्कोर'),
            value: '100',
          ),
          if (adjustments.isEmpty)
            _scoreBreakdownRow(
              label: _text(
                'No rule-based deductions',
                'कोई नियम आधारित कटौती नहीं',
              ),
              value: '0',
            ),
          for (final adjustment in adjustments)
            _scoreBreakdownRow(
              label: adjustment.$1,
              value: '-${adjustment.$2}',
            ),
          const Divider(height: 18),
          _scoreBreakdownRow(
            label: _text('Goal Suitability Index', 'लक्ष्य उपयुक्तता सूचकांक'),
            value: '$score/100',
            isFinal: true,
          ),
          const SizedBox(height: 8),
          Text(
            _text(
              'These prototype thresholds must be calibrated and validated against reference laboratory results before field claims are made.',
              'मैदानी दावे करने से पहले इन प्रोटोटाइप सीमाओं को संदर्भ प्रयोगशाला परिणामों के अनुसार कैलिब्रेट और सत्यापित करना आवश्यक है।',
            ),
            style: const TextStyle(
              color: Color(0xFF7A847D),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final reading = _reading;

    if (reading == null) {
      return const SizedBox.shrink();
    }
    final isRawHardwareScan =
        reading.hasSpectralData &&
        !reading.isSimulated &&
        reading.calibrationVersion.toLowerCase() == 'unvalidated';
    final risk = _overallRisk(reading);
    final score = _goalSuitabilityScore(reading);

    final List<Color> resultColors;
    final Color resultAccent;
    final IconData resultIcon;
    final String resultLabel;

    if (risk == 2) {
      resultColors = const [Color(0xFF7A2E27), Color(0xFFB54435)];
      resultAccent = const Color(0xFFFFC2B8);
      resultIcon = Icons.dangerous_rounded;
      resultLabel = _text(
        'Poor quality • High risk',
        'खराब गुणवत्ता • अधिक जोखिम',
      );
    } else if (risk == 1) {
      resultColors = const [Color(0xFF795315), Color(0xFFB47B20)];
      resultAccent = const Color(0xFFFFE0A3);
      resultIcon = Icons.warning_rounded;
      resultLabel = _text(
        'Moderate quality • Check values',
        'मध्यम गुणवत्ता • मान जाँचें',
      );
    } else {
      resultColors = const [Color(0xFF174D35), Color(0xFF2F7650)];
      resultAccent = const Color(0xFFBCE4C4);
      resultIcon = Icons.verified_rounded;
      resultLabel = _text(
        'Good quality • Low risk',
        'अच्छी गुणवत्ता • कम जोखिम',
      );
    }
    return Column(
      children: [
        if (isRawHardwareScan)
          _buildRawScanHeader(reading)
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: resultColors),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Icon(resultIcon, color: resultAccent, size: 45),
                const SizedBox(height: 10),
                Text(
                  _text('Analysis complete', 'विश्लेषण पूरा हुआ'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedFeed,
                  style: const TextStyle(
                    color: Color(0xFFDDEBE1),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  '$score/100',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _text('Goal Suitability Index', 'लक्ष्य उपयुक्तता सूचकांक'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _productionGoalLabel(),
                  style: TextStyle(
                    color: resultAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  resultLabel,
                  style: TextStyle(
                    color: resultAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        _buildScanInformationCard(reading),
        const SizedBox(height: 14),
        if (reading.calibrationVersion == 'pls-feed-mash-v0.1')
          _buildPlsModelStatusCard(),
        const SizedBox(height: 14),
        if (isRawHardwareScan) ...[
          _buildRawCalibrationNotice(),
          const SizedBox(height: 14),
          _buildRawSpectralCard(reading),
        ] else ...[
          _buildAnimalContextCard(),
          const SizedBox(height: 14),
          _buildScreeningNotice(),
          const SizedBox(height: 14),
          _buildScoreExplanation(reading),
          const SizedBox(height: 18),
          _buildMetricsCard(),
          const SizedBox(height: 18),
          _buildRecommendationCard(),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _resetScan,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              _text('Test another sample', 'दूसरे नमूने की जाँच करें'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRawScanHeader(DeviceReading reading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF174D35), Color(0xFF2F7650)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.multiline_chart_rounded,
            color: Color(0xFFBCE4C4),
            size: 45,
          ),
          const SizedBox(height: 10),
          Text(
            _text(
              'Raw spectral scan complete',
              'कच्चा स्पेक्ट्रल स्कैन पूरा हुआ',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reading.feedType,
            style: const TextStyle(color: Color(0xFFDDEBE1), fontSize: 13),
          ),
          const SizedBox(height: 17),
          Text(
            '${reading.spectralChannels.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 35,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _text('Spectral channels received', 'स्पेक्ट्रल चैनल प्राप्त हुए'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _text(
              'Hardware data captured successfully',
              'हार्डवेयर डेटा सफलतापूर्वक प्राप्त हुआ',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFBCE4C4),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawCalibrationNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E4),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE4C87A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.science_outlined,
            color: Color(0xFF9A6815),
            size: 24,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text('Calibration required', 'कैलिब्रेशन आवश्यक है'),
                  style: const TextStyle(
                    color: Color(0xFF795315),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _text(
                    'These are raw AS7343 spectral readings. Moisture, protein, fibre, fat, ash and quality scores cannot be calculated until a model is trained and validated using laboratory reference results.',
                    'ये कच्ची AS7343 स्पेक्ट्रल रीडिंग हैं। प्रयोगशाला संदर्भ परिणामों से मॉडल को प्रशिक्षित और सत्यापित किए बिना नमी, प्रोटीन, फाइबर, वसा, राख और गुणवत्ता स्कोर की गणना नहीं की जा सकती।',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF795315),
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawSpectralCard(DeviceReading reading) {
    const preferredOrder = [
      'F1',
      'F2',
      'FZ',
      'F3',
      'F4',
      'F5',
      'FY',
      'FXL',
      'F6',
      'F7',
      'F8',
      'NIR',
      'Clear',
    ];

    final orderedChannels = <MapEntry<String, double>>[];

    for (final channel in preferredOrder) {
      final value = reading.spectralChannels[channel];

      if (value != null) {
        orderedChannels.add(MapEntry(channel, value));
      }
    }

    for (final entry in reading.spectralChannels.entries) {
      if (!preferredOrder.contains(entry.key)) {
        orderedChannels.add(entry);
      }
    }

    String formatValue(double value) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }

      return value.toStringAsFixed(2);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.multiline_chart_rounded,
                color: ParakhColors.forestGreen,
              ),
              const SizedBox(width: 9),
              Text(
                _text('Raw spectral readings', 'कच्ची स्पेक्ट्रल रीडिंग'),
                style: const TextStyle(
                  color: Color(0xFF26372D),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _text(
              'Uncalibrated sensor counts from the AS7343',
              'AS7343 से प्राप्त बिना कैलिब्रेशन वाले सेंसर काउंट',
            ),
            style: const TextStyle(
              color: Color(0xFF7A847D),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(height: 25),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orderedChannels.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.35,
            ),
            itemBuilder: (context, index) {
              final entry = orderedChannels[index];

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7F2),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFDCE9DE)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          color: Color(0xFF4C5A50),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      formatValue(entry.value),
                      style: const TextStyle(
                        color: Color(0xFF174D35),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 13),
          Text(
            _text(
              'Compare readings only when distance, illumination, container, sample depth and sensor settings are kept constant.',
              'रीडिंग की तुलना तभी करें जब दूरी, रोशनी, कंटेनर, नमूने की गहराई और सेंसर सेटिंग समान रखी जाएँ।',
            ),
            style: const TextStyle(
              color: Color(0xFF6F796F),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanInformationCard(DeviceReading reading) {
    final sourceLabel = reading.isSimulated
        ? _text('Simulated demo', 'सिम्युलेटेड डेमो')
        : _text('Hardware scan', 'हार्डवेयर स्कैन');

    final qualityLabel = switch (reading.scanQuality) {
      'good' => _text('Good scan quality', 'अच्छी स्कैन गुणवत्ता'),
      'warning' => _text('Review scan quality', 'स्कैन गुणवत्ता जाँचें'),
      'poor' => _text('Poor scan quality', 'खराब स्कैन गुणवत्ता'),
      'demo' => _text('Demo quality', 'डेमो गुणवत्ता'),
      _ => _text('Quality not reported', 'गुणवत्ता उपलब्ध नहीं'),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory_rounded, color: ParakhColors.forestGreen),
              const SizedBox(width: 9),
              Text(
                _text('Scan information', 'स्कैन की जानकारी'),
                style: const TextStyle(
                  color: Color(0xFF26372D),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _profileChip(Icons.source_rounded, sourceLabel),
              _profileChip(Icons.sensors_rounded, reading.device),
              _profileChip(Icons.fact_check_outlined, qualityLabel),
              _profileChip(
                Icons.developer_board_rounded,
                'FW ${reading.firmwareVersion}',
              ),
              _profileChip(
                Icons.model_training_rounded,
                reading.calibrationVersion,
              ),
              if (reading.hasSpectralData)
                _profileChip(
                  Icons.multiline_chart_rounded,
                  _text(
                    '${reading.spectralChannels.length} spectral channels',
                    '${reading.spectralChannels.length} स्पेक्ट्रल चैनल',
                  ),
                ),
              if (!reading.hasSpectralData)
                _profileChip(
                  Icons.visibility_off_outlined,
                  _text('No raw spectrum', 'कच्चा स्पेक्ट्रम उपलब्ध नहीं'),
                ),
              if (reading.integrationTimeMs != null)
                _profileChip(
                  Icons.timer_outlined,
                  '${reading.integrationTimeMs} ms',
                ),
              if (reading.sensorGain != null)
                _profileChip(
                  Icons.tune_rounded,
                  'Gain ${reading.sensorGain!.toStringAsFixed(1)}×',
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _metricStatus({
    required double value,
    required MetricReferenceBand band,
  }) {
    final level = band.riskLevel(value);

    if (level == 0) {
      return _text('Good', 'अच्छा');
    }

    if (level == 1) {
      return _text('Caution', 'सावधानी');
    }

    return _text('Poor', 'खराब');
  }

  double? _moistureSpectralIndex(DeviceReading reading) {
    final nir = reading.spectralChannels['NIR']?.toDouble();
    final clear = reading.spectralChannels['Clear']?.toDouble();

    if (nir == null || clear == null || clear <= 0) {
      return null;
    }

    return (nir / clear * 100).clamp(0.0, 100.0).toDouble();
  }

  Widget _buildMetricsCard() {
    final reading = _reading;
    final profile = FeedReferenceProfile.forFeed(_selectedFeed);
    final isPlsFeedMash = reading?.calibrationVersion == 'pls-feed-mash-v0.4';

    final moistureIndex = reading == null
        ? null
        : _moistureSpectralIndex(reading);

    if (reading == null || profile == null) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text('Feed-specific assessment', 'चारा-विशिष्ट मूल्यांकन'),
            style: const TextStyle(
              color: Color(0xFF26372D),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.referenceLabel,
            style: const TextStyle(
              color: Color(0xFF7A847D),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(height: 25),
          _metricRow(
            isPlsFeedMash
                ? _text('Moisture spectral proxy', 'नमी स्पेक्ट्रल प्रॉक्सी')
                : _text('Moisture', 'नमी'),
            isPlsFeedMash
                ? moistureIndex?.toStringAsFixed(2) ?? '—'
                : '${reading.moisture.toStringAsFixed(1)}%',
            isPlsFeedMash
                ? _text('Review • Experimental', 'जाँच • प्रायोगिक')
                : _metricStatus(
                    value: reading.moisture,
                    band: profile.moisture,
                  ),
          ),
          const Divider(height: 25),
          _metricRow(
            _text('Crude protein', 'कच्चा प्रोटीन'),
            '${reading.protein.toStringAsFixed(2)}%',
            _metricStatus(value: reading.protein, band: profile.protein),
          ),
          const Divider(height: 25),
          _metricRow(
            _text('Fibre', 'फाइबर'),
            '${reading.fiber.toStringAsFixed(2)}%',
            _metricStatus(value: reading.fiber, band: profile.fiber),
          ),
          const Divider(height: 25),
          _metricRow(
            _text('Fat', 'वसा'),
            '${reading.fat.toStringAsFixed(2)}%',
            _metricStatus(value: reading.fat, band: profile.fat),
          ),
          _metricRow(
            _text('Ash', 'राख'),
            isPlsFeedMash ? '—' : '${reading.ash.toStringAsFixed(1)}%',
            isPlsFeedMash
                ? _text('Review • Not estimated', 'जाँच • अनुमान उपलब्ध नहीं')
                : _metricStatus(value: reading.ash, band: profile.ash),
          ),
          if (isPlsFeedMash) ...[
            const Divider(height: 25),
            Text(
              _text(
                'Moisture proxy is calculated from the NIR/Clear spectral ratio. It is not a calibrated moisture percentage. Ash is not estimated. Neither value is included in scoring.',
                'नमी प्रॉक्सी की गणना NIR/Clear स्पेक्ट्रल अनुपात से की जाती है। यह कैलिब्रेटेड नमी प्रतिशत नहीं है। राख का अनुमान उपलब्ध नहीं है। दोनों मान स्कोर में शामिल नहीं हैं।',
              ),
              style: const TextStyle(
                color: Color(0xFF7A847D),
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, String status) {
    final normalizedStatus = status.toLowerCase();

    final bool isDanger =
        normalizedStatus.contains('poor') ||
        normalizedStatus.contains('high') ||
        normalizedStatus.contains('low') ||
        normalizedStatus.contains('खराब') ||
        normalizedStatus.contains('अधिक') ||
        normalizedStatus.contains('कम');

    final bool isWarning =
        normalizedStatus.contains('caution') ||
        normalizedStatus.contains('check') ||
        normalizedStatus.contains('review') ||
        normalizedStatus.contains('सावधानी') ||
        normalizedStatus.contains('जाँच');

    final Color statusColor;
    final Color statusBackground;

    if (isDanger) {
      statusColor = const Color(0xFFB54435);
      statusBackground = const Color(0xFFFBE8E4);
    } else if (isWarning) {
      statusColor = const Color(0xFF9A6815);
      statusBackground = const Color(0xFFFFF1CF);
    } else {
      statusColor = const Color(0xFF32834C);
      statusBackground = const Color(0xFFE3F1E6);
    }

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.25),
                blurRadius: 5,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF566158),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1B2B21),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: statusBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreeningNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8C979)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF8A6418),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _text(
                'Estimated screening guidance based on the available sensor readings and animal profile. This is not a laboratory-certified result or a complete ration formulation.',
                'यह उपलब्ध सेंसर रीडिंग और पशु प्रोफाइल पर आधारित अनुमानित स्क्रीनिंग मार्गदर्शन है। यह प्रयोगशाला-प्रमाणित परिणाम या पूर्ण राशन निर्माण नहीं है।',
              ),
              style: const TextStyle(
                color: Color(0xFF74591E),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _goalGuidance(DeviceReading reading) {
    final profile = FeedReferenceProfile.forFeed(_selectedFeed);

    if (profile == null) {
      return _text(
        'No reference profile is available for this feed type. Get the sample reviewed before changing the ration.',
        'इस चारे के प्रकार के लिए संदर्भ प्रोफाइल उपलब्ध नहीं है। राशन बदलने से पहले नमूने की समीक्षा कराएँ।',
      );
    }

    final proteinNeedsAttention =
        profile.protein.riskLevel(reading.protein) > 0;
    final fatNeedsAttention = profile.fat.riskLevel(reading.fat) > 0;
    final fibreNeedsAttention = profile.fiber.riskLevel(reading.fiber) > 0;

    switch (_productionGoal) {
      case 'weight_gain':
        if (proteinNeedsAttention && fatNeedsAttention) {
          return _text(
            'For the weight-gain goal, the protein and fat indicators need attention relative to the $_selectedFeed reference profile. Ask a livestock nutrition expert to review suitable protein and energy sources for the complete ration.',
            'वजन बढ़ाने के लक्ष्य के लिए $_selectedFeed संदर्भ प्रोफाइल की तुलना में प्रोटीन और वसा संकेतकों पर ध्यान देने की आवश्यकता है। पूर्ण राशन के लिए उपयुक्त प्रोटीन और ऊर्जा स्रोतों की पशु पोषण विशेषज्ञ से समीक्षा कराएँ।',
          );
        }

        if (proteinNeedsAttention) {
          return _text(
            'For the weight-gain goal, the protein indicator needs attention relative to the selected feed profile. Ask an expert whether protein-rich fodder, legumes or a suitable oilseed cake can help balance the complete ration.',
            'वजन बढ़ाने के लक्ष्य के लिए चयनित चारा प्रोफाइल की तुलना में प्रोटीन संकेतक पर ध्यान देने की आवश्यकता है। विशेषज्ञ से पूछें कि प्रोटीनयुक्त चारा, दलहनी चारा या उपयुक्त खली पूरे राशन को संतुलित करने में मदद कर सकती है या नहीं।',
          );
        }

        return _text(
          'The available indicators broadly support the weight-gain goal for the selected feed profile. Confirm the complete energy, protein, fibre and mineral balance with a livestock nutrition expert.',
          'चयनित चारा प्रोफाइल के लिए उपलब्ध संकेतक वजन बढ़ाने के लक्ष्य का सामान्य रूप से समर्थन करते हैं। पूर्ण ऊर्जा, प्रोटीन, फाइबर और खनिज संतुलन की पशु पोषण विशेषज्ञ से पुष्टि कराएँ।',
        );

      case 'milk_yield':
        if (proteinNeedsAttention || fatNeedsAttention) {
          return _text(
            'For the milk-yield goal, the protein or fat indicator needs attention relative to the selected feed profile. Ask an expert to review the complete ration, energy sources and mineral mixture.',
            'दूध उत्पादन के लक्ष्य के लिए चयनित चारा प्रोफाइल की तुलना में प्रोटीन या वसा संकेतक पर ध्यान देने की आवश्यकता है। पूर्ण राशन, ऊर्जा स्रोतों और खनिज मिश्रण की विशेषज्ञ से समीक्षा कराएँ।',
          );
        }

        return _text(
          'The available indicators broadly support the milk-yield goal. Continue monitoring feed intake, milk output and body condition because this scan alone cannot determine the complete ration.',
          'उपलब्ध संकेतक दूध उत्पादन के लक्ष्य का सामान्य रूप से समर्थन करते हैं। चारा सेवन, दूध उत्पादन और शरीर की स्थिति की निगरानी जारी रखें क्योंकि केवल यह स्कैन पूर्ण राशन निर्धारित नहीं कर सकता।',
        );

      case 'milk_fat':
        if (fibreNeedsAttention) {
          return _text(
            'For the milk-fat and SNF goal, the fibre indicator needs attention relative to the selected feed profile. Ask an expert to review effective fibre and good-quality roughage before changing the ration.',
            'दूध वसा और SNF के लक्ष्य के लिए चयनित चारा प्रोफाइल की तुलना में फाइबर संकेतक पर ध्यान देने की आवश्यकता है। राशन बदलने से पहले प्रभावी फाइबर और अच्छी गुणवत्ता वाले सूखे चारे की विशेषज्ञ से समीक्षा कराएँ।',
          );
        }

        return _text(
          'The fibre indicator broadly supports the milk-fat goal for the selected feed profile. Avoid sudden ration changes and have the complete ration and milk-fat trend reviewed by an expert.',
          'चयनित चारा प्रोफाइल के लिए फाइबर संकेतक दूध वसा लक्ष्य का सामान्य रूप से समर्थन करता है। राशन में अचानक बदलाव न करें और पूर्ण राशन तथा दूध वसा की प्रवृत्ति की विशेषज्ञ से समीक्षा कराएँ।',
        );

      default:
        return _text(
          'For maintenance, keep the complete ration balanced and monitor body condition, appetite and health. Use expert advice before adding supplements.',
          'सामान्य रखरखाव के लिए पूर्ण राशन संतुलित रखें और शरीर की स्थिति, भूख तथा स्वास्थ्य की निगरानी करें। पूरक आहार जोड़ने से पहले विशेषज्ञ की सलाह लें।',
        );
    }
  }

  List<({IconData icon, String title, String detail})> _feedOptions(
    DeviceReading reading,
  ) {
    final options = <({IconData icon, String title, String detail})>[];
    final profile = FeedReferenceProfile.forFeed(_selectedFeed);

    if (profile == null) {
      return [
        (
          icon: Icons.info_outline_rounded,
          title: _text('Expert review required', 'विशेषज्ञ समीक्षा आवश्यक'),
          detail: _text(
            'No reference profile is available for this feed type. Do not change the ration using this screening alone.',
            'इस चारे के प्रकार के लिए संदर्भ प्रोफाइल उपलब्ध नहीं है। केवल इस स्क्रीनिंग के आधार पर राशन न बदलें।',
          ),
        ),
      ];
    }

    final proteinNeedsAttention =
        profile.protein.riskLevel(reading.protein) > 0;
    final fatNeedsAttention = profile.fat.riskLevel(reading.fat) > 0;
    final fibreNeedsAttention = profile.fiber.riskLevel(reading.fiber) > 0;
    final ashNeedsAttention = profile.ash.riskLevel(reading.ash) > 0;
    final moistureNeedsAttention =
        profile.moisture.riskLevel(reading.moisture) > 0;

    if (proteinNeedsAttention) {
      options.add((
        icon: Icons.grass_rounded,
        title: _text('Protein-source review', 'प्रोटीन स्रोत समीक्षा'),
        detail: _text(
          'Discuss whether leguminous green fodder or a suitable locally available oilseed cake could help balance the complete ration.',
          'विशेषज्ञ से चर्चा करें कि दलहनी हरा चारा या उपयुक्त स्थानीय खली पूर्ण राशन को संतुलित करने में मदद कर सकती है या नहीं।',
        ),
      ));
    }

    if (fibreNeedsAttention || _productionGoal == 'milk_fat') {
      options.add((
        icon: Icons.eco_rounded,
        title: _text('Effective-fibre review', 'प्रभावी फाइबर समीक्षा'),
        detail: _text(
          'Review good-quality roughage, hay or suitable dry fodder for the complete ration. This feed reading alone cannot measure total effective fibre.',
          'पूर्ण राशन के लिए अच्छी गुणवत्ता वाले मोटे चारे, भूसे या उपयुक्त सूखे चारे की समीक्षा करें। केवल इस चारे की रीडिंग कुल प्रभावी फाइबर को नहीं माप सकती।',
        ),
      ));
    }

    final needsEnergyReview =
        (_productionGoal == 'weight_gain' || _productionGoal == 'milk_yield') &&
        (proteinNeedsAttention || fatNeedsAttention);

    if (needsEnergyReview) {
      options.add((
        icon: Icons.bolt_rounded,
        title: _text('Energy-balance review', 'ऊर्जा संतुलन समीक्षा'),
        detail: _text(
          'Ask an expert to assess the complete ration before using grains, bran or another approved energy ingredient.',
          'अनाज, चोकर या किसी अन्य अनुमोदित ऊर्जा सामग्री का उपयोग करने से पहले विशेषज्ञ से पूर्ण राशन का आकलन कराएँ।',
        ),
      ));
    }

    if (ashNeedsAttention) {
      options.add((
        icon: Icons.science_outlined,
        title: _text(
          'Mineral and contamination review',
          'खनिज और मिलावट समीक्षा',
        ),
        detail: _text(
          'Review mineral balance and possible soil or foreign-material contamination before adding supplements.',
          'पूरक देने से पहले खनिज संतुलन और मिट्टी या बाहरी पदार्थ की संभावित मिलावट की समीक्षा कराएँ।',
        ),
      ));
    }

    if (moistureNeedsAttention) {
      options.add((
        icon: Icons.water_drop_outlined,
        title: _text('Moisture and storage review', 'नमी और भंडारण समीक्षा'),
        detail: _text(
          'Review storage conditions, spoilage risk and dry-matter intake. Do not directly add water based only on this result.',
          'भंडारण की स्थिति, खराब होने के जोखिम और सूखे पदार्थ के सेवन की समीक्षा करें। केवल इस परिणाम के आधार पर सीधे पानी न मिलाएँ।',
        ),
      ));
    }

    if (options.isEmpty) {
      options.add((
        icon: Icons.check_circle_outline_rounded,
        title: _text('Maintain balance', 'संतुलन बनाए रखें'),
        detail: _text(
          'No specific ingredient category is suggested by this screening. Continue the balanced ration and monitor the animal.',
          'इस स्क्रीनिंग से किसी विशेष सामग्री श्रेणी का सुझाव नहीं मिलता। संतुलित राशन जारी रखें और पशु की निगरानी करें।',
        ),
      ));
    }

    return options;
  }

  Widget _buildFeedOptions(DeviceReading reading, Color color) {
    final options = _feedOptions(reading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _text(
            'What could be discussed?',
            'किन चीजों पर चर्चा की जा सकती है?',
          ),
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          _text(
            'Possible ingredient categories—not a feeding prescription.',
            'संभावित सामग्री श्रेणियाँ—यह पशु आहार का नुस्खा नहीं है।',
          ),
          style: TextStyle(
            color: color.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ...options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(option.icon, color: color, size: 20),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.detail,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          _text(
            'The exact ingredient and quantity must be decided from the complete ration by a qualified livestock nutrition professional.',
            'सटीक सामग्री और मात्रा का निर्णय पूर्ण राशन के आधार पर योग्य पशु पोषण विशेषज्ञ द्वारा किया जाना चाहिए।',
          ),
          style: TextStyle(
            color: color,
            fontSize: 11,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBreakdown(DeviceReading reading, Color color) {
    final adjustments = _scoreAdjustments(reading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _text('How this score was calculated', 'यह स्कोर कैसे बनाया गया'),
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (adjustments.isEmpty)
          Text(
            _text(
              'No deductions were applied using the selected feed reference profile and production goal.',
              'चयनित चारा संदर्भ प्रोफाइल और उत्पादन लक्ष्य के अनुसार कोई अंक नहीं काटे गए।',
            ),
            style: TextStyle(color: color, fontSize: 13, height: 1.4),
          )
        else
          ...adjustments.map(
            (adjustment) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.remove_circle_outline_rounded,
                    color: color,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      adjustment.$1,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-${adjustment.$2}',
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          _text(
            'Prototype suitability score—not a laboratory grade.',
            'यह प्रोटोटाइप उपयुक्तता स्कोर है—प्रयोगशाला ग्रेड नहीं।',
          ),
          style: TextStyle(
            color: color.withValues(alpha: 0.82),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard() {
    final reading = _reading;
    final profile = FeedReferenceProfile.forFeed(_selectedFeed);

    if (reading == null || profile == null) {
      return const SizedBox.shrink();
    }

    final risk = _overallRisk(reading);
    final concerns = <String>[];

    if (profile.moisture.riskLevel(reading.moisture) > 0) {
      concerns.add(_text('moisture', 'नमी'));
    }

    if (profile.protein.riskLevel(reading.protein) > 0) {
      concerns.add(_text('protein', 'प्रोटीन'));
    }

    if (profile.fiber.riskLevel(reading.fiber) > 0) {
      concerns.add(_text('fibre', 'फाइबर'));
    }

    if (profile.fat.riskLevel(reading.fat) > 0) {
      concerns.add(_text('fat', 'वसा'));
    }

    if (profile.ash.riskLevel(reading.ash) > 0) {
      concerns.add(_text('ash', 'राख'));
    }

    final String recommendation;
    final Color backgroundColor;
    final Color foregroundColor;
    final IconData icon;

    if (risk == 2) {
      recommendation = _text(
        'Keep this feed sample separate. Retest it and consult a livestock nutrition expert before feeding. Check: ${concerns.join(', ')}.',
        'इस चारे के नमूने को अलग रखें। दोबारा जाँच करें और पशु को खिलाने से पहले पशु पोषण विशेषज्ञ से सलाह लें। जाँचें: ${concerns.join(', ')}।',
      );
      backgroundColor = const Color(0xFFFBE8E4);
      foregroundColor = const Color(0xFF8F352C);
      icon = Icons.report_problem_rounded;
    } else if (risk == 1) {
      recommendation = _text(
        'Some values need attention. Review ${concerns.join(', ')} and test the sample again before regular use.',
        'कुछ मानों पर ध्यान देने की आवश्यकता है। ${concerns.join(', ')} की समीक्षा करें और नियमित उपयोग से पहले नमूने की दोबारा जाँच करें।',
      );
      backgroundColor = const Color(0xFFFFF1CF);
      foregroundColor = const Color(0xFF795315);
      icon = Icons.warning_amber_rounded;
    } else {
      recommendation = _text(
        'The tested values are within the expected range. Continue normal use and follow your livestock nutrition plan.',
        'जाँचे गए मान अपेक्षित सीमा में हैं। सामान्य उपयोग जारी रखें और अपनी पशु पोषण योजना का पालन करें।',
      );
      backgroundColor = const Color(0xFFE3F1E6);
      foregroundColor = const Color(0xFF286B3E);
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foregroundColor, size: 27),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text('Parakh Feed Assistant', 'परख फीड सहायक'),
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  recommendation,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                Divider(
                  height: 24,
                  color: foregroundColor.withValues(alpha: 0.25),
                ),
                Text(
                  _text('Goal-based guidance', 'लक्ष्य आधारित मार्गदर्शन'),
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _goalGuidance(reading),
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                Divider(
                  height: 24,
                  color: foregroundColor.withValues(alpha: 0.25),
                ),
                _buildScoreBreakdown(reading, foregroundColor),
                Divider(
                  height: 24,
                  color: foregroundColor.withValues(alpha: 0.25),
                ),
                _buildFeedOptions(reading, foregroundColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
