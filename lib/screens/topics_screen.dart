// DOSYA: lib/screens/topics_screen.dart

import 'package:flutter/material.dart';
import 'package:kpss_app/models/models.dart';
import 'quiz_screen.dart';

class TopicsScreen extends StatelessWidget {
  final Unit unit;

  const TopicsScreen({super.key, required this.unit});

  @override
  Widget build(BuildContext context) {
    // Renkler
    final Color zeoPurple = const Color(0xFF7D52A0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(unit.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: zeoPurple,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: unit.topics.length,
        separatorBuilder: (context, index) => const SizedBox(height: 15),
        itemBuilder: (context, index) {
          final topic = unit.topics[index];

          return Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              leading: CircleAvatar(
                backgroundColor: zeoPurple.withOpacity(0.1),
                child: Text(
                  "${index + 1}",
                  style:
                      TextStyle(color: zeoPurple, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                topic.title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text("${topic.questions.length} Soru / Etkinlik"),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey),
              onTap: () {
                // Konuya tıklayınca o konunun sorularını alıp Quiz'e gidiyoruz
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                        title: topic.title, // Başlık artık Konu adı
                        questions: topic.questions // Sorular konudan geliyor
                        ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
