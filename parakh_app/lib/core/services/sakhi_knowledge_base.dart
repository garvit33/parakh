import '../models/sakhi_question.dart';

class SakhiKnowledgeBase {
  const SakhiKnowledgeBase._();

  static const List<SakhiQuestion> questions = [
    SakhiQuestion(
      id: 'start_nir_scan',
      category: 'NIR Scan',
      questionEnglish: 'How do I start an NIR scan?',
      questionHindi: 'मैं NIR स्कैन कैसे शुरू करूँ?',
      answerEnglish: 'Connect the Parakh device, open NIR Feed Scan, confirm the animal profile, place the feed sample inside the device and press and hold the scan button.',
      answerHindi: 'परख डिवाइस कनेक्ट करें, NIR फीड स्कैन खोलें, पशु प्रोफाइल की पुष्टि करें, चारे का नमूना डिवाइस में रखें और स्कैन बटन दबाकर रखें।',
      keywords: ['start scan', 'nir scan', 'feed scan', 'स्कैन शुरू', 'एनआईआर'],
    ),
    SakhiQuestion(
      id: 'connect_device',
      category: 'Device',
      questionEnglish: 'How do I connect the Parakh device?',
      questionHindi: 'मैं परख डिवाइस कैसे कनेक्ट करूँ?',
      answerEnglish: 'Switch on the device and enable Bluetooth. Open the device connection screen, select the Parakh device and wait for the connected status.',
      answerHindi: 'डिवाइस चालू करें और ब्लूटूथ चालू करें। डिवाइस कनेक्शन स्क्रीन खोलें, परख डिवाइस चुनें और कनेक्टेड स्थिति की प्रतीक्षा करें।',
      keywords: ['connect', 'bluetooth', 'device', 'कनेक्ट', 'ब्लूटूथ'],
    ),
    SakhiQuestion(
      id: 'animal_profile',
      category: 'Animal Profile',
      questionEnglish: 'Why should I add an animal profile?',
      questionHindi: 'मुझे पशु प्रोफाइल क्यों जोड़नी चाहिए?',
      answerEnglish: 'The animal profile helps Parakh interpret feed results according to the animal type, breed, production stage, weight and production goal.',
      answerHindi: 'पशु प्रोफाइल परख को पशु के प्रकार, नस्ल, उत्पादन अवस्था, वजन और उत्पादन लक्ष्य के अनुसार परिणाम समझने में मदद करती है।',
      keywords: [
        'animal profile',
        'cow',
        'buffalo',
        'breed',
        'पशु प्रोफाइल',
        'नस्ल',
      ],
    ),
    SakhiQuestion(
      id: 'goal_score',
      category: 'Results',
      questionEnglish: 'What is the goal suitability score?',
      questionHindi: 'लक्ष्य उपयुक्तता स्कोर क्या है?',
      answerEnglish: 'It is a screening score comparing the available feed estimates with the selected animal profile and production goal. It is not a laboratory-certified ration recommendation.',
      answerHindi: 'यह एक स्क्रीनिंग स्कोर है जो उपलब्ध चारा अनुमानों की तुलना चुनी गई पशु प्रोफाइल और उत्पादन लक्ष्य से करता है। यह प्रयोगशाला प्रमाणित राशन सुझाव नहीं है।',
      keywords: ['score', 'suitability', 'goal score', 'स्कोर', 'उपयुक्तता'],
    ),
    SakhiQuestion(
      id: 'nutrient_results',
      category: 'Results',
      questionEnglish: 'Are the nutrient results laboratory certified?',
      questionHindi: 'क्या पोषक परिणाम प्रयोगशाला द्वारा प्रमाणित हैं?',
      answerEnglish: 'No. Protein, fat and fibre are prototype estimates from the current spectral model. Use laboratory testing before important feeding or commercial decisions.',
      answerHindi: 'नहीं। प्रोटीन, वसा और फाइबर वर्तमान स्पेक्ट्रल मॉडल के प्रोटोटाइप अनुमान हैं। महत्वपूर्ण आहार या व्यावसायिक निर्णय से पहले प्रयोगशाला परीक्षण कराएँ।',
      keywords: [
        'protein',
        'fat',
        'fibre',
        'fiber',
        'laboratory',
        'accurate',
        'प्रोटीन',
        'पोषक',
      ],
    ),
    SakhiQuestion(
      id: 'camera_screening',
      category: 'Camera',
      questionEnglish: 'What can camera screening detect?',
      questionHindi: 'कैमरा स्क्रीनिंग क्या पहचान सकती है?',
      answerEnglish: 'It can identify the feed category and screen for visible mould, stones, sand or soil and foreign material. It cannot detect invisible toxins, microbes or chemicals.',
      answerHindi: 'यह चारे की श्रेणी और दिखाई देने वाली फफूंदी, पत्थर, रेत या मिट्टी तथा बाहरी सामग्री की जाँच कर सकती है। यह अदृश्य विष, सूक्ष्मजीव या रसायन नहीं पहचान सकती।',
      keywords: [
        'camera',
        'impurity',
        'mould',
        'stone',
        'sand',
        'कैमरा',
        'अशुद्धि',
        'फफूंदी',
      ],
    ),
    SakhiQuestion(
      id: 'ph_test',
      category: 'pH Test',
      questionEnglish: 'How do I perform the pH test?',
      questionHindi: 'मैं pH परीक्षण कैसे करूँ?',
      answerEnglish: 'Prepare the feed extract using the same measured feed-to-water ratio each time. Dip the pH strip, wait for its colour to develop and photograph it in clear neutral lighting.',
      answerHindi: 'हर बार चारे और पानी का समान मापा अनुपात रखकर घोल तैयार करें। pH स्ट्रिप डुबोएँ, रंग विकसित होने दें और साफ सामान्य रोशनी में तस्वीर लें।',
      keywords: ['ph', 'ph strip', 'acidity', 'पीएच', 'स्ट्रिप'],
    ),
    SakhiQuestion(
      id: 'empty_device',
      category: 'NIR Scan',
      questionEnglish: 'Can I scan an empty device?',
      questionHindi: 'क्या मैं खाली डिवाइस को स्कैन कर सकता हूँ?',
      answerEnglish: 'Do not treat an empty-device scan as a feed result. Add enough feed to cover the sensing area. Empty, extremely dark or saturated readings should be rejected.',
      answerHindi: 'खाली डिवाइस के स्कैन को चारे का परिणाम न मानें। सेंसर क्षेत्र ढकने के लिए पर्याप्त चारा रखें। खाली, बहुत कम या संतृप्त रीडिंग अस्वीकार करें।',
      keywords: ['empty', 'no sample', 'blank scan', 'खाली', 'नमूना नहीं'],
    ),
    SakhiQuestion(
      id: 'unsafe_feed',
      category: 'Safety',
      questionEnglish: 'What should I do if the feed looks unsafe?',
      questionHindi: 'यदि चारा असुरक्षित लगे तो मुझे क्या करना चाहिए?',
      answerEnglish: 'Do not feed visibly mouldy, badly spoiled or heavily contaminated feed. Isolate it and consult a veterinarian, nutritionist or laboratory before use.',
      answerHindi: 'दिखाई देने वाली फफूंदी, बहुत खराब या अधिक दूषित चारा पशु को न खिलाएँ। इसे अलग रखें और उपयोग से पहले विशेषज्ञ या प्रयोगशाला से सलाह लें।',
      keywords: [
        'unsafe',
        'spoiled',
        'bad feed',
        'contaminated',
        'असुरक्षित',
        'खराब चारा',
      ],
    ),
  ];

  static SakhiQuestion? findAnswer(String query) {
    for (final question in questions) {
      if (question.matches(query)) {
        return question;
      }
    }

    return null;
  }
}
