// DOSYA: lib/models/models.dart

enum QuestionType {
  multipleChoice,
  dragDrop,
  match,
  sorting,
  findMistake,
  trueFalse,
  flashcard,
  infoCard,
  wordSearch,
  sentenceParsing,
  paragraphPuzzle,
  bucketSort,
  multipleSelection,
  mapQuestion,
  graphInterpretation,
  hierarchyPyramid,
  timelineRope,
  elimination,
}

class Question {
  final String id;
  final QuestionType type;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;

  // ÖZEL ALANLAR
  final Map<String, String>? matchingPairs; // Eşleştirme için şart!
  final Map<String, int>? graphData;
  final Map<String, List<int>>? groupGraphData;
  final List<String>? graphLegends;
  final String? imageUrl;
  final Map<String, double>? answerLocation;
  final List<int>? answerIndices;
  final bool isFixed;
  final int order;

  Question({
    this.id = '',
    this.type = QuestionType.multipleChoice,
    required this.text,
    this.options = const [],
    this.correctAnswerIndex = -1,
    this.matchingPairs,
    this.graphData,
    this.groupGraphData,
    this.graphLegends,
    this.imageUrl,
    this.answerLocation,
    this.answerIndices,
    this.isFixed = false,
    this.order = 0,
  });

  factory Question.fromMap(Map<String, dynamic> map, String docId) {
    // 1. TİPİ BELİRLE
    QuestionType qType = QuestionType.multipleChoice;
    try {
      // Eğer 'type' string ise (örn: 'match') uygun enum'ı bul
      if (map['type'] is String) {
        String typeStr = map['type'].toString();
        // 'QuestionType.match' şeklinde geliyorsa temizle
        if (typeStr.startsWith('QuestionType.')) {
          typeStr = typeStr.split('.').last;
        }
        qType = QuestionType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => QuestionType.multipleChoice,
        );
      }
    } catch (e) {
      print("Tip dönüşüm hatası: $e");
    }

    // 2. EŞLEŞTİRME VERİSİNİ AL (Kritik Nokta)
    Map<String, String>? pairs;
    if (map['matchingPairs'] != null) {
      pairs = Map<String, String>.from(map['matchingPairs']);
    }

    return Question(
      id: docId,
      type: qType,
      text: map['text'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? -1,

      // BURASI ÇOK ÖNEMLİ:
      matchingPairs: pairs,

      graphData: map['graphData'] != null
          ? Map<String, int>.from(map['graphData'])
          : null,
      groupGraphData: map['groupGraphData'] != null
          ? (map['groupGraphData'] as Map).map(
              (key, value) => MapEntry(key as String, List<int>.from(value)))
          : null,
      graphLegends: map['graphLegends'] != null
          ? List<String>.from(map['graphLegends'])
          : null,
      imageUrl: map['imageUrl'],
      answerLocation: map['answerLocation'] != null
          ? Map<String, double>.from(map['answerLocation']
              .map((k, v) => MapEntry(k, (v as num).toDouble())))
          : null,
      answerIndices: map['answerIndices'] != null
          ? List<int>.from(map['answerIndices'])
          : null,
      isFixed: map['isFixed'] ?? false,
      order: map['order'] ?? 0,
    );
  }
}

class Topic {
  final String id;
  final String title;
  final String unitId;

  Topic({required this.id, required this.title, required this.unitId});

  factory Topic.fromMap(Map<String, dynamic> map, String docId) {
    return Topic(
      id: docId,
      title: map['name'] ?? '',
      unitId: map['unitId'] ?? '',
    );
  }
}

class Unit {
  final String id;
  final String title;
  final String lessonId;
  final bool isFree;

  Unit(
      {required this.id,
      required this.title,
      required this.lessonId,
      this.isFree = true});

  factory Unit.fromMap(Map<String, dynamic> map, String docId) {
    return Unit(
      id: docId,
      title: map['name'] ?? '',
      lessonId: map['lessonId'] ?? '',
      isFree: map['isFree'] ?? true,
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final bool isProUnlocked;

  Lesson({required this.id, required this.title, required this.isProUnlocked});

  factory Lesson.fromMap(Map<String, dynamic> map, String docId) {
    return Lesson(
      id: docId,
      title: map['name'] ?? '',
      isProUnlocked: false,
    );
  }
}
