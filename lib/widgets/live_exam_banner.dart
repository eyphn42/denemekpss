// DOSYA: lib/widgets/live_exam_banner.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../screens/exam_screen.dart';
import '../screens/exam_waiting_screen.dart';
import '../screens/exam_result_screen.dart';

class LiveExamBanner extends StatefulWidget {
  const LiveExamBanner({super.key});

  @override
  State<LiveExamBanner> createState() => _LiveExamBannerState();
}

class _LiveExamBannerState extends State<LiveExamBanner> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _isExpanded = true; // Banner açık mı kapalı mı?

  @override
  void initState() {
    super.initState();
    // Her saniye ekranı güncelle ki sayaç ilerlesin
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00"; // Süre bittiyse eksi gösterme
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(d.inHours);
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trial_exams')
          .where('isActive', isEqualTo: true)
          .orderBy('startTime', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        QueryDocumentSnapshot? activeExamDoc;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final startTime = (data['startTime'] as Timestamp).toDate();
          final durationMinutes = data['durationMinutes'] ?? 120;
          final endTime = startTime.add(Duration(minutes: durationMinutes));

          // Sınav bittikten sonra 1 saat daha tolerans tanı
          final visibleUntil = endTime.add(const Duration(hours: 1));

          if (visibleUntil.isAfter(_now)) {
            activeExamDoc = doc;
            break; // İlk uygun sınavı bulduk
          }
        }

        if (activeExamDoc == null) return const SizedBox.shrink();

        // --- VERİLER ---
        final data = activeExamDoc.data() as Map<String, dynamic>;
        final examId = activeExamDoc.id;
        final title = data['title'] ?? 'Canlı Deneme';
        final startTime = (data['startTime'] as Timestamp).toDate();
        final durationMinutes = data['durationMinutes'] ?? 120;
        final endTime = startTime.add(Duration(minutes: durationMinutes));

        bool isStarted = _now.isAfter(startTime);
        bool isFinished = _now.isAfter(endTime);

        Duration remaining;
        String statusText;
        Color statusColor;
        IconData statusIcon;
        String badgeText;
        Color badgeColor;

        if (!isStarted) {
          // 1. DURUM: BAŞLAMADI
          remaining = startTime.difference(_now);
          statusText = "BAŞLAMASINA KALAN";
          statusColor = Colors.orangeAccent;
          statusIcon = Icons.hourglass_empty;
          badgeText = "YAKLAŞAN SINAV";
          badgeColor = Colors.orange;
        } else if (isFinished) {
          // 2. DURUM: BİTTİ (Ama tolerans süresinde)
          remaining = Duration.zero;
          statusText = "SINAV SÜRESİ DOLDU";
          statusColor = Colors.grey.shade400;
          statusIcon = Icons.check_circle;
          badgeText = "TAMAMLANDI";
          badgeColor = Colors.grey;
        } else {
          // 3. DURUM: DEVAM EDİYOR (Canlı)
          remaining = endTime.difference(_now);
          statusText = "BİTİŞE KALAN SÜRE";
          statusColor = const Color(0xFF00FF88); // Neon Yeşil
          statusIcon = Icons.timer;
          badgeText = "SINAVA KATIL";
          badgeColor = Colors.redAccent;
        }

        // --- TIKLAMA MANTIĞI ---
        void onTapAction() {
          if (!isStarted) {
            // Başlamadıysa -> Bekleme Odası
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExamWaitingScreen(
                  examId: examId,
                  examTitle: title,
                  startTime: startTime,
                  durationMinutes: durationMinutes,
                ),
              ),
            );
          } else if (isFinished) {
            // Bittiyse -> Sonuç Ekranı
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExamResultScreen(
                  examId: examId,
                  examTitle: title,
                ),
              ),
            );
          } else {
            // Devam ediyorsa -> Sınav Ekranı
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => ExamScreen(
                  examId: examId,
                  examTitle: title,
                  startTime: startTime,
                  durationMinutes: durationMinutes,
                ),
              ),
            );
          }
        }

        // --- ANİMASYONLU GEÇİŞ ---
        return AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,

          // 1. GENİŞ (AÇIK) HALİ
          firstChild: GestureDetector(
            onTap: onTapAction,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isFinished
                      ? [Colors.grey.shade700, Colors.grey.shade900]
                      : [const Color(0xFF7D52A0), const Color(0xFF5B3B78)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: isFinished
                          ? Colors.black26
                          : const Color(0xFF7D52A0).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: Stack(
                children: [
                  // İÇERİK
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(
                                  isFinished
                                      ? Icons.assignment_turned_in
                                      : Icons.assignment,
                                  color: Colors.white,
                                  size: 24),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: badgeColor,
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Text(badgeText,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1)),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 10),

                        // Sınav bittiyse saatleri göstermeye gerek yok
                        if (isFinished)
                          const Center(
                            child: Text(
                                "Sonuçlar açıklandı. Görmek için tıklayın.",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoColumn("Başlangıç",
                                  DateFormat('HH:mm').format(startTime)),
                              const Icon(Icons.arrow_forward,
                                  color: Colors.white54, size: 16),
                              _buildInfoColumn(
                                  "Bitiş", DateFormat('HH:mm').format(endTime)),
                            ],
                          ),

                        if (!isFinished) ...[
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 15),
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: statusColor.withOpacity(0.5))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 20),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(statusText,
                                        style: TextStyle(
                                            color: statusColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                    Text(_formatDuration(remaining),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Courier',
                                            letterSpacing: 2)),
                                  ],
                                )
                              ],
                            ),
                          )
                        ]
                      ],
                    ),
                  ),

                  // KAPAT (KÜÇÜLT) BUTONU
                  Positioned(
                    top: 5,
                    right: 5,
                    child: IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up,
                          color: Colors.white54),
                      tooltip: "Küçült",
                      onPressed: () {
                        setState(() {
                          _isExpanded = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. DAR (KAPALI) HALİ - MİNİ BANNER
          secondChild: GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = true;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isFinished ? Colors.grey.shade800 : const Color(0xFF7D52A0),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: isFinished
                            ? Colors.grey
                            : (isStarted
                                ? Colors.redAccent
                                : Colors.orangeAccent),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: (isFinished
                                      ? Colors.grey
                                      : (isStarted
                                          ? Colors.red
                                          : Colors.orange))
                                  .withOpacity(0.5),
                              blurRadius: 5,
                              spreadRadius: 2)
                        ]),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            isFinished
                                ? "Sınav Tamamlandı"
                                : (isStarted
                                    ? "Sınav Devam Ediyor"
                                    : "Sınav Yaklaşıyor"),
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                        Text(
                            isFinished
                                ? "Sonuçları Gör"
                                : _formatDuration(remaining),
                            // HATA BURADAYDI: const kaldırıldı çünkü isFinished dinamik
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: isFinished ? null : 'Courier')),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoColumn(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        Text(time,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ],
    );
  }
}
