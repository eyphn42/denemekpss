// DOSYA: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Servisler
import 'services/auth_service.dart';

// Ekranlar
import 'screens/welcome_screen.dart';
// NOT: game_screen.dart burada çağrılmaz, o zincirin en son halkasıdır.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase başlatma (Hata alırsan GoogleService-Info.plist / google-services.json kontrol et)
  await Firebase.initializeApp();

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
        title: 'KPSS Pro',
        theme: ThemeData(
          // Senin renk paletin ve fontun
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
          fontFamily: 'Omnes',
        ),
        // Uygulama WelcomeScreen ile başlar.
        // Akış şöyledir: Welcome -> Login -> MainNav -> Lessons -> CourseMap -> Game
        home: WelcomeScreen(),
      ),
    );
  }
}
