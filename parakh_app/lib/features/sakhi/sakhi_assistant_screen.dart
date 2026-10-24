import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/models/sakhi_question.dart';
import '../../core/services/sakhi_knowledge_base.dart';
import '../../core/theme/parakh_colors.dart';

class SakhiAssistantScreen extends StatefulWidget {
  const SakhiAssistantScreen({required this.isHindi, super.key});

  final bool isHindi;

  @override
  State<SakhiAssistantScreen> createState() => _SakhiAssistantScreenState();
}

class _SakhiAssistantScreenState extends State<SakhiAssistantScreen> {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();
  final TextEditingController _controller = TextEditingController();

  SakhiQuestion? _selectedQuestion;
  String? _fallbackAnswer;
  bool _isListening = false;
  bool _speechAvailable = false;

  String _text(String english, String hindi) {
    return widget.isHindi ? hindi : english;
  }

  String? get _answer {
    final selectedQuestion = _selectedQuestion;

    if (selectedQuestion != null) {
      return selectedQuestion.answer(isHindi: widget.isHindi);
    }

    return _fallbackAnswer;
  }

  @override
  void initState() {
    super.initState();
    _configureVoice();
  }

  Future<void> _configureVoice() async {
    await _tts.setLanguage(widget.isHindi ? 'hi-IN' : 'en-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1);
    await _tts.setVolume(1);

    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;

        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
    );

    if (!mounted) return;

    setState(() {
      _speechAvailable = available;
    });
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.setLanguage(widget.isHindi ? 'hi-IN' : 'en-IN');
    await _tts.speak(text);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();

      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      final available = await _speech.initialize();

      if (!mounted) return;

      setState(() {
        _speechAvailable = available;
      });

      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Speech recognition is unavailable.',
                'वाणी पहचान उपलब्ध नहीं है।',
              ),
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isListening = true);

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: widget.isHindi ? 'hi_IN' : 'en_IN',
      ),
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          _controller.text = result.recognizedWords;
        });

        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _ask(result.recognizedWords);
        }
      },
    );
  }

  void _ask([String? spokenQuestion]) {
    final query = (spokenQuestion ?? _controller.text).trim();

    if (query.isEmpty) return;

    final matchedQuestion = SakhiKnowledgeBase.findAnswer(query);

    setState(() {
      _selectedQuestion = matchedQuestion;
      _fallbackAnswer = matchedQuestion == null
          ? _text(
              'I can only help with Parakh, feed scanning, animal profiles, camera screening and pH testing. Please select one of the suggested questions.',
              'मैं केवल परख, चारा स्कैनिंग, पशु प्रोफाइल, कैमरा स्क्रीनिंग और pH परीक्षण में सहायता कर सकती हूँ। कृपया सुझाए गए प्रश्नों में से एक चुनें।',
            )
          : null;
    });

    final currentAnswer = _answer;

    if (currentAnswer != null) {
      _speak(currentAnswer);
    }
  }

  void _selectQuestion(SakhiQuestion question) {
    _controller.text = question.question(isHindi: widget.isHindi);

    setState(() {
      _selectedQuestion = question;
      _fallbackAnswer = null;
    });

    _speak(question.answer(isHindi: widget.isHindi));
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAnswer = _answer;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F2),
        surfaceTintColor: Colors.transparent,
        title: Text(
          _text('Sakhi Assistant', 'सखी सहायक'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildInput(),
            if (currentAnswer != null) ...[
              const SizedBox(height: 18),
              _buildAnswer(currentAnswer),
            ],
            const SizedBox(height: 22),
            Text(
              _text('Suggested questions', 'सुझाए गए प्रश्न'),
              style: const TextStyle(
                color: Color(0xFF26372D),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...SakhiKnowledgeBase.questions.map(_buildQuestion),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE4F2E7), Color(0xFFF7F2D9)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset('assets/images/sakhi.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sakhi',
                  style: TextStyle(
                    color: ParakhColors.forestGreen,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _text('Your Parakh feed companion', 'आपकी परख चारा सहायक'),
                  style: const TextStyle(
                    color: Color(0xFF46564C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _text(
                    'Ask me how to use Parakh.',
                    'मुझसे परख का उपयोग करना पूछें।',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _ask(),
              decoration: InputDecoration(
                hintText: _text(
                  'Ask Sakhi about Parakh...',
                  'सखी से परख के बारे में पूछें...',
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: _toggleListening,
            icon: Icon(
              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isListening
                  ? const Color(0xFFB54435)
                  : ParakhColors.forestGreen,
            ),
          ),
          IconButton(
            onPressed: _ask,
            style: IconButton.styleFrom(
              backgroundColor: ParakhColors.forestGreen,
            ),
            icon: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswer(String answer) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F4EB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC9E0CD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: ParakhColors.forestGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              answer,
              style: const TextStyle(
                color: Color(0xFF33483A),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _speak(answer),
            icon: const Icon(
              Icons.volume_up_rounded,
              color: ParakhColors.forestGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(SakhiQuestion question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Color(0xFFE0E8DD)),
        ),
        title: Text(
          question.question(isHindi: widget.isHindi),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: ParakhColors.forestGreen,
        ),
        onTap: () => _selectQuestion(question),
      ),
    );
  }
}
