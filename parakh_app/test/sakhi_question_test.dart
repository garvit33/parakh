import 'package:flutter_test/flutter_test.dart';
import 'package:parakh/core/services/sakhi_knowledge_base.dart';

void main() {
  test(
    'returns the complete Hindi answer without truncating Devanagari text',
    () {
      final question = SakhiKnowledgeBase.questions.firstWhere(
        (question) => question.id == 'start_nir_scan',
      );

      final answer = question.answer(isHindi: true);

      expect(answer, contains('परख डिवाइस कनेक्ट करें'));
      expect(answer, contains('स्कैन बटन दबाकर रखें।'));
      expect(answer.length, greaterThan(40));
    },
  );

  test('returns the complete English answer', () {
    final question = SakhiKnowledgeBase.questions.firstWhere(
      (question) => question.id == 'start_nir_scan',
    );

    final answer = question.answer(isHindi: false);

    expect(answer, startsWith('Connect the Parakh device'));
    expect(answer, endsWith('hold the scan button.'));
  });

  test('matches a Hindi question containing Devanagari text', () {
    final question = SakhiKnowledgeBase.questions.firstWhere(
      (question) => question.id == 'start_nir_scan',
    );

    expect(question.matches('मैं NIR स्कैन कैसे शुरू करूँ?'), isTrue);
  });
}
