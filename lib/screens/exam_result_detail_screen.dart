// DOSYA: lib/screens/exam_result_detail_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ExamResultDetailScreen extends StatefulWidget {
  final String examId;
  final String examTitle;
  final DateTime? date;

  const ExamResultDetailScreen({
    super.key,
    required this.examId,
    required this.examTitle,
    this.date,
  });

  @override
  State<ExamResultDetailScreen> createState() => _ExamResultDetailScreenState();
}

class _ExamResultDetailScreenState extends State<ExamResultDetailScreen> {
  bool _isLoading = true;
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  // Ders Bazlı İstatistikler
  // Örnek Yapı: "MATEMATİK": {correct: 5, incorrect: 1, ...}
  Map<String, Map<String, double>> _lessonStats = {};
  double _totalNet = 0;
  int _totalCorrect = 0;
  int _totalIncorrect = 0;

  @override
  void initState() {
    super.initState();
    _calculateDetailedStats();
  }

  Future<void> _calculateDetailedStats() async {
    try {
      // 1. Kullanıcının Cevaplarını Çek
      var participationDoc = await FirebaseFirestore.instance
          .collection('trial_exams')
          .doc(widget.examId)
          .collection('participations')
          .doc(_userId)
          .get();

      if (!participationDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      Map<String, dynamic> userAnswers =
          participationDoc.data()!['answers'] ?? {};

      // 2. Soruları Çek
      var questionsSnapshot = await FirebaseFirestore.instance
          .collection('trial_exams')
          .doc(widget.examId)
          .collection('questions')
          .orderBy('order')
          .get();

      // 3. Hesaplama Motoru
      Map<String, Map<String, double>> tempStats = {};
      double totalNetCalc = 0;
      int totalCorrectCalc = 0;
      int totalIncorrectCalc = 0;

      for (var doc in questionsSnapshot.docs) {
        var data = doc.data();
        // Ders adını normalize et (Türkçe karakter vb.)
        String lesson = (data['lesson'] ?? 'Genel').toString().toUpperCase();
        // İsteğe bağlı: Ders adlarını daha düzgün formatlayabilirsin (MAP kullanarak)

        int correctAnswer = data['correctAnswerIndex'];
        String qId = doc.id;

        // İstatistik yapısını başlat
        if (!tempStats.containsKey(lesson)) {
          tempStats[lesson] = {
            "correct": 0,
            "incorrect": 0,
            "empty": 0,
            "total": 0,
            "net": 0
          };
        }

        tempStats[lesson]!["total"] = tempStats[lesson]!["total"]! + 1;

        if (userAnswers.containsKey(qId)) {
          int answer = userAnswers[qId];
          if (answer == correctAnswer) {
            tempStats[lesson]!["correct"] = tempStats[lesson]!["correct"]! + 1;
            totalCorrectCalc++;
          } else {
            tempStats[lesson]!["incorrect"] =
                tempStats[lesson]!["incorrect"]! + 1;
            totalIncorrectCalc++;
          }
        } else {
          tempStats[lesson]!["empty"] = tempStats[lesson]!["empty"]! + 1;
        }
      }

      // Net Hesapla (Her ders için ayrı ayrı)
      tempStats.forEach((key, value) {
        double net = value["correct"]! - (value["incorrect"]! / 4);
        value["net"] = net;
        totalNetCalc += net;
      });

      if (mounted) {
        setState(() {
          _lessonStats = tempStats;
          _totalNet = totalNetCalc;
          _totalCorrect = totalCorrectCalc;
          _totalIncorrect = totalIncorrectCalc;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Hata: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateStr = widget.date != null
        ? "${widget.date!.day}/${widget.date!.month}/${widget.date!.year}"
        : "";

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Sınav Analizi",
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- ÜST ÖZET KARTI ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF7D52A0), Color(0xFF9B6BC0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF7D52A0).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5))
                        ]),
                    child: Column(
                      children: [
                        Text(widget.examTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(dateStr,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildBigStat(
                                "Toplam Net", _totalNet.toStringAsFixed(2)),
                            Container(
                                width: 1, height: 40, color: Colors.white24),
                            _buildBigStat("Doğru", "$_totalCorrect"),
                            Container(
                                width: 1, height: 40, color: Colors.white24),
                            _buildBigStat("Yanlış", "$_totalIncorrect"),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Ders Bazlı Performans",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 15),

                  // --- DERS LİSTESİ ---
                  if (_lessonStats.isEmpty)
                    const Text("Analiz verisi bulunamadı.")
                  else
                    ..._lessonStats.entries.map((entry) {
                      return _buildLessonCard(entry.key, entry.value);
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildBigStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        Text(label,
            style:
                TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildLessonCard(String lessonName, Map<String, double> stats) {
    double total = stats["total"]!;
    double correct = stats["correct"]!;
    double incorrect = stats["incorrect"]!;
    double empty = stats["empty"]!;
    double net = stats["net"]!;

    // Başarı oranı (Bar için)
    double successRatio = total > 0 ? (correct / total) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lessonName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFF7D52A0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text("${net.toStringAsFixed(2)} NET",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF7D52A0))),
              )
            ],
          ),
          const SizedBox(height: 15),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: successRatio,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniInfo(Colors.green, "Doğru", "${correct.toInt()}"),
              _buildMiniInfo(Colors.red, "Yanlış", "${incorrect.toInt()}"),
              _buildMiniInfo(Colors.grey, "Boş", "${empty.toInt()}"),
              _buildMiniInfo(Colors.blue, "Toplam", "${total.toInt()}"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniInfo(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text("$value $label",
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
