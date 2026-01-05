// DOSYA ADI: lib/models/question.dart

class Question {
  final String id;
  final String text;
  final String? imageUrl;
  final List<String> options;
  final int answerIndex;

  Question({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.options,
    required this.answerIndex,
  });

  // Veritabanından gelen veriyi modele çevirir
  factory Question.fromMap(String id, Map<String, dynamic> map) {
    return Question(
      id: id,
      text: map['text'] ?? '',
      imageUrl: _parseImage(map['image']),
      options: List<String>.from(map['options'] ?? []),
      answerIndex: map['correct_index'] ?? 0,
    );
  }

  // Resim linkini almak için yardımcı fonksiyon
  static String? _parseImage(dynamic imageField) {
    if (imageField == null) return null;
    if (imageField is String) return imageField;
    if (imageField is List && imageField.isNotEmpty) {
      return imageField[0]['downloadURL'];
    }
    return null;
  }
}
