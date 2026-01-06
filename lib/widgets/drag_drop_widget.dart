// DOSYA: lib/widgets/drag_drop_widget.dart
import 'package:flutter/material.dart';

class DragDropWidget extends StatefulWidget {
  final String sentencePart1;
  final String sentencePart2;
  final String correctWord;
  final List<String> options;
  final VoidCallback onCorrectAnswer;

  const DragDropWidget({
    super.key,
    required this.sentencePart1,
    required this.sentencePart2,
    required this.correctWord,
    required this.options,
    required this.onCorrectAnswer,
  });

  @override
  State<DragDropWidget> createState() => _DragDropWidgetState();
}

class _DragDropWidgetState extends State<DragDropWidget> {
  String? droppedWord;
  bool isCorrect = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(widget.sentencePart1,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              DragTarget<String>(
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: droppedWord != null
                          ? (isCorrect ? Colors.green[100] : Colors.red[100])
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: droppedWord != null
                            ? (isCorrect ? Colors.green : Colors.red)
                            : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      droppedWord ?? "      ",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: droppedWord != null
                              ? Colors.black
                              : Colors.transparent),
                    ),
                  );
                },
                onAccept: (data) {
                  setState(() {
                    droppedWord = data;
                    if (data == widget.correctWord) {
                      isCorrect = true;
                      widget.onCorrectAnswer();
                    } else {
                      isCorrect = false;
                      Future.delayed(const Duration(seconds: 1), () {
                        setState(() {
                          droppedWord = null;
                        });
                      });
                    }
                  });
                },
              ),
              Text(widget.sentencePart2,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          if (!isCorrect)
            Wrap(
              spacing: 15,
              runSpacing: 15,
              alignment: WrapAlignment.center,
              children: widget.options.map((option) {
                return Draggable<String>(
                  data: option,
                  feedback: Material(
                      color: Colors.transparent,
                      child: _buildOptionChip(option, isDragging: true)),
                  childWhenDragging:
                      Opacity(opacity: 0.3, child: _buildOptionChip(option)),
                  child: _buildOptionChip(option),
                );
              }).toList(),
            ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildOptionChip(String text, {bool isDragging = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: isDragging
            ? []
            : [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 5)
              ],
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
