class SakhiQuestion {
  const SakhiQuestion({
    required this.id,
    required this.category,
    required this.questionEnglish,
    required this.questionHindi,
    required this.answerEnglish,
    required this.answerHindi,
    this.keywords = const [],
  });

  final String id;
  final String category;
  final String questionEnglish;
  final String questionHindi;
  final String answerEnglish;
  final String answerHindi;
  final List<String> keywords;

  String question({required bool isHindi}) {
    return isHindi ? questionHindi : questionEnglish;
  }

  String answer({required bool isHindi}) {
    return isHindi ? answerHindi : answerEnglish;
  }

  bool matches(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) return false;

    return questionEnglish.toLowerCase().contains(normalizedQuery) ||
        questionHindi.contains(query.trim()) ||
        keywords.any(
          (keyword) =>
              normalizedQuery.contains(keyword.toLowerCase()) ||
              keyword.toLowerCase().contains(normalizedQuery),
        );
  }
}
