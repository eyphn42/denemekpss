// DOSYA: lib/screens/exam_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'exam_success_screen.dart';

class ExamScreen extends StatefulWidget {
  final String examId;
  final String examTitle;
  final int durationMinutes;
  final DateTime startTime;

  const ExamScreen({
    super.key,
    required this.examId,
    required this.examTitle,
    required this.durationMinutes,
    required this.startTime,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentQuestionIndex = 0;
  Map<String, int> _userAnswers = {};
  List<QueryDocumentSnapshot> _questions = [];

  // DERS İSİMLERİ EŞLEŞTİRMESİ (TÜRKÇE KARAKTER İÇİN)
  final Map<String, String> _lessonNames = {
    'turkce': 'TÜRKÇE',
    'matematik': 'MATEMATİK',
    'tarih': 'TARİH',
    'cografya': 'COĞRAFYA',
    'vatandaslik': 'VATANDAŞLIK',
    'guncel': 'GÜNCEL BİLGİLER',
    'fizik': 'FİZİK',
    'kimya': 'KİMYA',
    'biyoloji': 'BİYOLOJİ',
    'geometri': 'GEOMETRİ',
  };

  // DERS NAVİGASYONU VE GRUPLAMA
  Map<String, int> _lessonStartIndices = {};
  List<String> _lessonOrder = [];
  Map<String, List<int>> _questionsByLesson = {};
  String _currentLessonName = "";

  bool _isLoading = true;
  Timer? _timer;
  int _remainingSeconds = 0;
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  final double _baseFontSize = 17.0;
  final double _lineHeight = 1.6;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeExam() async {
    await _fetchQuestions();
    await _restoreUserSession();
    _calculateRemainingTime();

    if (mounted) {
      setState(() => _isLoading = false);
      if (_currentQuestionIndex > 0 && _questions.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_currentQuestionIndex);
          }
        });
      }
    }
    _startTimer();
  }

  // --- DERSLERİ ANALİZ ET VE TÜRKÇE KARAKTER DÜZELT ---
  void _analyzeLessons() {
    _lessonStartIndices.clear();
    _lessonOrder.clear();
    _questionsByLesson.clear();
    String lastLesson = "";

    for (int i = 0; i < _questions.length; i++) {
      var data = _questions[i].data() as Map<String, dynamic>;

      // Veritabanındaki ham key (örn: 'turkce' veya 'matematik')
      String rawKey = (data['lesson'] ?? 'genel').toString();

      // Haritadan güzel ismini al, yoksa manuel düzelt
      String lessonDisplay = _lessonNames[rawKey] ?? rawKey.toUpperCase();

      // Ders Sırası ve Başlangıç İndeksi
      if (lessonDisplay != lastLesson) {
        _lessonStartIndices[lessonDisplay] = i;
        _lessonOrder.add(lessonDisplay);
        lastLesson = lessonDisplay;
      }

      // Soruyu ilgili derse ekle
      if (!_questionsByLesson.containsKey(lessonDisplay)) {
        _questionsByLesson[lessonDisplay] = [];
      }
      _questionsByLesson[lessonDisplay]!.add(i);
    }

    // İlk sorunun dersini güncelle
    if (_questions.isNotEmpty) {
      var firstData =
          _questions[_currentQuestionIndex].data() as Map<String, dynamic>;
      String firstKey = (firstData['lesson'] ?? 'genel').toString();
      _currentLessonName = _lessonNames[firstKey] ?? firstKey.toUpperCase();
    }
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    final examEndTime =
        widget.startTime.add(Duration(minutes: widget.durationMinutes));
    final difference = examEndTime.difference(now);

    if (difference.isNegative) {
      _remainingSeconds = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _finishExam(timeUp: true);
      });
    } else {
      _remainingSeconds = difference.inSeconds;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _finishExam(timeUp: true);
      }
    });
  }

  String get _timerText {
    int hours = _remainingSeconds ~/ 3600;
    int minutes = (_remainingSeconds % 3600) ~/ 60;
    int seconds = _remainingSeconds % 60;
    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Future<void> _fetchQuestions() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('trial_exams')
        .doc(widget.examId)
        .collection('questions')
        .orderBy('order')
        .get();
    if (mounted) {
      _questions = snapshot.docs;
      _analyzeLessons();
    }
  }

  Future<void> _restoreUserSession() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('trial_exams')
          .doc(widget.examId)
          .collection('participations')
          .doc(_userId)
          .get();

      if (doc.exists) {
        var data = doc.data()!;
        if (data['isCompleted'] == true) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ExamSuccessScreen(
                examTitle: widget.examTitle,
                startTime: widget.startTime,
                durationMinutes: widget.durationMinutes,
              ),
            ),
          );
          return;
        }
        if (data['answers'] != null) {
          Map<String, dynamic> savedAnswers = data['answers'];
          savedAnswers.forEach((key, value) {
            _userAnswers[key] = value as int;
          });
        }
        if (data['lastQuestionIndex'] != null) {
          _currentQuestionIndex = data['lastQuestionIndex'];
        }
      } else {
        await FirebaseFirestore.instance
            .collection('trial_exams')
            .doc(widget.examId)
            .collection('participations')
            .doc(_userId)
            .set({
          'userEmail': FirebaseAuth.instance.currentUser?.email,
          'startedAt': FieldValue.serverTimestamp(),
          'answers': {},
          'lastQuestionIndex': 0,
          'isCompleted': false,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Oturum yükleme hatası: $e");
    }
  }

  void _toggleAnswer(String questionId, int answerIndex) {
    bool isUnselecting = _userAnswers[questionId] == answerIndex;

    setState(() {
      if (isUnselecting) {
        _userAnswers.remove(questionId);
      } else {
        _userAnswers[questionId] = answerIndex;
      }
    });

    var participationRef = FirebaseFirestore.instance
        .collection('trial_exams')
        .doc(widget.examId)
        .collection('participations')
        .doc(_userId);

    if (isUnselecting) {
      participationRef.update({
        "answers.$questionId": FieldValue.delete(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } else {
      participationRef.update({
        "answers.$questionId": answerIndex,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentQuestionIndex = index;
      if (_questions.isNotEmpty) {
        var data = _questions[index].data() as Map<String, dynamic>;
        // Yeni ders adını bul (Türkçe karakterli)
        String rawKey = (data['lesson'] ?? '').toString();
        String lesson = _lessonNames[rawKey] ?? rawKey.toUpperCase();

        if (lesson.isNotEmpty && lesson != _currentLessonName) {
          _currentLessonName = lesson;
        }
      }
    });

    FirebaseFirestore.instance
        .collection('trial_exams')
        .doc(widget.examId)
        .collection('participations')
        .doc(_userId)
        .update({"lastQuestionIndex": index});
  }

  void _finishExam({bool timeUp = false}) async {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );
    }
    await FirebaseFirestore.instance
        .collection('trial_exams')
        .doc(widget.examId)
        .collection('participations')
        .doc(_userId)
        .update(
            {'finishedAt': FieldValue.serverTimestamp(), 'isCompleted': true});

    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExamSuccessScreen(
          examTitle: widget.examTitle,
          startTime: widget.startTime,
          durationMinutes: widget.durationMinutes,
        ),
      ),
    );
  }

  // --- SORU GEZGİNİ ---
  void _showQuestionPalette() {
    int initialIndex = _lessonOrder.indexOf(_currentLessonName);
    if (initialIndex == -1) initialIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DefaultTabController(
            length: _lessonOrder.length,
            initialIndex: initialIndex,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Soru Gezgini",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Row(
                        children: [
                          _buildLegendItem(const Color(0xFF7D52A0), "Dolu"),
                          const SizedBox(width: 10),
                          _buildLegendItem(Colors.white, "Boş", border: true),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TabBar(
                  isScrollable: true,
                  labelColor: const Color(0xFF7D52A0),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF7D52A0),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs:
                      _lessonOrder.map((lesson) => Tab(text: lesson)).toList(),
                ),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    children: _lessonOrder.map((lessonName) {
                      List<int> questionIndices =
                          _questionsByLesson[lessonName] ?? [];
                      if (questionIndices.isEmpty)
                        return const Center(child: Text("Soru yok."));

                      return GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: questionIndices.length,
                        itemBuilder: (context, i) {
                          int globalIndex = questionIndices[i];
                          final questionId = _questions[globalIndex].id;
                          final isAnswered =
                              _userAnswers.containsKey(questionId);
                          final isCurrent =
                              globalIndex == _currentQuestionIndex;

                          return InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _pageController.jumpToPage(globalIndex);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: isAnswered
                                      ? const Color(0xFF7D52A0)
                                      : Colors.white,
                                  border: Border.all(
                                      color: isCurrent
                                          ? Colors.orange
                                          : (isAnswered
                                              ? const Color(0xFF7D52A0)
                                              : Colors.grey.shade300),
                                      width: isCurrent ? 2.5 : 1),
                                  borderRadius: BorderRadius.circular(12)),
                              alignment: Alignment.center,
                              child: Text(
                                "${globalIndex + 1}",
                                style: TextStyle(
                                    color: isAnswered
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, {bool border = false}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border ? Border.all(color: Colors.grey) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  // --- AKILLI RENDERER (Smart Paragraphs + Math) ---
  List<Widget> _buildSmartRichContent(dynamic deltaInput,
      {bool isOption = false}) {
    List<Widget> widgets = [];
    if (deltaInput == null) return [const SizedBox.shrink()];

    try {
      dynamic parsed;
      if (deltaInput is String) {
        if (deltaInput.trim().isEmpty) return [const SizedBox.shrink()];
        try {
          parsed = jsonDecode(deltaInput);
        } catch (e) {
          return [Text(deltaInput.toString())];
        }
      } else {
        parsed = deltaInput;
      }

      List<dynamic> operations = [];
      if (parsed is List) {
        operations = parsed;
      } else if (parsed is Map && parsed.containsKey('ops')) {
        operations = parsed['ops'] ?? [];
      } else {
        return [const SizedBox.shrink()];
      }

      List<InlineSpan> currentSpans = [];

      void flushSpans() {
        if (currentSpans.isNotEmpty) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RichText(
              text: TextSpan(
                children: List.from(currentSpans),
                style: TextStyle(
                  fontSize: isOption ? _baseFontSize - 1 : _baseFontSize,
                  color: Colors.black87,
                  fontFamily: 'Arial',
                  height: _lineHeight,
                ),
              ),
            ),
          ));
          currentSpans.clear();
        }
      }

      for (var op in operations) {
        if (op is! Map) continue;

        if (op['insert'] is String) {
          String text = op['insert'];

          if (text == '\n') {
            flushSpans();
            continue;
          }

          if (text.endsWith('\n')) {
            text = text.substring(0, text.length - 1);
            TextStyle style =
                const TextStyle(color: Colors.black87, fontFamily: 'Arial');
            if (op['attributes'] != null && op['attributes'] is Map) {
              final attrs = op['attributes'];
              if (attrs['bold'] == true)
                style = style.copyWith(fontWeight: FontWeight.bold);
              if (attrs['italic'] == true)
                style = style.copyWith(fontStyle: FontStyle.italic);
              if (attrs['underline'] == true)
                style = style.copyWith(decoration: TextDecoration.underline);
            }
            currentSpans.add(TextSpan(text: text, style: style));
            flushSpans();
          } else {
            TextStyle style =
                const TextStyle(color: Colors.black87, fontFamily: 'Arial');
            if (op['attributes'] != null && op['attributes'] is Map) {
              final attrs = op['attributes'];
              if (attrs['bold'] == true)
                style = style.copyWith(fontWeight: FontWeight.bold);
              if (attrs['italic'] == true)
                style = style.copyWith(fontStyle: FontStyle.italic);
              if (attrs['underline'] == true)
                style = style.copyWith(decoration: TextDecoration.underline);
            }
            currentSpans.add(TextSpan(text: text, style: style));
          }
        } else if (op['insert'] is Map) {
          flushSpans();

          final insertMap = op['insert'] as Map;
          String? formula;

          if (insertMap.containsKey('custom') && insertMap['custom'] is Map) {
            var custom = insertMap['custom'];
            if (custom.containsKey('formula'))
              formula = custom['formula'].toString();
          } else if (insertMap.containsKey('formula')) {
            formula = insertMap['formula'].toString();
          } else if (insertMap.containsKey('custom') &&
              insertMap['custom'] is String) {
            try {
              var decoded = jsonDecode(insertMap['custom']);
              if (decoded is Map && decoded.containsKey('formula'))
                formula = decoded['formula'];
            } catch (_) {}
          }

          if (formula != null) {
            String osymStyleFormula = "\\displaystyle\\mathsf{ $formula }";
            widgets.add(Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Math.tex(
                  osymStyleFormula,
                  textStyle: TextStyle(
                    fontSize: isOption ? 17 : 20,
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                    fontFamily: null,
                  ),
                  options: MathOptions(
                      style: MathStyle.display, color: Colors.black),
                  onErrorFallback: (err) => Text("FORMÜL HATASI",
                      style: const TextStyle(color: Colors.red, fontSize: 10)),
                ),
              ),
            ));
          }
        }
      }
      flushSpans();
    } catch (e) {
      return [const Text("İçerik Hatası", style: TextStyle(color: Colors.red))];
    }

    return widgets;
  }

  Widget _buildContentArea(dynamic deltaData, String fallbackHtml,
      {bool isOption = false}) {
    if (deltaData != null) {
      List<Widget> content =
          _buildSmartRichContent(deltaData, isOption: isOption);
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: content);
    } else {
      return HtmlWidget(
        fallbackHtml,
        textStyle: TextStyle(
          fontSize: isOption ? _baseFontSize - 1 : _baseFontSize,
          fontFamily: 'Arial',
          height: _lineHeight,
        ),
      );
    }
  }

  Widget _buildZoomableImage(String url) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                  backgroundColor: Colors.black, foregroundColor: Colors.white),
              backgroundColor: Colors.black,
              body: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(url),
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Column(
          children: [
            Text(widget.examTitle,
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.normal)),
            Text(_timerText,
                style: const TextStyle(
                    color: Color(0xFFE67E22),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                    fontSize: 18)),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                        title: const Text("Sınavı Bitir?"),
                        content:
                            const Text("Soruları cevaplamayı tamamladınız mı?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text("DEVAM ET")),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(c);
                                _finishExam();
                              },
                              child: const Text("BİTİR",
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ));
            },
            child: const Text("BİTİR",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.redAccent)),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // DERS FİLTRE ÇUBUĞU
                if (_lessonOrder.isNotEmpty)
                  Container(
                    height: 50,
                    width: double.infinity,
                    color: Colors.white,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      itemCount: _lessonOrder.length,
                      itemBuilder: (context, index) {
                        String lessonName = _lessonOrder[index];
                        bool isActive = lessonName == _currentLessonName;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(lessonName),
                            selected: isActive,
                            selectedColor: const Color(0xFF7D52A0),
                            labelStyle: TextStyle(
                                color: isActive ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                            onSelected: (bool selected) {
                              int? targetIndex =
                                  _lessonStartIndices[lessonName];
                              if (targetIndex != null) {
                                _pageController.jumpToPage(targetIndex);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),

                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF7D52A0)),
                  minHeight: 4,
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _questions.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      return _buildQuestionCard(_questions[index], index);
                    },
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildQuestionCard(QueryDocumentSnapshot doc, int index) {
    final data = doc.data() as Map<String, dynamic>;
    final questionId = doc.id;

    dynamic questionDelta = data['text_delta'];
    String? imageUrl = data['imageUrl'];

    List<dynamic> rawOptions = data['options'] ?? [];
    List<dynamic>? optionsDeltas = data['options_delta'];

    int optionCount = (optionsDeltas != null && optionsDeltas.isNotEmpty)
        ? optionsDeltas.length
        : rawOptions.length;

    Map<String, String> optionImages = {};
    if (data['optionImages'] != null) {
      data['optionImages'].forEach((k, v) => optionImages[k] = v);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Soru ${index + 1}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF7D52A0))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(_currentLessonName,
                    style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (imageUrl != null) ...[
            _buildZoomableImage(imageUrl),
            const SizedBox(height: 25),
          ],
          _buildContentArea(questionDelta, data['text'] ?? ''),
          const SizedBox(height: 35),
          ...List.generate(optionCount, (optIndex) {
            String label = String.fromCharCode(65 + optIndex);
            bool isSelected = _userAnswers[questionId] == optIndex;
            String? optImg = optionImages[optIndex.toString()];

            dynamic currentOptionDelta =
                (optionsDeltas != null && optIndex < optionsDeltas.length)
                    ? optionsDeltas[optIndex]
                    : null;
            String currentOptionHtml = (optIndex < rawOptions.length)
                ? rawOptions[optIndex].toString()
                : "";

            return GestureDetector(
              onTap: () => _toggleAnswer(questionId, optIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7D52A0).withOpacity(0.08)
                        : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF7D52A0)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? []
                        : [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                offset: const Offset(0, 2),
                                blurRadius: 4)
                          ]),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF7D52A0)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.grey.shade400)),
                      child: Text(label,
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: optImg != null
                          ? Image.network(optImg,
                              height: 100, alignment: Alignment.centerLeft)
                          : _buildContentArea(
                              currentOptionDelta, currentOptionHtml,
                              isOption: true),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5))
      ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: _currentQuestionIndex > 0
                ? () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut)
                : null,
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            label: const Text("Önceki"),
            style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300)),
          ),
          GestureDetector(
            onTap: _showQuestionPalette,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.grid_view, size: 18, color: Colors.black87),
                  const SizedBox(width: 5),
                  Text("${_currentQuestionIndex + 1} / ${_questions.length}",
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.black87)),
                ],
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _currentQuestionIndex < _questions.length - 1
                ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut)
                : () {
                    showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                              title: const Text("Sınavı Bitir"),
                              content:
                                  const Text("Tüm soruları tamamladınız mı?"),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(c),
                                    child: const Text("İPTAL")),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(c);
                                      _finishExam();
                                    },
                                    child: const Text("BİTİR",
                                        style: TextStyle(color: Colors.red))),
                              ],
                            ));
                  },
            icon: Icon(
                _currentQuestionIndex < _questions.length - 1
                    ? Icons.arrow_forward_ios
                    : Icons.check_circle,
                size: 16),
            label: Text(_currentQuestionIndex < _questions.length - 1
                ? "Sonraki"
                : "Bitir"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: const Color(0xFF7D52A0),
              foregroundColor: Colors.white,
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}
