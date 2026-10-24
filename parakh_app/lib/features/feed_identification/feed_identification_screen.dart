import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/camera_analysis_result.dart';
import '../../core/services/camera_analysis_ai_service.dart';
import '../../core/storage/latest_analysis_storage.dart';

import '../../core/models/feed_identification_result.dart';
import '../../core/services/feed_classifier_service.dart';
import '../../core/theme/parakh_colors.dart';
import '../../core/services/impurity_classifier_service.dart';

class FeedIdentificationScreen extends StatefulWidget {
  const FeedIdentificationScreen({required this.isHindi, super.key});

  final bool isHindi;

  @override
  State<FeedIdentificationScreen> createState() =>
      _FeedIdentificationScreenState();
}

class _FeedIdentificationScreenState extends State<FeedIdentificationScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  final FeedClassifierService _feedClassifierService = FeedClassifierService(
    confidenceThreshold: 0.65,
  );

  final CameraAnalysisAiService _cameraAnalysisService =
      CameraAnalysisAiService();

  final ImpurityClassifierService _impurityClassifierService =
      ImpurityClassifierService();

  final LatestAnalysisStorage _latestAnalysisStorage = LatestAnalysisStorage();

  static const List<String> _feedTypes = [
    'Maize Silage',
    'Wheat Straw',
    'Green Fodder',
    'Concentrate Feed',
    'Cattle Feed Pellets',
  ];

  Uint8List? _imageBytes;
  FeedIdentificationResult? _result;
  CameraAnalysisResult? _cameraResult;
  bool _cameraAnalysisFailed = false;
  String _imageSource = 'unknown';
  String _confirmedFeed = 'Maize Silage';
  bool _isAnalysing = false;

  String _text(String english, String hindi) {
    return widget.isHindi ? hindi : english;
  }

  String _feedTypeFromModelLabel(String label) {
    switch (label) {
      case 'cattle_feed_pellets':
        return 'Cattle Feed Pellets';
      case 'feed_mash':
        return 'Concentrate Feed';
      case 'green_fodder':
        return 'Green Fodder';
      case 'maize_silage':
        return 'Maize Silage';
      case 'wheat_straw':
        return 'Wheat Straw';
      default:
        return 'Unknown';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _imageSource = source == ImageSource.camera ? 'camera' : 'gallery';
        _result = null;
        _cameraResult = null;
        _cameraAnalysisFailed = false;
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Unable to access the selected image.',
              'चुनी गई तस्वीर तक पहुँच नहीं हो सकी।',
            ),
          ),
          backgroundColor: const Color(0xFFB75B4A),
        ),
      );
    }
  }

  Future<void> _analyseImage() async {
    final imageBytes = _imageBytes;

    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Take or select a feed image first.',
              'पहले चारे की तस्वीर लें या चुनें।',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isAnalysing = true;
      _result = null;
      _cameraResult = null;
      _cameraAnalysisFailed = false;
    });

    FeedIdentificationResult feedResult;

    try {
      final classification = await _feedClassifierService.classify(imageBytes);

      final identifiedFeed = _feedTypeFromModelLabel(classification.label);

      feedResult = FeedIdentificationResult(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        imageSource: _imageSource,
        analysisSource: 'offline-tflite',
        modelVersion: 'mobilenetv3-feed-v1',
        imageQuality: 'acceptable',
        predictions: [
          FeedPrediction(
            feedType: identifiedFeed,
            confidence: classification.confidence,
          ),
        ],
        createdAt: DateTime.now(),
        isValidated: false,
        requiresFarmerConfirmation:
            classification.requiresManualConfirmation ||
            identifiedFeed == 'Unknown',
      );
    } catch (error) {
      debugPrint('Offline feed identification failed: $error');

      feedResult = FeedIdentificationResult.modelNotConnected(
        imageSource: _imageSource,
      );
    }

    CameraAnalysisResult? cameraResult;
    var cameraFailed = false;

    // Use the offline TFLite model first.
    try {
      cameraResult = await _impurityClassifierService.analyse(
        imageBytes: imageBytes,
        imageSource: _imageSource,
      );
    } catch (offlineError) {
      debugPrint('Offline impurity screening failed: $offlineError');

      // Firebase remains an optional fallback.
      try {
        cameraResult = await _cameraAnalysisService.analyse(
          imageBytes: imageBytes,
          imageSource: _imageSource,
        );
      } catch (firebaseError) {
        debugPrint('Firebase impurity screening failed: $firebaseError');
        cameraFailed = true;
      }
    }

    if (!mounted) return;

    setState(() {
      _result = feedResult;
      _cameraResult = cameraResult;
      _cameraAnalysisFailed = cameraFailed;
      _isAnalysing = false;

      final prediction = feedResult.bestPrediction;

      if (prediction != null &&
          prediction.feedType != 'Unknown' &&
          _feedTypes.contains(prediction.feedType)) {
        _confirmedFeed = prediction.feedType;
      }
    });

    if (cameraFailed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Feed type was identified offline, but visible impurity screening was unavailable.',
              'चारे का प्रकार ऑफलाइन पहचाना गया, लेकिन दृश्य अशुद्धि स्क्रीनिंग उपलब्ध नहीं थी।',
            ),
          ),
          backgroundColor: const Color(0xFF9A6815),
        ),
      );
    }
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _imageSource = 'unknown';
      _result = null;
      _cameraResult = null;
      _cameraAnalysisFailed = false;
      _isAnalysing = false;
    });
  }

  Future<void> _confirmFeed() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString('identifiedFeedType', _confirmedFeed);

    final cameraResult = _cameraResult;

    if (cameraResult != null) {
      await _latestAnalysisStorage.saveCameraResult(
        result: cameraResult,
        feedType: _confirmedFeed,
      );
    }

    if (!mounted) return;

    Navigator.of(context).pop(_confirmedFeed);
  }

  @override
  void dispose() {
    _feedClassifierService.dispose();
    _impurityClassifierService.dispose();
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
          _text('Feed image screening', 'चारा तस्वीर स्क्रीनिंग'),
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
                _buildInformationCard(),
                const SizedBox(height: 18),
                _buildImageArea(),
                const SizedBox(height: 16),
                _buildImageButtons(),
                if (_imageBytes != null) ...[
                  const SizedBox(height: 18),
                  _buildAnalyseButton(),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  _buildResultCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3EC),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.camera_alt_rounded, color: ParakhColors.forestGreen),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              _text(
                'Take a clear, close photo of the feed in natural light. Keep only one feed type visible.',
                'प्राकृतिक रोशनी में चारे की साफ और पास से तस्वीर लें। तस्वीर में केवल एक प्रकार का चारा रखें।',
              ),
              style: const TextStyle(
                color: Color(0xFF355743),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    return Container(
      height: 270,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: _imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.image_search_rounded,
                    size: 58,
                    color: Color(0xFF8B968E),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _text('Add a feed image', 'चारे की तस्वीर जोड़ें'),
                    style: const TextStyle(
                      color: Color(0xFF667169),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(_imageBytes!, fit: BoxFit.cover),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton.filled(
                      onPressed: _isAnalysing ? null : _clearImage,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildImageButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isAnalysing
                ? null
                : () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_rounded),
            label: Text(_text('Camera', 'कैमरा')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isAnalysing
                ? null
                : () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded),
            label: Text(_text('Gallery', 'गैलरी')),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyseButton() {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: _isAnalysing ? null : _analyseImage,
        style: FilledButton.styleFrom(
          backgroundColor: ParakhColors.forestGreen,
        ),
        icon: _isAnalysing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.image_search_rounded),
        label: Text(
          _isAnalysing
              ? _text('Checking image...', 'तस्वीर की जाँच हो रही है...')
              : _text('Analyse feed image', 'चारे की तस्वीर का विश्लेषण करें'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildVisualFindingSummary() {
    final result = _cameraResult;

    if (_cameraAnalysisFailed) {
      return _visualNotice(
        icon: Icons.cloud_off_rounded,
        color: const Color(0xFF9A6815),
        text: _text(
          'Visible impurity screening was unavailable. Inspect the sample manually.',
          'दृश्य अशुद्धि स्क्रीनिंग उपलब्ध नहीं थी। नमूने की स्वयं जाँच करें।',
        ),
      );
    }

    if (result == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDDE5DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.visibility_rounded,
                color: ParakhColors.forestGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _text(
                    'Visible impurity screening',
                    'दृश्य अशुद्धि स्क्रीनिंग',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF26372D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            result.imageQuality == 'acceptable'
                ? _text(
                    'Image quality acceptable',
                    'तस्वीर की गुणवत्ता स्वीकार्य है',
                  )
                : _text(
                    'Image quality poor — verify manually',
                    'तस्वीर की गुणवत्ता खराब है — स्वयं जाँच करें',
                  ),
            style: const TextStyle(color: Color(0xFF667169), fontSize: 12),
          ),
          const Divider(height: 22),
          _visualFindingRow(
            _text('Sand or soil', 'रेत या मिट्टी'),
            result.findingFor('sand_or_soil'),
          ),
          const SizedBox(height: 10),
          _visualFindingRow(
            _text('Stones', 'पत्थर'),
            result.findingFor('stones'),
          ),
          const SizedBox(height: 10),
          _visualFindingRow(
            _text('Visible mould', 'दिखाई देने वाली फफूँद'),
            result.findingFor('mould'),
          ),
          const SizedBox(height: 10),
          _visualFindingRow(
            _text('Foreign material', 'बाहरी पदार्थ'),
            result.findingFor('foreign_material'),
          ),
          const SizedBox(height: 12),
          Text(
            _text(
              'Camera screening detects only visible indicators. It does not detect toxins, microbes or invisible contamination.',
              'कैमरा स्क्रीनिंग केवल दिखाई देने वाले संकेत पहचानती है। यह विषाक्त पदार्थ, सूक्ष्मजीव या अदृश्य संदूषण नहीं पहचानती।',
            ),
            style: const TextStyle(
              color: Color(0xFF8A6257),
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _visualFindingRow(String label, CameraFinding? finding) {
    final level = finding?.level ?? 'unknown';

    final String value;
    final Color color;

    switch (level) {
      case 'not_detected':
        value = _text('Not detected', 'नहीं मिला');
        color = const Color(0xFF32834C);
        break;
      case 'low':
        value = _text('Low', 'कम');
        color = const Color(0xFF32834C);
        break;
      case 'possible':
        value = _text('Possible', 'संभावित');
        color = const Color(0xFF9A6815);
        break;
      case 'medium':
        value = _text('Medium', 'मध्यम');
        color = const Color(0xFF9A6815);
        break;
      case 'high':
        value = _text('High', 'अधिक');
        color = const Color(0xFFB54435);
        break;
      default:
        value = _text('Unavailable', 'उपलब्ध नहीं');
        color = const Color(0xFF7A847D);
    }

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
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _visualNotice({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _result;

    if (result == null) {
      return const SizedBox.shrink();
    }

    final prediction = result.bestPrediction;
    final hasPrediction =
        prediction != null && prediction.feedType != 'Unknown';

    final confidence = prediction?.confidence ?? 0;
    final needsConfirmation =
        result.requiresFarmerConfirmation || confidence < 0.65;

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
          Row(
            children: [
              Icon(
                hasPrediction
                    ? Icons.auto_awesome_rounded
                    : Icons.warning_amber_rounded,
                color: hasPrediction
                    ? ParakhColors.forestGreen
                    : const Color(0xFFC48526),
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasPrediction
                      ? _text(
                          'Offline feed identification',
                          'ऑफलाइन चारा पहचान',
                        )
                      : _text(
                          'Feed could not be identified',
                          'चारे की पहचान नहीं हो सकी',
                        ),
                  style: const TextStyle(
                    color: Color(0xFF26372D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasPrediction) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: needsConfirmation
                    ? const Color(0xFFFFF7DF)
                    : const Color(0xFFE3F1E6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.feedType,
                    style: const TextStyle(
                      color: Color(0xFF26372D),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_text('Confidence', 'विश्वसनीयता')}: '
                    '${(confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: needsConfirmation
                          ? const Color(0xFF9A6815)
                          : const Color(0xFF32834C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (needsConfirmation) ...[
                    const SizedBox(height: 5),
                    Text(
                      _text(
                        'Low-confidence prediction. Confirm the feed manually.',
                        'कम विश्वसनीयता वाला अनुमान। चारे की स्वयं पुष्टि करें।',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF795315),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else
            _visualNotice(
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFF9A6815),
              text: _text(
                'The offline classifier could not produce a usable prediction. Select the feed manually.',
                'ऑफलाइन मॉडल उपयोग योग्य अनुमान नहीं दे सका। चारा स्वयं चुनें।',
              ),
            ),
          const SizedBox(height: 18),
          _buildVisualFindingSummary(),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _confirmedFeed,
            decoration: InputDecoration(
              labelText: _text(
                'Confirm feed type',
                'चारे के प्रकार की पुष्टि करें',
              ),
              prefixIcon: const Icon(Icons.grass_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: _feedTypes
                .map((feed) => DropdownMenuItem(value: feed, child: Text(feed)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _confirmedFeed = value;
              });
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _confirmFeed,
              style: FilledButton.styleFrom(
                backgroundColor: ParakhColors.forestGreen,
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text(
                _text('Use this feed type', 'इस चारे के प्रकार का उपयोग करें'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _text(
              'Feed identification is an unvalidated prototype prediction. Visible impurity screening detects only visible indicators.',
              'चारा पहचान एक असत्यापित प्रोटोटाइप अनुमान है। अशुद्धि स्क्रीनिंग केवल दिखाई देने वाले संकेत पहचानती है।',
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
}
