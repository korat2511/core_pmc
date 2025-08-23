class Question {
  final int id;
  final String question;
  String? answer;
  String remark;

  Question({
    required this.id,
    required this.question,
    required this.remark,
    this.answer,
  });

  // Convert Question to a map with custom field names
  Map<String, dynamic> toMap() {
    return {
      'question_$id': question,
      'answer_$id': answer ?? '',
      'remark_$id': remark,
    };
  }
}
