import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Sayfalarımızı çağırıyoruz
import 'services/auth_service.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart'; // <-- BU SATIRIN OLDUĞUNDAN EMİN OL

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'KPSS Pro',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
          fontFamily: 'Omnes',
        ),
        // --- İŞTE DEĞİŞTİRMEN GEREKEN YER BURASI ---
        // Eskiden: home: const SignUpScreen(),
        // Şimdi:
        home: WelcomeScreen(),
      ),
    );
  }
}
