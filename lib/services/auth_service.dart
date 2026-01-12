// DOSYA: lib/services/auth_service.dart

import 'dart:math';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Kullanıcı verilerini canlı dinle
  Stream<DocumentSnapshot> getUserStream() {
    if (_user == null) return const Stream.empty();
    return _firestore.collection('users').doc(_user!.uid).snapshots();
  }

  // --- 1. KOD GÖNDERME ---
  Future<String?> sendTempOtp(String email) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return "Bu e-posta adresi zaten kayıtlı.";
      }

      String otpCode = (Random().nextInt(900000) + 100000).toString();
      await _firestore.collection('temp_registrations').doc(email).set({
        'otpCode': otpCode,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // EmailJS API
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': 'service_q61o5f8',
          'template_id': 'template_2lbzqne',
          'user_id': 'QfHgBrPlJgGGHfZDt',
          'template_params': {
            'user_email': email,
            'otp_code': otpCode,
            'reply_to': 'noreply@kpss.com',
          }
        }),
      );

      if (response.statusCode == 200) {
        return "success";
      } else {
        return "Mail servisi hatası.";
      }
    } catch (e) {
      return "Hata: $e";
    }
  }

  // --- 2. KAYIT ---
  Future<String?> completeRegistration({
    required String email,
    required String password,
    required String username,
    required String inputCode,
  }) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('temp_registrations').doc(email).get();

      if (!doc.exists || doc.get('otpCode') != inputCode) {
        return "Hatalı veya süresi dolmuş kod.";
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;

      if (_user != null) {
        await _user!.updateDisplayName(username);

        await _firestore.collection('users').doc(_user!.uid).set({
          'uid': _user!.uid,
          'username': username,
          'email': email,
          'fullName': '',
          'phoneNumber': '',
          'lessonsUnlocked': [], // Başlangıçta boş
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'student',
          'stats': {'xp': 0, 'level': 1, 'hearts': 5, 'gem': 0},
        });

        await _firestore.collection('temp_registrations').doc(email).delete();
        notifyListeners();
        return "success";
      }
    } catch (e) {
      return "Kayıt Hatası: $e";
    }
    return "Bilinmeyen hata";
  }

  // --- GİRİŞ / ÇIKIŞ ---
  Future<String?> loginUser(
      {required String email, required String password}) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = cred.user;
      notifyListeners();
      return "success";
    } on FirebaseAuthException catch (e) {
      return "Giriş başarısız: ${e.message}";
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  // --- PROFİL GÜNCELLEME ---
  Future<String?> updateUserProfile(
      {String? fullName, String? phoneNumber}) async {
    try {
      Map<String, dynamic> data = {};
      if (fullName != null) data['fullName'] = fullName;
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber;

      await _firestore.collection('users').doc(_user!.uid).update(data);
      notifyListeners();
      return "success";
    } catch (e) {
      return "Hata: $e";
    }
  }

  Future<String?> resetPassword() async {
    if (_user?.email == null) return "Mail bulunamadı";
    await _auth.sendPasswordResetEmail(email: _user!.email!);
    return "success";
  }

  // --- PRO KOD DOĞRULAMA (DÜZELTİLDİ: Tireler kalıyor) ---
  Future<String?> redeemCourseCode(String codeInput) async {
    try {
      // DÜZELTME: Tireleri SİLMİYORUZ. Olduğu gibi (trim yaparak) alıyoruz.
      String code = codeInput.trim();

      // Format: XXXX-XXXX-XXXX-XXXX (16 rakam + 3 tire = 19 karakter)
      if (code.length != 19) {
        return "Kod formatı hatalı (XXXX-XXXX-XXXX-XXXX).";
      }

      // 1. Kodu 'codes' koleksiyonunda ara (Tireli haliyle)
      DocumentSnapshot codeDoc =
          await _firestore.collection('codes').doc(code).get();

      if (!codeDoc.exists) {
        return "Geçersiz kod.";
      }

      Map<String, dynamic> codeData = codeDoc.data() as Map<String, dynamic>;

      // 2. Kullanılmış mı?
      if (codeData['isUsed'] == true) {
        return "Bu kod daha önce kullanılmış.";
      }

      String lessonIdToUnlock = codeData['lessonId'];

      // 3. Kullanıcıda zaten var mı?
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      List<dynamic> unlocked =
          (userDoc.data() as Map<String, dynamic>)['lessonsUnlocked'] ?? [];

      if (unlocked.contains(lessonIdToUnlock)) {
        return "Bu derse zaten sahipsiniz.";
      }

      // 4. İŞLEMİ YAP: Kodu 'used' yap ve Dersi kullanıcıya ekle
      await _firestore.runTransaction((transaction) async {
        transaction.update(codeDoc.reference, {
          'isUsed': true,
          'usedBy': _user!.uid,
          'usedAt': FieldValue.serverTimestamp()
        });
        transaction.update(userDoc.reference, {
          'lessonsUnlocked': FieldValue.serverTimestamp(),
          // ignore: equal_keys_in_map
          'lessonsUnlocked': FieldValue.arrayUnion([lessonIdToUnlock])
        });
      });

      notifyListeners();
      return "success|$lessonIdToUnlock";
    } catch (e) {
      return "Hata oluştu: $e";
    }
  }
}
