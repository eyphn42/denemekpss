import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simple_auth_service.dart';
import '../models/question.dart';
import '../data/questions_data.dart';
import 'lesson_complete_screen.dart';

class QuizScreen extends StatefulWidget {
  final int lessonIndex;
  final String categoryName; // YENİ: Kategori adını da alıyoruz

  QuizScreen({required this.lessonIndex, required this.categoryName});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Question> _questions;
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  bool _isChecked = false;
  bool _isCorrect = false;
  int _correctAnswerCount = 0;

  @override
  void initState() {
    super.initState();
    // YENİ: Soruları çekerken kategori adını da gönderiyoruz
    _questions = QuestionData.getQuestions(widget.categoryName, widget.lessonIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text("Soru bulunamadı.")),
      );
    }

    final question = _questions[_currentQuestionIndex];
    double progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.grey, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 15,
            backgroundColor: Colors.grey[200],
            color: Color(0xFF58CC02),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Doğru cevabı seçin", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2B2B2B))),
                  SizedBox(height: 30),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(question.questionText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  ),
                  SizedBox(height: 30),
                  Expanded(
                    child: ListView.separated(
                      itemCount: question.options.length,
                      separatorBuilder: (context, index) => SizedBox(height: 12),
                      itemBuilder: (context, index) => _buildOptionCard(index, question.options[index], question.correctAnswerIndex),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomArea(question),
        ],
      ),
    );
  }

  Widget _buildBottomArea(Question question) {
    Color bgColor = Colors.transparent;
    String feedbackText = "";
    Color feedbackColor = Colors.transparent;

    if (_isChecked) {
      bgColor = _isCorrect ? Color(0xFFd7ffb8) : Color(0xFFffdfe0);
      feedbackText = _isCorrect ? "Harika!" : "Doğru cevap: ${question.options[question.correctAnswerIndex]}";
      feedbackColor = _isCorrect ? Color(0xFF58a700) : Colors.red;
    }

    return Container(
      color: bgColor,
      padding: EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isChecked) ...[
              Row(
                children: [
                  Icon(
                    _isCorrect ? Icons.check_circle : Icons.cancel,
                    color: feedbackColor,
                    size: 30,
                  ),
                  SizedBox(width: 10),
                  Text(
                    _isCorrect ? "Mükemmel!" : "Yanlış!",
                    style: TextStyle(
                      color: feedbackColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              if (!_isCorrect)
                Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    feedbackText,
                    style: TextStyle(color: feedbackColor, fontSize: 16),
                  ),
                ),
              SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedOptionIndex == null ? null : () => _handleCheckAnswer(question),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isChecked 
                      ? (_isCorrect ? Color(0xFF58CC02) : Colors.red) 
                      : Color(0xFF58CC02),
                  disabledBackgroundColor: Colors.grey[300],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  _isChecked ? "DEVAM ET" : "KONTROL ET",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(int index, String text, int correctIndex) {
    bool isSelected = _selectedOptionIndex == index;
    Color borderColor = Colors.grey[300]!;
    Color bgColor = Colors.white;

    if (_isChecked) {
      if (index == correctIndex) {
        borderColor = Color(0xFF58CC02);
        bgColor = Color(0xFF58CC02).withOpacity(0.1);
      } else if (isSelected && index != correctIndex) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
      }
    } else if (isSelected) {
      borderColor = Color(0xFF1CB0F6);
      bgColor = Color(0xFF1CB0F6).withOpacity(0.1);
    }

    return GestureDetector(
      onTap: _isChecked ? null : () => setState(() => _selectedOptionIndex = index),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(["A", "B", "C", "D"][index], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
            ),
            SizedBox(width: 12),
            Expanded(child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  void _handleCheckAnswer(Question question) {
    if (_isChecked) {
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedOptionIndex = null;
          _isChecked = false;
        });
      } else {
        Provider.of<SimpleAuthService>(context, listen: false).completeLesson(widget.categoryName, widget.lessonIndex);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LessonCompleteScreen(
              totalQuestions: _questions.length,
              correctAnswers: _correctAnswerCount,
              earnedXp: _correctAnswerCount * 10,
            ),
          ),
        );
      }
    } else {
      bool correct = _selectedOptionIndex == question.correctAnswerIndex;
      setState(() {
        _isChecked = true;
        _isCorrect = correct;
        if (correct) {
          _correctAnswerCount++;
        }
      });
    }
  }
}