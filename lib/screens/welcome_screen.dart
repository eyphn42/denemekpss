import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

// import 'signup_screen.dart'; // Kayıt ekranını oluşturunca bu yorumu kaldır.

class WelcomeScreen extends StatelessWidget {
  // Tasarımdaki Renkler (login_screen.dart ile aynı)
  final Color _kPurpleColor = Color(0xFF7E57C2);
  final Color _kOrangeColor = Color(0xFFE67E22);
  final Color _kBackgroundColor = Color(0xFFF0F0F0);

  // Omnes Font Stili (Tutarlılık için)
  TextStyle get _omnesStyle => TextStyle(
        fontFamily: 'Omnes',
        fontWeight: FontWeight.bold,
      );

  @override
  Widget build(BuildContext context) {
    // Ekranın genişliğini alarak padding'i ona göre ayarlayabiliriz
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 400 ? 40.0 : 30.0;

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. LOGO
                // Eğer logo resmini assets'e eklediysen alttaki satırı aç, diğerini sil.
                Image.asset('assets/images/zeo_logo.png', height: 160),

                // 2. BAŞLIK
                Text(
                  'hoşgeldin',
                  style: _omnesStyle.copyWith(
                    fontSize: 34,
                    color: _kPurpleColor,
                  ),
                ),

                SizedBox(height: 80),

                // 3. KAYIT OL BUTONU
                SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: () {
                      // YENİ: Kayıt ekranına yönlendir
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignUpScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kOrangeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 5,
                    ),
                    child: Text(
                      'kayıt ol',
                      style: _omnesStyle.copyWith(fontSize: 22),
                    ),
                  ),
                ),

                SizedBox(height: 24), // Butonlar arası boşluk

                // 4. ZATEN HESABIM VAR BUTONU
                SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: () {
                      // Giriş ekranına yönlendir
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kOrangeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 5,
                    ),
                    child: Text(
                      'zaten hesabım var',
                      style: _omnesStyle.copyWith(fontSize: 22),
                    ),
                  ),
                ),
                SizedBox(height: 40), // Alt boşluk
              ],
            ),
          ),
        ),
      ),
    );
  }
}
