// DOSYA: lib/screens/exam_result_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class ExamResultScreen extends StatefulWidget {
  final String examId;
  final String examTitle;

  const ExamResultScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  bool _isLoading = true;

  // İstatistikler
  int _correctCount = 0;
  int _wrongCount = 0;
  int _emptyCount = 0;
  double _netScore = 0.0;

  // Detaylı Analiz Listesi
  List<Map<String, dynamic>> _analysisList = [];

  @override
  void initState() {
    super.initState();
    _calculateResults();
  }

  Future<void> _calculateResults() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      // 1. Soruları Çek (Doğru cevapları öğrenmek için)
      var qSnapshot = await FirebaseFirestore.instance
          .collection('trial_exams')
          .doc(widget.examId)
          .collection('questions')
          .orderBy('order')
          .get();

      // 2. Kullanıcının Cevaplarını Çek
      var pSnapshot = await FirebaseFirestore.instance
          .collection('trial_exams')
          .doc(widget.examId)
          .collection('participations')
          .doc(userId)
          .get();

      if (!pSnapshot.exists) return; // Hata durumu

      Map<String, dynamic> userAnswers = pSnapshot.data()!['answers'] ?? {};

      // 3. Karşılaştırma ve Hesaplama
      for (var doc in qSnapshot.docs) {
        Map<String, dynamic> qData = doc.data();
        String qId = doc.id;
        int correctAnswerIndex = qData['correctAnswerIndex'] ?? 0;

        // Kullanıcının cevabı var mı?
        bool isAnswered = userAnswers.containsKey(qId);
        int? userAnswerIndex = isAnswered ? userAnswers[qId] : null;

        String status = "empty"; // correct, wrong, empty

        if (!isAnswered) {
          _emptyCount++;
          status = "empty";
        } else if (userAnswerIndex == correctAnswerIndex) {
          _correctCount++;
          status = "correct";
        } else {
          _wrongCount++;
          status = "wrong";
        }

        // Analiz listesine ekle (Listede göstermek için)
        _analysisList.add({
          'questionText': qData['text'],
          'userAnswer': userAnswerIndex,
          'correctAnswer': correctAnswerIndex,
          'status': status,
          'order': qData['order'] ?? 0,
        });
      }

      // 4. KPSS Puan Mantığı (4 Yanlış 1 Doğruyu Götürür)
      _netScore = _correctCount - (_wrongCount / 4.0);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Hata: $e");
    }
  }

  // HTML ve Math Render Yardımcısı (Özet görünüm için sadeleştirildi)
  Widget _renderSimpleHtml(String htmlContent) {
    // HTML taglerini temizleyip sadece metni alalım (Özet için)
    String plainText = htmlContent.replaceAll(RegExp(r'<[^>]*>'), '');
    if (plainText.contains(r'$$')) {
      return const Text("Matematik Sorusu",
          style: TextStyle(fontStyle: FontStyle.italic));
    }
    return Text(
      plainText,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color zeoPurple = Color(0xFF7D52A0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınav Sonucu"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- 1. ÖZET KARTI ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [zeoPurple, Color(0xFF5B3B78)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: zeoPurple.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5))
                        ]),
                    child: Column(
                      children: [
                        Text(widget.examTitle,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem("DOĞRU", _correctCount.toString(),
                                Colors.greenAccent),
                            _buildStatItem("YANLIŞ", _wrongCount.toString(),
                                Colors.redAccent),
                            _buildStatItem("BOŞ", _emptyCount.toString(),
                                Colors.orangeAccent),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 10),
                        Text(
                          "NET: ${_netScore.toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Cevap Anahtarı",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),

                  // --- 2. CEVAP ANAHTARI LİSTESİ ---
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _analysisList.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _analysisList[index];
                      String status = item['status'];
                      Color statusColor;
                      IconData statusIcon;

                      if (status == 'correct') {
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                      } else if (status == 'wrong') {
                        statusColor = Colors.red;
                        statusIcon = Icons.cancel;
                      } else {
                        statusColor = Colors.orange;
                        statusIcon = Icons.remove_circle;
                      }

                      String userAnsChar = item['userAnswer'] != null
                          ? String.fromCharCode(
                              65 + (item['userAnswer'] as int))
                          : "-";
                      String correctAnsChar = String.fromCharCode(
                          65 + (item['correctAnswer'] as int));

                      return Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            // Soru No
                            CircleAvatar(
                              backgroundColor: statusColor.withOpacity(0.1),
                              child: Text("${index + 1}",
                                  style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 15),

                            // Soru Özeti
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _renderSimpleHtml(item['questionText']),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      // Kullanıcı Cevabı
                                      Text("Sen: ",
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12)),
                                      Text(userAnsChar,
                                          style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 15),
                                      // Doğru Cevap
                                      Text("Doğru: ",
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12)),
                                      Text(correctAnsChar,
                                          style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                ],
                              ),
                            ),

                            Icon(statusIcon, color: statusColor),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white),
                      child: const Text("ANA SAYFAYA DÖN"),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }
}
