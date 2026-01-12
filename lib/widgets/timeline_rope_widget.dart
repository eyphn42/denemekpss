// DOSYA: lib/widgets/timeline_rope_widget.dart

import 'package:flutter/material.dart';
import 'package:kpss_app/models/models.dart';

class TimelineRopeWidget extends StatefulWidget {
  final Question question;
  final Function(bool) onAnswerChanged;

  const TimelineRopeWidget({
    Key? key,
    required this.question,
    required this.onAnswerChanged,
  }) : super(key: key);

  @override
  State<TimelineRopeWidget> createState() => _TimelineRopeWidgetState();
}

class _TimelineRopeWidgetState extends State<TimelineRopeWidget> {
  // Hangi kutuda hangi metin var? (Index -> String)
  final Map<int, String> placedItems = {};

  // Havuzda bekleyen seçenekler
  late List<String> availableItems;

  @override
  void initState() {
    super.initState();
    // Seçenekleri karıştırıp havuza atıyoruz
    availableItems = List.from(widget.question.options)..shuffle();
  }

  // --- SÜRÜKLEME VE TAKAS MANTIĞI ---
  void _handleDrop(String item, int targetIndex) {
    setState(() {
      int? oldSlotIndex;
      // 1. Bu eleman zaten yukarıdaki bir kutuda mıydı?
      if (placedItems.containsValue(item)) {
        for (var entry in placedItems.entries) {
          if (entry.value == item) {
            oldSlotIndex = entry.key;
            break;
          }
        }
      }

      String? existingItemInTarget = placedItems[targetIndex];

      // SENARYO A: Aşağıdan Yukarıya Taşıma
      if (oldSlotIndex == null) {
        availableItems.remove(item);
        // Hedef doluysa, oradakini havuza geri at (Basit çözüm)
        if (existingItemInTarget != null) {
          availableItems.add(existingItemInTarget);
        }
        placedItems[targetIndex] = item;
      }
      // SENARYO B: Kutudan Kutuya Taşıma (Takas/Swap)
      else {
        if (oldSlotIndex == targetIndex) return; // Aynı yerse işlem yapma

        // Eski yerden sil
        placedItems.remove(oldSlotIndex);

        // Hedef doluysa -> TAKAS YAP (Swap)
        if (existingItemInTarget != null) {
          placedItems[oldSlotIndex] = existingItemInTarget;
        }

        // Yeni yere koy
        placedItems[targetIndex] = item;
      }

      _checkAnswer();
    });
  }

  void _checkAnswer() {
    // Hepsi yerleşti mi?
    if (placedItems.length != widget.question.options.length) {
      widget.onAnswerChanged(false);
      return;
    }

    // Sıralama doğru mu? (Orijinal options listesindeki sırayla kıyasla)
    bool isCorrect = true;
    for (int i = 0; i < widget.question.options.length; i++) {
      if (placedItems[i] != widget.question.options[i]) {
        isCorrect = false;
        break;
      }
    }
    widget.onAnswerChanged(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            widget.question.text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),

        // --- TARİH ŞERİDİ (İP VE KUTULAR) ---
        Container(
          height: 120,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // İp Görünümü
              Container(height: 6, color: Colors.brown[400]),

              // Kutular
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    List.generate(widget.question.options.length, (index) {
                  return _buildTargetSlot(index);
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
        const Text("Seçenekleri yukarı sürükleyin:",
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 10),

        // --- SEÇENEK HAVUZU ---
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: availableItems.map((item) {
            return Draggable<String>(
              data: item,
              feedback: _buildChip(item, isDragging: true),
              childWhenDragging: Opacity(opacity: 0.3, child: _buildChip(item)),
              child: _buildChip(item),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTargetSlot(int index) {
    String? content = placedItems[index];

    return DragTarget<String>(
      onWillAccept: (data) => true,
      onAccept: (data) => _handleDrop(data, index),
      builder: (context, candidateData, rejectedData) {
        // Kutu Tasarımı
        Widget box = Container(
          width: 70,
          height: 80,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: content != null ? Colors.orange[100] : Colors.white,
            border: Border.all(
              color: candidateData.isNotEmpty ? Colors.green : Colors.brown,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          alignment: Alignment.center,
          child: content != null
              ? Text(content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold))
              : Text("${index + 1}",
                  style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
        );

        // Kutu doluysa, içindeki de taşınabilir olmalı (Draggable)
        if (content != null) {
          return Draggable<String>(
            data: content,
            feedback: _buildChip(content, isDragging: true),
            childWhenDragging: Container(
              width: 70,
              height: 80,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: box,
          );
        } else {
          return box;
        }
      },
    );
  }

  Widget _buildChip(String text, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              isDragging ? Colors.orange : const Color(0xFF7D52A0), // Zeo Moru
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDragging
              ? [const BoxShadow(blurRadius: 10, color: Colors.black26)]
              : [],
        ),
        child: Text(
          text,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
