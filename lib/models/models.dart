// DOSYA: lib/models/models.dart

// 1. Enum'ı en tepeye ekledik
enum QuestionType { multipleChoice, dragDrop }

class Lesson {
  final String id;
  final String title;
  final bool isProUnlocked;
  final List<Unit> units;

  Lesson({
    required this.id,
    required this.title,
    required this.isProUnlocked,
    required this.units,
  });
}

class Unit {
  final String id;
  final String title;
  final bool isFree;
  final List<Topic> topics;

  Unit({
    required this.id,
    required this.title,
    required this.isFree,
    required this.topics,
  });
}

class Topic {
  final String id;
  final String title;
  final List<Question> questions;

  Topic({
    required this.id,
    required this.title,
    required this.questions,
  });
}

class Question {
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final QuestionType
      type; // İşte hata veren satır burasıydı (noktalı virgül eklendi)

  Question({
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    // Varsayılan olarak 'multipleChoice' atadık ki eski sorular bozulmasın
    this.type = QuestionType.multipleChoice,
  });
}
