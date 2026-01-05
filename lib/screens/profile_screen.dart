import 'package:flutter/material.dart';
import '../models/question.dart'; // Question modelinin olduğu yer

class QuizScreen extends StatefulWidget {
  // --- EKLENEN KISIM BAŞLANGIÇ ---
  // Dışarıdan ders numarasını (index) alıyoruz
  final int lessonIndex;

  const QuizScreen({
    super.key,
    required this.lessonIndex, // Bunu zorunlu hale getirdik
  });
  // --- EKLENEN KISIM BİTİŞ ---

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // --- DEĞİŞKENLER ---
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _isChecked = false;
  bool _isCorrect = false;

  // --- RENKLER ---
  final Color _primaryColor = const Color(0xFF7D52A0);
  final Color _correctColor = const Color(0xFF58CC02);
  final Color _wrongColor = const Color(0xFFFF4B4B);

  // --- FONKSİYONLAR ---
  void _checkAnswer() {
    if (_selectedOptionIndex == null) return;

    final currentQuestion = demoQuestions[_currentIndex];
    bool correct = _selectedOptionIndex == currentQuestion.correctAnswerIndex;

    setState(() {
      _isChecked = true;
      _isCorrect = correct;
    });

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildResultSheet(),
    );
  }

  void _nextQuestion() {
    Navigator.pop(context); // Paneli kapat

    if (_currentIndex < demoQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _isChecked = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tebrikler! Ünite tamamlandı.")),
      );
      Navigator.pop(context);
    }
  }

  // --- ARAYÜZ ---
  @override
  Widget build(BuildContext context) {
    final question = demoQuestions[_currentIndex];
    double progress = (_currentIndex + 1) / demoQuestions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: Stack(
          children: [
            Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 16,
              width: MediaQuery.of(context).size.width * 0.7 * progress,
              decoration: BoxDecoration(
                color: _correctColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Başlıkta hangi ünitede olduğumuzu gösterebiliriz (İsteğe bağlı)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Ünite ${widget.lessonIndex + 1}", // Gelen indexi burada kullandık
                  style: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Soru ${_currentIndex + 1}",
                  style: TextStyle(
                      color: Colors.grey[600], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              question.questionText,
              style: TextStyle(
                color: _primaryColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  bool isSelected = _selectedOptionIndex == index;
                  return GestureDetector(
                    onTap: _isChecked
                        ? null
                        : () {
                            setState(() => _selectedOptionIndex = index);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFFEADDFF) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected ? _primaryColor : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isSelected ? _primaryColor : Colors.white,
                              border: Border.all(color: _primaryColor),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : _primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              question.options[index],
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _selectedOptionIndex == null ? null : _checkAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _correctColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "KONTROL ET",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isCorrect ? const Color(0xFFD7FFB8) : const Color(0xFFFFDFE0),
        border: Border(
          top: BorderSide(
            color: _isCorrect ? _correctColor : _wrongColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isCorrect ? Icons.check_circle : Icons.cancel,
                color: _isCorrect ? _correctColor : _wrongColor,
                size: 30,
              ),
              const SizedBox(width: 10),
              Text(
                _isCorrect ? "Harika!" : "Hatalı Cevap",
                style: TextStyle(
                  color: _isCorrect ? _correctColor : _wrongColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!_isCorrect)
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                "Doğru Cevap: ${demoQuestions[_currentIndex].options[demoQuestions[_currentIndex].correctAnswerIndex]}",
                style: TextStyle(
                    color: _wrongColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCorrect ? _correctColor : _wrongColor,
                elevation: 0,
              ),
              onPressed: _nextQuestion,
              child: Text(
                _currentIndex == demoQuestions.length - 1
                    ? "BİTİR"
                    : "DEVAM ET",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
