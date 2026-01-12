import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kpss_app/models/models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kpss_app/widgets/timeline_rope_widget.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class QuizScreen extends StatefulWidget {
  final String title;
  final List<Question> questions;
// --- İLERLEME İÇİN GEREKLİ VERİLER ---
  final String? courseId;
  final String? unitId;
  final String? topicId;
  final int? totalTopicCount;

  const QuizScreen({
    super.key,
    required this.title,
    required this.questions,
    this.courseId,
    this.unitId,
    this.topicId,
    this.totalTopicCount,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // --- RENKLER ---
  final Color zeoPurple = const Color(0xFF7D52A0);
  final Color zeoOrange = const Color(0xFFE67E22);
  final Color correctColor = const Color(0xFF58CC02);
  final Color wrongColor = const Color(0xFFFF4B4B);

  // --- GENEL DEĞİŞKENLER ---
  int currentQuestionIndex = 0;
  int score = 0;
  bool isFinished = false;
  bool isProgressUpdated = false; // İlerleme bir kez güncellensin

  // --- ORTAK DURUM ---
  int? selectedOptionIndex;
  bool isChecked = false;
  int? _hoveredIndex; // Drag & Drop hover efekti için

  // --- SORU TİPİNE ÖZEL DEĞİŞKENLER ---

  // Eşleştirme (Düzeltildi)
  List<String> matchItems = [];
  String? firstSelectedItem;
  List<String> matchedItems = [];
  bool isProcessingMatch = false;

  // Sıralama
  List<String> sortingItems = [];
  bool isSortingCorrect = false;

  // Flashcard
  bool isCardFlipped = false;

  // Kelime Avı
  int gridSize = 8;
  List<List<String>> wsGrid = [];
  List<String> wsFoundWords = [];
  List<Point<int>> wsCurrentDrag = [];
  List<Point<int>> wsCorrectCells = [];

  // Bucket Sort
  Map<String, String> bucketItems = {};
  List<String> remainingBucketItems = [];
  List<String> categories = [];

  // Çoklu Seçim
  List<int> multiSelectedIndices = [];
  bool isMultiCorrect = false;

  // Harita
  Offset? userTapPosition;
  bool isMapCorrect = false;

  // Hiyerarşi & Timeline
  List<String?> placedItems = [];
  List<String> draggablePool = [];

  @override
  void initState() {
    super.initState();
    _prepareQuestion();
  }

  String _cleanText(String htmlString) {
    if (htmlString.isEmpty) return "";
    String text = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    return text.trim();
  }

  // --- İLERLEME GÜNCELLEME (FIREBASE) ---
  Future<void> _updateProgress() async {
    // 1. Kontroller
    if (isProgressUpdated) return;
    if (widget.courseId == null ||
        widget.unitId == null ||
        widget.topicId == null) {
      debugPrint("HATA: ID bilgileri eksik! İlerleme kaydedilemedi.");
      return;
    }

    setState(() => isProgressUpdated = true);

    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(widget.courseId);

      debugPrint(
          "İLERLEME BAŞLIYOR... Ders: ${widget.courseId}, Ünite: ${widget.unitId}");

      String listKey = 'completed_topics_${widget.unitId}';

      await docRef.set({
        listKey: FieldValue.arrayUnion([widget.topicId])
      }, SetOptions(merge: true));

      debugPrint("Konu listeye eklendi.");

      // 3. Şimdi güncel listeyi çekip yüzdesini hesaplayalım
      var snapshot = await docRef.get();
      if (snapshot.exists &&
          widget.totalTopicCount != null &&
          widget.totalTopicCount! > 0) {
        var data = snapshot.data() as Map<String, dynamic>;
        List<dynamic> completedList = data[listKey] ?? [];

        double percentage = completedList.length / widget.totalTopicCount!;
        if (percentage > 1.0) percentage = 1.0;

        // 4. Yüzdeyi yaz: progress_{unitId}
        String progressKey = 'progress_${widget.unitId}';

        await docRef.set({progressKey: percentage}, SetOptions(merge: true));

        debugPrint("Yüzde güncellendi: $progressKey = $percentage");
      }
    } catch (e) {
      debugPrint("CRITICAL ERROR (İlerleme Kaydı): $e");
    }
  }

  // --- SORU HAZIRLIK (HER YENİ SORUDA ÇALIŞIR) ---
  void _prepareQuestion() {
    if (widget.questions.isEmpty) return;

    final question = widget.questions[currentQuestionIndex];

    // 1. Tüm State'leri Sıfırla
    setState(() {
      isChecked = false;
      selectedOptionIndex = null;
      isCardFlipped = false;
      multiSelectedIndices = [];
      isMultiCorrect = false;
      userTapPosition = null;
      isMapCorrect = false;
      placedItems = [];
      draggablePool = [];
      matchItems = [];
      matchedItems = [];
      firstSelectedItem = null;
      isProcessingMatch = false;
      sortingItems = [];
      isSortingCorrect = false;
    });

    // Tipe Göre Veri Doldurma
    if (question.type == QuestionType.match && question.matchingPairs != null) {
      question.matchingPairs!.forEach((k, v) {
        matchItems.add(k);
        matchItems.add(v);
      });
      matchItems.shuffle();
    } else if (question.type == QuestionType.sorting) {
      sortingItems = List.from(question.options)..shuffle();
    } else if (question.type == QuestionType.wordSearch) {
      _generateWordSearchGrid(question.options);
    } else if (question.type == QuestionType.bucketSort &&
        question.matchingPairs != null) {
      bucketItems = question.matchingPairs!;
      categories = bucketItems.values.toSet().toList();
      remainingBucketItems = bucketItems.keys.toList()..shuffle();
    } else if (question.type == QuestionType.hierarchyPyramid ||
        question.type == QuestionType.timelineRope) {
      placedItems = List<String?>.filled(question.options.length, null);
      draggablePool = List.from(question.options)..shuffle();
    }
  }

  // --- ACTIONS (KULLANICI ETKİLEŞİMLERİ) ---

  void _onOptionSelected(int index) {
    if (isChecked) return;
    setState(() {
      selectedOptionIndex = index;
      isChecked = true;
      if (index == widget.questions[currentQuestionIndex].correctAnswerIndex) {
        score++;
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex >= widget.questions.length - 1) {
      setState(() {
        isFinished = true;
      });
      _updateProgress();
      return;
    }
    // InfoCard -> Soru Geçişi Uyarısı
    final currentType = widget.questions[currentQuestionIndex].type;
    final nextType = widget.questions[currentQuestionIndex + 1].type;

    if (currentType == QuestionType.infoCard &&
        nextType != QuestionType.infoCard) {
      _showTransitionDialog();
      return;
    }

    setState(() {
      currentQuestionIndex++;
      _prepareQuestion();
    });
  }

  void _showTransitionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.rocket_launch, size: 50, color: Color(0xFFE67E22)),
            SizedBox(height: 10),
            Text("Hazır mısın?", textAlign: TextAlign.center),
          ],
        ),
        content: const Text(
          "Bilgi kartını tamamladın.\nŞimdi öğrendiklerini test etme zamanı! 🚀",
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: correctColor),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                currentQuestionIndex++;
                _prepareQuestion();
              });
            },
            child: const Text("TESTE BAŞLA",
                style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- EŞLEŞTİRME MANTIĞI (DÜZELTİLDİ) ---
  void _onMatchItemTap(String item) async {
    if (matchedItems.contains(item) || isProcessingMatch) return;

    if (firstSelectedItem == item) {
      setState(() => firstSelectedItem = null);
      return;
    }

    if (firstSelectedItem == null) {
      setState(() => firstSelectedItem = item);
    } else {
      final question = widget.questions[currentQuestionIndex];
      final pairs = question.matchingPairs!;

      // A -> B veya B -> A eşleşmesi kontrolü
      bool isMatch = (pairs[firstSelectedItem] == item) ||
          (pairs[item] == firstSelectedItem);

      if (isMatch) {
        setState(() {
          matchedItems.add(firstSelectedItem!);
          matchedItems.add(item);
          firstSelectedItem = null;
        });

        if (matchedItems.length == matchItems.length) {
          score++;
          isProcessingMatch = true;
          await Future.delayed(const Duration(seconds: 1));
          isProcessingMatch = false;
          _nextQuestion();
        }
      } else {
        setState(() => firstSelectedItem = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text("Eşleşmedi!"),
            backgroundColor: wrongColor,
            duration: const Duration(milliseconds: 500)));
      }
    }
  }

  // --- KELİME AVI MANTIĞI (ORİJİNAL KODDAN) ---
  void _generateWordSearchGrid(List<String> words) {
    wsGrid = List.generate(gridSize, (_) => List.filled(gridSize, ''));
    wsFoundWords = [];
    wsCurrentDrag = [];
    wsCorrectCells = [];
    final random = Random();
    const alphabet = "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ";
    for (String word in words) {
      bool placed = false;
      int attempts = 0;
      while (!placed && attempts < 100) {
        int row = random.nextInt(gridSize);
        int col = random.nextInt(gridSize);
        int direction = random.nextInt(2);
        if (direction == 0) {
          if (col + word.length <= gridSize) {
            bool canPlace = true;
            for (int i = 0; i < word.length; i++) {
              if (wsGrid[row][col + i] != '' &&
                  wsGrid[row][col + i] != word[i]) {
                canPlace = false;
                break;
              }
            }
            if (canPlace) {
              for (int i = 0; i < word.length; i++)
                wsGrid[row][col + i] = word[i];
              placed = true;
            }
          }
        } else {
          if (row + word.length <= gridSize) {
            bool canPlace = true;
            for (int i = 0; i < word.length; i++) {
              if (wsGrid[row + i][col] != '' &&
                  wsGrid[row + i][col] != word[i]) {
                canPlace = false;
                break;
              }
            }
            if (canPlace) {
              for (int i = 0; i < word.length; i++)
                wsGrid[row + i][col] = word[i];
              placed = true;
            }
          }
        }
        attempts++;
      }
    }
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (wsGrid[i][j] == '') {
          wsGrid[i][j] = alphabet[random.nextInt(alphabet.length)];
        }
      }
    }
  }

  void _handleDrag(Offset localPosition, double itemSize) {
    int col = (localPosition.dx / itemSize).floor();
    int row = (localPosition.dy / itemSize).floor();
    if (row >= 0 && row < gridSize && col >= 0 && col < gridSize) {
      final point = Point(row, col);
      if (!wsCurrentDrag.contains(point)) {
        setState(() {
          wsCurrentDrag.add(point);
        });
      }
    }
  }

  void _checkWordSelection(Question question) {
    String selectedWord = "";
    for (var point in wsCurrentDrag) {
      selectedWord += wsGrid[point.x][point.y];
    }
    String reversedWord = selectedWord.split('').reversed.join('');
    if (question.options.contains(selectedWord) &&
        !wsFoundWords.contains(selectedWord)) {
      setState(() {
        wsFoundWords.add(selectedWord);
        wsCorrectCells.addAll(wsCurrentDrag);
        wsCurrentDrag = [];
      });
    } else if (question.options.contains(reversedWord) &&
        !wsFoundWords.contains(reversedWord)) {
      setState(() {
        wsFoundWords.add(reversedWord);
        wsCorrectCells.addAll(wsCurrentDrag);
        wsCurrentDrag = [];
      });
    } else {
      setState(() {
        wsCurrentDrag = [];
      });
    }
    if (wsFoundWords.length == question.options.length) {
      score++;
    }
  }

  // --- DİĞER YARDIMCILAR (ORİJİNAL KODDAN) ---
  void _bucketItemDropped(String item, String targetCategory) {
    if (bucketItems[item] == targetCategory) {
      setState(() {
        remainingBucketItems.remove(item);
      });
      if (remainingBucketItems.isEmpty) {
        score++;
        _nextQuestion();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Yanlış Sepet!"),
          backgroundColor: wrongColor,
          duration: const Duration(milliseconds: 500)));
    }
  }

  void _onRemoveItem(int index, String item) {
    if (isChecked) return;
    setState(() {
      placedItems[index] = null;
      draggablePool.add(item);
    });
  }

  void _checkOrderedAnswer() {
    // 1. Önce boş alan var mı kontrol et
    if (placedItems.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen tüm alanları doldurunuz."),
          backgroundColor: Colors.orange,
          duration: Duration(milliseconds: 1000),
        ),
      );
      return;
    }

    setState(() {
      isChecked = true;
      final correctList = widget.questions[currentQuestionIndex].options;

      // 2. Eleman eleman karşılaştırma yap (En sağlıklı yöntem)
      bool isCorrect = true;
      for (int i = 0; i < correctList.length; i++) {
        if (placedItems[i] != correctList[i]) {
          isCorrect = false;
          break;
        }
      }

      if (isCorrect) {
        score++;
        // BottomBar'da "Doğru" algılanması için -1'den farklı bir değer atıyoruz
        selectedOptionIndex = 1;
      } else {
        selectedOptionIndex = -1; // Hatalı
      }
    });
  }

  void _checkSortingAnswer() {
    setState(() {
      isChecked = true;
      final correctOrder = widget.questions[currentQuestionIndex].options;
      if (sortingItems.toString() == correctOrder.toString()) {
        isSortingCorrect = true;
        score++;
      } else {
        isSortingCorrect = false;
      }
    });
  }

  void _checkMultiSelectionAnswer() {
    setState(() {
      isChecked = true;
      final correct =
          widget.questions[currentQuestionIndex].answerIndices ?? [];
      final sSet = multiSelectedIndices.toSet();
      final cSet = correct.toSet();
      if (sSet.length == cSet.length && sSet.containsAll(cSet)) {
        isMultiCorrect = true;
        score++;
      } else {
        isMultiCorrect = false;
      }
    });
  }

  void _onMultiSelect(int index) {
    if (isChecked) return;
    setState(() {
      if (multiSelectedIndices.contains(index))
        multiSelectedIndices.remove(index);
      else
        multiSelectedIndices.add(index);
    });
  }

  void _onMapTap(
      TapUpDetails details, BoxConstraints constraints, Question question) {
    if (isChecked) return;
    double localX = details.localPosition.dx;
    double localY = details.localPosition.dy;
    double normalizedX = localX / constraints.maxWidth;
    double normalizedY = localY / constraints.maxHeight;
    setState(() {
      userTapPosition = Offset(normalizedX, normalizedY);
      isChecked = true;
      double targetX = question.answerLocation!['x']!;
      double targetY = question.answerLocation!['y']!;
      double tolerance = question.answerLocation!['tolerance']!;
      double distance =
          sqrt(pow(normalizedX - targetX, 2) + pow(normalizedY - targetY, 2));
      if (distance <= tolerance) {
        isMapCorrect = true;
        score++;
      } else {
        isMapCorrect = false;
      }
    });
  }

  // --- WIDGET BUILD (ANA EKRAN) ---
  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
          appBar: AppBar(), body: const Center(child: Text("Soru bulunamadı")));
    }

    final question = widget.questions[currentQuestionIndex];

    // --- ALT BAR GÖRÜNME MANTIĞI ---
    bool showBottomBar = false;

    // 1. Cevap verildiyse (Sonuç ekranı) -> KESİN GÖSTER
    if (isChecked) {
      showBottomBar = true;
    }
    // 2. Cevap verilmediyse -> Soru tipine göre karar ver
    else {
      if (question.type == QuestionType.sorting ||
          question.type == QuestionType.flashcard ||
          question.type == QuestionType.multipleSelection ||
          question.type == QuestionType.hierarchyPyramid || // <-- EKLENDİ
          question.type == QuestionType.timelineRope) {
        // <-- EKLENDİ
        showBottomBar = true;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isFinished
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.grey[800]),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              title: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (currentQuestionIndex + 1) / widget.questions.length,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(zeoOrange),
                ),
              ),
              centerTitle: true,
            ),

      // ALT BAR BURADA ÇAĞRILIYOR
      bottomNavigationBar: showBottomBar ? _buildBottomFeedback() : null,

      // BODY (İÇERİK)
      body: SafeArea(
        child: isFinished ? _buildResultScreen() : _buildBodySelector(),
      ),
    );
  }

  Widget _buildBodySelector() {
    final question = widget.questions[currentQuestionIndex];

    // --- DEBUG İÇİN KONSOLA YAZDIRMA ---
    print("------------------------------------------------");
    print("GÖSTERİLEN SORU SIRASI: ${currentQuestionIndex + 1}");
    print("SORU ID: ${question.id}");
    print("SORU TİPİ (Enum): ${question.type}");
    print("SORU METNİ: ${question.text}");
    print("------------------------------------------------");
    if (question.type == QuestionType.dragDrop)
      return _buildDragDropBody(question);
    if (question.type == QuestionType.match) return _buildMatchBody(question);
    if (question.type == QuestionType.sorting)
      return _buildSortingBody(question);
    if (question.type == QuestionType.findMistake)
      return _buildFindMistakeBody(question);
    if (question.type == QuestionType.trueFalse)
      return _buildTrueFalseBody(question);
    if (question.type == QuestionType.flashcard)
      return _buildFlashcardBody(question);
    if (question.type == QuestionType.elimination)
      return _buildEliminationBody(question);
    if (currentQuestionIndex >= widget.questions.length) {
      return const Center(child: Text("Soru indeksi taştı!"));
    }
    if (widget.questions.isEmpty) {
      return const Center(child: Text("Soru listesi boş!"));
    }
    // YENİ: InfoCard
    if (question.type == QuestionType.infoCard) {
      return InfoCardWidget(
        text: question.text,
        onContinue: () {
          _nextQuestion();
        },
      );
    }

    if (question.type == QuestionType.wordSearch)
      return _buildWordSearchBody(question);
    if (question.type == QuestionType.sentenceParsing)
      return _buildSentenceParsingBody(question);
    if (question.type == QuestionType.paragraphPuzzle)
      return _buildParagraphPuzzleBody(question);
    if (question.type == QuestionType.bucketSort)
      return _buildBucketSortBody(question);
    if (question.type == QuestionType.multipleSelection)
      return _buildMultipleSelectionBody(question);
    if (question.type == QuestionType.mapQuestion)
      return _buildMapQuestionBody(question);
    if (question.type == QuestionType.graphInterpretation)
      return _buildGraphBody(question);
    if (question.type == QuestionType.hierarchyPyramid)
      return _buildHierarchyBody(question);
    if (question.type == QuestionType.timelineRope)
      return _buildTimelineBody(question);

    return _buildMultipleChoiceBody(question);
  }

  // --- 1. EŞLEŞTİRME (DÜZELTİLDİ) ---
  Widget _buildMatchBody(Question question) {
    if (matchItems.isEmpty) {
      return const Center(child: Text("Eşleştirme verisi yüklenemedi."));
    }
    return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(children: [
          const SizedBox(height: 10),
          Text(question.text,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: zeoPurple),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Expanded(
              child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.0, // Daha geniş kartlar
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10),
                  itemCount: matchItems.length,
                  itemBuilder: (context, index) {
                    final item = matchItems[index];
                    final isSelected = item == firstSelectedItem;
                    final isMatched = matchedItems.contains(item);

                    Color boxColor = isMatched
                        ? Colors.grey.shade100
                        : (isSelected ? Colors.blue.shade50 : Colors.white);
                    Color borderColor = isMatched
                        ? Colors.transparent
                        : (isSelected ? Colors.blue : Colors.grey.shade300);

                    return GestureDetector(
                        onTap: () => _onMatchItemTap(item),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: boxColor,
                                border:
                                    Border.all(color: borderColor, width: 2),
                                borderRadius: BorderRadius.circular(15)),
                            child: isMatched
                                ? const Icon(Icons.check, color: Colors.green)
                                : Text(item,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isMatched
                                            ? Colors.grey.shade300
                                            : zeoPurple))));
                  }))
        ]));
  }

  // --- GEREKSİZİ SİL (ELIMINATION) EKRANI ---
  Widget _buildEliminationBody(Question question) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Text(
            "Cümledeki gereksiz veya hatalı kelimeye dokun:",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(question.options.length, (index) {
                final word = question.options[index];

                // Renk Durumları
                Color chipColor = Colors.grey.shade100;
                Color textColor = Colors.black87;
                BorderSide border = BorderSide.none;

                if (isChecked) {
                  // Doğru cevap (atılması gereken kelime)
                  if (index == question.correctAnswerIndex) {
                    chipColor = correctColor.withOpacity(0.2); // Yeşilimsi
                    textColor = correctColor;
                    border = BorderSide(color: correctColor);
                  }
                  // Kullanıcının yanlış seçimi
                  else if (index == selectedOptionIndex) {
                    chipColor = wrongColor.withOpacity(0.2); // Kırmızımsı
                    textColor = wrongColor;
                    border = BorderSide(color: wrongColor);
                  }
                }

                return GestureDetector(
                  onTap: () => _onOptionSelected(index),
                  child: Chip(
                    label: Text(
                      word,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        decoration:
                            (isChecked && index == question.correctAnswerIndex)
                                ? TextDecoration
                                    .lineThrough // Atılan kelimenin üstünü çiz
                                : null,
                      ),
                    ),
                    backgroundColor: chipColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: border,
                    ),
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // --- 2. SÜRÜKLE BIRAK (DÜZELTİLDİ) ---
  Widget _buildDragDropBody(Question question) {
    List<String> parts = question.text.split('____');
    String part1 = parts.isNotEmpty ? parts[0] : "";
    String part2 = parts.length > 1 ? parts[1] : "";

    return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(children: [
          const SizedBox(height: 20),
          Text("Boşluğu doldur:",
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 40),
          Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(part1,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: zeoPurple),
                    textAlign: TextAlign.center),

                // Hedef Alan
                DragTarget<int>(
                    onWillAccept: (data) => !isChecked,
                    onAccept: (data) {
                      _onOptionSelected(data);
                    },
                    builder: (context, candidateData, rejectedData) {
                      String? droppedText;
                      Color boxColor = Colors.grey.shade200;
                      Color borderColor = Colors.grey.shade400;
                      if (selectedOptionIndex != null) {
                        droppedText = question.options[selectedOptionIndex!];
                        if (selectedOptionIndex ==
                            question.correctAnswerIndex) {
                          boxColor = correctColor.withOpacity(0.2);
                          borderColor = correctColor;
                        } else {
                          boxColor = wrongColor.withOpacity(0.2);
                          borderColor = wrongColor;
                        }
                      } else if (candidateData.isNotEmpty) {
                        borderColor = zeoOrange;
                        boxColor = zeoOrange.withOpacity(0.1);
                      }
                      return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: boxColor,
                              border: Border.all(color: borderColor, width: 2),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(droppedText ?? "      ",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: selectedOptionIndex != null
                                      ? borderColor
                                      : Colors.transparent)));
                    }),

                Text(part2,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: zeoPurple),
                    textAlign: TextAlign.center)
              ]),
          const Spacer(),

          // Seçenekler
          Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(question.options.length, (index) {
                if (isChecked && selectedOptionIndex == index)
                  return const SizedBox(
                      width: 60, height: 40); // Sürüklenen öğe kaybolsun

                return Draggable<int>(
                    data: index,
                    feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                                color: zeoOrange,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(question.options[index],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)))),
                    childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(question.options[index],
                                style: const TextStyle(fontSize: 18)))),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: Colors.grey.shade300, width: 2),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(question.options[index],
                            style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 18,
                                fontWeight: FontWeight.bold))));
              })),
          const SizedBox(height: 40)
        ]));
  }

  // --- 1. ÇOKTAN SEÇMELİ (HTML DESTEKLİ) ---
  Widget _buildMultipleChoiceBody(Question question) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text("Soru ${currentQuestionIndex + 1}",
            style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 20),
        if (question.imageUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(question.imageUrl!,
                  height: 200, fit: BoxFit.contain, errorBuilder: (c, e, s) {
                return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image)));
              }),
            ),
          ),

        // SORU KÖKÜ (HTML)
        HtmlWidget(
          question.text,
          textStyle: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: zeoPurple),
        ),

        const Spacer(),
        ...List.generate(question.options.length,
            (index) => _buildOptionButton(index, question)),
        const Spacer()
      ]),
    );
  }

  Widget _buildOptionButton(int index, Question question) {
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = zeoPurple;
    if (isChecked) {
      if (index == question.correctAnswerIndex) {
        backgroundColor = correctColor.withOpacity(0.2);
        borderColor = correctColor;
        textColor = correctColor;
      } else if (index == selectedOptionIndex &&
          index != question.correctAnswerIndex) {
        backgroundColor = wrongColor.withOpacity(0.2);
        borderColor = wrongColor;
        textColor = wrongColor;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton(
        onPressed: () => _onOptionSelected(index),
        style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            padding: const EdgeInsets.symmetric(vertical: 15),
            side: BorderSide(color: borderColor, width: 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 0),
        child: Row(children: [
          const SizedBox(width: 20),
          Expanded(
              // ŞIKLAR (HTML)
              child: HtmlWidget(
            question.options[index],
            textStyle: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          )),
          if (isChecked && index == question.correctAnswerIndex)
            Icon(Icons.check_circle, color: correctColor),
          if (isChecked &&
              index == selectedOptionIndex &&
              index != question.correctAnswerIndex)
            Icon(Icons.cancel, color: wrongColor),
          const SizedBox(width: 20)
        ]),
      ),
    );
  }

  // --- ORİJİNAL KODDAN RESTORE EDİLENLER (Harita, Kelime Avı vb.) ---

  Widget _buildBucketSortBody(Question question) {
    return Column(children: [
      const SizedBox(height: 10),
      Text(question.text,
          style: TextStyle(color: Colors.grey[600], fontSize: 16)),
      Align(alignment: Alignment.centerRight),
      const SizedBox(height: 20),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: categories
                .map((category) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: DragTarget<String>(
                          onWillAccept: (data) => true,
                          onAccept: (data) =>
                              _bucketItemDropped(data, category),
                          builder: (context, candidateData, rejectedData) =>
                              Container(
                                  width: MediaQuery.of(context).size.width /
                                      2.8, // Genişliği biraz kıstık
                                  height: 150,
                                  decoration: BoxDecoration(
                                      color: candidateData.isNotEmpty
                                          ? zeoOrange.withOpacity(0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: candidateData.isNotEmpty
                                              ? zeoOrange
                                              : Colors.grey.shade300,
                                          width: 2)),
                                  alignment: Alignment.center,
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.shopping_basket_outlined,
                                            size: 40, color: zeoPurple),
                                        const SizedBox(height: 10),
                                        Text(category,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: zeoPurple,
                                                fontSize: 14))
                                      ]))),
                    ))
                .toList()),
      ),
      const Spacer(),
      if (remainingBucketItems.isEmpty)
        const Center(
            child: Text("Tebrikler!",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)))
      else
        Wrap(
            spacing: 10,
            runSpacing: 10,
            children: remainingBucketItems
                .map((item) => Draggable<String>(
                    data: item,
                    feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration:
                                BoxDecoration(color: zeoOrange, borderRadius: BorderRadius.circular(15), boxShadow: const [
                              BoxShadow(blurRadius: 10, color: Colors.black26)
                            ]),
                            child: Text(item,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)))),
                    childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
                            child: Text(item, style: const TextStyle(color: Colors.transparent)))),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: zeoPurple, width: 1.5), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), offset: const Offset(0, 3))]), child: Text(item, style: TextStyle(color: zeoPurple, fontWeight: FontWeight.bold, fontSize: 16)))))
                .toList()),
      const SizedBox(height: 50)
    ]);
  }

  Widget _buildMultipleSelectionBody(Question question) {
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 10),
          HtmlWidget(question.text,
              textStyle: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
              child: ListView.builder(
                  itemCount: question.options.length,
                  itemBuilder: (context, index) {
                    String optText = _cleanText(question.options[index]);
                    bool isSelected = multiSelectedIndices.contains(index);
                    bool isCorrectOption =
                        question.answerIndices?.contains(index) ?? false;
                    Color boxColor = Colors.white;
                    Color borderColor = Colors.grey.shade300;
                    IconData icon =
                        isSelected ? Icons.check_circle : Icons.circle_outlined;
                    Color iconColor = isSelected ? zeoPurple : Colors.grey;
                    if (isChecked) {
                      if (isCorrectOption) {
                        boxColor = correctColor.withOpacity(0.1);
                        borderColor = correctColor;
                        icon = Icons.check_circle;
                        iconColor = correctColor;
                      } else if (isSelected && !isCorrectOption) {
                        boxColor = wrongColor.withOpacity(0.1);
                        borderColor = wrongColor;
                        icon = Icons.cancel;
                        iconColor = wrongColor;
                      }
                    } else if (isSelected) {
                      borderColor = zeoPurple;
                    }
                    return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                            onTap: () => _onMultiSelect(index),
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                    color: boxColor,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                        color: borderColor, width: 2)),
                                child: Row(children: [
                                  Icon(icon, color: iconColor, size: 28),
                                  const SizedBox(width: 15),
                                  Expanded(
                                      child: Text(optText,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500)))
                                ]))));
                  }))
        ]));
  }

  // --- 2. CÜMLE ÖGELERİ (PARÇALAMA İÇİN TEMİZ METİN ŞART) ---
  Widget _buildSentenceParsingBody(Question question) {
    // Burada HTML temizliyoruz çünkü kelime kelime bölmemiz lazım
    String cleanText = _cleanText(question.text);

    // Yönergeyi HTML olarak gösterebiliriz
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 10),
        HtmlWidget(question.text,
            textStyle:
                TextStyle(color: Colors.grey[600], fontSize: 16)), // Yönerge
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ]),
          child: Wrap(
            spacing: 6,
            runSpacing: 14,
            alignment: WrapAlignment.start,
            children: List.generate(question.options.length, (index) {
              // Optionlar tek tek kelimelerdir, bunları temizliyoruz
              final chunk = _cleanText(question.options[index]);

              Color underlineColor = Colors.transparent;
              double underlineThickness = 2;
              Color textColor = Colors.black87;

              if (isChecked) {
                if (index == question.correctAnswerIndex) {
                  underlineColor = correctColor;
                  underlineThickness = 4;
                  textColor = correctColor;
                } else if (index == selectedOptionIndex &&
                    index != question.correctAnswerIndex) {
                  underlineColor = wrongColor;
                  underlineThickness = 3;
                  textColor = wrongColor;
                }
              } else {
                if (index == selectedOptionIndex) {
                  underlineColor = zeoPurple;
                  underlineThickness = 3;
                  textColor = zeoPurple;
                }
              }

              return GestureDetector(
                onTap: () => _onOptionSelected(index),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: underlineColor,
                              width: underlineThickness))),
                  child: Text(chunk,
                      style: TextStyle(
                          fontSize: 20,
                          height: 1.2,
                          color: textColor,
                          fontWeight: index == selectedOptionIndex
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
        if (!isChecked)
          Text("Seçmek istediğin ögeye dokun.",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              textAlign: TextAlign.center)
      ]),
    );
  }

  Widget _buildParagraphPuzzleBody(Question question) {
    List<String> parts = question.text.split('____');
    String part1 = parts.isNotEmpty ? parts[0] : "";
    String part2 = parts.length > 1 ? parts[1] : "";
    return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(children: [
          const SizedBox(height: 10),
          Text("Paragrafı en uygun cümleyle tamamla:",
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 20),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200, width: 2)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(part1,
                        style: const TextStyle(
                            fontSize: 18, height: 1.5, color: Colors.black87)),
                    DragTarget<int>(
                        onWillAccept: (data) => !isChecked,
                        onAccept: (data) {
                          _onOptionSelected(data);
                        },
                        builder: (context, candidateData, rejectedData) {
                          String? droppedText;
                          Color boxColor = Colors.grey.shade100;
                          Color borderColor = Colors.grey.shade300;
                          if (selectedOptionIndex != null) {
                            droppedText =
                                question.options[selectedOptionIndex!];
                            if (selectedOptionIndex ==
                                question.correctAnswerIndex) {
                              boxColor = correctColor.withOpacity(0.1);
                              borderColor = correctColor;
                            } else {
                              boxColor = wrongColor.withOpacity(0.1);
                              borderColor = wrongColor;
                            }
                          } else if (candidateData.isNotEmpty) {
                            boxColor = zeoOrange.withOpacity(0.1);
                            borderColor = zeoOrange;
                          }
                          return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: boxColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: borderColor,
                                      width: 2,
                                      style: BorderStyle.solid)),
                              child: Text(droppedText ?? " (Buraya sürükle) ",
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: selectedOptionIndex != null
                                          ? Colors.black
                                          : Colors.grey.shade500,
                                      fontWeight: selectedOptionIndex != null
                                          ? FontWeight.bold
                                          : FontWeight.normal),
                                  textAlign: TextAlign.center));
                        }),
                    Text(part2,
                        style: const TextStyle(
                            fontSize: 18, height: 1.5, color: Colors.black87))
                  ])),
          const Spacer(),
          ListView.separated(
              shrinkWrap: true,
              itemCount: question.options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (isChecked && selectedOptionIndex == index)
                  return const SizedBox.shrink();
                return Draggable<int>(
                    data: index,
                    feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                            width: MediaQuery.of(context).size.width - 40,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                color: zeoOrange,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: const [
                                  BoxShadow(
                                      blurRadius: 10, color: Colors.black26)
                                ]),
                            child: Text(question.options[index],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)))),
                    childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(15)),
                            child: Text(question.options[index],
                                style: const TextStyle(
                                    color: Colors.transparent)))),
                    child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: Colors.grey.shade100, offset: const Offset(0, 3))]),
                        child: Text(question.options[index], style: const TextStyle(fontSize: 16))));
              }),
          const SizedBox(height: 20)
        ]));
  }

  Widget _buildWordSearchBody(Question question) {
    return Column(children: [
      const SizedBox(height: 10),
      Text("Gizlenmiş kelimeleri bul!",
          style: TextStyle(color: Colors.grey[600], fontSize: 16)),
      const SizedBox(height: 10),
      Expanded(
          flex: 3,
          child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: LayoutBuilder(builder: (context, constraints) {
                final double itemSize = constraints.maxWidth / gridSize;
                return GestureDetector(
                    onPanStart: (details) {
                      _handleDrag(details.localPosition, itemSize);
                    },
                    onPanUpdate: (details) {
                      _handleDrag(details.localPosition, itemSize);
                    },
                    onPanEnd: (details) {
                      _checkWordSelection(question);
                    },
                    child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridSize),
                        itemCount: gridSize * gridSize,
                        itemBuilder: (context, index) {
                          final int row = index ~/ gridSize;
                          final int col = index % gridSize;
                          final point = Point(row, col);
                          bool isSelected = wsCurrentDrag.contains(point);
                          bool isFound = wsCorrectCells.contains(point);
                          Color color = Colors.white;
                          if (isFound)
                            color = correctColor.withOpacity(0.3);
                          else if (isSelected)
                            color = Colors.blue.withOpacity(0.3);
                          return Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                  border:
                                      Border.all(color: Colors.grey.shade300)),
                              alignment: Alignment.center,
                              child: Text(wsGrid[row][col],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: (isFound || isSelected)
                                          ? zeoPurple
                                          : Colors.black87)));
                        }));
              }))),
      Expanded(
          flex: 1,
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              color: Colors.grey[50],
              child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: question.options.map((word) {
                    bool isFound = wsFoundWords.contains(word);
                    return Chip(
                        label: Text(word,
                            style: TextStyle(
                                color: isFound ? Colors.white : Colors.black87,
                                decoration: isFound
                                    ? TextDecoration.lineThrough
                                    : null)),
                        backgroundColor: isFound ? correctColor : Colors.white,
                        side: BorderSide(
                            color: isFound
                                ? Colors.transparent
                                : Colors.grey.shade300));
                  }).toList()))),
    ]);
  }

  Widget _buildFlashcardBody(Question question) {
    return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(children: [
          const SizedBox(height: 20),
          Text(isCardFlipped ? "Cevap / Açıklama" : "Öğrenmek için karta dokun",
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 30),
          Expanded(
              child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isCardFlipped = !isCardFlipped;
                    });
                  },
                  child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        final rotateAnim =
                            Tween(begin: 3.14, end: 0.0).animate(animation);
                        return AnimatedBuilder(
                            animation: rotateAnim,
                            child: child,
                            builder: (context, widget) {
                              return Transform(
                                  transform:
                                      Matrix4.rotationY(isCardFlipped ? 0 : 0),
                                  alignment: Alignment.center,
                                  child: widget);
                            });
                      },
                      child: isCardFlipped
                          ? _buildCardContent(
                              question.options.isNotEmpty
                                  ? question.options[0]
                                  : "Cevap yok",
                              true)
                          : _buildCardContent(question.text, false)))),
          const SizedBox(height: 20)
        ]));
  }

  Widget _buildCardContent(String text, bool isBack) {
    return Container(
        key: ValueKey(isBack),
        width: double.infinity,
        height: 400,
        padding: const EdgeInsets.all(30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: isBack ? zeoPurple : Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: isBack
                      ? zeoPurple.withOpacity(0.4)
                      : Colors.grey.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
            border: isBack ? null : Border.all(color: zeoPurple, width: 2)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isBack ? Icons.lightbulb : Icons.question_mark_rounded,
              size: 60, color: isBack ? zeoOrange : zeoPurple),
          const SizedBox(height: 30),
          Text(text,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isBack ? Colors.white : Colors.black87,
                  height: 1.4),
              textAlign: TextAlign.center)
        ]));
  }

  Widget _buildTrueFalseBody(Question question) {
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 10),
          Text("Doğru mu Yanlış mı?",
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
              child: Center(
                  child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10))
                          ],
                          border: Border.all(
                              color: Colors.grey.shade100, width: 2)),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.info_outline,
                            size: 60, color: Colors.blueAccent),
                        const SizedBox(height: 20),
                        Text(question.text,
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: zeoPurple,
                                height: 1.3),
                            textAlign: TextAlign.center)
                      ])))),
          const SizedBox(height: 40),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _buildTFButton(1, "YANLIŞ", wrongColor, Icons.close, question),
            _buildTFButton(0, "DOĞRU", correctColor, Icons.check, question)
          ]),
          const SizedBox(height: 20)
        ]));
  }

  Widget _buildTFButton(
      int index, String label, Color color, IconData icon, Question question) {
    Color buttonColor = Colors.white;
    Color iconColor = color;
    Color borderColor = color.withOpacity(0.3);
    if (isChecked) {
      if (index == question.correctAnswerIndex) {
        buttonColor = color;
        iconColor = Colors.white;
        borderColor = color;
      } else if (index == selectedOptionIndex) {
        buttonColor = color.withOpacity(0.2);
      } else {
        borderColor = Colors.grey.shade200;
        iconColor = Colors.grey.shade300;
      }
    }
    return GestureDetector(
        onTap: () => _onOptionSelected(index),
        child: Column(children: [
          Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: buttonColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 4),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ]),
              child: Icon(icon, size: 40, color: iconColor)),
          const SizedBox(height: 10),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: iconColor == Colors.white ? color : Colors.grey,
                  fontSize: 16))
        ]));
  }

  // --- HATAYI BUL ---
  Widget _buildFindMistakeBody(Question question) {
    return Padding(
        padding: const EdgeInsets.all(20.0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 10),
          Text(question.text,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ]),
              child: Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(question.options.length, (index) {
                    final word = question.options[index];
                    Color boxColor = Colors.grey.shade100;
                    Color textColor = Colors.black87;
                    Color borderColor = Colors.transparent;
                    if (isChecked) {
                      if (index == question.correctAnswerIndex) {
                        boxColor = correctColor.withOpacity(0.2);
                        borderColor = correctColor;
                        textColor = correctColor;
                      } else if (index == selectedOptionIndex &&
                          index != question.correctAnswerIndex) {
                        boxColor = wrongColor.withOpacity(0.2);
                        borderColor = wrongColor;
                        textColor = wrongColor;
                      }
                    } else {
                      boxColor = Colors.white;
                      borderColor = Colors.grey.shade300;
                    }
                    return GestureDetector(
                        onTap: () => _onOptionSelected(index),
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                                color: boxColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: borderColor == Colors.transparent
                                        ? Colors.grey.shade300
                                        : borderColor,
                                    width: 2)),
                            child: Text(word,
                                style: TextStyle(
                                    fontSize: 18,
                                    color: textColor,
                                    fontWeight: FontWeight.bold))));
                  })))
        ]));
  }

  Widget _buildSortingBody(Question question) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            question.text,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: zeoPurple),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (!isChecked)
            Text(
              "Sıralamak için kutunun herhangi bir yerine basılı tutup sürükle 👇",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: ReorderableListView(
              // 1. Otomatik tutamaçları kapatıyoruz
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                if (isChecked) return;
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = sortingItems.removeAt(oldIndex);
                  sortingItems.insert(newIndex, item);
                });
              },
              children: [
                for (int i = 0; i < sortingItems.length; i++)
                  // 2. Her öğeyi bu Listener ile sarıyoruz
                  ReorderableDragStartListener(
                    key: ValueKey(sortingItems[i]), // Key artık burada olmalı
                    index: i,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: isChecked
                              ? (isSortingCorrect ? correctColor : wrongColor)
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor: zeoOrange.withOpacity(0.1),
                          child: Text(
                            "${i + 1}",
                            style: TextStyle(
                                color: zeoOrange, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          sortingItems[i],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        // İkonu görsel olarak bırakıyoruz ama artık her yerden tutulabilir
                        trailing: const Icon(Icons.drag_indicator,
                            color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyBody(Question question) {
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text(question.text,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Expanded(
              child: Center(
                  child: SingleChildScrollView(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              List.generate(question.options.length, (index) {
                            double widthFactor = 0.3 +
                                (0.7 * (index + 1) / question.options.length);
                            return DragTarget<String>(
                              onWillAccept: (data) =>
                                  !isChecked && placedItems[index] == null,
                              onAccept: (data) {
                                setState(() {
                                  placedItems[index] = data;
                                  draggablePool.remove(data);
                                });
                              },
                              builder: (context, candidateData, rejectedData) {
                                bool isCorrectSlot = isChecked &&
                                    placedItems[index] ==
                                        question.options[index];
                                Color slotColor = isChecked
                                    ? (isCorrectSlot
                                        ? correctColor
                                        : wrongColor)
                                    : (candidateData.isNotEmpty
                                        ? zeoOrange.withOpacity(0.3)
                                        : zeoPurple
                                            .withOpacity(0.1 + (0.15 * index)));
                                return GestureDetector(
                                  onTap: () {
                                    if (placedItems[index] != null &&
                                        !isChecked)
                                      _onRemoveItem(index, placedItems[index]!);
                                  },
                                  child: Container(
                                      margin: const EdgeInsets.only(bottom: 2),
                                      width: MediaQuery.of(context).size.width *
                                          widthFactor,
                                      height: 50,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: slotColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.white, width: 2)),
                                      child: Text(placedItems[index] ?? "",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isChecked
                                                  ? Colors.white
                                                  : zeoPurple,
                                              fontSize: 14),
                                          textAlign: TextAlign.center)),
                                );
                              },
                            );
                          }))))),
          const SizedBox(height: 20),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: draggablePool
                  .map((item) => Draggable<String>(
                      data: item,
                      feedback: Material(
                          color: Colors.transparent,
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                  color: zeoOrange,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(item,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)))),
                      childWhenDragging:
                          Opacity(opacity: 0.3, child: Chip(label: Text(item))),
                      child: Chip(
                          label: Text(item), backgroundColor: Colors.white)))
                  .toList()),
          const SizedBox(height: 20),
        ]));
  }

  // Timeline Rope (Widget Entegrasyonu)
  // DOSYA: lib/screens/quiz_screen.dart içinde...

  // --- DİKEY TARİH ŞERİDİ (TEMİZ & BUTON ENTEGRASYONLU) ---
  Widget _buildTimelineBody(Question question) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        children: [
          Text(
            question.text,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // --- LİSTE ALANI ---
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. SOL TARAF
                      SizedBox(
                        width: 50,
                        child: Column(
                          children: [
                            Expanded(
                              child: index == 0
                                  ? const SizedBox()
                                  : Container(
                                      width: 2,
                                      color: zeoPurple.withOpacity(0.3)),
                            ),
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: zeoPurple,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        blurRadius: 4)
                                  ]),
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: index == question.options.length - 1
                                  ? const SizedBox()
                                  : Container(
                                      width: 2,
                                      color: zeoPurple.withOpacity(0.3)),
                            ),
                          ],
                        ),
                      ),

                      // 2. SAĞ TARAF (DİNAMİK YUVA)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: DragTarget<Map<String, dynamic>>(
                            onWillAccept: (data) {
                              if (!isChecked) {
                                setState(() => _hoveredIndex = index);
                                return true;
                              }
                              return false;
                            },
                            onLeave: (data) {
                              setState(() => _hoveredIndex = null);
                            },
                            onAccept: (incomingData) {
                              setState(() {
                                _hoveredIndex = null;
                                String incomingItem = incomingData['item'];
                                int sourceIndex = incomingData['fromIndex'];
                                String? currentItemInThisSlot =
                                    placedItems[index];

                                if (sourceIndex != -1) {
                                  placedItems[sourceIndex] =
                                      currentItemInThisSlot;
                                  placedItems[index] = incomingItem;
                                } else {
                                  if (currentItemInThisSlot != null) {
                                    draggablePool.add(currentItemInThisSlot);
                                  }
                                  placedItems[index] = incomingItem;
                                  draggablePool.remove(incomingItem);
                                }
                              });
                            },
                            builder: (context, candidateData, rejectedData) {
                              String? currentItem = placedItems[index];
                              bool isHovered = _hoveredIndex == index;

                              return SizedBox(
                                height: 55,
                                child: Stack(
                                  children: [
                                    // KATMAN 1: SOCKET (BOŞLUK)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    // KATMAN 2: İÇERİK
                                    AnimatedSlide(
                                      offset: isHovered
                                          ? const Offset(0.0, 0.4)
                                          : Offset.zero,
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeOutCubic,
                                      child: AnimatedOpacity(
                                        opacity: isHovered ? 0.6 : 1.0,
                                        duration:
                                            const Duration(milliseconds: 250),
                                        child: _buildSlotContent(
                                            currentItem, index, question),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // --- SÜRÜKLEME HAVUZU (SADECE CHIPLER) ---
          // "Yerleştirilecekler" yazısı kaldırıldı.
          // Havuz boşalınca tamamen kaybolur (yer kaplamaz).
          if (draggablePool.isNotEmpty && !isChecked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center, // Ortala
                children: draggablePool.map((item) {
                  return Draggable<Map<String, dynamic>>(
                    data: {'item': item, 'fromIndex': -1},
                    feedback: Material(
                      color: Colors.transparent,
                      child: Transform.scale(
                          scale: 1.05,
                          child: _buildDraggableChip(item, isDragging: true)),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _buildDraggableChip(item),
                    ),
                    child: _buildDraggableChip(item),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- YARDIMCI: KUTU İÇERİĞİ (SADE & MİNİMAL) ---
  Widget _buildSlotContent(String? currentItem, int index, Question question) {
    // 1. DURUM: BOŞ KUTU
    if (currentItem == null) {
      return Container(
        height: 50, // Yükseklik hizalaması için
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.grey.shade300, width: 1), // İnce gri çerçeve
        ),
      );
    }

    // 2. DURUM: DOLU KUTU
    Color boxColor = Colors.white;
    Color borderColor = Colors.transparent;
    IconData? statusIcon;
    List<BoxShadow> shadows = [
      BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2))
    ];

    if (isChecked) {
      if (currentItem == question.options[index]) {
        boxColor = correctColor.withOpacity(0.1);
        borderColor = correctColor;
        statusIcon = Icons.check_circle;
      } else {
        boxColor = wrongColor.withOpacity(0.1);
        borderColor = wrongColor;
        statusIcon = Icons.cancel;
      }
      shadows = [];
    }

    Widget content = Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != Colors.transparent
            ? Border.all(color: borderColor, width: 2)
            : null,
        boxShadow: shadows,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              currentItem,
              style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (statusIcon != null)
            Icon(statusIcon,
                color: isChecked && currentItem == question.options[index]
                    ? correctColor
                    : wrongColor,
                size: 20)
        ],
      ),
    );

    // Doluysa ve kontrol edilmemişse sürüklenebilir olsun
    if (!isChecked) {
      return Draggable<Map<String, dynamic>>(
        data: {'item': currentItem, 'fromIndex': index},
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 250,
            child: Opacity(opacity: 0.9, child: content),
          ),
        ),
        childWhenDragging: Opacity(
          opacity:
              0.0, // Sürüklendiği an görünmez olsun (Alttaki boşluk görünsün)
          child: content,
        ),
        child: content,
      );
    }

    return content;
  }

  // --- YARDIMCI: SÜRÜKLENEBİLİR CHIP ---
  Widget _buildDraggableChip(String item, {bool isDragging = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: isDragging
                  ? [zeoOrange.withOpacity(0.9), zeoOrange]
                  : [zeoOrange, zeoOrange.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: zeoOrange.withOpacity(isDragging ? 0.4 : 0.2),
                blurRadius: isDragging ? 12 : 6,
                offset: Offset(0, isDragging ? 4 : 2))
          ]),
      child: Text(
        item,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  // --- YENİLENMİŞ & GÜVENLİ GRAFİK SORUSU ---
  Widget _buildGraphBody(Question question) {
    // 1. VERİ KONTROLÜ
    bool hasData = question.graphData != null && question.graphData!.isNotEmpty;
    bool hasGroupData =
        question.groupGraphData != null && question.groupGraphData!.isNotEmpty;

    if (!hasData && !hasGroupData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 10),
            Text("Grafik verisi bulunamadı.\n(ID: ${question.id})",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    // 2. GRAFİK HESAPLAMALARI
    // Hangi veriyi kullanacağız? (Öncelik: Group, sonra Simple)
    final bool isGrouped = hasGroupData;
    final List<String> labels = isGrouped
        ? question.groupGraphData!.keys.toList()
        : question.graphData!.keys.toList();

    // Y Ekseni için Maksimum Değeri Bulma
    int maxValue = 0;
    if (isGrouped) {
      for (var list in question.groupGraphData!.values) {
        for (var val in list) {
          if (val > maxValue) maxValue = val;
        }
      }
    } else {
      if (question.graphData!.values.isNotEmpty) {
        maxValue = question.graphData!.values.reduce(max);
      }
    }

    // Grafiğin tavan değerini hesapla (Örn: max 45 ise tavan 50 olsun)
    int yAxisMax = ((maxValue / 10).ceil() * 10);
    if (yAxisMax == 0) yAxisMax = 10;

    // Renk Paleti (Gruplu grafikler için)
    List<Color> barColors = [
      zeoPurple,
      zeoOrange,
      Colors.blueAccent,
      Colors.green
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SORU METNİ
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Text(
              question.text,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 20),

          // GRAFİK ALANI (Expanded ile kalan alanı kaplasın)
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.fromLTRB(5, 20, 10, 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      // Y EKSENİ (Sayılar)
                      SizedBox(
                        width: 30,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            int val = (yAxisMax * (5 - index) / 5).round();
                            return Text(
                              val.toString(),
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            );
                          }),
                        ),
                      ),

                      // ÇUBUKLAR VE ÇİZGİLER
                      Expanded(
                        child: Stack(
                          children: [
                            // Yatay Kılavuz Çizgileri
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (index) {
                                return Container(
                                  height: 1,
                                  color: index == 5
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade100,
                                );
                              }),
                            ),

                            // Barların Dizilimi
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment:
                                  CrossAxisAlignment.end, // Alttan hizala
                              children: List.generate(labels.length, (index) {
                                String label = labels[index];

                                // Tekil Grafik Mantığı
                                if (!isGrouped) {
                                  int value = question.graphData![label] ?? 0;
                                  double heightRatio = value / yAxisMax;
                                  // Max yükseklikten biraz pay bırakıyoruz (padding)
                                  double barHeight =
                                      (constraints.maxHeight - 20) *
                                          heightRatio;

                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Değer etiketi (Bar üstünde sayı)
                                      Text("$value",
                                          style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      // Bar
                                      TweenAnimationBuilder<double>(
                                          tween:
                                              Tween(begin: 0, end: barHeight),
                                          duration:
                                              const Duration(milliseconds: 800),
                                          curve: Curves.easeOutQuart,
                                          builder: (context, val, _) {
                                            return Container(
                                              width: (constraints.maxWidth /
                                                      labels.length) *
                                                  0.4, // Genişlik dinamik
                                              height: val,
                                              decoration: BoxDecoration(
                                                  color: zeoPurple,
                                                  borderRadius:
                                                      const BorderRadius
                                                          .vertical(
                                                          top: Radius.circular(
                                                              6)),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      zeoPurple
                                                          .withOpacity(0.8),
                                                      zeoPurple
                                                    ],
                                                  )),
                                            );
                                          }),
                                      const SizedBox(height: 5),
                                      // X Ekseni Etiketi
                                      Text(label,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  );
                                }
                                // Gruplu Grafik Mantığı (Opsiyonel, basitlik için şimdilik tekil odaklıyız ama kod hazır)
                                else {
                                  return const SizedBox(); // Gruplu grafik için özel kod gerekirse buraya eklenir
                                }
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text("Doğru cevabı seçiniz:",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),

          // SEÇENEKLER (Aşağıda şıklar olarak listelenir)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(question.options.length,
                    (index) => _buildOptionButton(index, question)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Harita Sorusu
  Widget _buildMapQuestionBody(Question question) {
    return Column(children: [
      const SizedBox(height: 10),
      Text(question.text,
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
          textAlign: TextAlign.center),
      const SizedBox(height: 20),
      Expanded(
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: LayoutBuilder(builder: (context, constraints) {
                    return Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.shade300, width: 2),
                            borderRadius: BorderRadius.circular(12)),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(children: [
                              GestureDetector(
                                  onTapUp: (details) =>
                                      _onMapTap(details, constraints, question),
                                  child: Image.asset(question.imageUrl ?? "",
                                      fit: BoxFit.contain,
                                      width: constraints.maxWidth,
                                      height: constraints.maxHeight,
                                      errorBuilder: (context, error,
                                              stackTrace) =>
                                          const Center(
                                              child: Text(
                                                  "Harita yüklenemedi.\nassets/images/turkiye_map.png dosyasını kontrol et.")))),
                              if (userTapPosition != null)
                                Positioned(
                                    left: userTapPosition!.dx *
                                            constraints.maxWidth -
                                        20,
                                    top: userTapPosition!.dy *
                                            constraints.maxHeight -
                                        40,
                                    child: Icon(Icons.location_on,
                                        size: 40,
                                        color: isMapCorrect
                                            ? correctColor
                                            : wrongColor)),
                              if (isChecked && !isMapCorrect)
                                Positioned(
                                    left: question.answerLocation!['x']! *
                                            constraints.maxWidth -
                                        20,
                                    top: question.answerLocation!['y']! *
                                            constraints.maxHeight -
                                        40,
                                    child: Icon(Icons.flag,
                                        size: 40,
                                        color: correctColor.withOpacity(0.7))),
                              if (isChecked && !isMapCorrect)
                                Positioned(
                                    left: (question.answerLocation!['x']! * constraints.maxWidth) -
                                        (question.answerLocation!['tolerance']! *
                                            constraints.maxWidth),
                                    top: (question.answerLocation!['y']! *
                                            constraints.maxHeight) -
                                        (question.answerLocation!['tolerance']! *
                                            constraints.maxHeight *
                                            (constraints.maxWidth /
                                                constraints.maxHeight)),
                                    child: Container(
                                        width: question.answerLocation!['tolerance']! *
                                            constraints.maxWidth *
                                            2,
                                        height:
                                            question.answerLocation!['tolerance']! *
                                                constraints.maxWidth *
                                                2,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: correctColor.withOpacity(0.5),
                                                width: 2),
                                            color: correctColor.withOpacity(0.1))))
                            ])));
                  })))),
      const SizedBox(height: 20)
    ]);
  }

  // --- SONUÇ EKRANI VE GERİ BİLDİRİM ---

  Widget _buildResultScreen() {
    bool isFlashcard = widget.questions.isNotEmpty &&
        widget.questions[0].type == QuestionType.flashcard;
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.emoji_events, size: 100, color: zeoOrange),
      const SizedBox(height: 20),
      Text("Tebrikler!",
          style: TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: zeoPurple)),
      const SizedBox(height: 10),
      Text(isFlashcard ? "Harika bir tekrar oldu!" : "Konu Tamamlandı",
          style: TextStyle(fontSize: 18, color: Colors.grey[600])),
      const SizedBox(height: 30),
      if (!isFlashcard)
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              Text("Toplam Skor",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              Text("$score / ${widget.questions.length}",
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: zeoPurple))
            ])),
      if (isFlashcard)
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20)),
            child: Text("Hadi devam edelim!",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: zeoPurple))),
      const SizedBox(height: 40),
      ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
              backgroundColor: zeoPurple,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15))),
          child: const Text("Konulara Dön",
              style: TextStyle(color: Colors.white, fontSize: 16)))
    ]));
  }

  // --- ALT GERİ BİLDİRİM ALANI (DÜZELTİLMİŞ) ---
  Widget? _buildBottomFeedback() {
    if (widget.questions.isEmpty) return null;
    final question = widget.questions[currentQuestionIndex];

    // 1. DURUM: CEVAP HENÜZ VERİLMEDİ (!isChecked)
    if (!isChecked) {
      // A. FLASHCARD
      if (question.type == QuestionType.flashcard) {
        return _buildStickyButton(
            text: "DEVAM ET",
            color: const Color(0xFF7D52A0), // zeoPurple
            onPressed: _nextQuestion);
      }

      // B. HİYERARŞİ & TARİH ŞERİDİ
      if (question.type == QuestionType.hierarchyPyramid ||
          question.type == QuestionType.timelineRope) {
        // Hepsi yerleşti mi?
        bool isReady = placedItems.isNotEmpty && !placedItems.contains(null);

        // Hazır değilse buton gösterme
        if (!isReady) return null;

        return _buildStickyButton(
            text: "KONTROL ET",
            color: const Color(0xFF7D52A0),
            onPressed: _checkOrderedAnswer);
      }

      // C. DİĞER TİPLER
      if (question.type == QuestionType.sorting) {
        return _buildStickyButton(
            text: "KONTROL ET",
            color: const Color(0xFF7D52A0),
            onPressed: _checkSortingAnswer);
      }
      if (question.type == QuestionType.multipleSelection) {
        return _buildStickyButton(
            text: "KONTROL ET",
            color: const Color(0xFF7D52A0),
            onPressed: _checkMultiSelectionAnswer);
      }

      return null;
    }

    // 2. DURUM: CEVAP VERİLDİ (SONUÇ KUTUSU)
    bool isCorrect = false;
    if (question.type == QuestionType.sorting)
      isCorrect = isSortingCorrect;
    else if (question.type == QuestionType.multipleSelection)
      isCorrect = isMultiCorrect;
    else if (question.type == QuestionType.mapQuestion)
      isCorrect = isMapCorrect;
    else if (question.type == QuestionType.hierarchyPyramid ||
        question.type == QuestionType.timelineRope) {
      isCorrect = selectedOptionIndex == 1;
    } else {
      isCorrect = selectedOptionIndex == question.correctAnswerIndex;
    }

    String feedbackText =
        isCorrect ? "Harika! Doğru cevap." : "Üzgünüm, yanlış cevap.";
    if (!isCorrect && question.type == QuestionType.findMistake)
      feedbackText = "Yanlışı bulamadın";
    if (!isCorrect && question.type == QuestionType.mapQuestion)
      feedbackText = "Konum yanlış";

    final Color correctColor = const Color(0xFF58CC02);
    final Color wrongColor = const Color(0xFFFF4B4B);

    return Container(
      color: isCorrect
          ? correctColor.withOpacity(0.1)
          : wrongColor.withOpacity(0.1),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? correctColor : wrongColor, size: 30),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(feedbackText,
                      style: TextStyle(
                          color: isCorrect ? correctColor : wrongColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                    backgroundColor: isCorrect ? correctColor : wrongColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(isFinished ? "BİTİR" : "DEVAM ET",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- YARDIMCI: BUTON TASARIMI ---
  Widget _buildStickyButton(
      {required String text,
      required Color color,
      required VoidCallback onPressed}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

// --- INFO CARD WIDGET (EN ALTTA) ---
class InfoCardWidget extends StatelessWidget {
  final String text;
  final VoidCallback onContinue;

  const InfoCardWidget(
      {super.key, required this.text, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.all(20),
            color: const Color(0xFFFFF8E1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              constraints: const BoxConstraints(minHeight: 300),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lightbulb, color: Colors.orange, size: 50),
                  const SizedBox(height: 20),
                  Text("BİLGİ KARTI",
                      style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 14)),
                  const SizedBox(height: 20),
                  Text(text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20,
                          height: 1.5,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30))),
            icon: const Icon(Icons.check_circle, color: Colors.white),
            label: const Text("ANLADIM / DEVAM ET",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
