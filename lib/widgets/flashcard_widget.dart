// lib/widgets/flashcard_widget.dart
import 'package:flutter/material.dart';
// Kartı döndürme efekti için

class FlashCardWidget extends StatefulWidget {
  // Bu verileri normalde veritabanından alacağız, şimdilik elle giriyoruz
  final String frontText;
  final String backText;

  const FlashCardWidget(
      {super.key, required this.frontText, required this.backText});

  @override
  State<FlashCardWidget> createState() => _FlashCardWidgetState();
}

class _FlashCardWidgetState extends State<FlashCardWidget> {
  bool isFlipped = false; // Kart döndü mü?

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isFlipped = !isFlipped; // Tıklayınca tersine çevir
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutBack,
          width: 300,
          height: 400,
          decoration: BoxDecoration(
            color: isFlipped
                ? Colors.white
                : Colors.indigo, // Arka beyaz, Ön İndigo
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
            border:
                isFlipped ? Border.all(color: Colors.indigo, width: 2) : null,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // KARTIN ÜSTÜNDEKİ İKON
                  Icon(
                    isFlipped ? Icons.lightbulb : Icons.touch_app,
                    size: 50,
                    color: isFlipped ? Colors.orange : Colors.white54,
                  ),
                  const SizedBox(height: 20),

                  // KARTTAKİ YAZI
                  Text(
                    isFlipped ? widget.backText : widget.frontText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isFlipped ? Colors.black87 : Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),
                  // KÜÇÜK İPUCU YAZISI
                  Text(
                    isFlipped ? "(Cevap)" : "(Çevirmek için dokun)",
                    style: TextStyle(
                      color: isFlipped ? Colors.grey : Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
