import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String password;
  final String username;

  const OtpScreen({
    super.key,
    required this.email,
    required this.password,
    required this.username,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  String _currentCode = "";

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verifyAndRegister() async {
    if (_isLoading || _otpController.text.length != 6) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    String? res = await authService.completeRegistration(
      email: widget.email,
      password: widget.password,
      username: widget.username,
      inputCode: _otpController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (res == "success") {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res ?? "Hata"),
            backgroundColor: Colors.redAccent,
          ),
        );
        _otpController.clear();
        setState(() => _currentCode = "");
        _focusNode.requestFocus();
      }
    }
  }

  // _buildZeoLetter fonksiyonunu sildim, artık gerek yok.

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFE6E6E6);
    const Color boxColor = Color(0xFFDC8C47);
    const Color textColor = Color(0xFF7D52A0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- LOGO ALANI (YENİLENDİ) ---
                // Eğer resim görünmezse yolunu kontrol et: 'assets/zeo_logo.png' olabilir.
                Image.asset(
                  'assets/images/zeo_logo.png',
                  height: 120, // Logonun büyüklüğünü buradan ayarlayabilirsin
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    "e postana gelen 6 haneli\ndoğrulama kodunu gir",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- OTP GİRİŞ ALANI (Tıklama Garantili) ---
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).requestFocus(_focusNode);
                  },
                  child: Container(
                    color: Colors.transparent,
                    height: 80,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // GİZLİ TEXTFIELD
                        SizedBox(
                          width: 1,
                          height: 1,
                          child: TextField(
                            controller: _otpController,
                            focusNode: _focusNode,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            autofocus: true,
                            showCursor: false,
                            enableInteractiveSelection: false,
                            decoration: const InputDecoration(
                              counterText: "",
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _currentCode = value;
                              });
                              if (value.length == 6) {
                                _verifyAndRegister();
                              }
                            },
                          ),
                        ),

                        // GÖRÜNÜR KUTUCUKLAR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              width: 45,
                              height: 55,
                              decoration: BoxDecoration(
                                color: boxColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  )
                                ],
                                border: index == _currentCode.length
                                    ? Border.all(color: textColor, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  index < _currentCode.length
                                      ? _currentCode[index]
                                      : "",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                if (_isLoading)
                  const CircularProgressIndicator(
                    color: textColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
