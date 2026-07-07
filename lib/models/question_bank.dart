class Question {
  final String uid;
  final int index;
  final String text;
  final String? answer;
  final bool isRisk;
  final bool used;
  const Question({
    required this.uid,
    required this.index,
    required this.text,
    this.answer,
    this.isRisk = false,
    this.used = false,
  });

  Question copyWith({String? text, String? answer, bool? isRisk, bool? used}) =>
      Question(
        uid: uid,
        index: index,
        text: text ?? this.text,
        answer: answer ?? this.answer,
        isRisk: isRisk ?? this.isRisk,
        used: used ?? this.used,
      );
}

class QuestionBank {
  final String uid;
  final String name;
  final List<Question> questions;
  const QuestionBank({
    required this.uid,
    required this.name,
    this.questions = const [],
  });

  QuestionBank copyWith({String? name, List<Question>? questions}) =>
      QuestionBank(
        uid: uid,
        name: name ?? this.name,
        questions: questions ?? this.questions,
      );
}
