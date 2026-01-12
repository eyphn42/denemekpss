// DOSYA: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'units_screen.dart';
import 'profile_screen.dart';
// YENİ EKLENEN IMPORT (Dosya yolunun doğru olduğundan emin ol)
import '../widgets/live_exam_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Seçili sekme indeksi (0: Dersler, 1: Görevler, 2: Liderler, 3: Profil)
  int _selectedIndex = 0;

  // Renkler
  final Color zeoPurple = const Color(0xFF7D52A0);
  final Color zeoOrange = const Color(0xFFE67E22);

  // --- SAYFA LİSTESİ ---
  List<Widget> get _pages => [
        _buildLessonsTab(), // 0. Dersler + Canlı Banner
        _buildPlaceholder("Görevler"), // 1. Görevler
        _buildPlaceholder("Liderler Tablosu"), // 2. Liderler
        const ProfileScreen(), // 3. Profil
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // APP BAR: Profilde gizli, diğerlerinde açık
      appBar: _selectedIndex == 3
          ? null
          : AppBar(
              title: Image.asset('assets/images/zeologo_appbar.png',
                  height: 40, // Logonun boyutunu buradan ayarlayabilirsiniz
                  fit: BoxFit.contain),
              backgroundColor: zeoPurple,
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
            ),

      body: _pages[_selectedIndex],

      // ALT MENÜ
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: zeoPurple,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'Dersler',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_rounded),
              label: 'Görevler',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_rounded),
              label: 'Liderler',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. SEKME: DERSLER VE CANLI ETKİNLİK ---
  Widget _buildLessonsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. CANLI DENEME BANNERI (Buraya Eklendi)
        // Eğer aktif sınav yoksa bu widget otomatik olarak gizlenecek (SizedBox.shrink)
        const LiveExamBanner(),

        // 2. BAŞLIK
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 15),
          child: Text(
            "Dersler",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ),

        // 3. DERSLER GRID LISTESI
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.1,
              // Alt tarafta biraz boşluk bırakalım ki son kart kesilmesin
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                _buildLessonCard(
                    title: "Türkçe", icon: Icons.book, courseId: "turkce"),
                _buildLessonCard(
                    title: "Tarih", icon: Icons.history_edu, courseId: "tarih"),
                _buildLessonCard(
                    title: "Coğrafya",
                    icon: Icons.public,
                    courseId: "cografya"),
                _buildLessonCard(
                    title: "Matematik",
                    icon: Icons.calculate,
                    courseId: "matematik"),
                _buildLessonCard(
                    title: "Vatandaşlık",
                    icon: Icons.gavel,
                    courseId: "vatandaslik"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- DERS KARTI ---
  Widget _buildLessonCard(
      {required String title,
      required IconData icon,
      required String courseId}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnitsScreen(
              courseId: courseId,
              courseName: title,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [
            BoxShadow(
              color: zeoPurple.withOpacity(0.05), // Gölgeyi hafiflettik
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: zeoPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: zeoPurple, size: 30),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- PLACEHOLDER ---
  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 80, color: zeoOrange.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: zeoPurple),
          ),
          const SizedBox(height: 10),
          const Text(
            "Çok Yakında!",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
