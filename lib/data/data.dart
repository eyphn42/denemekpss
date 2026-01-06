// DOSYA: lib/data/data.dart

import 'package:kpss_app/models/models.dart';

final Lesson turkishLesson = Lesson(
  id: 'turkce',
  title: 'Türkçe',
  isProUnlocked: false,
  units: [
    // --- ÜNİTE 1: SÖZCÜKTE ANLAM ---
    Unit(
      id: 'u1',
      title: 'Sözcükte Anlam',
      isFree: true,
      topics: [
        // KONU 1
        Topic(
          id: 't1',
          title: '1. Gerçek ve Mecaz Anlam',
          questions: [
            Question(
              text: '"Keskin" sözcüğü hangisinde mecaz anlamdadır?',
              options: [
                'Keskin bıçak.',
                'Keskin zeka.',
                'Keskin koku.',
                'Keskin nişancı.'
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              text: 'Hangisi gerçek anlamda kullanılmıştır?',
              options: ['Ağır söz', 'Boş bakış', 'Sıcak hava', 'İnce davranış'],
              correctAnswerIndex: 2,
            ),
          ],
        ),
        // KONU 2
        Topic(
          id: 't2',
          title: '2. Terim ve Yan Anlam',
          questions: [
            Question(
              text: 'Hangisi bir terimdir?',
              options: ['Açı', 'Masa', 'Kalem', 'Silgi'],
              correctAnswerIndex: 0,
            ),
          ],
        ),
        // KONU 3 (Örnek olarak 10 etkinlik varmış gibi çoğaltabiliriz)
        Topic(id: 't3', title: '3. Eş ve Zıt Anlam', questions: []),
        Topic(id: 't4', title: '4. Yansıma Sözcükler', questions: []),
        Topic(id: 't5', title: '5. İkilemeler', questions: []),
      ],
    ),

    // --- ÜNİTE 2: CÜMLEDE ANLAM ---
    Unit(
      id: 'u2',
      title: 'Cümlede Anlam',
      isFree: true,
      topics: [
        Topic(
          id: 't_drag',
          title: 'Etkinlik: Boşluk Doldurma',
          questions: [
            // SÜRÜKLE BIRAK SORUSU
            Question(
              type: QuestionType.dragDrop, // Tipi burada belirtiyoruz
              text:
                  "Gülünç duruma düşecek davranışlarda bulunmak anlamına gelen deyim '____ olmak' tır.",
              options: ['Maymun', 'Kuş', 'Aslan', 'Tilki'], // Sürüklenecekler
              correctAnswerIndex: 0, // Doğru cevap: Maymun (olmak)
            ),
            // NORMAL TEST SORUSU
            Question(
              text: 'Hangisi bir meyvedir?',
              options: ['Elma', 'Pırasa', 'Ispanak', 'Patates'],
              correctAnswerIndex: 0,
            ),
          ],
        ),
        Topic(
          id: 't2_1',
          title: '1. Öznel ve Nesnel Yargı',
          questions: [
            Question(
              text: 'Hangisi nesnel bir yargıdır?',
              options: [
                'Güzel bir gün.',
                'Mavi en iyi renktir.',
                'Su sıvıdır.',
                'Film sıkıcıydı.'
              ],
              correctAnswerIndex: 2,
            ),
          ],
        ),
      ],
    ),
  ],
);
