import 'package:flutter/material.dart';
import 'home_screen.dart';

class LessonCompleteScreen extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;
  final int earnedXp;

  const LessonCompleteScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.earnedXp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Büyük Görsel / İkon
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 80,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                "Ders Tamamlandı!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF58CC02), // Yeşil renk
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Harika bir iş çıkardın. Hedefine bir adım daha yaklaştın.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 40),

              // İstatistik Kartları
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard("Toplam XP", "+$earnedXp", Colors.orange),
                  _buildStatCard("Doğruluk", "$correctAnswers/$totalQuestions",
                      Colors.blue),
                ],
              ),

              const Spacer(),

              // Devam Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Ana sayfaya dön ve önceki sayfaları sil (geri gelinemez olsun)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58CC02),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    "DEVAM ET",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
