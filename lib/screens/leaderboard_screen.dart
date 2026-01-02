import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Sıralama", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0),
      body: Center(child: Text("Liderlik Tablosu")),
    );
  }
}