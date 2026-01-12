import 'package:flutter/material.dart';
import 'package:kpss_app/models/models.dart';

class EliminationWidget extends StatefulWidget {
  final Question question;
  final Function(bool) onAnswerChanged;

  const EliminationWidget({
    Key? key,
    required this.question,
    required this.onAnswerChanged,
  }) : super(key: key);

  @override
  State<EliminationWidget> createState() => _EliminationWidgetState();
}

class _EliminationWidgetState extends State<EliminationWidget> {
  // Hangi kelime görünür, hangisi silindi?
  late List<bool> _isVisible;
  bool _isAnswered = false;
  int? _wrongSelectedIndex; // Yanlış tıklananı kırmızı yakmak için

  @override
  void initState() {
    super.initState();
    // Başlangıçta hepsi görünür (true)
    _isVisible = List.filled(widget.question.options.length, true);
  }

  void _handleWordTap(int index) {
    if (_isAnswered) return; // Zaten cevaplandıysa işlem yapma

    setState(() {
      if (index == widget.question.correctAnswerIndex) {
        // DOĞRU CEVAP: Kelimeyi yok et (Buharlaştır)
        _isVisible[index] = false;
        _isAnswered = true;
        _wrongSelectedIndex = null;
        widget.onAnswerChanged(true); // Ebeveyn'e bildir
      } else {
        // YANLIŞ CEVAP: Kırmızı yak
        _wrongSelectedIndex = index;
        _isAnswered = true;
        widget.onAnswerChanged(false); // Ebeveyn'e bildir
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Soru Metni (Yönerge)
        Text(
          widget.question.text, // Örn: "Gereksiz sözcüğe dokunarak yok et."
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // Cümle (Wrap içinde kelimeler)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8.0, // Kelimeler arası boşluk
            runSpacing: 12.0, // Satırlar arası boşluk
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: List.generate(widget.question.options.length, (index) {
              return _buildWordChip(index);
            }),
          ),
        ),

        const SizedBox(height: 40),
        if (_isAnswered && _wrongSelectedIndex != null)
          const Text(
            "Yanlış kelimeyi seçtin!",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        if (_isAnswered && _wrongSelectedIndex == null)
          const Text(
            "Tebrikler! Gereksiz kelime uçtu gitti.",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildWordChip(int index) {
    bool visible = _isVisible[index];
    bool isWrong = index == _wrongSelectedIndex;

    // Animasyonlu Görünüm
    return GestureDetector(
      onTap: () => _handleWordTap(index),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 600), // Buharlaşma süresi
        opacity: visible ? 1.0 : 0.0,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isWrong ? Colors.red.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isWrong ? Colors.red : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: [
              if (visible)
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
            ],
          ),
          // Kelime büyüyerek kaybolsun (Scale efekti)
          transform: !visible
              ? Matrix4.diagonal3Values(1.5, 1.5, 1.0) // Büyüt
              : Matrix4.identity(),
          child: Text(
            widget.question.options[index],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isWrong ? Colors.red : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
