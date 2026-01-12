// DOSYA: lib/screens/units_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpss_app/models/models.dart';
import 'package:kpss_app/services/database_service.dart';
import 'package:kpss_app/services/auth_service.dart';
import 'topics_screen.dart';

class UnitsScreen extends StatelessWidget {
  final String courseId;
  final String courseName;

  const UnitsScreen(
      {super.key, required this.courseId, required this.courseName});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    final Color zeoPurple = const Color(0xFF7D52A0);
    final Color zeoOrange = const Color(0xFFE67E22);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Hafif gri-mavi arka plan
      appBar: AppBar(
        title: Text(courseName,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: zeoPurple,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // 1. KATMAN: KİLİT KONTROLÜ
      body: StreamBuilder<DocumentSnapshot>(
        stream: authService.getUserStream(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          bool isCourseUnlocked = false;
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            List<dynamic> rawList = userData['lessonsUnlocked'] ?? [];
            List<String> unlockedList =
                rawList.map((e) => e.toString().trim()).toList();
            if (unlockedList.contains(courseId)) isCourseUnlocked = true;
          }

          // 2. KATMAN: İLERLEME VERİSİNİ DİNLE
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('progress')
                .doc(courseId)
                .snapshots(),
            builder: (context, progressSnapshot) {
              Map<String, dynamic> progressData = {};
              if (progressSnapshot.hasData && progressSnapshot.data!.exists) {
                progressData =
                    progressSnapshot.data!.data() as Map<String, dynamic>;
              }

              // 3. KATMAN: ÜNİTELERİ LİSTELE
              return StreamBuilder<List<Unit>>(
                stream: DatabaseService().getUnits(courseId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Ünite bulunamadı."));
                  }

                  final units = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        vertical: 40, horizontal: 20),
                    itemCount: units.length,
                    itemBuilder: (context, index) {
                      final unit = units[index];
                      bool isLocked = (index > 0) && !isCourseUnlocked;

                      double progress = 0.0;
                      String key = 'progress_${unit.id}';

                      if (progressData.containsKey(key)) {
                        progress = (progressData[key] as num).toDouble();
                      }

                      return _buildTimelineItem(
                          context,
                          unit,
                          index,
                          units.length,
                          zeoOrange,
                          zeoPurple,
                          isLocked,
                          progress);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // --- HER BİR ETKİNLİK İKONU VE YOLU ---
  Widget _buildTimelineItem(
      BuildContext context,
      Unit unit,
      int index,
      int totalCount,
      Color activeColor,
      Color textColor,
      bool isLocked,
      double progress) {
    bool isCompleted = progress >= 1.0;

    // Her üniteye özel ikon belirleme (Modüler aritmetik ile döngüsel)
    List<IconData> unitIcons = [
      Icons.menu_book_rounded, // Kitap
      Icons.psychology_rounded, // Beyin
      Icons.edit_note_rounded, // Notlar
      Icons.school_rounded, // Okul
      Icons.emoji_events_rounded, // Kupa
      Icons.lightbulb_rounded, // Fikir
    ];
    IconData currentIcon = unitIcons[index % unitIcons.length];

    return Column(
      children: [
        // --- 1. ETKİNLİK İKONU (DOLUM EFEKTLİ) ---
        InkWell(
          onTap: () {
            if (isLocked) {
              showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                          title: const Text("Ünite Kilitli 🔒"),
                          content: const Text(
                              "Dersin Aktivasyon Kodunu Etkinleştirerek Kilidi Kaldırabilirsiniz."),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("Tamam"))
                          ]));
            } else {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          TopicsScreen(unit: unit, courseId: courseId)));
            }
          },
          borderRadius:
              BorderRadius.circular(100), // Tıklama efekti yuvarlak olsun
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                // Kilitli değilse gölge ekle
                boxShadow: isLocked
                    ? []
                    : [
                        BoxShadow(
                            color: activeColor.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8))
                      ],
                border: Border.all(
                    color: isLocked
                        ? Colors.grey.shade300
                        : (isCompleted ? Colors.green : Colors.white),
                    width: 3)),
            child: isLocked
                // DURUM A: KİLİTLİ (GRİ ASMA KİLİT)
                ? const Icon(Icons.lock, color: Colors.grey, size: 35)

                // DURUM B: AÇIK (DOLUM EFEKTLİ İKON)
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Katman: Gri (Boş) İkon
                      Icon(currentIcon, size: 45, color: Colors.grey.shade200),

                      // 2. Katman: Renkli (Dolu) İkon + Kırpma (Clip)
                      // Progress 0.0 ise hiç görünmez, 0.5 ise yarısı görünür.
                      ClipRect(
                        child: Align(
                          alignment:
                              Alignment.bottomCenter, // Aşağıdan yukarı dolar
                          heightFactor: progress > 0 ? progress : 0,
                          child: Icon(currentIcon,
                              size: 45,
                              color: isCompleted ? Colors.green : activeColor),
                        ),
                      ),

                      // %100 bittiyse küçük bir tik işareti ekleyelim
                      if (isCompleted)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.green, shape: BoxShape.circle),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 12),
                          ),
                        )
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // --- 2. BAŞLIK VE YÜZDE ---
        Text(
          unit.title,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isLocked ? Colors.grey : Colors.black87),
        ),
        if (!isLocked && progress > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "%${(progress * 100).toInt()}",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isCompleted ? Colors.green : activeColor),
            ),
          ),

        // --- 3. YOL ÇİZGİSİ (SONUNCU HARİÇ) ---
        if (index < totalCount - 1)
          Container(
            height: 50,
            width: 6, // Yol kalınlığı
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
                // Eğer bu ünite bittiyse yol yeşil olsun, yoksa gri/kesikli
                color: isCompleted
                    ? Colors.green.withOpacity(0.3)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3)),
          ),
      ],
    );
  }
}
