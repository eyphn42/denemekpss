// DOSYA: lib/screens/units_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_screen.dart';

class UnitsScreen extends StatefulWidget {
  // <--- SINIF ADI BURADA
  final String courseId;
  final String courseName;

  const UnitsScreen(
      {super.key, required this.courseId, required this.courseName});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  bool isProUser = false;

  @override
  Widget build(BuildContext context) {
    // ... (Kodun geri kalanı önceki cevaptaki gibi)
    // Hata almaman için sadece boş bir iskelet koyuyorum,
    // önceki cevaptaki tam kodu buraya yapıştırmalısın.
    return Scaffold(appBar: AppBar(title: Text(widget.courseName)));
  }
}
