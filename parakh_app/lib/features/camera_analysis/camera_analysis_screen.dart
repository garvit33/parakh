import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/camera_analysis_result.dart';
import '../../core/services/camera_analysis_ai_service.dart';
import '../../core/theme/parakh_colors.dart';
import '../../core/storage/latest_analysis_storage.dart';
import '../../core/services/ai_error_handler.dart';

class CameraAnalysisScreen extends StatefulWidget {
  const CameraAnalysisScreen({required this.isHindi, super.key});

  final bool isHindi;

  @override
  State<CameraAnalysisScreen> createState() => _CameraAnalysisScreenState();
}

class _CameraAnalysisScreenState extends State<CameraAnalysisScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final CameraAnalysisAiService _aiService = CameraAnalysisAiService();
  final LatestAnalysisStorage _latestAnalysisStorage = LatestAnalysisStorage();
  Uint8List? _imageBytes;
  CameraAnalysisResult? _analysisResult;
  String _selectedImageSource = 'unknown';
  bool _isAnalysing = false;
  bool _showResult = false;

  String _text(String english, String hindi) {
    return widget.isHindi ? hindi : english;
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
        _selectedImageSource = source == ImageSource.camera
            ? 'camera'
            : 'gallery';
        _analysisResult = null;
        _showResult = false;
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
      _analysisResult = null;
      _showResult = false;
    });

    try {
      final result = await _aiService.analyse(
        imageBytes: imageBytes,
        imageSource: _selectedImageSource,
      );

      final preferences = await SharedPreferences.getInstance();
      final identifiedFeed = preferences.getString('identifiedFeedType');

      if (identifiedFeed != null &&
          result.analysisSource == 'firebase-ai-logic') {
        await _latestAnalysisStorage.saveCameraResult(
          result: result,
          feedType: identifiedFeed,
        );
      }

      if (!mounted) return;

      setState(() {
        _analysisResult = result;
        _isAnalysing = false;
        _showResult = true;
      });
    } catch (error) {
      debugPrint('Camera AI analysis failed: $error');

      final failure = AiFailure.fromError(error);

      if (!mounted) return;

      setState(() {
        _analysisResult = CameraAnalysisResult.prototype(
          imageSource: _selectedImageSource,
        );
        _isAnalysing = false;
        _showResult = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.localizedMessage(isHindi: widget.isHindi)),
          backgroundColor: const Color(0xFFB75B4A),
        ),
      );
    }
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _analysisResult = null;
      _selectedImageSource = 'unknown';
      _showResult = false;
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
          _text('Camera Analysis', 'कैमरा विश्लेषण'),
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
                if (_showResult) ...[
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
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_rounded, color: Color(0xFFC48526)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _text(
                'Spread the feed on a clean, plain surface. Use bright natural light and keep the camera directly above the sample.',
                'चारे को साफ और समतल सतह पर फैलाएँ। प्राकृतिक रोशनी में कैमरा नमूने के ठीक ऊपर रखें।',
              ),
              style: const TextStyle(
                color: Color(0xFF735B2E),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    return Container(
      height: 310,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFDCE5DA), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: _imageBytes == null
          ? _buildEmptyImageArea()
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(_imageBytes!, fit: BoxFit.cover),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton.filled(
                    onPressed: _clearImage,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyImageArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: const BoxDecoration(
            color: Color(0xFFF5EAE3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            size: 39,
            color: Color(0xFFD17B3F),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _text('Add a feed sample image', 'चारे के नमूने की तस्वीर जोड़ें'),
          style: const TextStyle(
            color: Color(0xFF26342B),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          _text('Camera or phone gallery', 'कैमरा या फोन गैलरी'),
          style: const TextStyle(color: Color(0xFF7B847D), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildImageButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              style: FilledButton.styleFrom(
                backgroundColor: ParakhColors.forestGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(_text('Camera', 'कैमरा')),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              style: OutlinedButton.styleFrom(
                foregroundColor: ParakhColors.forestGreen,
                side: const BorderSide(color: ParakhColors.forestGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.photo_library_rounded),
              label: Text(_text('Gallery', 'गैलरी')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyseButton() {
    return SizedBox(
      height: 53,
      child: FilledButton.icon(
        onPressed: _isAnalysing ? null : _analyseImage,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFD17B3F),
          disabledBackgroundColor: const Color(0xFFD7AA8C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: _isAnalysing
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_awesome_rounded),
        label: Text(
          _isAnalysing
              ? _text('Analysing image...', 'तस्वीर का विश्लेषण हो रहा है...')
              : _text(
                  'Detect visible impurities',
                  'दिखाई देने वाली अशुद्धियाँ पहचानें',
                ),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _analysisResult;

    if (result == null) {
      return const SizedBox.shrink();
    }
    final isAiResult = result.analysisSource == 'firebase-ai-logic';

    final sandFinding = result.findingFor('sand_or_soil');
    final stoneFinding = result.findingFor('stones');
    final mouldFinding = result.findingFor('mould');
    final foreignFinding = result.findingFor('foreign_material');

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1CF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.science_outlined,
                  color: Color(0xFF9A6815),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAiResult
                          ? _text(
                              'AI visual screening complete',
                              'AI दृश्य स्क्रीनिंग पूरी हुई',
                            )
                          : _text(
                              'Prototype visual screening',
                              'प्रोटोटाइप दृश्य स्क्रीनिंग',
                            ),
                      style: const TextStyle(
                        color: Color(0xFF1B2B21),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isAiResult
                          ? result.imageQuality == 'acceptable'
                                ? _text(
                                    'Image quality acceptable',
                                    'तस्वीर की गुणवत्ता स्वीकार्य है',
                                  )
                                : _text(
                                    'Poor image quality — review manually',
                                    'तस्वीर की गुणवत्ता खराब है — मैन्युअल जाँच करें',
                                  )
                          : _text(
                              'AI screening unavailable',
                              'AI स्क्रीनिंग उपलब्ध नहीं है',
                            ),
                      style: const TextStyle(
                        color: Color(0xFF9A6815),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _resultRow(
            _text('Sand or soil', 'रेत या मिट्टी'),
            _findingText(sandFinding),
            _findingColor(sandFinding),
          ),
          const Divider(height: 25),
          _resultRow(
            _text('Stones', 'पत्थर'),
            _findingText(stoneFinding),
            _findingColor(stoneFinding),
          ),
          const Divider(height: 25),
          _resultRow(
            _text('Mould', 'फफूँद'),
            _findingText(mouldFinding),
            _findingColor(mouldFinding),
          ),
          const Divider(height: 25),
          _resultRow(
            _text('Foreign material', 'बाहरी पदार्थ'),
            _findingText(foreignFinding),
            _findingColor(foreignFinding),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _metadataItem(
                  Icons.image_outlined,
                  _text('Image source', 'तस्वीर स्रोत'),
                  result.imageSource,
                ),
                _metadataItem(
                  Icons.model_training_rounded,
                  _text('Model', 'मॉडल'),
                  result.modelVersion,
                ),
                _metadataItem(
                  Icons.fact_check_outlined,
                  _text('Validation', 'सत्यापन'),
                  result.isValidated
                      ? _text('Validated', 'सत्यापित')
                      : _text('Not validated', 'सत्यापित नहीं'),
                ),
                _metadataItem(
                  Icons.percent_rounded,
                  _text('Confidence', 'विश्वसनीयता'),
                  result.overallConfidence == null
                      ? _text('Not available', 'उपलब्ध नहीं')
                      : '${(result.overallConfidence! * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, color: Color(0xFF3D70A8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _text(
                      'Inspect the actual feed manually. Sieve it when appropriate and separate samples with visible mould, soil, stones or foreign material for expert review.',
                      'वास्तविक चारे की मैन्युअल जाँच करें। उपयुक्त होने पर इसे छानें और दिखाई देने वाली फफूँद, मिट्टी, पत्थर या बाहरी पदार्थ वाले नमूनों को विशेषज्ञ समीक्षा के लिए अलग रखें।',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF3D5E7C),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _text(
              'Current findings are simulated placeholders for interface testing. They are not predictions from the selected image.',
              'वर्तमान निष्कर्ष इंटरफेस परीक्षण के लिए सिम्युलेटेड प्लेसहोल्डर हैं। ये चुनी गई तस्वीर से प्राप्त भविष्यवाणियाँ नहीं हैं।',
            ),
            style: const TextStyle(
              color: Color(0xFF8F352C),
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _findingText(CameraFinding? finding) {
    switch (finding?.level) {
      case 'not_detected':
        return _text('Not detected', 'नहीं मिला');
      case 'possible':
        return _text('Possible trace', 'संभावित अंश');
      case 'low':
        return _text('Low', 'कम');
      case 'medium':
        return _text('Medium', 'मध्यम');
      case 'high':
        return _text('High', 'अधिक');
      default:
        return _text('Not available', 'उपलब्ध नहीं');
    }
  }

  Color _findingColor(CameraFinding? finding) {
    switch (finding?.level) {
      case 'high':
        return const Color(0xFFB54435);
      case 'possible':
      case 'medium':
        return const Color(0xFF9A6815);
      case 'not_detected':
      case 'low':
        return const Color(0xFF32834C);
      default:
        return const Color(0xFF7A847D);
    }
  }

  Widget _metadataItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF607067)),
        const SizedBox(width: 5),
        Text(
          '$label: $value',
          style: const TextStyle(
            color: Color(0xFF607067),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _resultRow(String title, String result, Color resultColor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF566158),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          result,
          style: TextStyle(color: resultColor, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
