class Question {
  final String questionText;    // Sorunun metni
  final List<String> options;   // Şıklar (A, B, C, D)
  final int correctAnswerIndex; // Doğru cevabın sırası (0, 1, 2, 3)

  Question({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });
}

// Demo amaçlı sahte sorular
final List<Question> demoQuestions = [
  Question(
    questionText: "Aşağıdakilerden hangisi 'Yazım Kuralları'na uygundur?",
    options: ["Herşey güzel olacak", "Her şey güzel olacak", "Hersey güzel olacak", "Her-şey güzel olacak"],
    correctAnswerIndex: 1, // İkinci şık doğru
  ),
  Question(
    questionText: "Türkiye'nin başkenti neresidir?",
    options: ["İstanbul", "İzmir", "Ankara", "Bursa"],
    correctAnswerIndex: 2, // Üçüncü şık doğru
  ),
];