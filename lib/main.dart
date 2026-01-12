// DOSYA: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 1. BU EKLENDİ
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart'; // 2. BU EKLENDİ (Hatayı çözen kütüphane)
import 'package:kpss_app/widgets/lottie_splash.dart';

// Servisler
import 'services/auth_service.dart';

// Ekranlar
import 'screens/welcome_screen.dart';
// NOT: game_screen.dart burada çağrılmaz, o zincirin en son halkasıdır.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase başlatma (Hata alırsan GoogleService-Info.plist / google-services.json kontrol et)
  await Firebase.initializeApp();
  await initializeDateFormatting('tr_TR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth servisini tüm uygulamaya yayıyoruz
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ZEO',
        theme: ThemeData(
          // Senin renk paletin ve fontun
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
          fontFamily: 'Omnes',
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'),
        ],
        locale: const Locale('tr', 'TR'),
        // Uygulama WelcomeScreen ile başlar.
        // Akış şöyledir: Welcome -> Login -> MainNav -> Lessons -> CourseMap -> Game
        home: const LottieSplashScreen(),
      ),
    );
  }
}
