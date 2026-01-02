import 'package:flutter/material.dart';

class Lesson {
  final String title;
  final IconData icon;
  final bool isLocked;
  final bool isCompleted;

  Lesson({
    required this.title,
    required this.icon,
    this.isLocked = true,
    this.isCompleted = false,
  });
}

// ARTIK TEK BİR LİSTE DEĞİL, KATEGORİLERE AYRILMIŞ BİR HARİTA VAR
final Map<String, List<Lesson>> kpssCategories = {
  'Türkçe': [
    Lesson(title: "Sözcükte Anlam", icon: Icons.book, isLocked: false, isCompleted: true),
    Lesson(title: "Cümlede Anlam", icon: Icons.short_text, isLocked: false),
    Lesson(title: "Paragraf", icon: Icons.segment, isLocked: true),
    Lesson(title: "Ses Bilgisi", icon: Icons.record_voice_over, isLocked: true),
    Lesson(title: "Yazım Kuralları", icon: Icons.edit, isLocked: true),
    Lesson(title: "Noktalama", icon: Icons.rule, isLocked: true),
    Lesson(title: "Anlatım Bozukluğu", icon: Icons.error_outline, isLocked: true),
  ],
  'Matematik': [
    Lesson(title: "Temel Kavramlar", icon: Icons.calculate, isLocked: false),
    Lesson(title: "Sayı Basamakları", icon: Icons.format_list_numbered, isLocked: true),
    Lesson(title: "Bölme - Bölünebilme", icon: Icons.pie_chart, isLocked: true),
    Lesson(title: "Rasyonel Sayılar", icon: Icons.percent, isLocked: true),
    Lesson(title: "Denklemler", icon: Icons.functions, isLocked: true),
    Lesson(title: "Problemler", icon: Icons.question_answer, isLocked: true),
  ],
  'Tarih': [
    Lesson(title: "İslamiyet Öncesi", icon: Icons.history_edu, isLocked: false),
    Lesson(title: "İlk Türk İslam", icon: Icons.mosque, isLocked: true),
    Lesson(title: "Osmanlı Kuruluş", icon: Icons.account_balance, isLocked: true),
    Lesson(title: "Kurtuluş Savaşı", icon: Icons.flag, isLocked: true),
    Lesson(title: "İnkılaplar", icon: Icons.change_circle, isLocked: true),
  ],
  'Coğrafya': [
    Lesson(title: "Coğrafi Konum", icon: Icons.public, isLocked: false),
    Lesson(title: "Yer Şekilleri", icon: Icons.landscape, isLocked: true),
    Lesson(title: "İklim ve Bitki", icon: Icons.wb_sunny, isLocked: true),
    Lesson(title: "Nüfus", icon: Icons.people, isLocked: true),
  ],
  'Vatandaşlık': [
    Lesson(title: "Temel Hukuk", icon: Icons.gavel, isLocked: false),
    Lesson(title: "Anayasa Tarihi", icon: Icons.article, isLocked: true),
    Lesson(title: "Yasama", icon: Icons.account_balance_wallet, isLocked: true),
    Lesson(title: "Yürütme", icon: Icons.admin_panel_settings, isLocked: true),
  ],
};