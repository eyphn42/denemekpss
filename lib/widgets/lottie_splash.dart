import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:kpss_app/screens/home_screen.dart'; // Ana sayfanızın olduğu dosya

class LottieSplashScreen extends StatefulWidget {
  const LottieSplashScreen({super.key});

  @override
  State<LottieSplashScreen> createState() => _LottieSplashScreenState();
}

class _LottieSplashScreenState extends State<LottieSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Controller'ı başlatıyoruz ama süreyi henüz vermiyoruz (Lottie yüklenince alacağız)
    _controller = AnimationController(vsync: this);

    // Animasyon durumunu dinle: Bittiğinde (completed) ana sayfaya git
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutlarını alıyoruz
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white, // Veya animasyonun zemin rengi
      body: SizedBox(
        width: screenWidth,
        height: screenHeight, // Ekran yüksekliğine kilitliyoruz
        child: Lottie.asset(
          'assets/images/splash.json',
          // 'cover': Ekranı tamamen kaplar (boşluk kalmaz, taşma olmaz)
          fit: BoxFit.cover,
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward();
          },
        ),
      ),
    );
  }
}
