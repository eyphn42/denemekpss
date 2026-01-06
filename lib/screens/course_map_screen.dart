// lib/screens/course_map_screen.dart

import 'package:flutter/material.dart';
import '../models/models.dart';
import 'game_screen.dart';

// İSMİ DEĞİŞTİRDİK: Artık eski kodla karışamaz!
class NewUnitMapScreen extends StatelessWidget {
  final Lesson lesson;

  const NewUnitMapScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Arka planı hafif gri yaptık
      appBar: AppBar(title: Text(lesson.name)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lesson.units.length,
        itemBuilder: (context, index) {
          final unit = lesson.units[index];
          // Kilit Kontrolü
          bool isLocked = !unit.isFree && !lesson.isProUnlocked;

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              // Başlık Kısmı
              leading: Icon(
                isLocked ? Icons.lock : Icons.star,
                color: isLocked ? Colors.grey : Colors.orange,
                size: 32,
              ),
              title: Text(
                "Ünite ${unit.id}: ${unit.title}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isLocked ? "Kilitli (Pro Kod Gerekli)" : "Açmak için dokun 👇",
                style: TextStyle(color: isLocked ? Colors.red : Colors.green),
              ),

              // LİSTE AÇILINCA GÖRÜNECEK KISIM (Children)
              children: [
                if (isLocked)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Bu ünite kilitli."),
                  )
                else if (unit.topics.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Bu ünitede henüz konu yok."),
                  )
                else
                  // Konuları Listeliyoruz
                  ...unit.topics.map((topic) {
                    return Container(
                      color: Colors
                          .orange[50], // Konuların arkası hafif turuncu olsun
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.only(left: 30, right: 10),
                        title: Text(topic.title),
                        leading: const Icon(Icons.play_arrow,
                            color: Colors.deepOrange),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          // TIKLAMA KONTROLÜ
                          print(
                              "Tıklanan Konu: ${topic.title}"); // Terminale yazdırır

                          try {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GameScreen(topic: topic),
                              ),
                            );
                          } catch (e) {
                            print("HATA OLUŞTU: $e");
                          }
                        },
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
