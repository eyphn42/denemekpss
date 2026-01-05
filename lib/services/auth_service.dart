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

  // Constructor: Uygulama açıldığında kullanıcı durumunu dinle
  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // --- 1. AŞAMA: KOD GÖNDERME ---
  Future<String?> sendTempOtp(String email) async {
    try {
      // Önce bu mail kayıtlı mı diye bak
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return "Bu e-posta adresi zaten kayıtlı. Lütfen giriş yapın.";
      }

      String otpCode = (Random().nextInt(900000) + 100000).toString();
      print("GÖNDERİLECEK KOD: $otpCode");

      await _firestore.collection('temp_registrations').doc(email).set({
        'otpCode': otpCode,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // EmailJS Bilgileri
      final serviceId = 'service_q61o5f8';
      final templateId = 'template_2lbzqne';
      final userId = 'QfHgBrPlJgGGHfZDt';

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
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
        return "Mail servisi hatası: ${response.body}";
      }
    } catch (e) {
      return "Hata: $e";
    }
  }

  // --- 2. AŞAMA: DOĞRULAMA VE KAYIT ---
  Future<String?> completeRegistration({
    required String email,
    required String password,
    required String username,
    required String inputCode,
  }) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('temp_registrations').doc(email).get();

      if (!doc.exists) return "Kod süresi dolmuş veya hatalı.";

      String? correctCode = doc.get('otpCode');

      if (correctCode == inputCode) {
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
            'createdAt': FieldValue.serverTimestamp(),
            'role': 'student',
            'isVerified': true,
            'stats': {'xp': 0, 'level': 1, 'hearts': 5, 'gem': 0},
          });

          await _firestore.collection('temp_registrations').doc(email).delete();
          notifyListeners();
          return "success";
        }
      } else {
        return "Hatalı kod girdiniz!";
      }
    } catch (e) {
      return "Kayıt Hatası: $e";
    }
    return "Bilinmeyen hata";
  }

  // --- 3. GİRİŞ YAPMA (Geliştirilmiş Hata Mesajları) ---
  Future<String?> loginUser(
      {required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;
      notifyListeners();
      return "success";
    } on FirebaseAuthException catch (e) {
      // Hata kodlarına göre özel Türkçe mesajlar
      if (e.code == 'user-not-found') {
        return "Bu e-posta adresiyle kayıtlı bir kullanıcı bulunamadı.";
      } else if (e.code == 'wrong-password') {
        return "Girdiğiniz şifre hatalı. Lütfen tekrar deneyin.";
      } else if (e.code == 'invalid-email') {
        return "Geçersiz bir e-posta formatı girdiniz.";
      } else if (e.code == 'user-disabled') {
        return "Bu kullanıcının hesabı dondurulmuş.";
      } else if (e.code == 'invalid-credential') {
        // Firebase'in yeni sürümleri bazen güvenlik için genel hata döner
        return "E-posta veya şifre hatalı.";
      }
      // Diğer hatalar için
      return "Giriş başarısız: ${e.message}";
    } catch (e) {
      return "Beklenmedik bir hata oluştu: $e";
    }
  }

  // --- 4. ÇIKIŞ YAP ---
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  // --- 5. HATA GİDERİCİ EKLEMELER ---

  // HomeScreen'deki hata için eklendi (Şimdilik sahte veri döndürür)
  int getProgress(String category) {
    // İleride burayı veritabanından çekeceğiz
    return 1;
  }

  String? get userName => _user?.displayName;
  String? get userEmail => _user?.email;
}
