// lib/screens/lessons_screen.dart

import 'package:flutter/material.dart';
import '../data/data.dart';
import 'course_map_screen.dart'; // Dosya adı aynı kalsa da içindeki sınıf değişti

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dersler")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allLessons.length,
        itemBuilder: (context, index) {
          final lesson = allLessons[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              // ... diğer kısımlar aynı
              onTap: () {
                // BURAYI DEĞİŞTİRİYORUZ!
                // Eski: CourseMapScreen(lesson: lesson),
                // Yeni: NewUnitMapScreen(lesson: lesson),

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewUnitMapScreen(lesson: lesson),
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
