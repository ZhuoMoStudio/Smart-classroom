import 'class_model.dart';

class Question {
  final String uid;
  final int index;
  final String text;
  final String? answer;
  final bool isRisk;
  final bool used;
  const Question({required this.uid, required this.index, required this.text,
      this.answer, this.isRisk = false, this.used = false});

  Question copyWith({String? text, String? answer, bool? isRisk, bool? used}) =>
      Question(uid: uid, index: index, text: text ?? this.text,
          answer: answer ?? this.answer, isRisk: isRisk ?? this.isRisk, used: used ?? this.used);

  Map<String, dynamic> toJson() =>
      {'uid':uid,'index':index,'text':text,'answer':answer,'isRisk':isRisk,'used':used};
  factory Question.fromJson(Map<String, dynamic> json) => Question(
      uid: json['uid'], index: json['index'], text: json['text'],
      answer: json['answer'], isRisk: json['isRisk'] ?? false, used: json['used'] ?? false);
}

class QuestionBank {
  final String uid;
  final String name;
  final List<Question> questions;
  const QuestionBank({required this.uid, required this.name, this.questions = const []});

  QuestionBank copyWith({String? name, List<Question>? questions}) =>
      QuestionBank(uid: uid, name: name ?? this.name, questions: questions ?? this.questions);

  Map<String, dynamic> toJson() =>
      {'uid':uid,'name':name,'questions':questions.map((q)=>q.toJson()).toList()};
  factory QuestionBank.fromJson(Map<String, dynamic> json) => QuestionBank(
      uid: json['uid'], name: json['name'],
      questions: (json['questions'] as List).map((q)=>Question.fromJson(q as Map<String,dynamic>)).toList());
}

class AppData {
  final List<Classroom> classrooms;
  final List<QuestionBank> questionBanks;
  final String? lastModified;
  const AppData({this.classrooms = const [], this.questionBanks = const [], this.lastModified});

  Map<String, dynamic> toJson() => {
    'classrooms': classrooms.map((c)=>c.toJson()).toList(),
    'questionBanks': questionBanks.map((b)=>b.toJson()).toList(),
    'lastModified': lastModified ?? DateTime.now().toIso8601String(),
  };
  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
    classrooms: (json['classrooms'] as List).map((c)=>Classroom.fromJson(c as Map<String,dynamic>)).toList(),
    questionBanks: (json['questionBanks'] as List).map((b)=>QuestionBank.fromJson(b as Map<String,dynamic>)).toList(),
    lastModified: json['lastModified']);
}
