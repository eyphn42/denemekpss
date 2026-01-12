// DOSYA: lib/screens/exam_success_screen.dart

import 'package:flutter/material.dart';
import 'home_screen.dart'; // <-- BURAYI KENDİ ANASAYFA DOSYA ADINLA DEĞİŞTİR

class ExamSuccessScreen extends StatelessWidget {
  final String examTitle;
  final DateTime startTime;
  final int durationMinutes;

  const ExamSuccessScreen({
    super.key,
    required this.examTitle,
    required this.startTime,
    required this.durationMinutes,
  });

  @override
  Widget build(BuildContext context) {
    // Sınav bittiği anki zaman
    final endTime = DateTime.now();
    final difference = endTime.difference(startTime);

    // Geçen süreyi formatla (dk:sn)
    String timeSpent =
        "${difference.inMinutes.toString().padLeft(2, '0')}:${(difference.inSeconds % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Başarı İkonu
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 60),
              ),
              const SizedBox(height: 30),

              const Text(
                "Sınav Tamamlandı!",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Text(
                examTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, color: Colors.grey, fontFamily: 'Omnes'),
              ),

              const SizedBox(height: 40),

              // İstatistik Kartı
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(Icons.timer, "Süre", timeSpent),
                    _buildStatItem(Icons.event_available, "Durum", "Bitti"),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // ANASAYFAYA DÖN BUTONU
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // --- KRİTİK DÜZELTME BURADA ---
                    // WelcomeScreen yerine HomeScreen'e gidiyoruz.
                    // (route) => false diyerek gerideki tüm ekranları (sınav, loading vs) siliyoruz.
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7D52A0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  child: const Text("Anasayfaya Dön",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: () {
                  // İstersen burada "Sonuçlarımı Gör" gibi başka bir sayfaya da yönlendirebilirsin
                  // Şimdilik bu da anasayfaya gitsin
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text("Sonuçlarım",
                    style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF7D52A0), size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
