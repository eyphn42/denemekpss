import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // --- KUTUCUKLARI KONTROL EDEN DEĞİŞKENLER ---
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- TASARIM RENKLERİ ---
  final Color zeoPurple = const Color(0xFF8E54E9);
  final Color zeoOrange = const Color(0xFFE67E22);
  final Color backgroundColor = const Color(0xFFE0E0E0);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- KAYIT OL BUTONUNA BASINCA ÇALIŞAN KOD (Mantık Aynen Korundu) ---
  void _handleSignUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
      );
      return;
    }

    // Yükleniyor simgesi
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final authService = Provider.of<AuthService>(context, listen: false);

    // SADECE MAIL GÖNDER (Kayıt yok)
    String? res = await authService.sendTempOtp(email);

    if (mounted) Navigator.of(context).pop(); // Yükleniyor'u kapat

    if (res == "success") {
      // Başarılıysa bilgileri alıp OTP Ekranına git
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              email: email,
              password: password,
              username: username,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res ?? "Hata")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Gri Arka Plan
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- LOGO ---
                Image.asset(
                  'assets/images/zeo_logo.png', // Dosya adınız neyse onu yazın
                  height: 120, // Logonun boyutunu buradan ayarlayabilirsiniz
                  fit: BoxFit.contain, // Resmi bozmadan sığdırır
                ),

                const SizedBox(height: 30),

                // --- PROFİL İKONU ---
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: zeoOrange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(
                        15.0), // Resim kenarlara yapışmasın diye boşluk
                    child: Image.asset(
                      'assets/images/avatar_icon.png', // SENİN DOSYA ADIN
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // --- BAŞLIK ---
                Text(
                  'hesap oluştur',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: zeoPurple,
                  ),
                ),
                const SizedBox(height: 30),

                // --- KULLANICI ADI ALANI ---
                _buildZeoTextField(
                  controller: _usernameController,
                  icon: Icons.person,
                  hintText: "Kullanıcı Adı",
                ),
                const SizedBox(height: 15),

                // --- EMAIL ALANI ---
                _buildZeoTextField(
                  controller: _emailController,
                  icon: Icons.email,
                  hintText: "E-posta",
                  inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),

                // --- ŞİFRE ALANI ---
                _buildZeoTextField(
                  controller: _passwordController,
                  icon: Icons.lock,
                  hintText: "Şifre",
                  obscureText: true,
                ),
                const SizedBox(height: 40),

                // --- KAYIT OL BUTONU ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                        _handleSignUp, // Senin fonksiyonunu buraya bağladım
                    style: ElevatedButton.styleFrom(
                      backgroundColor: zeoOrange,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'KAYIT OL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- ÖZEL TEXTFIELD TASARIMI (Yardımcı Fonksiyon) ---
  Widget _buildZeoTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool obscureText = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: inputType,
      cursorColor: zeoPurple,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(icon, color: zeoPurple),
        // Sadece alt çizgi olsun (Görseldeki gibi)
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: zeoPurple.withOpacity(0.5), width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: zeoPurple, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
