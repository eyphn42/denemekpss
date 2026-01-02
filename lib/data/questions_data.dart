import '../models/question.dart';

class QuestionData {
  // Artık hem kategori adını hem de ders sırasını istiyoruz
  static List<Question> getQuestions(String category, int lessonIndex) {
    
    // ---------------- TÜRKÇE SORULARI ----------------
    if (category == 'Türkçe') {
      switch (lessonIndex) {
        case 0: // Sözcükte Anlam
          return [
            Question(
              questionText: "Aşağıdakilerden hangisi 'eş sesli' (sesteş) bir kelimedir?",
              options: ["Kitap", "Yüz", "Okul", "Silgi"],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: "'Kara' sözcüğü hangi cümlede mecaz anlamda kullanılmıştır?",
              options: ["Kara gözlü bir çocuktu.", "Kara tahtaya yazı yazdı.", "Bugün kara haberler aldık.", "Üstüne kara bir palto giydi."],
              correctAnswerIndex: 2,
            ),
          ];
        case 1: // Cümlede Anlam
          return [
             Question(
              questionText: "Hangisi öznel bir yargıdır?",
              options: ["Su 100 derecede kaynar.", "Türkiye'nin başkenti Ankara'dır.", "En güzel renk mavidir.", "Bir hafta 7 gündür."],
              correctAnswerIndex: 2,
            ),
          ];
      }
    } 
    
    // ---------------- MATEMATİK SORULARI ----------------
    else if (category == 'Matematik') {
      switch (lessonIndex) {
        case 0: // Temel Kavramlar
          return [
            Question(
              questionText: "En küçük asal sayı kaçtır?",
              options: ["1", "2", "3", "5"],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: "3 + 4 x 2 işleminin sonucu kaçtır?",
              options: ["14", "11", "10", "24"], // İşlem önceliği!
              correctAnswerIndex: 1, 
            ),
          ];
        case 1: // Sayı Basamakları
          return [
             Question(
              questionText: "İki basamaklı en büyük sayı ile iki basamaklı en küçük sayının toplamı kaçtır?",
              options: ["109", "110", "199", "100"],
              correctAnswerIndex: 0, // 99 + 10 = 109
            ),
          ];
      }
    }

    // ---------------- TARİH SORULARI ----------------
    else if (category == 'Tarih') {
      switch (lessonIndex) {
        case 0: // İslamiyet Öncesi
          return [
            Question(
              questionText: "Türk adının anlamı aşağıdakilerden hangisidir?",
              options: ["Güçlü, Kuvvetli", "Miğfer", "Töreli", "Hepsi"],
              correctAnswerIndex: 3, // Farklı kaynaklara göre hepsi
            ),
          ];
      }
    }

    // Varsayılan (Eğer soru eklemediysek bu gelir)
    return [
      Question(
        questionText: "$category - $lessonIndex. Dersin soruları hazırlanıyor.",
        options: ["Tamam", "Beklerim", "Olsun", "Geç"],
        correctAnswerIndex: 0,
      ),
    ];
  }
}