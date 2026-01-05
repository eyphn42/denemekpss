import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: const Text("Sıralama", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0),
      body: const Center(child: Text("Liderlik Tablosu")),
    );
  }
}
