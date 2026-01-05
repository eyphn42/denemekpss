// DOSYA: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'units_screen.dart'; // <--- BU SATIR OLMADAN ÇALIŞMAZ!

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> courses = [
    {
      "id": "turkce",
      "name": "Türkçe",
      "icon": Icons.book,
      "color": const Color(0xFFE57373)
    },
    {
      "id": "matematik",
      "name": "Matematik",
      "icon": Icons.calculate,
      "color": const Color(0xFF64B5F6)
    },
    {
      "id": "tarih",
      "name": "Tarih",
      "icon": Icons.history_edu,
      "color": const Color(0xFFFFB74D)
    },
    {
      "id": "cografya",
      "name": "Coğrafya",
      "icon": Icons.public,
      "color": const Color(0xFF81C784)
    },
    {
      "id": "vatandaslik",
      "name": "Vatandaşlık",
      "icon": Icons.balance,
      "color": const Color(0xFFBA68C8)
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("ZeO KPSS",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF7D52A0),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hangi dersten çalışmak istersin?",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1,
                ),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return GestureDetector(
                    onTap: () {
                      // UnitsScreen burada çağrılıyor.
                      // Import satırı sayesinde artık hata vermeyecek.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UnitsScreen(
                            courseId: course['id'],
                            courseName: course['name'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: course['color'].withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(course['icon'],
                                size: 40, color: course['color']),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            course['name'],
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
