// DOSYA: lib/screens/profile_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/badge_manager.dart';
import 'exam_result_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _proCodeController = TextEditingController();

  bool _isLoading = false;
  bool _isImageUploading = false;
  bool _isInit = true;
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  // ROZET TOOLTIP YÖNETİMİ
  OverlayEntry? _overlayEntry;

  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = BadgeManager.getUserStats(_userId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.getUserStream().first.then((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _fullNameController.text = data['fullName'] ?? '';
              _phoneController.text = data['phoneNumber'] ?? '';
            });
          }
        }
      });
      _isInit = false;
    }
  }

  // Tooltip'i kapat
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  // --- YENİ TOOLTIP GÖSTERME MANTIĞI (PERDESİZ) ---
  void _showTooltip(BuildContext context, GlobalKey widgetKey, BadgeItem badge,
      bool isEarned) {
    // 1. Varsa eskiyi kapat
    _removeOverlay();

    // 2. Konumu hesapla
    RenderBox renderBox =
        widgetKey.currentContext!.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    // 3. Sadece kutuyu ekle (Arka plan engelleyici YOK)
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx - 60 + (size.width / 2),
        top: offset.dy - 90, // Rozetin hemen üstünde
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color:
                    const Color(0xFF2C3E50).withOpacity(0.95), // Koyu şık tema
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 10),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: isEarned ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    isEarned ? "KAZANILDI" : "KİLİTLİ",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // --- RESİM YÜKLEME ---
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 60, maxWidth: 600);
    if (image == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Profil Resmi"),
        content: const Text(
            "Yükleyeceğiniz fotoğrafın topluluk kurallarına uygun olduğunu onaylıyor musunuz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("İPTAL", style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("ONAYLIYORUM",
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isImageUploading = true);
    try {
      File file = File(image.path);
      String fileName = "profile_images/$_userId.jpg";
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putData(await file.readAsBytes(),
          SettableMetadata(contentType: 'image/jpeg'));
      String downloadUrl = await ref.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update({'photoUrl': downloadUrl});
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Profil resmi güncellendi!"),
            backgroundColor: Colors.green));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isImageUploading = false);
    }
  }

  // --- DETAYLI NET HESABI ---
  Future<Map<String, double>> _calculateDetailedResult(
      String examId, Map<String, dynamic> userAnswers) async {
    int correct = 0;
    int incorrect = 0;
    var questionsSnapshot = await FirebaseFirestore.instance
        .collection('trial_exams')
        .doc(examId)
        .collection('questions')
        .get();
    for (var doc in questionsSnapshot.docs) {
      var qData = doc.data();
      int correctAnswer = qData['correctAnswerIndex'];
      if (userAnswers.containsKey(doc.id)) {
        int userAnswer = userAnswers[doc.id];
        if (userAnswer == correctAnswer) {
          correct++;
        } else {
          incorrect++;
        }
      }
    }
    double net = correct - (incorrect / 4);
    return {
      "net": net,
      "correct": correct.toDouble(),
      "incorrect": incorrect.toDouble()
    };
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    const Color zeoPurple = Color(0xFF7D52A0);
    const Color zeoOrange = Color(0xFFE67E22);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Profilim",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: zeoPurple,
        elevation: 0,
      ),
      // --- ANA DEĞİŞİKLİK BURADA ---
      // Tüm sayfayı GestureDetector ile sarıyoruz.
      // Boş bir yere dokununca _removeOverlay çalışır ve tooltip kapanır.
      // behavior: HitTestBehavior.translucent sayesinde kaydırma vb. engellenmez.
      body: GestureDetector(
        onTap: _removeOverlay,
        behavior: HitTestBehavior.translucent,
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification is ScrollStartNotification) {
              _removeOverlay(); // Kaydırma başlayınca da kapat
            }
            return true;
          },
          child: StreamBuilder<DocumentSnapshot>(
            stream: authService.getUserStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || !snapshot.data!.exists)
                return const Center(child: Text("Veri yok."));

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final List lessonsUnlocked = userData['lessonsUnlocked'] ?? [];
              final String fullName = userData['fullName'] ?? '';
              final String? photoUrl = userData['photoUrl'];
              final bool isNameEditable = fullName.isEmpty;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- KULLANICI KARTI ---
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: zeoPurple.withOpacity(0.2),
                                          width: 3)),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: photoUrl != null
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    child: _isImageUploading
                                        ? const CircularProgressIndicator()
                                        : (photoUrl == null
                                            ? const Icon(Icons.person,
                                                size: 50, color: Colors.grey)
                                            : null),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickAndUploadImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                          color: zeoOrange,
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.camera_alt,
                                          color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text(userData['username'] ?? 'Kullanıcı',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text(
                                lessonsUnlocked.isNotEmpty
                                    ? "${lessonsUnlocked.length} Derse Sahip"
                                    : "Henüz Ders Alınmadı",
                                style: TextStyle(
                                    color: lessonsUnlocked.isNotEmpty
                                        ? zeoOrange
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // --- ROZETLER ---
                      Row(
                        children: [
                          const Icon(Icons.military_tech, color: zeoPurple),
                          const SizedBox(width: 8),
                          const Text("Başarı Rozetleri",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: zeoPurple)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      _buildBadgeSection(),

                      const SizedBox(height: 30),

                      // --- KİŞİSEL BİLGİLER ---
                      const Text("Kişisel Bilgiler",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: zeoPurple)),
                      const SizedBox(height: 10),
                      _buildReadOnlyField(
                          "Kullanıcı Adı", userData['username']),
                      const SizedBox(height: 15),
                      _buildReadOnlyField("E-Posta", userData['email']),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _fullNameController,
                        readOnly: !isNameEditable,
                        decoration: InputDecoration(
                          labelText: "Ad Soyad",
                          hintText: "Ad Soyad Giriniz",
                          suffixIcon: !isNameEditable
                              ? const Icon(Icons.lock, color: Colors.grey)
                              : null,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: !isNameEditable
                              ? Colors.grey.shade200
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11)
                        ],
                        decoration: InputDecoration(
                          labelText: "Telefon Numarası",
                          hintText: "05xxxxxxxxx",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: zeoPurple,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15)),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (isNameEditable &&
                                      _fullNameController.text.trim().isEmpty)
                                    return;
                                  setState(() => _isLoading = true);
                                  String? newName = isNameEditable
                                      ? _fullNameController.text.trim()
                                      : null;
                                  String newPhone =
                                      _phoneController.text.trim();
                                  await authService.updateUserProfile(
                                      fullName: newName, phoneNumber: newPhone);
                                  setState(() => _isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text("Bilgiler güncellendi!"),
                                          backgroundColor: Colors.green));
                                },
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("GÜNCELLE",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 30),
                      const Divider(),
                      const SizedBox(height: 10),

                      // --- SINAV GEÇMİŞİ ---
                      const Text("Sınav Geçmişim",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: zeoPurple)),
                      const SizedBox(height: 10),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('trial_exams')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, examSnapshot) {
                          if (!examSnapshot.hasData)
                            return const Center(
                                child: CircularProgressIndicator());
                          var exams = examSnapshot.data!.docs;
                          if (exams.isEmpty)
                            return const Text("Henüz sınav yok.");

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: exams.length,
                            itemBuilder: (context, index) {
                              var examDoc = exams[index];
                              var examData =
                                  examDoc.data() as Map<String, dynamic>;

                              return FutureBuilder<DocumentSnapshot>(
                                future: examDoc.reference
                                    .collection('participations')
                                    .doc(_userId)
                                    .get(),
                                builder: (context, participationSnapshot) {
                                  if (!participationSnapshot.hasData ||
                                      !participationSnapshot.data!.exists)
                                    return const SizedBox.shrink();
                                  var pDoc = participationSnapshot.data!;
                                  if (pDoc['isCompleted'] != true)
                                    return const SizedBox.shrink();

                                  var pData =
                                      pDoc.data() as Map<String, dynamic>;
                                  Map<String, dynamic> userAnswers =
                                      pData['answers'] ?? {};
                                  DateTime? date =
                                      (pData['finishedAt'] as Timestamp?)
                                          ?.toDate();

                                  return FutureBuilder<Map<String, double>>(
                                    future: _calculateDetailedResult(
                                        examDoc.id, userAnswers),
                                    builder: (context, statsSnapshot) {
                                      if (!statsSnapshot.hasData)
                                        return const SizedBox.shrink();
                                      var stats = statsSnapshot.data!;
                                      return _buildDetailedExamCard(
                                        context: context,
                                        examId: examDoc.id,
                                        title: examData['title'],
                                        date: date,
                                        net: stats['net']!,
                                        correct: stats['correct']!.toInt(),
                                        incorrect: stats['incorrect']!.toInt(),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),

                      // --- DİĞERLERİ ---
                      const Text("Güvenlik",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: zeoPurple)),
                      ListTile(
                        title: const Text("Şifremi Değiştir"),
                        subtitle: const Text("Sıfırlama maili gönder"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await authService.resetPassword();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Mail gönderildi."),
                                  backgroundColor: Colors.green));
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text("Ders Aktivasyon Kodu",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: zeoOrange)),
                      const SizedBox(height: 5),
                      const Text(
                          "Satın aldığınız kodu girerek dersin kilidini açabilirsiniz.",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _proCodeController,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 19,
                        inputFormatters: [ProCodeFormatter()],
                        decoration: InputDecoration(
                          labelText: "Aktivasyon Kodu",
                          hintText: "ABCD-1234-EFGH-5678",
                          counterText: "",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            onPressed: () async {
                              String code = _proCodeController.text.trim();
                              if (code.length < 19) return;
                              setState(() => _isLoading = true);
                              final result =
                                  await authService.redeemCourseCode(code);
                              setState(() => _isLoading = false);
                              if (result!.startsWith("success")) {
                                _proCodeController.clear();
                                showDialog(
                                    context: context,
                                    builder: (ctx) =>
                                        AlertDialog(
                                            title: const Text("Başarılı!"),
                                            content:
                                                const Text("Ders eklendi."),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text("TAMAM"))
                                            ]));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(result),
                                        backgroundColor: Colors.red));
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => authService.signOut(),
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text("Çıkış Yap",
                              style: TextStyle(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- ROZET BÖLÜMÜ ---
  Widget _buildBadgeSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: LinearProgressIndicator());

        var stats = snapshot.data!;
        List<BadgeItem> badges = BadgeManager.getAllBadges();

        return SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            itemBuilder: (context, index) {
              BadgeItem badge = badges[index];
              bool isEarned = badge.condition(stats);

              GlobalKey iconKey = GlobalKey();

              return GestureDetector(
                key: iconKey,
                onTap: () => _showTooltip(context, iconKey, badge, isEarned),
                child: Container(
                  margin: const EdgeInsets.only(right: 15),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isEarned
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                              width: 2),
                          color: isEarned
                              ? Colors.yellow.shade50
                              : Colors.grey.shade100,
                        ),
                        child: ClipOval(
                          child: ColorFiltered(
                            colorFilter: isEarned
                                ? const ColorFilter.mode(
                                    Colors.transparent, BlendMode.multiply)
                                : const ColorFilter.mode(
                                    Colors.grey, BlendMode.saturation),
                            child: Image.asset(badge.assetPath,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (c, o, s) => Icon(
                                    Icons.emoji_events,
                                    size: 40,
                                    color: isEarned
                                        ? Colors.orange
                                        : Colors.grey)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(badge.name,
                          style: TextStyle(
                              fontSize: 10,
                              color: isEarned ? Colors.black87 : Colors.grey,
                              fontWeight: isEarned
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- DETAYLI SINAV KARTI ---
  Widget _buildDetailedExamCard({
    required BuildContext context,
    required String examId,
    required String title,
    required DateTime? date,
    required double net,
    required int correct,
    required int incorrect,
  }) {
    String dateStr =
        date != null ? "${date.day}.${date.month}.${date.year}" : "";
    const Color zeoPurple = Color(0xFF7D52A0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ExamResultDetailScreen(
                          examId: examId,
                          examTitle: title,
                          date: date,
                        )));
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                      color: zeoPurple.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.assignment_turned_in,
                      color: zeoPurple, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(dateStr,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(width: 10),
                          Container(
                              width: 1,
                              height: 12,
                              color: Colors.grey.shade300),
                          const SizedBox(width: 10),
                          Text("$correct D",
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                          const SizedBox(width: 6),
                          Text("$incorrect Y",
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: zeoPurple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: zeoPurple.withOpacity(0.2))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(net.toStringAsFixed(2),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: zeoPurple)),
                      const Text("NET",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String? value) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade200,
        suffixIcon:
            const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
      ),
    );
  }
}

class ProCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text =
        newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (text.length > 16) text = text.substring(0, 16);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('-');
      buffer.write(text[i]);
    }
    final newText = buffer.toString();
    return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}
