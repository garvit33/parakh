abstract final class AppStrings {
  static const Map<String, Map<String, String>> values = {
    'en': {
      'skip': 'Skip',
      'next': 'Next',
      'start': 'Start using Parakh',
      'welcomeTitle': 'Welcome to Parakh',
      'welcomeBody': 'Test feed quality and receive simple recommendations without needing the internet.',
      'connectTitle': 'Connect your device',
      'connectBody': 'Connect the portable Parakh device through Bluetooth and receive readings directly.',
      'scanTitle': 'Scan and understand',
      'scanBody': 'Use guided NIR, feed-camera and pH-strip scans for a complete assessment.',
      'resultTitle': 'Get useful guidance',
      'resultBody': 'View quality, safety, storage and nutritional recommendations in simple language.',
      'setupComplete': 'Parakh setup completed',
    },
    'hi': {
      'skip': 'छोड़ें',
      'next': 'आगे',
      'start': 'परख शुरू करें',
      'welcomeTitle': 'परख में आपका स्वागत है',
      'welcomeBody':
          'बिना इंटरनेट चारे की गुणवत्ता जाँचें और आसान सुझाव प्राप्त करें।',
      'connectTitle': 'अपना उपकरण जोड़ें',
      'connectBody':
          'ब्लूटूथ से पोर्टेबल परख उपकरण जोड़ें और सीधे रीडिंग प्राप्त करें।',
      'scanTitle': 'स्कैन करें और समझें',
      'scanBody':
          'संपूर्ण जाँच के लिए NIR, चारा कैमरा और पीएच स्ट्रिप स्कैन करें।',
      'resultTitle': 'उपयोगी सुझाव पाएँ',
      'resultBody':
          'गुणवत्ता, सुरक्षा, भंडारण और पोषण संबंधी आसान सुझाव देखें।',
      'setupComplete': 'परख सेटअप पूरा हुआ',
    },
  };

  static String text(String key, bool isHindi) {
    final language = isHindi ? 'hi' : 'en';
    return values[language]?[key] ?? key;
  }
}
