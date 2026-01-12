// DOSYA ADI: lib/models/question.dart

// 1. SORU TİPLERİ ENUM (QuizScreen bu tiplere göre ekranı çiziyor)
enum QuestionType {
  multipleSelection, // Çoktan seçmeli
  sorting, // Sıralama
  timelineRope, // Tarih Şeridi / İp
  hierarchyPyramid, // Hiyerarşi Piramidi
  flashcard, // Bilgi Kartı
  findMistake, // Yanlışı Bul
  mapQuestion, // Harita Sorusu
  graphInterpretation, // Grafik Yorumlama (YENİ)
  dragDrop, // Sürükle Bırak (Boşluk Doldurma)
  match, // Eşleştirme
  trueFalse, // Doğru Yanlış
  elimination, // Gereksizi Sil
  infoCard, // Bilgi Kartı (Soru değil, bilgi ekranı)
  wordSearch, // Kelime Avı
  sentenceParsing, // Cümle Ögeleri
  paragraphPuzzle, // Paragraf Tamamlama
  bucketSort, // Kutuya Atma
  unknown // Bilinmeyen
}

class Question {
  final String id;
  final String text;
  final String? imageUrl;
  final List<String> options;
  final int correctAnswerIndex; // Doğru cevap indeksi

  // --- YENİ EKLENEN KRİTİK ALANLAR ---
  final bool isFixed; // Soru sabit mi? (Raptiyeli mi?)
  final int order; // Sabitse kaçıncı sırada?
  final QuestionType type; // Sorunun tipi ne?
  final String topicId; // Hangi konuya ait?

  // --- TİPE ÖZEL VERİ ALANLARI ---
  final Map<String, int>? graphData; // Basit Grafik: {"2020": 50, "2021": 80}
  final Map<String, List<int>>?
      groupGraphData; // Gruplu Grafik: {"2020": [30, 50, 20]}
  final List<String>? graphLegends; // Lejantlar: ["Üretim", "Tüketim"]
  final Map<String, String>? matchingPairs; // Eşleştirme: {"Elma": "Meyve"}
  final Map<String, dynamic>?
      answerLocation; // Harita: {x: 0.5, y: 0.3, tolerance: 0.1}
  final List<int>?
      answerIndices; // Çoklu Seçim: [0, 2] (Birden fazla doğru varsa)

  Question({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.options,
    required this.correctAnswerIndex,
    this.isFixed = false, // Varsayılan false
    this.order = 0, // Varsayılan 0
    this.type = QuestionType.multipleSelection,
    this.topicId = '',
    this.graphData,
    this.groupGraphData,
    this.graphLegends,
    this.matchingPairs,
    this.answerLocation,
    this.answerIndices,
  });

