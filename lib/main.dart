import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'services/simple_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Kullanıcı daha önce giriş yapmış mı kontrol et
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final userName = prefs.getString('userName');
  
  // Servisi oluştur ve başlangıç verilerini yükle
  final authService = SimpleAuthService();
  if (isLoggedIn && userName != null) {
    // Servis içindeki durumu manuel güncelle ki Home ekranı doğru çalışsın
    // Not: Gerçek bir app'te bu kısmı servisin içinde handle etmek daha iyidir
    // ama şimdilik hızlı çözüm için buradayız.
    await authService.loadUserData();
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authService),
      ],
      child: KPSSApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class KPSSApp extends StatelessWidget {
  final bool isLoggedIn;
  
  KPSSApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KPSS Öğrenme',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF1CB0F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF1CB0F6),
          secondary: Color(0xFF58CC02),
        ),
        useMaterial3: true,
        // Font ailesini burada belirtebiliriz (Google Fonts eklersek)
      ),
      // Eğer giriş yapılmışsa Home, yapılmamışsa Welcome ekranını aç
      home: isLoggedIn ? HomeScreen() : WelcomeScreen(),
    );
  }
}