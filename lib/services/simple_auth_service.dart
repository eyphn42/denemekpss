import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleAuthService extends ChangeNotifier {
  String? _userName;
  String? _userEmail;
  bool _isLoggedIn = false;
  
  // Her kategori için ayrı ilerleme tutacağız
  // Örn: {'Türkçe': 2, 'Matematik': 0, 'Tarih': 5}
  Map<String, int> _categoryProgress = {};

  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isLoggedIn => _isLoggedIn;

  // İstenen kategorinin ilerleme durumunu getir
  int getProgress(String category) {
    return _categoryProgress[category] ?? 0;
  }

  // Verileri yükle
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userName = prefs.getString('userName');
    _userEmail = prefs.getString('userEmail');
    
    // Tüm kategorilerin ilerlemesini tek tek yükle
    // Varsayılan kategorilerimiz:
    List<String> categories = ['Türkçe', 'Matematik', 'Tarih', 'Coğrafya', 'Vatandaşlık'];
    
    _categoryProgress = {};
    for (var cat in categories) {
      // 'progress_Türkçe', 'progress_Matematik' gibi anahtarlarla kaydediyoruz
      _categoryProgress[cat] = prefs.getInt('progress_$cat') ?? 0;
    }
    
    notifyListeners();
  }

  // Ders tamamlanınca çağıracağız (Kategori adı da lazım!)
  Future<void> completeLesson(String category, int lessonIndex) async {
    int currentLevel = getProgress(category);

    // Eğer bitirdiğimiz ders, o kategorideki mevcut seviyemizden büyük veya eşitse artır
    if (lessonIndex >= currentLevel) {
      int newLevel = lessonIndex + 1;
      _categoryProgress[category] = newLevel;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('progress_$category', newLevel);
      
      notifyListeners(); // Ekranları yenile
    }
  }

  // Kayıt ol
  Future<String?> signUp({required String name, required String email, required String password}) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) return 'Tüm alanları doldurun';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('userPassword', password);
    await prefs.setBool('isLoggedIn', true);
    
    // Yeni kullanıcının tüm ilerlemelerini sıfırla
    List<String> categories = ['Türkçe', 'Matematik', 'Tarih', 'Coğrafya', 'Vatandaşlık'];
    for (var cat in categories) {
      await prefs.setInt('progress_$cat', 0);
    }

    _userName = name;
    _userEmail = email;
    _isLoggedIn = true;
    _categoryProgress = {}; // Boş başla
    notifyListeners();
    return null;
  }

  // Giriş yap
  Future<String?> signIn({required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('userEmail') != email || prefs.getString('userPassword') != password) {
      return 'Hatalı e-posta veya şifre';
    }

    // Giriş yapınca verileri yükle
    await loadUserData();
    return null;
  }

  // Çıkış yap
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    _userName = null;
    _userEmail = null;
    _isLoggedIn = false;
    _categoryProgress = {};
    notifyListeners();
  }
}