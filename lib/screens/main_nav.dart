// lib/screens/main_nav.dart
import 'package:flutter/material.dart';
import 'lessons_screen.dart'; // Az önce yaptığımız ders haritası
import 'profile_screen.dart'; // Senin gönderdiğin profil ekranı (düzelteceğiz)

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;
  final Color zeoPurple = const Color(0xFF8E54E9);

  // Sayfalarımız
  final List<Widget> _pages = [
    const LessonsScreen(), // 0: Dersler
    const ProfileScreen(), // 1: Profil (Senin kodun)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Dersler'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: zeoPurple,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
      ),
    );
  }
}