  // Veritabanından gelen veriyi modele çevirir
  // NOT: DatabaseService ile uyumlu olması için parametre sırasını (Map, ID) yaptım.
  factory Question.fromMap(Map<String, dynamic> map, String id) {
    // --- GÜVENLİ GRAFİK VERİSİ DÖNÜŞÜMÜ (TEKİL) ---
    Map<String, int> parsedGraphData = {};
    if (map['graphData'] != null && map['graphData'] is Map) {
      (map['graphData'] as Map).forEach((key, value) {
        // Gelen değer String ise int'e çevir, double ise int'e yuvarla, null ise 0 yap.
        int val = 0;
        if (value is int)
          val = value;
        else if (value is double)
          val = value.toInt();
        else if (value is String) val = int.tryParse(value) ?? 0;

        parsedGraphData[key.toString()] = val;
      });
    }

    // --- GÜVENLİ GRAFİK VERİSİ DÖNÜŞÜMÜ (GRUPLU) ---
    Map<String, List<int>> parsedGroupGraphData = {};
    if (map['groupGraphData'] != null && map['groupGraphData'] is Map) {
      (map['groupGraphData'] as Map).forEach((key, value) {
        if (value is List) {
          List<int> cleanList = value
              .map((v) {
                if (v is int) return v;
                if (v is double) return v.toInt();
                if (v is String) return int.tryParse(v) ?? 0;
                return 0;
              })
              .toList()
              .cast<int>();
          parsedGroupGraphData[key.toString()] = cleanList;
        }
      });
    }

    // --- DİĞER TİPLER İÇİN DÖNÜŞÜMLER ---
    Map<String, String>? parsedMatchingPairs;
    if (map['matchingPairs'] != null && map['matchingPairs'] is Map) {
      parsedMatchingPairs = Map<String, String>.from(map['matchingPairs']);
    }

    Map<String, dynamic>? parsedLocation;
    if (map['answerLocation'] != null && map['answerLocation'] is Map) {
      parsedLocation = Map<String, dynamic>.from(map['answerLocation']);
    }

    List<int>? parsedAnswerIndices;
    if (map['answerIndices'] != null && map['answerIndices'] is List) {
      parsedAnswerIndices = List<int>.from(map['answerIndices']);
    }

    return Question(
      id: id,
      text: map['text'] ?? '',
      imageUrl: _parseImage(map['image']),

      // Güvenli Liste Dönüşümü
      options: List<String>.from(map['options'] ?? []),

      // Cevap Anahtarı (Hem 'correct_index' hem 'answerIndex' kontrolü yapar)
      correctAnswerIndex:
          map['correct_index'] ?? map['correctAnswerIndex'] ?? 0,

      // --- SORUNU ÇÖZEN KISIMLAR ---
      isFixed: map['isFixed'] ?? false,
      order: map['order'] ?? 0,
      topicId: map['topicId'] ?? '',

      // Soru Tipi Dönüştürme (String -> Enum)
      type: _questionTypeFromString(map['type']),

      // Özel Veriler
      graphData: parsedGraphData,
      groupGraphData: parsedGroupGraphData,
      graphLegends: map['graphLegends'] != null
          ? List<String>.from(map['graphLegends'])
          : null,
      matchingPairs: parsedMatchingPairs,
      answerLocation: parsedLocation,
      answerIndices: parsedAnswerIndices,
    );
  }

  // Resim linkini almak için yardımcı fonksiyon
  static String? _parseImage(dynamic imageField) {
    if (imageField == null) return null;
    if (imageField is String) {
      return imageField.isNotEmpty ? imageField : null;
    }
    if (imageField is List && imageField.isNotEmpty) {
      // Strapi gibi CMS'lerden gelen liste formatı için
      return imageField[0]['downloadURL'] ?? imageField[0]['url'];
    }
    return null;
  }

  // String gelen tipi Enum'a çeviren yardımcı fonksiyon
  static QuestionType _questionTypeFromString(String? typeString) {
    switch (typeString) {
      case 'multiple_selection':
      case 'multipleSelection':
        return QuestionType.multipleSelection;
      case 'sorting':
        return QuestionType.sorting;
      case 'timeline_rope':
      case 'timelineRope':
        return QuestionType.timelineRope;
      case 'hierarchy_pyramid':
      case 'hierarchyPyramid':
        return QuestionType.hierarchyPyramid;
      case 'flashcard':
        return QuestionType.flashcard;
      case 'find_mistake':
      case 'findMistake':
        return QuestionType.findMistake;
      case 'map_question':
      case 'mapQuestion':
        return QuestionType.mapQuestion;
      case 'graph_interpretation':
      case 'graphInterpretation':
        return QuestionType.graphInterpretation;
      case 'drag_drop':
      case 'dragDrop':
        return QuestionType.dragDrop;
      case 'match':
        return QuestionType.match;
      case 'true_false':
      case 'trueFalse':
        return QuestionType.trueFalse;
      case 'elimination':
        return QuestionType.elimination;
      case 'info_card':
      case 'infoCard':
        return QuestionType.infoCard;
      case 'word_search':
      case 'wordSearch':
        return QuestionType.wordSearch;
      case 'sentence_parsing':
      case 'sentenceParsing':
        return QuestionType.sentenceParsing;
      case 'paragraph_puzzle':
      case 'paragraphPuzzle':
        return QuestionType.paragraphPuzzle;
      case 'bucket_sort':
      case 'bucketSort':
        return QuestionType.bucketSort;
      default:
        return QuestionType.multipleSelection; // Tanımsızsa standart soru yap
    }
  }
}
