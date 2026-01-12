// DOSYA: lib/screens/exam_waiting_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'exam_screen.dart'; // Sınav ekranını import ediyoruz

class ExamWaitingScreen extends StatefulWidget {
  final String examId;
  final String examTitle;
  final DateTime startTime;
  final int durationMinutes;

  const ExamWaitingScreen({
    super.key,
    required this.examId,
    required this.examTitle,
    required this.startTime,
    required this.durationMinutes,
  });

  @override
  State<ExamWaitingScreen> createState() => _ExamWaitingScreenState();
}

class _ExamWaitingScreenState extends State<ExamWaitingScreen> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isExamStarted = false;

  @override
  void initState() {
    super.initState();
    _calculateTime();

    // Her saniye sayacı güncelle
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTime() {
    final now = DateTime.now();

    if (now.isAfter(widget.startTime)) {
      // Sınav başladıysa
      if (!_isExamStarted) {
        setState(() {
          _isExamStarted = true;
          _remainingTime = Duration.zero;
        });
        _timer?.cancel(); // Sayacı durdur
      }
    } else {
      // Sınav başlamadıysa farkı hesapla
      setState(() {
        _remainingTime = widget.startTime.difference(now);
      });
    }
  }

  // Format: 01 : 15 : 30
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(d.inHours);
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours : $minutes : $seconds";
  }

  void _enterExam() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExamScreen(
          examId: widget.examId,
          examTitle: widget.examTitle,
          durationMinutes: widget.durationMinutes,
          startTime: widget.startTime, // <-- BUNU EKLE
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color zeoPurple = Color(0xFF7D52A0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Üst İkon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: zeoPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isExamStarted ? Icons.lock_open : Icons.lock_clock,
                  size: 60,
                  color: zeoPurple,
                ),
              ),
              const SizedBox(height: 30),

              // Başlık
              Text(
                widget.examTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              // Durum Metni
              Text(
                _isExamStarted
                    ? "Sınav Erişime Açıldı!"
                    : "Bu sınav henüz başlamadı.\nLütfen geri sayımın bitmesini bekleyiniz.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // --- BÜYÜK SAYAÇ ---
              if (!_isExamStarted) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5))
                      ]),
                  child: Column(
                    children: [
                      const Text(
                        "KALAN SÜRE",
                        style: TextStyle(
                            color: Colors.grey, fontSize: 12, letterSpacing: 2),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _formatDuration(_remainingTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily:
                              'Courier', // Monospace font (rakamlar titremez)
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Başlangıç: ${DateFormat('dd MMMM HH:mm', 'tr').format(widget.startTime)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: zeoPurple),
                ),
              ],

              const Spacer(),

              // --- BUTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isExamStarted
                      ? _enterExam
                      : null, // Başlamadıysa tıklanamaz
                  style: ElevatedButton.styleFrom(
                    backgroundColor: zeoPurple,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: _isExamStarted ? 5 : 0,
                  ),
                  child: Text(
                    _isExamStarted ? "SINAVA BAŞLA" : "BEKLENİYOR...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          _isExamStarted ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
