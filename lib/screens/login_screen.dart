import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart'; // SimpleAuthService yerine bunu kullanıyoruz
import 'home_screen.dart';
import 'signup_screen.dart'; // "Kayıt Ol" yönlendirmesi için

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- KONTROLLER ---
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // --- ZEO TASARIM RENKLERİ ---
  final Color _zeoPurple = const Color(0xFF8E54E9);
  final Color _zeoOrange = const Color(0xFFE67E22);
  final Color _backgroundColor = const Color(0xFFE0E0E0); // Gri Arka Plan

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- GİRİŞ YAP FONKSİYONU ---
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen e-posta ve şifrenizi girin")),
      );
      return;
    }

    // Yükleniyor simgesi göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final authService = Provider.of<AuthService>(context, listen: false);

    // Servisten giriş yapmasını iste
    String? res = await authService.loginUser(
      email: email,
      password: password,
    );

    // İşlem bitince yükleniyor simgesini kapat
    if (mounted) Navigator.of(context).pop();

    if (res == "success") {
      // Başarılıysa Ana Sayfaya git
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } else {
      // Hata varsa göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res ?? "Giriş başarısız"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Özel gri arka plan
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- 1. LOGO ALANI ---
                Image.asset(
                  'assets/images/zeo_logo.png', // Senin yeni logo dosyan
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Logo yoksa metin göster (Yedek)
                    return Text(
                      'Zeo',
                      style: TextStyle(
                        fontFamily: 'Omnes',
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: _zeoPurple,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // --- 2. BAŞLIK ---
                Text(
                  'tekrar hoşgeldin',
                  style: TextStyle(
                    fontFamily: 'Omnes',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _zeoPurple,
                  ),
                ),

                const SizedBox(height: 30),

                // --- 3. E-POSTA KUTUSU ---
                _buildZeoTextField(
                  controller: _emailController,
                  hintText: "E-posta",
                  iconPath: 'assets/images/email_icon.png', // Senin ikonun
                  iconData: Icons.email, // Yedek ikon
                  inputType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                // --- 4. ŞİFRE KUTUSU ---
                _buildZeoTextField(
                  controller: _passwordController,
                  hintText: "Şifre",
                  iconPath: 'assets/images/lock_icon.png', // Senin ikonun
                  iconData: Icons.lock, // Yedek ikon
                  obscureText: true,
                ),

                const SizedBox(height: 10),

                // --- 5. ŞİFREMİ UNUTTUM & BENİ HATIRLA ---
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Şifre sıfırlama eklenebilir
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Yakında eklenecek!")),
                      );
                    },
                    child: Text(
                      'şifremi unuttum',
                      style: TextStyle(
                        fontFamily: 'Omnes',
                        color: _zeoPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- 6. GİRİŞ YAP BUTONU ---
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _zeoOrange,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'GİRİŞ YAP',
                      style: TextStyle(
                        fontFamily: 'Omnes',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- 7. KAYIT OL YÖNLENDİRMESİ ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Hesabın yok mu? ",
                      style: TextStyle(
                          color: Colors.grey[600], fontFamily: 'Omnes'),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Kayıt ekranına git
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignUpScreen()),
                        );
                      },
                      child: Text(
                        "Kayıt Ol",
                        style: TextStyle(
                          fontFamily: 'Omnes',
                          color: _zeoPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- ÖZEL TEXTFIELD TASARIMI (Resim ve İkon Destekli) ---
  Widget _buildZeoTextField({
    required TextEditingController controller,
    required String hintText,
    String? iconPath, // Resim yolu (Opsiyonel)
    IconData? iconData, // Yedek Flutter ikonu
    bool obscureText = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: inputType,
      cursorColor: _zeoPurple,
      style: const TextStyle(
        fontFamily: 'Omnes',
        fontWeight: FontWeight.w500,
        fontSize: 18,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'Omnes',
          color: _zeoPurple.withOpacity(0.5),
          fontSize: 16,
        ),

        // İKON KISMI: Asset varsa onu kullanır, yoksa Flutter ikonunu
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: (iconPath != null)
              ? Image.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  color: _zeoPurple, // İkon rengini mor yap
                  errorBuilder: (c, e, s) => Icon(iconData, color: _zeoPurple),
                )
              : Icon(iconData, color: _zeoPurple),
        ),

        // Sadece alt çizgi (Zeo Tasarımı)
        enabledBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: _zeoPurple.withOpacity(0.5), width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _zeoPurple, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
