// DOSYA: lib/screens/game_screen.dart

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/drag_drop_widget.dart';

class GameScreen extends StatefulWidget {
  final Topic topic;

  const GameScreen({super.key, required this.topic});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _currentIndex = 0;
  bool _isStepCompleted = false;

  void _nextStep() {
    setState(() {
      if (_currentIndex < widget.topic.activities.length - 1) {
        _currentIndex++;
        _isStepCompleted = false;
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tebrikler! Konu tamamlandı 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listeden o anki Aktivite nesnesini alıyoruz
    final Activity currentActivity = widget.topic.activities[_currentIndex];

    double progress = (_currentIndex + 1) / widget.topic.activities.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic.title, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            color: Colors.green,
            minHeight: 6,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            // BURADA ARTIK SAHTE VERİ DEĞİL, Activity NESNESİNİN İÇİNDEKİ DATAYI KULLANIYORUZ
            child: _buildGameBody(currentActivity),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildGameBody(Activity activity) {
    switch (activity.type) {
      // 1. HAFIZA KARTI
      case ActivityType.flashCard:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isStepCompleted) {
            setState(() => _isStepCompleted = true);
          }
        });

        return FlashCardWidget(
          // data.dart dosyasındaki anahtarları kullanıyoruz ('front', 'back')
          frontText: activity.data['front'] ?? "Hata: Veri Yok",
          backText: activity.data['back'] ?? "Hata: Veri Yok",
        );

      // 2. SÜRÜKLE BIRAK
      case ActivityType.dragDrop:
        return DragDropWidget(
          // data.dart dosyasındaki anahtarları kullanıyoruz
          sentencePart1: activity.data['part1'],
          sentencePart2: activity.data['part2'],
          correctWord: activity.data['correct'],
          // List<String> olarak cast ediyoruz
          options: List<String>.from(activity.data['options']),

          onCorrectAnswer: () {
            setState(() {
              _isStepCompleted = true;
            });
          },
        );

      // DİĞERLERİ
      default:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isStepCompleted) setState(() => _isStepCompleted = true);
        });
        return Center(
          child: Text("${activity.type.name} hazırlanıyor..."),
        );
    }
  }

  Widget _buildBottomBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: _isStepCompleted ? _nextStep : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isStepCompleted ? Colors.green : Colors.grey[300],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: _isStepCompleted ? 2 : 0,
        ),
        child: Text(
          _currentIndex == widget.topic.activities.length - 1
              ? "BİTİR"
              : "DEVAM ET",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
