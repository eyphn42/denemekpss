import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simple_auth_service.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<SimpleAuthService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(height: 20),
              CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFF1CB0F6).withOpacity(0.1),
                child: Text(
                  authService.userName?[0].toUpperCase() ?? "K",
                  style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Color(0xFF1CB0F6)),
                ),
              ),
              SizedBox(height: 24),
              Text(authService.userName ?? "İsimsiz", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Text(authService.userEmail ?? "email@yok.com", style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await authService.signOut();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => WelcomeScreen()),
                      (route) => false,
                    );
                  },
                  child: Text("ÇIKIŞ YAP", style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}