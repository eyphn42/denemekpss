// DOSYA: lib/utils/badge_manager.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// --- ROZET MODELİ ---
class BadgeItem {
  final String id;
  final String name;
  final String description;
  final String assetPath; // Resim yolu (assets/badges/...)
  final bool Function(Map<String, dynamic> stats) condition; // Kazanma şartı

  BadgeItem({
    required this.id,
    required this.name,
    required this.description,
    required this.assetPath,
    required this.condition,
  });
}

class BadgeManager {
  // --- ROZET LİSTESİ (BURADAN DEĞİŞTİREBİLİRSİN) ---
  // Yeni rozet eklemek için bu listeye yeni bir BadgeItem eklemen yeterli.
  static List<BadgeItem> getAllBadges() {
    return [
      BadgeItem(
        id: 'first_step',
        name: 'İlk Adım',
        description: 'İlk deneme sınavını tamamla.',
        assetPath: 'assets/badges/badge_first.png', // Resim dosyası
        condition: (stats) => (stats['totalFinished'] ?? 0) >= 1,
      ),
      BadgeItem(
        id: 'dedicated_student',
        name: 'Azimli Öğrenci',
        description: 'Toplam 5 deneme sınavı bitir.',
        assetPath: 'assets/badges/badge_bronze.png',
        condition: (stats) => (stats['totalFinished'] ?? 0) >= 5,
      ),
      BadgeItem(
        id: 'master_solver',
        name: 'Soru Canavarı',
        description: 'Toplam 100 doğru cevaba ulaş.',
        assetPath: 'assets/badges/badge_gold.png',
        condition: (stats) => (stats['totalCorrect'] ?? 0) >= 100,
      ),
      BadgeItem(
        id: 'high_scorer',
        name: 'Zirveye Oynayan',
        description: 'Bir sınavda 80 NET barajını geç.',
        assetPath: 'assets/badges/badge_diamond.png',
        condition: (stats) => (stats['maxNet'] ?? 0) >= 80.0,
      ),
      // --- YENİ ROZETLERİ BURAYA EKLEYEBİLİRSİN ---
    ];
  }

  // --- İSTATİSTİK HESAPLAYICI ---
  // Kullanıcının tüm sınav geçmişini tarar ve istatistik çıkarır
  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    int totalFinished = 0;
    int totalCorrect = 0;
    double maxNet = 0.0;

    try {
      // 1. Tüm sınavları çek
      var examsSnapshot =
          await FirebaseFirestore.instance.collection('trial_exams').get();

      for (var examDoc in examsSnapshot.docs) {
        // 2. Bu kullanıcının katılımına bak
        var participationDoc = await examDoc.reference
            .collection('participations')
            .doc(userId)
            .get();

        if (participationDoc.exists &&
            participationDoc.data()!['isCompleted'] == true) {
          totalFinished++;

          // Doğru/Yanlış analizi için soruları çekmemiz lazım (veya önceden kaydettiysek oradan okuruz)
          // Performans notu: İdealde sınav bitince 'user_stats' diye ayrı bir tablo güncellenmeli.
          // Ancak şimdilik mevcut yapı üzerinden hesaplıyoruz:

          Map<String, dynamic> answers =
              participationDoc.data()!['answers'] ?? {};

          // Soruları çekip doğru sayısını bulma (Hafif maliyetli işlem)
          var questions = await examDoc.reference.collection('questions').get();
          int currentCorrect = 0;
          int currentIncorrect = 0;

          for (var q in questions.docs) {
            if (answers.containsKey(q.id)) {
              if (answers[q.id] == q['correctAnswerIndex']) {
                currentCorrect++;
              } else {
                currentIncorrect++;
              }
            }
          }

          totalCorrect += currentCorrect;
          double currentNet = currentCorrect - (currentIncorrect / 4);
          if (currentNet > maxNet) maxNet = currentNet;
        }
      }
    } catch (e) {
      print("İstatistik Hatası: $e");
    }

    return {
      'totalFinished': totalFinished,
      'totalCorrect': totalCorrect,
      'maxNet': maxNet,
    };
  }
}
