// DOSYA: lib/services/database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kpss_app/models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // 1. DERSLERİ ÇEK (Home Screen için)
  // ---------------------------------------------------------------------------
  Stream<List<Lesson>> getLessons() {
    return _db
        .collection('lessons')
        .orderBy('order', descending: false) // Admin'deki sıraya göre getir
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Lesson.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // 2. ÜNİTELERİ ÇEK (UnitsScreen kullanır)
  // ---------------------------------------------------------------------------
  Stream<List<Unit>> getUnits(String lessonId) {
    return _db
        .collection('units')
        .where('lessonId', isEqualTo: lessonId)
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Unit.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // 3. KONULARI ÇEK (TopicsScreen kullanır)
  // ---------------------------------------------------------------------------
  Stream<List<Topic>> getTopics(String unitId) {
    return _db
        .collection('topics')
        .where('unitId', isEqualTo: unitId)
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Topic.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // 4. SORULARI ÇEK (QuizScreen kullanır) - AKILLI SIRALAMA ALGORİTMASI
  // ---------------------------------------------------------------------------
  Future<List<Question>> getQuestionsForTopic(String topicId) async {
    try {
      // 1. Tüm soruları çek
      QuerySnapshot snapshot = await _db
          .collection('questions')
          .where('topicId', isEqualTo: topicId)
          .get();

      if (snapshot.docs.isEmpty) return [];

      // 2. Veriyi Modele Çevir
      List<Question> allQuestions = snapshot.docs.map((doc) {
        return Question.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // --- MANTIK: AKILLI YERLEŞTİRME (SMART PLACEMENT) ---

      // A) Listeleri Ayır
      List<Question> fixedQuestions = []; // Raptiyeli (Sabit)
      List<Question> shufflingQuestions = []; // Raptiyesiz (Karışacak)

      for (var q in allQuestions) {
        if (q.isFixed) {
          fixedQuestions.add(q);
        } else {
          shufflingQuestions.add(q);
        }
      }

      // B) Raptiyesizleri Karıştır (Her testte farklı sıra olsun)
      shufflingQuestions.shuffle();

      // C) Sonuç Listesini Hazırla (Hepsi null ile dolu, koltuk sayısı kadar)
      List<Question?> resultList =
          List<Question?>.filled(allQuestions.length, null);

      // D) Önce Sabitleri (Raptiyelileri) Admin'deki Yerlerine Çivile
      for (var q in fixedQuestions) {
        // Eğer sıra numarası geçerliyse ve o koltuk boşsa
        if (q.order >= 0 && q.order < resultList.length) {
          if (resultList[q.order] == null) {
            resultList[q.order] = q; // Soruyu tam o sıraya koy
          } else {
            // Çakışma varsa (Aynı yere 2 soru raptiyelenmişse) havuza at
            shufflingQuestions.add(q);
          }
        } else {
          // Sıra numarası liste dışındaysa havuza at
          shufflingQuestions.add(q);
        }
      }

      // E) Kalan Boşlukları (Null) Karışık Sorularla Doldur
      int poolIndex = 0;
      for (int i = 0; i < resultList.length; i++) {
        if (resultList[i] == null) {
          if (poolIndex < shufflingQuestions.length) {
            resultList[i] = shufflingQuestions[poolIndex];
            poolIndex++;
          }
        }
      }

      // F) Listeyi Temizle (Olası null'ları at) ve Döndür
      return resultList.whereType<Question>().toList();
    } catch (e) {
      print("Hata (getQuestionsForTopic): $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // ESKİ FONKSİYONLAR
  // ---------------------------------------------------------------------------
  Future<List<Question>> getQuestions(String lessonId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('questions')
          .where('lessonId', isEqualTo: lessonId)
          .get();

      return snapshot.docs.map((doc) {
        return Question.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print("Hata: $e");
      return [];
    }
  }
}
