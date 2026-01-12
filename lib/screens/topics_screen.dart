// DOSYA: lib/screens/topics_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kpss_app/models/models.dart';
import 'package:kpss_app/services/database_service.dart';
import 'quiz_screen.dart';

class TopicsScreen extends StatelessWidget {
  final Unit unit;
  final String courseId;

  const TopicsScreen({
    super.key,
    required this.unit,
    required this.courseId,
  });

  void _handleTopicTap(
      BuildContext context, Topic topic, int totalTopicCount) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()));

    List<Question> questions =
        await DatabaseService().getQuestionsForTopic(topic.id);

    // --- KONTROL İÇİN EKLENDİ ---
    print("Çekilen Soru Sayısı: ${questions.length}");
    // ----------------------------

    if (!context.mounted) return;
    Navigator.pop(context);

    if (questions.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            title: topic.title,
            questions: questions,
            courseId: courseId,
            unitId: unit.id,
            topicId: topic.id,
            totalTopicCount: totalTopicCount,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bu konuda henüz soru yok.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    const Color zeoPurple = Color(0xFF7D52A0);
    const Color zeoOrange = Color(0xFFE67E22);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(unit.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: zeoPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // 1. ADIM: İLERLEME VERİSİNİ DİNLE
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('progress')
            .doc(courseId)
            .snapshots(),
        builder: (context, progressSnapshot) {
          List<dynamic> completedTopics = [];
          if (progressSnapshot.hasData && progressSnapshot.data!.exists) {
            var data = progressSnapshot.data!.data() as Map<String, dynamic>;
            // Bu üniteye ait tamamlanmış konuların listesini al
            completedTopics = data['completed_topics_${unit.id}'] ?? [];
          }

          return StreamBuilder<List<Topic>>(
            // 2. ADIM: KONULARI ÇEK
            stream: DatabaseService().getTopics(unit.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("Bu ünitede konu bulunamadı."));
              }

              final topics = snapshot.data!;

              // Ünite toplam ilerlemesini hesapla
              double unitProgress =
                  topics.isEmpty ? 0 : completedTopics.length / topics.length;

              return Column(
                children: [
                  // --- ÜST BİLGİ ALANI (İLERLEME) ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    decoration: const BoxDecoration(
                        color: zeoPurple,
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(30))),
                    child: Column(
                      children: [
                        const Text("Ünite İlerlemesi",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: unitProgress,
                            minHeight: 12,
                            backgroundColor: Colors.black26,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF58CC02)), // Duolingo Yeşili
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text("%${(unitProgress * 100).toInt()} Tamamlandı",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // --- KONU LİSTESİ (LEVEL HARİTASI GİBİ) ---
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final topic = topics[index];

                        // DURUM KONTROLÜ
                        bool isCompleted = completedTopics.contains(topic.id);

                        // Kilit Mantığı:
                        // 1. İlk konu her zaman açıktır.
                        // 2. Diğer konular, bir önceki konu "completed" listesindeyse açılır.
                        bool isLocked = false;
                        if (index > 0) {
                          String prevTopicId = topics[index - 1].id;
                          if (!completedTopics.contains(prevTopicId)) {
                            isLocked = true;
                          }
                        }

                        // Eğer tamamlanmışsa kilitli olamaz (Veri tutarsızlığına karşı önlem)
                        if (isCompleted) isLocked = false;

                        // Sıradaki Aktif Konu mu? (Kilitli değil ve henüz bitmemiş)
                        bool isCurrent = !isLocked && !isCompleted;

                        return _buildLevelCard(
                          context: context,
                          index: index,
                          topic: topic,
                          isCompleted: isCompleted,
                          isLocked: isLocked,
                          isCurrent: isCurrent,
                          totalTopics: topics.length,
                          onTap: () =>
                              _handleTopicTap(context, topic, topics.length),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLevelCard({
    required BuildContext context,
    required int index,
    required Topic topic,
    required bool isCompleted,
    required bool isLocked,
    required bool isCurrent,
    required int totalTopics,
    required VoidCallback onTap,
  }) {
    // Tasarım Renkleri
    Color cardColor = Colors.white;
    Color iconColor = Colors.grey;
    IconData statusIcon = Icons.lock;
    double elevation = 2;

    if (isCompleted) {
      cardColor = Colors.green.shade50;
      iconColor = Colors.green;
      statusIcon = Icons.check_circle;
      elevation = 1;
    } else if (isCurrent) {
      cardColor = Colors.white;
      iconColor = const Color(0xFFE67E22); // ZeoOrange
      statusIcon = Icons.play_circle_fill;
      elevation = 8; // Öne çıksın
    } else {
      // Locked
      cardColor = Colors.grey.shade200;
      iconColor = Colors.grey.shade400;
      statusIcon = Icons.lock;
      elevation = 0;
    }

    return GestureDetector(
      onTap: isLocked
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Önceki konuyu tamamlamalısın! 🔒"),
                  duration: Duration(milliseconds: 1000)));
            }
          : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        child: IntrinsicHeight(
          // Yan çizgi için yükseklik hesaplama
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. SOL TARAFTAKİ ÇİZGİ VE BALONCUK
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    // Üst Çizgi (İlk eleman hariç)
                    Expanded(
                      child: index == 0
                          ? const SizedBox()
                          : Container(
                              width: 4,
                              color: isCompleted || isCurrent
                                  ? Colors.green.shade200
                                  : Colors.grey.shade300),
                    ),
                    // Baloncuk (Level No)
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFE67E22)
                              : (isCompleted
                                  ? Colors.green
                                  : Colors.grey.shade400),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4)
                          ]),
                      child: Text("${index + 1}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                    // Alt Çizgi (Son eleman hariç)
                    Expanded(
                      child: index == totalTopics - 1
                          ? const SizedBox()
                          : Container(
                              width: 4,
                              color: isCompleted
                                  ? Colors.green.shade200
                                  : Colors.grey.shade300),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // 2. KARTIN KENDİSİ
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: isCurrent
                                ? const Color(0xFFE67E22).withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: elevation,
                            offset: Offset(0, elevation / 2))
                      ],
                      border: isCurrent
                          ? Border.all(color: const Color(0xFFE67E22), width: 2)
                          : null),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(topic.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isLocked
                                        ? Colors.grey
                                        : Colors.black87)),
                            if (isCurrent)
                              const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Text("Sıradaki Etkinlik",
                                    style: TextStyle(
                                        color: Color(0xFFE67E22),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            if (isCompleted)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text("Tamamlandı",
                                    style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),

                      // Sağ İkon (Play, Lock, Check)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFE67E22)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIcon,
                            color: isCurrent ? Colors.white : iconColor,
                            size: 28),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
