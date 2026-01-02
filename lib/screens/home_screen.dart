import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simple_auth_service.dart';
import '../models/lesson.dart';
import 'welcome_screen.dart';
import 'quiz_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'Türkçe';

  final List<String> _categories = kpssCategories.keys.toList();

  @override
  Widget build(BuildContext context) {
    // Servisi çağırıyoruz
    final authService = Provider.of<SimpleAuthService>(context);
    
    // NOT: Eski 'completedIndex' satırını buradan kaldırdık çünkü artık kategoriye özel çekiyoruz.

    Widget currentScreen;
    if (_selectedIndex == 0) {
      currentScreen = _buildCategoryLearningPath(authService);
    } else if (_selectedIndex == 1) {
      currentScreen = LeaderboardScreen();
    } else {
      currentScreen = ProfileScreen();
    }

    final bool showAppBar = _selectedIndex == 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: showAppBar ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.flag, color: Colors.red, size: 24),
            ),
            SizedBox(width: 12),
            Text(
              "KPSS",
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 20
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              _buildStatChip(Icons.local_fire_department, "3", Colors.orange),
              _buildStatChip(Icons.diamond, "500", Colors.blue),
              SizedBox(width: 20),
            ],
          ),
        ],
      ) : null,
      
      body: Column(
        children: [
          if (_selectedIndex == 0) ...[
            Container(height: 1, color: Colors.grey[200]),
            Container(
              height: 70,
              padding: EdgeInsets.symmetric(vertical: 12),
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Container(
                      margin: EdgeInsets.only(right: 10),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFF1CB0F6) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Color(0xFF1CB0F6) : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: isSelected ? [] : [
                          BoxShadow(color: Colors.grey[300]!, offset: Offset(0, 2), blurRadius: 0)
                        ],
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          Expanded(child: currentScreen),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF1CB0F6),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        iconSize: 28,
        elevation: 10,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Dersler'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Sıralama'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildCategoryLearningPath(SimpleAuthService authService) {
    final List<Lesson> currentLessons = kpssCategories[_selectedCategory] ?? [];
    
    // DÜZELTME BURADA: İlerlemeyi seçili kategoriye göre çekiyoruz
    final int completedIndex = authService.getProgress(_selectedCategory);

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 20),
      itemCount: currentLessons.length,
      itemBuilder: (context, index) {
        final lesson = currentLessons[index];
        
        bool isLocked = index > completedIndex;
        bool isCompleted = index < completedIndex;
        
        return _buildLessonNode(lesson, index, isLocked, isCompleted);
      },
    );
  }

  Widget _buildLessonNode(Lesson lesson, int index, bool isLocked, bool isCompleted) {
    EdgeInsets nodePadding = EdgeInsets.only(bottom: 24);
    if (index % 4 == 1) nodePadding = EdgeInsets.only(bottom: 24, left: 60);
    else if (index % 4 == 3) nodePadding = EdgeInsets.only(bottom: 24, right: 60);

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Bu seviye kilitli! Öncekileri tamamla."),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.grey[800],
            )
          );
        } else {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => QuizScreen(
                lessonIndex: index, 
                categoryName: _selectedCategory // Kategoriyi gönderiyoruz
              )
            )
          );
        }
      },
      child: Padding(
        padding: nodePadding,
        child: Center(
          child: Column(
            children: [
              Container(
                width: 80, height: 80,
                child: Stack(
                  children: [
                    Positioned(
                      top: 6,
                      child: Container(
                        width: 74, height: 74,
                        decoration: BoxDecoration(
                          color: isLocked ? Colors.grey[400] : Color(0xFF58CC02).withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Container(
                      width: 74, height: 74,
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.grey[300] : (isCompleted ? Color(0xFFFFC800) : Color(0xFF58CC02)),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Icon(
                        isLocked ? Icons.lock : (isCompleted ? Icons.check : lesson.icon),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    if (!isLocked && !isCompleted)
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF1CB0F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text("BAŞLA", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(lesson.title, style: TextStyle(color: isLocked ? Colors.grey : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(width: 16),
      ],
    );
  }
}