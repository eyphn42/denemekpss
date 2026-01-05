// DOSYA ADI: lib/screens/quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question.dart'; // <--- 1. Adımda oluşturduğumuz dosya

class QuizScreen extends StatefulWidget {
  final String courseId; // Hangi ders?
  final String unitId; // Hangi ünite?
  final String unitTitle; // Başlık

  const QuizScreen({
    super.key,
    required this.courseId,
    required this.unitId,
    required this.unitTitle,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _isChecked = false;
  bool _isCorrect = false;

  final Color _primaryColor = const Color(0xFF7D52A0);
  final Color _correctColor = const Color(0xFF58CC02);
  final Color _wrongColor = const Color(0xFFFF4B4B);

  // Veritabanından gelen soruları burada tutacağız
  List<Question> _questions = [];

  void _checkAnswer() {
    if (_selectedOptionIndex == null) return;

    final currentQuestion = _questions[_currentIndex];
    bool correct = _selectedOptionIndex == currentQuestion.answerIndex;

    setState(() {
      _isChecked = true;
      _isCorrect = correct;
    });

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildResultSheet(currentQuestion),
    );
  }

  void _nextQuestion() {
    Navigator.pop(context);

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _isChecked = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tebrikler! Ünite bitti.")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.unitTitle,
            style: const TextStyle(fontSize: 18, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // --- STREAMBUILDER İLE VERİTABANI BAĞLANTISI ---
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .collection('units')
            .doc(widget.unitId)
            .collection('questions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Bu ünitede henüz soru yok."));
          }

          // Verileri modele çevir
          _questions = snapshot.data!.docs.map((doc) {
            return Question.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();

          if (_questions.isEmpty) return const SizedBox();

          // Mevcut soru
          final question = _questions[_currentIndex];
          double progress = (_currentIndex + 1) / _questions.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    color: _correctColor,
                    minHeight: 10,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Soru ${_currentIndex + 1}",
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        question.text,
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Görsel varsa göster
                      if (question.imageUrl != null)
                        Container(
                          height: 200,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            image: DecorationImage(
                              image: NetworkImage(question.imageUrl!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                      // Şıklar
                      ...List.generate(question.options.length, (index) {
                        bool isSelected = _selectedOptionIndex == index;
                        return GestureDetector(
                          onTap: _isChecked
                              ? null
                              : () =>
                                  setState(() => _selectedOptionIndex = index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEADDFF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? _primaryColor
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundColor:
                                      isSelected ? _primaryColor : Colors.white,
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : _primaryColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    question.options[index],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                        _selectedOptionIndex == null ? null : _checkAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _correctColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("KONTROL ET",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultSheet(Question currentQuestion) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isCorrect ? const Color(0xFFD7FFB8) : const Color(0xFFFFDFE0),
        border: Border(
            top: BorderSide(
                color: _isCorrect ? _correctColor : _wrongColor, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_isCorrect ? Icons.check_circle : Icons.cancel,
                  color: _isCorrect ? _correctColor : _wrongColor, size: 30),
              const SizedBox(width: 10),
              Text(_isCorrect ? "Harika!" : "Hatalı Cevap",
                  style: TextStyle(
                      color: _isCorrect ? _correctColor : _wrongColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          if (!_isCorrect)
            Text(
                "Doğru Cevap: ${currentQuestion.options[currentQuestion.answerIndex]}",
                style:
                    TextStyle(color: _wrongColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _isCorrect ? _correctColor : _wrongColor),
              onPressed: _nextQuestion,
              child: const Text("DEVAM ET",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
