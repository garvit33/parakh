enum AiFailureType {
  quotaExhausted,
  overloaded,
  noInternet,
  appCheck,
  invalidImage,
  unknown,
}

class AiFailure {
  const AiFailure({
    required this.type,
    required this.messageEnglish,
    required this.messageHindi,
    required this.canRetry,
  });

  final AiFailureType type;
  final String messageEnglish;
  final String messageHindi;
  final bool canRetry;

  factory AiFailure.fromError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('quota') ||
        message.contains('resource_exhausted') ||
        message.contains('rate limit') ||
        message.contains('billing')) {
      return const AiFailure(
        type: AiFailureType.quotaExhausted,
        messageEnglish:
            'The free AI quota is exhausted. Try again after the quota resets.',
        messageHindi: 'मुफ्त AI कोटा समाप्त हो गया है। कोटा रीसेट होने के बाद फिर प्रयास करें।',
        canRetry: false,
      );
    }

    if (message.contains('overloaded') ||
        message.contains('503') ||
        message.contains('service unavailable')) {
      return const AiFailure(
        type: AiFailureType.overloaded,
        messageEnglish:
            'The AI service is temporarily busy. Please try again shortly.',
        messageHindi:
            'AI सेवा अभी व्यस्त है। कृपया थोड़ी देर बाद फिर प्रयास करें।',
        canRetry: true,
      );
    }

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('internet') ||
        message.contains('host lookup')) {
      return const AiFailure(
        type: AiFailureType.noInternet,
        messageEnglish: 'No reliable internet connection. Check the connection and try again.',
        messageHindi: 'विश्वसनीय इंटरनेट कनेक्शन उपलब्ध नहीं है। कनेक्शन जाँचकर फिर प्रयास करें।',
        canRetry: true,
      );
    }

    if (message.contains('app check') ||
        message.contains('appcheck') ||
        message.contains('unauthenticated') ||
        message.contains('permission denied') ||
        message.contains('403')) {
      return const AiFailure(
        type: AiFailureType.appCheck,
        messageEnglish: 'This app installation could not be verified. Restart the app or contact support.',
        messageHindi: 'इस ऐप इंस्टॉलेशन का सत्यापन नहीं हो सका। ऐप दोबारा खोलें या सहायता लें।',
        canRetry: false,
      );
    }

    if (message.contains('image') &&
        (message.contains('invalid') ||
            message.contains('unsupported') ||
            message.contains('decode'))) {
      return const AiFailure(
        type: AiFailureType.invalidImage,
        messageEnglish: 'The selected image could not be analysed. Choose a clear JPG or PNG image.',
        messageHindi: 'चुनी गई तस्वीर का विश्लेषण नहीं हो सका। साफ JPG या PNG तस्वीर चुनें।',
        canRetry: false,
      );
    }

    return const AiFailure(
      type: AiFailureType.unknown,
      messageEnglish: 'AI analysis is temporarily unavailable. Please review the sample manually.',
      messageHindi:
          'AI विश्लेषण अभी उपलब्ध नहीं है। कृपया नमूने की मैन्युअल जाँच करें।',
      canRetry: true,
    );
  }

  String localizedMessage({required bool isHindi}) {
    return isHindi ? messageHindi : messageEnglish;
  }
}
