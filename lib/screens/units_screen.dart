// DOSYA: lib/screens/units_screen.dart

import 'package:flutter/material.dart';
import 'package:kpss_app/models/models.dart';
import 'package:kpss_app/data/data.dart';
import 'profile_screen.dart';
import 'topics_screen.dart'; // YENİ EKRAN BURADA

class UnitsScreen extends StatefulWidget {
  final String courseId; // Örn: "turkce"
  final String courseName; // Örn: "Türkçe"

  const UnitsScreen(
      {super.key, required this.courseId, required this.courseName});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  // Zeo Renkleri
  final Color zeoPurple = const Color(0xFF7D52A0);
  final Color zeoOrange = const Color(0xFFE67E22);

  @override
  Widget build(BuildContext context) {
    // 1. HomeScreen'den gelen ID ile Veri Tabanındaki Dersi Eşleştirme
    Lesson? currentLesson;

    // Basit bir eşleştirme mantığı:
    if (widget.courseId == 'turkce') {
      currentLesson = turkishLesson;
    }
    // Diğer dersler eklendikçe buraya 'else if' ile eklenecek.

    // Eğer ders henüz data.dart içinde yoksa boş bir ekran göster
    if (currentLesson == null) {
      return Scaffold(
        appBar:
            AppBar(title: Text(widget.courseName), backgroundColor: zeoPurple),
        body: const Center(child: Text("Bu dersin içeriği hazırlanıyor...")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // HomeScreen ile aynı gri ton
      appBar: AppBar(
        title: Text(widget.courseName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: zeoPurple,
        elevation: 0,
        actions: [
          // Kullanıcı kilit açmak isterse buradan Profile gidebilsin
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen())).then((_) {
                // Profil'den dönünce ekranı yenile (Kilit açıldıysa görünsün)
                setState(() {});
              });
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        itemCount: currentLesson.units.length,
        itemBuilder: (context, index) {
          final unit = currentLesson!.units[index];

          // --- KİLİT MANTIĞI ---
          // Ünite bedava değilse VE Dersin kilidi açılmamışsa -> KİLİTLİDİR
          bool isLocked = !unit.isFree && !currentLesson!.isProUnlocked;

          return _buildUnitPathNode(
              unit, isLocked, index, currentLesson!.units.length);
        },
      ),
    );
  }

  // Duolingo Tarzı Yol Düğümü Tasarımı
  Widget _buildUnitPathNode(
      Unit unit, bool isLocked, int index, int totalCount) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            if (isLocked) {
              _showLockedDialog();
            } else {
              // --- GÜNCELLENEN KISIM BURASI ---
              // Artık Quiz'e değil, Konular Listesine (TopicsScreen) gidiyoruz
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TopicsScreen(unit: unit),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(100), // Yuvarlak tıklama efekti
          child: Container(
            padding: const EdgeInsets.all(4), // Dış çerçeve boşluğu
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: isLocked ? Colors.grey : zeoOrange, width: 3),
            ),
            child: CircleAvatar(
              radius: 40, // Dairenin büyüklüğü
              backgroundColor: isLocked ? Colors.grey[300] : zeoOrange,
              child: Icon(
                isLocked ? Icons.lock : Icons.star,
                color: Colors.white,
                size: 35,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Ünite Başlığı
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: isLocked ? Colors.grey[300] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (!isLocked)
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3))
              ]),
          child: Text(
            unit.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLocked ? Colors.grey[600] : zeoPurple,
            ),
          ),
        ),

        // Aşağı inen yol çizgisi (Son eleman hariç)
        if (index < totalCount - 1)
          Container(
            height: 40,
            width: 6,
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }

  // Kilitli Ünite Uyarısı
  void _showLockedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🔒 Kilitli İçerik"),
        content: const Text(
            "Bu üniteye erişmek için 'Pro Kodu' girmelisiniz.\nSağ üstteki profil ikonuna tıklayıp kodu girebilirsiniz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Diyaloğu kapat
              // Profil ekranına git
              Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()))
                  .then((_) => setState(() {}));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: zeoPurple, foregroundColor: Colors.white),
            child: const Text("Profile Git"),
          )
        ],
      ),
    );
  }
}
