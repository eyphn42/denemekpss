// DOSYA: lib/screens/quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:kpss_app/models/models.dart';

class QuizScreen extends StatefulWidget {
  final String title; // Konu Başlığı
  final List<Question> questions; // Konuya ait sorular

  const QuizScreen({super.key, required this.title, required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Color zeoPurple = const Color(0xFF7D52A0);
  final Color zeoOrange = const Color(0xFFE67E22);
  final Color correctColor = const Color(0xFF58CC02);
  final Color wrongColor = const Color(0xFFFF4B4B);

  int currentQuestionIndex = 0;
  int score = 0;
  bool isFinished = false;

  int? selectedOptionIndex;
  bool isChecked = false;

  void _onOptionSelected(int index) {
    if (isChecked) return;

    setState(() {
      selectedOptionIndex = index;
      isChecked = true;

      // widget.questions kullanıyoruz artık
      final currentQuestion = widget.questions[currentQuestionIndex];
      if (index == currentQuestion.correctAnswerIndex) {
        score++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      // widget.questions kullanıyoruz
      if (currentQuestionIndex < widget.questions.length - 1) {
        currentQuestionIndex++;
        selectedOptionIndex = null;
        isChecked = false;
      } else {
        isFinished = true;
        isChecked = false;
        selectedOptionIndex = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(backgroundColor: zeoPurple, title: Text(widget.title)),
        body: const Center(child: Text("Bu konuda henüz etkinlik yok.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isFinished
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.grey[800]),
              title: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (currentQuestionIndex + 1) / widget.questions.length,
                  minHeight: 10,
                  backgroundColor: Colors.grey[300],
                  color: zeoOrange,
                ),
              ),
            ),
      bottomNavigationBar:
          (isChecked && !isFinished) ? _buildBottomFeedback() : null,
      body: isFinished ? _buildResultScreen() : _buildQuestionBody(),
    );
  }

  Widget _buildQuestionBody() {
    final question = widget.questions[currentQuestionIndex];

    // Eğer soru tipi DragDrop ise o tasarıma git
    if (question.type == QuestionType.dragDrop) {
      return _buildDragDropBody(question);
    }

    // Değilse (Normal Test) eski tasarımı göster
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Soru ${currentQuestionIndex + 1}",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),
          Text(
            question.text,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: zeoPurple,
            ),
          ),
          const Spacer(),
          ...List.generate(
            question.options.length,
            (index) => _buildOptionButton(index, question),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // --- BU YENİ FONKSİYONU EKLE (Sürükle Bırak Tasarımı) ---
  Widget _buildDragDropBody(Question question) {
    // Soru metnini boşluk (____) kısmından ikiye bölelim
    // Not: Soruda mutlaka "____" ifadesi olmalı.
    List<String> parts = question.text.split('____');
    String part1 = parts.isNotEmpty ? parts[0] : "";
    String part2 = parts.length > 1 ? parts[1] : "";

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Text(
            "Aşağıdaki boşluğu doldur:",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 40),

          // --- CÜMLE VE HEDEF KUTUSU ---
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                part1,
                style: TextStyle(
                    fontSize: 22,
                    color: zeoPurple,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              // HEDEF KUTUSU (DragTarget)
              DragTarget<int>(
                onWillAccept: (data) => !isChecked, // Cevaplandıysa kabul etme
                onAccept: (data) {
                  _onOptionSelected(data); // Bırakıldığında cevabı kontrol et
                },
                builder: (context, candidateData, rejectedData) {
                  // Seçilen şıkkın metni (eğer seçildiyse)
                  String? droppedText;
                  Color boxColor = Colors.grey.shade200;
                  Color borderColor = Colors.grey.shade400;

                  if (selectedOptionIndex != null) {
                    droppedText = question.options[selectedOptionIndex!];
                    // Renk Mantığı (Doğru/Yanlış)
                    if (selectedOptionIndex == question.correctAnswerIndex) {
                      boxColor = correctColor.withOpacity(0.2);
                      borderColor = correctColor;
                    } else {
                      boxColor = wrongColor.withOpacity(0.2);
                      borderColor = wrongColor;
                    }
                  } else if (candidateData.isNotEmpty) {
                    // Üzerine gelince rengi koyulaşsın
                    borderColor = zeoOrange;
                    boxColor = zeoOrange.withOpacity(0.1);
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: boxColor,
                      border: Border.all(
                          color: borderColor,
                          width: 2,
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      droppedText ?? "      ", // Boşsa yer kaplasın diye boşluk
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: selectedOptionIndex != null
                              ? borderColor
                              : Colors.transparent),
                    ),
                  );
                },
              ),

              Text(
                part2,
                style: TextStyle(
                    fontSize: 22,
                    color: zeoPurple,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          const Spacer(),

          // --- SÜRÜKLENECEK SEÇENEKLER ---
          Wrap(
            spacing: 15,
            runSpacing: 15,
            alignment: WrapAlignment.center,
            children: List.generate(question.options.length, (index) {
              // Eğer bu seçenek zaten oraya bırakıldıysa, aşağıda gösterme (Gizle)
              if (isChecked && selectedOptionIndex == index) {
                return const SizedBox(
                    width: 80, height: 50); // Görünmez yer tutucu
              }

              return Draggable<int>(
                data: index, // Taşıdığı veri: Şıkkın indeksi
                feedback: Material(
                  // Sürüklerken görünen hali
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: zeoOrange,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(blurRadius: 10, color: Colors.black26)
                      ],
                    ),
                    child: Text(
                      question.options[index],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                childWhenDragging: Container(
                  // Sürüklenirken geride kalan hali (silik)
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    question.options[index],
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                child: Container(
                  // Normal hali
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: zeoOrange, width: 2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: zeoOrange.withOpacity(0.2),
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Text(
                    question.options[index],
                    style: TextStyle(
                        color: zeoOrange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int index, Question question) {
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = zeoPurple;

    if (isChecked) {
      if (index == question.correctAnswerIndex) {
        backgroundColor = correctColor.withOpacity(0.2);
        borderColor = correctColor;
        textColor = correctColor;
      } else if (index == selectedOptionIndex &&
          index != question.correctAnswerIndex) {
        backgroundColor = wrongColor.withOpacity(0.2);
        borderColor = wrongColor;
        textColor = wrongColor;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton(
        onPressed: () => _onOptionSelected(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: BorderSide(color: borderColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                question.options[index],
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
            ),
            if (isChecked && index == question.correctAnswerIndex)
              Icon(Icons.check_circle, color: correctColor),
            if (isChecked &&
                index == selectedOptionIndex &&
                index != question.correctAnswerIndex)
              Icon(Icons.cancel, color: wrongColor),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomFeedback() {
    final question = widget.questions[currentQuestionIndex];
    bool isCorrect = selectedOptionIndex == question.correctAnswerIndex;

    return Container(
      color: isCorrect
          ? correctColor.withOpacity(0.1)
          : wrongColor.withOpacity(0.1),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? correctColor : wrongColor,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCorrect ? "Harika!" : "Maalesef cevabın hatalı",
                    style: TextStyle(
                      color: isCorrect ? correctColor : wrongColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? correctColor : wrongColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("DEVAM ET",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 100, color: zeoOrange),
          const SizedBox(height: 20),
          Text(
            "Tebrikler!",
            style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold, color: zeoPurple),
          ),
          const SizedBox(height: 10),
          Text(
            "Konu Tamamlandı",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  "Toplam Skor",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                Text(
                  "$score / ${widget.questions.length}",
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: zeoPurple),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            // DİKKAT: Burada 2 kez pop yapabiliriz (Konulara dönmek için)
            // Ama şimdilik 1 kez yapıp TopicsScreen'e dönelim
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: zeoPurple,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("Konulara Dön",
                style: TextStyle(color: Colors.white, fontSize: 16)),
          )
        ],
      ),
    );
  }
}
