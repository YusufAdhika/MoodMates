import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/game_progress.dart';
import '../../providers/progress_provider.dart';
import '../../services/audio_service.dart';
import '../../services/storage_service.dart';

// ─── Zone Design Tokens ───────────────────────────────────────────────────────

const _zoneBg = Color(0xFFF0F9F0);
const _zoneColor = Color(0xFF4CAF6E);
const _zoneBlackColor = Color(0x00000000);
const _zoneShadow = Color(0xFF1A5E36);
const _textDark = Color(0xFF3D2B1A);
const _textMuted = Color(0xFF8D6E63);
const _successGreen = Color(0xFF388E3C);
const _errorRed = Color(0xFFE53935);
const _gold = Color(0xFFFFD54F);

// ─── Theme Styles ─────────────────────────────────────────────────────────────

class _ThemeStyle {
  final Color bg;
  final Color accent;
  final Color shadow;
  const _ThemeStyle(this.bg, this.accent, this.shadow);
}

const Map<String, _ThemeStyle> _themeStyles = {
  'Berbagi & Giliran':
      _ThemeStyle(Color(0xFFFFF8E7), Color(0xFFFF9A3C), Color(0xFFC85A00)),
  'Empati & Kepedulian':
      _ThemeStyle(Color(0xFFE8F5E9), Color(0xFF4CAF6E), Color(0xFF1A5E36)),
  'Regulasi Emosi':
      _ThemeStyle(Color(0xFFF3E5F5), Color(0xFF9C27B0), Color(0xFF4A0072)),
  'Komunikasi Asertif':
      _ThemeStyle(Color(0xFFE3F2FD), Color(0xFF1976D2), Color(0xFF0D47A1)),
  'Kontrol Diri':
      _ThemeStyle(Color(0xFFE0F2F1), Color(0xFF009688), Color(0xFF004D40)),
  'Resolusi Konflik':
      _ThemeStyle(Color(0xFFFFEBEE), Color(0xFFE53935), Color(0xFFB71C1C)),
};

_ThemeStyle _styleOf(String theme) =>
    _themeStyles[theme] ??
    const _ThemeStyle(Color(0xFFF0F9F0), Color(0xFF4CAF6E), Color(0xFF1A5E36));

// ─── Level Data ───────────────────────────────────────────────────────────────

const _themeOrder = [
  'Berbagi & Giliran',
  'Empati & Kepedulian',
  'Regulasi Emosi',
  'Komunikasi Asertif',
  'Kontrol Diri',
  'Resolusi Konflik',
];

const int _totalLevels = 3;
const int _questionsPerLevel = 6;

const _levelGoals = {
  1: 'Yuk mulai dengan 1 soal\ndari setiap tema ',
  2: 'Lanjut latihan dengan situasi baru\ndari semua tema ',
  3: 'Tantangan terakhir:\nsatu soal lagi dari semua tema   ',
};

// ─── Data Models ──────────────────────────────────────────────────────────────

class ThinkChoice {
  final String label;
  final String emoji;
  final Color cardColor;
  final bool isCorrect;
  final String feedback;
  final String? imagePath;

  const ThinkChoice({
    required this.label,
    required this.emoji,
    required this.cardColor,
    required this.isCorrect,
    required this.feedback,
    this.imagePath,
  });
}

class ThinkScenario {
  final String id;
  final int level;
  final String theme;
  final String situationLabel;
  final String situationNarration;
  final String question;
  final String emoji;
  final String? imagePath;
  final ThinkChoice choiceA;
  final ThinkChoice choiceB;
  final AudioAsset? audioAsset;

  const ThinkScenario({
    required this.id,
    required this.level,
    required this.theme,
    required this.situationLabel,
    required this.situationNarration,
    required this.question,
    required this.emoji,
    required this.choiceA,
    required this.choiceB,
    this.imagePath,
    this.audioAsset,
  });

  ThinkChoice get correctChoice => choiceA.isCorrect ? choiceA : choiceB;

  String get effectiveImagePath =>
      imagePath ?? 'assets/images/scenarios/${id}_question.png';

  String imagePathForChoice(ThinkChoice choice) {
    final suffix = identical(choice, choiceA) ? 'a' : 'b';
    return choice.imagePath ?? 'assets/images/scenarios/${id}_$suffix.png';
  }
}

// ─── Scenario Bank (30 soal) ──────────────────────────────────────────────────

const List<ThinkScenario> thinkScenarios = [
  // ── Level 1 · Berbagi & Giliran ───────────────────────────────────────────

  ThinkScenario(
    id: 'sharing_1',
    level: 1,
    theme: 'Berbagi & Giliran',
    situationLabel: 'Pinjam Mainan',
    situationNarration:
        'Kamu sedang bermain dengan mainan kesayanganmu. Teman di sebelahmu ingin meminjamnya sebentar.',
    question: 'Mainan kamu dipinjam teman',
    emoji: '🧸',
    imagePath: 'assets/images/scenarios/question(1).png',
    choiceA: ThinkChoice(
      label: 'Pinjamkan, bilang "nanti balikin ya"',
      emoji: '🤝',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Hebat! Itu pilihan yang baik. Meminjamkan mainan membuat teman merasa dihargai! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Rebut mainannya dan bilang "tidak mau"',
      emoji: '😤',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba pikir lagi ya 🤔 Bagaimana perasaan temanmu kalau tidak dipinjami?',
    ),
  ),

  ThinkScenario(
    id: 'sharing_2',
    level: 1,
    theme: 'Berbagi & Giliran',
    situationLabel: 'Krayon Biru',
    situationNarration:
        'Kamu dan teman ingin menggunakan krayon biru yang sama untuk mewarnai gambar.',
    question: 'Kamu dan teman berebut krayon biru',
    emoji: '🖍️',
    imagePath: 'assets/images/scenarios/question(2).png',
    choiceA: ThinkChoice(
      label: 'Pakai bergantian',
      emoji: '🔄',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Bagus sekali! Bergantian adalah cara yang adil dan menyenangkan semua orang! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Rebut krayon dari tangan teman',
      emoji: '😠',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba lihat lagi ya 😊 Apa cara yang lebih adil agar kalian bisa sama-sama mewarnai?',
    ),
  ),

  ThinkScenario(
    id: 'sharing_3',
    level: 1,
    theme: 'Berbagi & Giliran',
    situationLabel: 'Ayunan di Taman',
    situationNarration:
        'Saat bermain ayunan di taman, ada teman yang sudah menunggu lama ingin giliran naik.',
    question: 'Kamu main ayunan, teman menunggu',
    emoji: '🎠',
    imagePath: 'assets/images/scenarios/question(3).png',
    choiceA: ThinkChoice(
      label: 'Turun, kasih teman giliran',
      emoji: '😊',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Keren! Memberikan giliran kepada teman adalah tanda hati yang baik! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Tetap main ayunan dan tidak mau turun',
      emoji: '🙈',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Yuk coba bayangkan 🤔 Kalau kamu yang sudah menunggu lama, apa yang kamu rasakan?',
    ),
  ),

  ThinkScenario(
    id: 'sharing_4',
    level: 1,
    theme: 'Berbagi & Giliran',
    situationLabel: 'Kue Tersisa',
    situationNarration:
        'Ada sepotong kue tersisa di piring. Kamu ingin memakannya, tapi adikmu juga melihatnya.',
    question: 'Sisa kue tinggal satu',
    emoji: '🍰',
    imagePath: 'assets/images/scenarios/question(4).png',
    choiceA: ThinkChoice(
      label: 'Bagi dua sama-sama',
      emoji: '🤝',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Hebat! Berbagi dengan adik adalah tanda kamu penyayang. Adikmu pasti sangat senang! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Makan kue sendiri sampai habis',
      emoji: '😋',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba pikir lagi ya 🤔 Bagaimana perasaan adikmu kalau tidak kebagian?',
    ),
  ),

  ThinkScenario(
    id: 'sharing_5',
    level: 1,
    theme: 'Berbagi & Giliran',
    situationLabel: 'Buku Bergambar',
    situationNarration:
        'Kamu sedang membaca buku bergambar favoritmu. Temanmu datang dan ingin membaca bersama.',
    question: 'Kamu membaca buku, teman datang',
    emoji: '📖',
    imagePath: 'assets/images/scenarios/question(5).png',
    choiceA: ThinkChoice(
      label: 'Ajak baca bareng',
      emoji: '📚',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Bagus! Membaca bersama teman bisa jadi lebih seru dan menyenangkan! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Sembunyikan buku dari teman',
      emoji: '🙅',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba bayangkan 😊 Enak tidak kalau temanmu tidak mau membagi bukunya denganmu?',
    ),
  ),

  // ── Level 1 · Empati & Kepedulian ─────────────────────────────────────────

  ThinkScenario(
    id: 'empathy_1',
    level: 1,
    theme: 'Empati & Kepedulian',
    situationLabel: 'Teman Terjatuh',
    situationNarration:
        'Temanmu terjatuh di halaman sekolah dan lututnya terluka. Ia menangis kesakitan.',
    question: 'Temanmu jatuh',
    emoji: '🤕',
    imagePath: 'assets/images/scenarios/question(6).png',
    choiceA: ThinkChoice(
      label: 'Tolong dan panggil guru',
      emoji: '💚',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Hebat! Itu pilihan yang baik. Membantu teman yang terluka adalah tanda kamu peduli! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Tertawa saat teman jatuh',
      emoji: '😂',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba lihat lagi ya 😊 Bagaimana perasaan temanmu kalau ditinggal saat sedang sakit?',
    ),
  ),

  ThinkScenario(
    id: 'empathy_2',
    level: 1,
    theme: 'Empati & Kepedulian',
    situationLabel: 'Teman Sedih Sendiri',
    situationNarration:
        'Temanmu terlihat sedih sendirian di pojok kelas karena tidak diajak bermain.',
    question: 'Temanmu sendirian',
    emoji: '😢',
    imagePath: 'assets/images/scenarios/question(7).png',
    choiceA: ThinkChoice(
      label: 'Ajak ikut main',
      emoji: '🫂',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Luar biasa! Mengajak teman yang sedih bermain membuatnya tidak merasa sendirian lagi! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Membiarkan teman sendirian',
      emoji: '🙈',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba bayangkan kamu di posisi temanmu 🤔 Apa yang ingin kamu rasakan dari teman-temanmu?',
    ),
  ),

  ThinkScenario(
    id: 'empathy_3',
    level: 1,
    theme: 'Empati & Kepedulian',
    situationLabel: 'Gambar Teman Jatuh',
    situationNarration:
        'Kamu tidak sengaja menabrak dan menjatuhkan gambar teman hingga kotor.',
    question: 'Kamu menjatuhkan gambar teman',
    emoji: '🎨',
    imagePath: 'assets/images/scenarios/question(8).png',
    choiceA: ThinkChoice(
      label: 'Bilang "maaf", lalu bantu',
      emoji: '🙏',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Bagus! Meminta maaf dan membantu adalah tanda hati yang baik! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Pergi tanpa minta maaf',
      emoji: '🏃',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba pikir lagi ya 😊 Apa yang bisa kamu lakukan agar temanmu merasa lebih baik?',
    ),
  ),

  ThinkScenario(
    id: 'empathy_4',
    level: 1,
    theme: 'Empati & Kepedulian',
    situationLabel: 'Adik Menangis',
    situationNarration: 'Adikmu menangis karena mainan kesayangannya rusak.',
    question: 'Adikmu sedang sedih',
    emoji: '😭',
    imagePath: 'assets/images/scenarios/question(9).png',
    choiceA: ThinkChoice(
      label: 'Peluk dan temani',
      emoji: '🫂',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Wah, kamu kakak yang baik! Menemani adik yang sedih membuatnya merasa lebih nyaman! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Membiarkan adik menangis sendirian',
      emoji: '😑',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba lihat lagi ya 🤔 Bagaimana perasaan adik kalau tidak ditemani saat sedih?',
    ),
  ),

  ThinkScenario(
    id: 'empathy_5',
    level: 1,
    theme: 'Empati & Kepedulian',
    situationLabel: 'Teman Baru Bingung',
    situationNarration:
        'Temanmu baru pindah sekolah dan terlihat bingung tidak tahu harus ke mana.',
    question: 'Teman baru terlihat bingung',
    emoji: '🏫',
    imagePath: 'assets/images/scenarios/question(10).png',
    choiceA: ThinkChoice(
      label: 'Ajak dan bantu',
      emoji: '🤝',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Hebat! Menyambut teman baru membuat ia merasa senang dan tidak kesepian! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Mengabaikan teman baru',
      emoji: '🙄',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, bayangkan kamu jadi teman baru itu 😊 Apa yang ingin kamu rasakan dari teman-teman di sekolah baru?',
    ),
  ),

  // ── Level 2 · Regulasi Emosi ──────────────────────────────────────────────

  ThinkScenario(
    id: 'emoregulation_1',
    level: 2,
    theme: 'Regulasi Emosi',
    situationLabel: 'Kalah Balapan',
    situationNarration:
        'Kamu kalah dalam permainan balap mobil dan merasa sangat kesal.',
    question: 'Kamu kalah lomba mainan',
    emoji: '🏎️',
    imagePath: 'assets/images/scenarios/question(11).png',
    choiceA: ThinkChoice(
      label: 'Tarik napas, bilang "selamat ya"',
      emoji: '😌',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Keren! Itu pilihan yang baik. Menerima kekalahan dengan lapang dada adalah tanda kamu kuat! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Lempar mainan karena kesal',
      emoji: '😡',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba tarik napas dulu ya 😊 Apa yang bisa kamu lakukan agar perasaan kesalmu berkurang?',
    ),
  ),

  ThinkScenario(
    id: 'emoregulation_2',
    level: 2,
    theme: 'Regulasi Emosi',
    situationLabel: 'Menunggu Mainan Robot',
    situationNarration:
        'Kamu ingin bermain dengan mainan robot, tapi kakakmu bilang kamu harus menunggu sebentar.',
    question: 'Kamu diminta menunggu giliran',
    emoji: '🤖',
    imagePath: 'assets/images/scenarios/question(12).png',
    choiceA: ThinkChoice(
      label: 'Bilang "oke", tunggu sambil main lain',
      emoji: '😊',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Bagus! Bersabar dan mencari kegiatan lain saat menunggu adalah tanda kamu bijak! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Nangis keras dan marah-marah',
      emoji: '😭',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba pikir lagi ya 🤔 Kegiatan seru apa yang bisa kamu lakukan sambil menunggu giliran?',
    ),
  ),

  ThinkScenario(
    id: 'emoregulation_3',
    level: 2,
    theme: 'Regulasi Emosi',
    situationLabel: 'Gambar Rusak Kena Air',
    situationNarration:
        'Teman tidak sengaja menumpahkan air ke gambar yang sudah kamu buat dengan susah payah.',
    question: 'Gambarmu rusak kena air',
    emoji: '💦',
    imagePath: 'assets/images/scenarios/question(13).png',
    choiceA: ThinkChoice(
      label: 'Bilang "tidak apa-apa", buat lagi',
      emoji: '😌',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Hebat! Memaafkan teman yang tidak sengaja berbuat salah adalah tanda hati yang besar! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Kesal lalu mendorong teman',
      emoji: '😡',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba lihat lagi ya 😊 Teman tidak sengaja. Apa cara yang lebih baik untuk mengungkapkan perasaanmu?',
    ),
  ),

  ThinkScenario(
    id: 'emoregulation_4',
    level: 2,
    theme: 'Regulasi Emosi',
    situationLabel: 'Tidak Bisa Beli Es Krim',
    situationNarration:
        'Kamu sangat ingin membeli es krim, tapi ibu bilang hari ini tidak bisa.',
    question: 'Kamu tidak boleh beli es krim',
    emoji: '🍦',
    imagePath: 'assets/images/scenarios/question(14).png',
    choiceA: ThinkChoice(
      label: 'Bilang "ya sudah, nanti saja"',
      emoji: '😊',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Keren! Menerima keputusan orang tua dengan lapang dada adalah tanda kamu sudah besar! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Ngambek dan tidak mau bicara',
      emoji: '😤',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba tarik napas dulu ya 🤔 Cara apa yang lebih baik untuk menyampaikan kekecewaanmu?',
    ),
  ),

  ThinkScenario(
    id: 'emoregulation_5',
    level: 2,
    theme: 'Regulasi Emosi',
    situationLabel: 'Bangunan Balok Roboh',
    situationNarration:
        'Saat bermain balok, bangunan yang kamu buat tiba-tiba roboh sendiri.',
    question: 'Balok yang kamu susun roboh',
    emoji: '🧱',
    imagePath: 'assets/images/scenarios/question(15).png',
    choiceA: ThinkChoice(
      label: 'Coba susun lagi',
      emoji: '😄',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Bagus sekali! Mencoba lagi setelah gagal adalah tanda kamu pemberani dan tangguh! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Tendang balok sampai berantakan',
      emoji: '😡',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba tarik napas dulu ya 😊 Apa yang bisa kamu lakukan agar merasa lebih tenang sebelum mencoba lagi?',
    ),
  ),

  // ── Level 2 · Komunikasi Asertif ──────────────────────────────────────────

  ThinkScenario(
    id: 'assertive_1',
    level: 2,
    theme: 'Komunikasi Asertif',
    situationLabel: 'Pinjam Pensil Warna',
    situationNarration:
        'Kamu ingin meminjam pensil warna milik temanmu untuk menyelesaikan gambarmu.',
    question: 'Kamu ingin pinjam pensil teman',
    emoji: '✏️',
    imagePath: 'assets/images/scenarios/question(16).png',
    choiceA: ThinkChoice(
      label: 'Minta izin dulu',
      emoji: '🙏',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Hebat! Bertanya dengan sopan adalah cara yang baik untuk meminta sesuatu! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Ambil pensil tanpa izin',
      emoji: '🖐️',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba lihat lagi ya 🤔 Bagaimana perasaan temanmu kalau barangnya diambil tanpa permisi?',
    ),
  ),

  ThinkScenario(
    id: 'assertive_2',
    level: 2,
    theme: 'Komunikasi Asertif',
    situationLabel: 'Tidak Mau Main di Luar',
    situationNarration:
        'Temanmu mengajak bermain di luar, tapi kamu sedang tidak mau bermain di sana.',
    question: 'Teman mengajak main, tapi kamu tidak mau',
    emoji: '🌳',
    imagePath: 'assets/images/scenarios/question(17).png',
    choiceA: ThinkChoice(
      label: 'Bilang baik-baik "aku tidak mau"',
      emoji: '😊',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Bagus! Menolak dengan sopan sambil berterima kasih adalah cara komunikasi yang baik! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Diam lalu pergi tanpa bilang apa-apa',
      emoji: '🚶',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba pikir lagi ya 😊 Bagaimana cara yang lebih sopan untuk memberitahu temanmu?',
    ),
  ),

  ThinkScenario(
    id: 'assertive_3',
    level: 2,
    theme: 'Komunikasi Asertif',
    situationLabel: 'Tidak Mengerti Origami',
    situationNarration:
        'Kamu tidak mengerti cara melipat origami yang diajarkan bu guru.',
    question: 'Kamu tidak bisa membuat origami',
    emoji: '📝',
    imagePath: 'assets/images/scenarios/question(18).png',
    choiceA: ThinkChoice(
      label: 'Angkat tangan, tanya guru',
      emoji: '✋',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Keren! Berani bertanya kepada guru adalah tanda kamu mau belajar dan pintar! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Meniru pekerjaan teman diam-diam',
      emoji: '🙈',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba pikir lagi ya 🤔 Apa yang kamu pelajari kalau hanya menyalin tanpa mengerti?',
    ),
  ),

  ThinkScenario(
    id: 'assertive_4',
    level: 2,
    theme: 'Komunikasi Asertif',
    situationLabel: 'Barang Terus Disentuh',
    situationNarration:
        'Seorang teman terus-terusan menyentuh barang-barangmu meski kamu sudah terlihat tidak nyaman.',
    question: 'Teman memegang barangmu',
    emoji: '😤',
    imagePath: 'assets/images/scenarios/question(19).png',
    choiceA: ThinkChoice(
      label: 'Bilang pelan "jangan ya, aku tidak suka"',
      emoji: '💬',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Hebat! Berbicara dengan tenang untuk menyampaikan perasaanmu adalah cara yang tepat! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Mendorong tangan teman dengan kasar',
      emoji: '😠',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba lihat lagi ya 😊 Cara apa yang lebih baik untuk memberitahu temanmu bahwa kamu tidak suka?',
    ),
  ),

  ThinkScenario(
    id: 'assertive_5',
    level: 2,
    theme: 'Komunikasi Asertif',
    situationLabel: 'Bantu Ibu Belanja',
    situationNarration:
        'Kamu ingin membantu ibu membawakan belanjaan yang berat.',
    question: 'Kamu ingin membantu ibu',
    emoji: '🛍️',
    imagePath: 'assets/images/scenarios/question(20).png',
    choiceA: ThinkChoice(
      label: 'Bilang "aku bantu ya"',
      emoji: '🙋',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Wah, kamu anak yang baik! Menawarkan bantuan dengan sopan adalah tanda kamu peduli! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Menarik tas belanja dari tangan ibu',
      emoji: '😬',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba pikir lagi ya 🤔 Bagaimana cara yang lebih sopan untuk menawarkan bantuan?',
    ),
  ),

  // ── Level 3 · Kontrol Diri ────────────────────────────────────────────────

  ThinkScenario(
    id: 'selfcontrol_1',
    level: 3,
    theme: 'Kontrol Diri',
    situationLabel: 'Rapikan Mainan',
    situationNarration:
        'Bu guru meminta semua anak merapikan mainan sebelum waktu makan siang tiba.',
    question: 'Kamu diminta merapikan mainan',
    emoji: '🧹',
    imagePath: 'assets/images/scenarios/question(21).png',
    choiceA: ThinkChoice(
      label: 'Rapikan mainan, bantu teman',
      emoji: '✅',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Keren! Itu pilihan yang baik. Mengikuti aturan dan membantu teman adalah hal yang luar biasa! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Tetap bermain dan tidak merapikan',
      emoji: '🙈',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba pikir lagi ya 🤔 Apa yang terjadi kalau semua anak tidak merapikan mainan bersama?',
    ),
  ),

  ThinkScenario(
    id: 'selfcontrol_2',
    level: 3,
    theme: 'Kontrol Diri',
    situationLabel: 'Antre Cuci Tangan',
    situationNarration:
        'Saat antre mencuci tangan, kamu melihat ada celah di barisan untuk menyalip.',
    question: 'Kamu sedang antre cuci tangan',
    emoji: '🚰',
    imagePath: 'assets/images/scenarios/question(22).png',
    choiceA: ThinkChoice(
      label: 'Tunggu giliran dengan sabar',
      emoji: '🧍',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Bagus! Menunggu dengan sabar di antrian adalah tanda kamu jujur dan adil! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Menyelinap ke depan antrean',
      emoji: '🏃',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba bayangkan ya 😊 Bagaimana perasaan teman yang sudah lama mengantri kalau kamu menyalip?',
    ),
  ),

  ThinkScenario(
    id: 'selfcontrol_3',
    level: 3,
    theme: 'Kontrol Diri',
    situationLabel: 'Guru Sedang Menjelaskan',
    situationNarration:
        'Bu guru sedang menjelaskan sesuatu di depan kelas. Temanmu mengajakmu berbicara.',
    question: 'Guru sedang menjelaskan',
    emoji: '🗣️',
    imagePath: 'assets/images/scenarios/question(23).png',
    choiceA: ThinkChoice(
      label: 'Dengarkan guru, bilang "nanti ya"',
      emoji: '🤫',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Hebat! Mendengarkan guru dengan fokus adalah tanda kamu menghormati bu guru! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Mengobrol keras saat guru menjelaskan',
      emoji: '📢',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba pikir lagi ya 🤔 Apa yang terjadi dengan pelajaran kalau semua anak berbicara saat guru menjelaskan?',
    ),
  ),

  ThinkScenario(
    id: 'selfcontrol_4',
    level: 3,
    theme: 'Kontrol Diri',
    situationLabel: 'Buang Sampah',
    situationNarration:
        'Selesai makan, kamu diminta membuang bungkus makananmu ke tempat sampah.',
    question: 'Kamu selesai makan',
    emoji: '🗑️',
    imagePath: 'assets/images/scenarios/question(24).png',
    choiceA: ThinkChoice(
      label: 'Buang ke tempat sampah',
      emoji: '♻️',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Keren! Membuang sampah pada tempatnya adalah tanggung jawab yang membuat lingkungan bersih! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Meninggalkan sampah di meja',
      emoji: '😴',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba bayangkan ya 😊 Bagaimana kalau semua orang meninggalkan sampahnya sembarangan?',
    ),
  ),

  ThinkScenario(
    id: 'selfcontrol_5',
    level: 3,
    theme: 'Kontrol Diri',
    situationLabel: 'Tidak Boleh Berlari',
    situationNarration:
        'Saat bermain di dalam kelas, ada aturan tidak boleh berlari.',
    question: 'Kamu bermain di dalam kelas',
    emoji: '🚶',
    imagePath: 'assets/images/scenarios/question(25).png',
    choiceA: ThinkChoice(
      label: 'Jalan pelan',
      emoji: '🚶',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Bagus! Mematuhi aturan dan mengingatkan teman dengan sopan adalah tanda kamu bertanggung jawab! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Berlari di dalam kelas',
      emoji: '🏃',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba pikir lagi ya 🤔 Kenapa ya aturan tidak boleh berlari di kelas itu ada?',
    ),
  ),

  // ── Level 3 · Resolusi Konflik ────────────────────────────────────────────

  ThinkScenario(
    id: 'conflict_1',
    level: 3,
    theme: 'Resolusi Konflik',
    situationLabel: 'Berebut Boneka',
    situationNarration:
        'Kamu dan teman menginginkan boneka yang sama untuk dimainkan. Hanya ada satu.',
    question: 'Kamu dan teman berebut boneka',
    emoji: '🪆',
    imagePath: 'assets/images/scenarios/question(26).png',
    choiceA: ThinkChoice(
      label: 'Bergantian main',
      emoji: '🤝',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Pintar sekali! Mengusulkan giliran adalah cara yang adil dan damai! 🕊️',
    ),
    choiceB: ThinkChoice(
      label: 'Menarik boneka dari tangan teman',
      emoji: '😤',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba pikir lagi ya 😊 Apa cara yang lebih baik agar kalian bisa sama-sama bermain?',
    ),
  ),

  ThinkScenario(
    id: 'conflict_2',
    level: 3,
    theme: 'Resolusi Konflik',
    situationLabel: 'Cat Tumpah ke Baju',
    situationNarration:
        'Temanmu tidak sengaja menumpahkan cat ke bajumu saat kalian melukis bersama.',
    question: 'Bajumu terkena cat teman',
    emoji: '🖌️',
    imagePath: 'assets/images/scenarios/question(27).png',
    choiceA: ThinkChoice(
      label: 'Bilang "tidak apa-apa"',
      emoji: '😊',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Hebat! Memaafkan teman yang tidak sengaja adalah tanda kamu punya hati yang besar! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Sengaja menumpahkan cat ke teman',
      emoji: '😠',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba lihat lagi ya 🤔 Teman tidak sengaja melakukannya. Apa yang terjadi kalau kamu membalasnya?',
    ),
  ),

  ThinkScenario(
    id: 'conflict_3',
    level: 3,
    theme: 'Resolusi Konflik',
    situationLabel: 'Berebut Jadi Pemimpin',
    situationNarration:
        'Kamu dan teman berselisih tentang siapa yang akan menjadi pemimpin dalam permainan.',
    question: 'Kamu dan teman berebut jadi pemimpin',
    emoji: '👑',
    imagePath: 'assets/images/scenarios/question(28).png',
    choiceA: ThinkChoice(
      label: 'Main hompimpa atau gantian',
      emoji: '🤝',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Keren! Mengusulkan cara yang adil agar semua bisa mendapat giliran adalah hal yang bijaksana! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Ngambek dan tidak mau ikut main',
      emoji: '😤',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba pikir lagi ya 😊 Cara apa yang bisa membuat semua teman senang dan permainan tetap berlanjut?',
    ),
  ),

  ThinkScenario(
    id: 'conflict_4',
    level: 3,
    theme: 'Resolusi Konflik',
    situationLabel: 'Kata-Kata Menyakitkan',
    situationNarration:
        'Temanmu berkata kata-kata yang membuatmu tersinggung dan sedih.',
    question: 'Kamu disakiti kata teman',
    emoji: '😔',
    imagePath: 'assets/images/scenarios/question(29).png',
    choiceA: ThinkChoice(
      label: 'Bilang "aku sedih kalau begitu"',
      emoji: '💬',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Bagus! Mengungkapkan perasaanmu dengan tenang adalah cara yang tepat dan berani! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Membalas dengan kata-kata kasar',
      emoji: '😈',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba lihat lagi ya 🤔 Kalau kata-kata menyakitkan dibalas, apa yang akan terjadi selanjutnya?',
    ),
  ),

  ThinkScenario(
    id: 'conflict_5',
    level: 3,
    theme: 'Resolusi Konflik',
    situationLabel: 'Dituduh Mengambil',
    situationNarration:
        'Teman menuduh kamu mengambil penghapusnya, padahal kamu tidak melakukannya.',
    question: 'Kamu dituduh mengambil barang',
    emoji: '🔍',
    imagePath: 'assets/images/scenarios/question(30).png',
    choiceA: ThinkChoice(
      label: 'Bilang "bukan aku, ayo cari sama-sama"',
      emoji: '🔍',
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Hebat! Menjelaskan dengan tenang dan mengajak mencari bersama adalah cara yang bijak dan jujur! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Berteriak dan menuduh balik',
      emoji: '😡',
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm, coba tarik napas dulu ya 😊 Cara apa yang lebih tenang untuk membuktikan bahwa kamu tidak mengambilnya?',
    ),
  ),
];

// ─── Phase ────────────────────────────────────────────────────────────────────

enum _Phase { levelIntro, choosing, revealed, levelResult, done }

// ─── Screen ───────────────────────────────────────────────────────────────────

class SocialSituationsScreen extends StatefulWidget {
  const SocialSituationsScreen({super.key});

  @override
  State<SocialSituationsScreen> createState() => _SocialSituationsScreenState();
}

class _SocialSituationsScreenState extends State<SocialSituationsScreen>
    with TickerProviderStateMixin {
  // ── Session state ─────────────────────────────────────────────────────────
  _Phase _phase = _Phase.levelIntro;
  int _currentLevel = 1;
  int _questionInLevel = 0;
  int _levelCorrect = 0;
  int _totalCorrect = 0;
  ThinkChoice? _selectedChoice;
  late Map<int, List<ThinkScenario>> _levelScenarios;

  ThinkScenario get _current =>
      _levelScenarios[_currentLevel]![_questionInLevel];
  int get _questionsThisLevel =>
      _levelScenarios[_currentLevel]?.length ?? _questionsPerLevel;
  int get _passScoreThisLevel => (_questionsThisLevel * 2 / 3).ceil();
  bool get _isLastQuestionInLevel =>
      _questionInLevel >= _questionsThisLevel - 1;
  int get _totalQuestionsInRun => _questionsPerLevel * _totalLevels;

  String get _backgroundImagePath {
    if (_phase == _Phase.levelResult) {
      final passed = _levelCorrect >= _passScoreThisLevel;
      final isPerfect = _levelCorrect == _questionsThisLevel;
      if (isPerfect) return 'assets/images/background/bg_racoo_think_success.png';
      if (passed) return 'assets/images/background/bg_racoo_think_mild_success.png';
      return 'assets/images/background/bg_racoo_think_good_job.png';
    }
    if (_phase == _Phase.done) {
      return 'assets/images/background/bg_racoo_think_summary.png';
    }
    return 'assets/images/background/bg_racoo_think.png';
  }

  // Urutan tampil jawaban — diacak tiap soal agar posisi benar/salah berubah
  List<ThinkChoice> _orderedChoices = [];

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _cardSlideController;
  late AnimationController _choiceEntranceController;
  late AnimationController _feedbackController;
  late AnimationController _raccooController;
  late AnimationController _shakeController;
  late AnimationController _celebrationController;

  late Animation<Offset> _cardSlide;
  late Animation<Offset> _choiceASlide;
  late Animation<Offset> _choiceBSlide;
  late Animation<double> _raccooFloat;
  late Animation<double> _shakeAnimation;
  late Animation<double> _celebrationScale;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _buildLevelScenarios();

    _cardSlideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _cardSlide = Tween<Offset>(begin: const Offset(0, -0.25), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _cardSlideController,
            curve: const Cubic(0.34, 1.56, 0.64, 1)));

    _choiceEntranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _choiceASlide = Tween<Offset>(
            begin: const Offset(-0.5, 0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _choiceEntranceController,
            curve:
                const Interval(0.0, 0.7, curve: Cubic(0.34, 1.56, 0.64, 1))));
    _choiceBSlide = Tween<Offset>(begin: const Offset(0.5, 0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _choiceEntranceController,
            curve:
                const Interval(0.15, 0.85, curve: Cubic(0.34, 1.56, 0.64, 1))));

    _feedbackController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));

    _raccooController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _raccooFloat = Tween<double>(begin: -6, end: 6).animate(
        CurvedAnimation(parent: _raccooController, curve: Curves.easeInOut));

    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));

    _celebrationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _celebrationScale = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _celebrationController,
        curve: const Cubic(0.34, 1.56, 0.64, 1)));

    // Inisialisasi urutan awal (Level Intro belum menampilkan soal, tapi perlu non-empty)
    _orderedChoices = [
      _levelScenarios[1]![0].choiceA,
      _levelScenarios[1]![0].choiceB,
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioService>().play(AudioAsset.instructionSocialSituations);
      _checkResumeState();
    });
  }

  // ── Resume state ──────────────────────────────────────────────────────────

  Future<void> _checkResumeState() async {
    if (!mounted) return;
    final storage = context.read<StorageService>();
    final profileId = storage.activeProfileId;
    if (profileId == null) return;

    final saved = storage.loadSocialSituationsResume(profileId);
    if (saved == null) return;

    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Lanjutkan permainan?',
            style: GoogleFonts.baloo2(
                fontSize: 20, fontWeight: FontWeight.w700, color: _textDark)),
        content: Text(
          'Kamu sudah bermain sampai Level ${saved['currentLevel']} soal ${(saved['questionInLevel'] as int) + 1}. Lanjutkan dari sini?',
          style: GoogleFonts.dmSans(fontSize: 14, color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Mulai Baru',
                style: GoogleFonts.dmSans(color: _textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Ya, Lanjutkan',
                style: GoogleFonts.dmSans(
                    color: _zoneColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (resume == true) {
      _restoreFromSaved(saved);
    } else {
      await storage.clearSocialSituationsResume(profileId);
    }
  }

  void _restoreFromSaved(Map<String, dynamic> saved) {
    final scenarioIds = saved['scenarioIds'] as Map<String, dynamic>;
    final restored = <int, List<ThinkScenario>>{};
    for (int l = 1; l <= _totalLevels; l++) {
      final ids = (scenarioIds['$l'] as List<dynamic>).cast<String>();
      restored[l] = ids
          .map((id) => thinkScenarios.firstWhere(
                (s) => s.id == id,
                orElse: () => thinkScenarios.first,
              ))
          .toList();
    }
    setState(() {
      _levelScenarios = restored;
      _currentLevel = saved['currentLevel'] as int;
      _questionInLevel = saved['questionInLevel'] as int;
      _levelCorrect = saved['levelCorrect'] as int;
      _totalCorrect = saved['totalCorrect'] as int;
      _phase = _Phase.levelIntro;
    });
  }

  Future<void> _saveResumeState() async {
    if (!mounted) return;
    final storage = context.read<StorageService>();
    final profileId = storage.activeProfileId;
    if (profileId == null) return;

    // Tidak simpan jika di phase levelIntro level 1 soal 0 (baru mulai)
    final isAtStart = _currentLevel == 1 &&
        _questionInLevel == 0 &&
        _levelCorrect == 0 &&
        _totalCorrect == 0;
    if (isAtStart) return;

    final scenarioIds = <String, List<String>>{};
    for (int l = 1; l <= _totalLevels; l++) {
      scenarioIds['$l'] = _levelScenarios[l]!.map((s) => s.id).toList();
    }

    await storage.saveSocialSituationsResume(profileId, {
      'currentLevel': _currentLevel,
      'questionInLevel': _questionInLevel,
      'levelCorrect': _levelCorrect,
      'totalCorrect': _totalCorrect,
      'scenarioIds': scenarioIds,
    });
  }

  Future<void> _clearResumeState() async {
    if (!mounted) return;
    final storage = context.read<StorageService>();
    final profileId = storage.activeProfileId;
    if (profileId == null) return;
    await storage.clearSocialSituationsResume(profileId);
  }

  @override
  void dispose() {
    _cardSlideController.dispose();
    _choiceEntranceController.dispose();
    _feedbackController.dispose();
    _raccooController.dispose();
    _shakeController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  // ── Scenario management ───────────────────────────────────────────────────

  void _buildLevelScenarios([int? retryLevel]) {
    final rng = math.Random();
    final byTheme = <String, List<ThinkScenario>>{
      for (final theme in _themeOrder)
        theme: thinkScenarios.where((s) => s.theme == theme).toList()
          ..shuffle(rng),
    };

    if (retryLevel != null) {
      final usedInOtherLevels = <String>{
        for (final entry in _levelScenarios.entries)
          if (entry.key != retryLevel) ...entry.value.map((s) => s.id),
      };
      final previousLevelIds =
          _levelScenarios[retryLevel]!.map((s) => s.id).toSet();

      final refreshed = <ThinkScenario>[
        for (final theme in _themeOrder)
          () {
            final candidates = byTheme[theme]!
                .where((s) => !usedInOtherLevels.contains(s.id))
                .where((s) => !previousLevelIds.contains(s.id))
                .toList();
            final pool = candidates.isNotEmpty
                ? candidates
                : byTheme[theme]!
                    .where((s) => !usedInOtherLevels.contains(s.id))
                    .toList();
            pool.shuffle(rng);
            return pool.first;
          }(),
      ]..shuffle(rng);

      _levelScenarios[retryLevel] = refreshed;
    } else {
      _levelScenarios = {
        for (int level = 1; level <= _totalLevels; level++)
          level: [
            for (final theme in _themeOrder) byTheme[theme]![level - 1],
          ]..shuffle(rng),
      };
    }
  }

  // ── Game flow ─────────────────────────────────────────────────────────────

  void _startQuestion() {
    final choices = [_current.choiceA, _current.choiceB]
      ..shuffle(math.Random());
    setState(() {
      _phase = _Phase.choosing;
      _selectedChoice = null;
      _orderedChoices = choices;
    });
    _cardSlideController.forward(from: 0);
    _choiceEntranceController.forward(from: 0);
    _feedbackController.reset();
  }

  Future<void> _onChoiceTap(ThinkChoice choice) async {
    if (_phase != _Phase.choosing) return;
    final progressProvider = context.read<ProgressProvider>();
    final audioService = context.read<AudioService>();

    setState(() {
      _selectedChoice = choice;
      _phase = _Phase.revealed;
      if (choice.isCorrect) {
        _levelCorrect++;
        _totalCorrect++;
      }
    });
    audioService
        .play(choice.isCorrect ? AudioAsset.correct : AudioAsset.incorrect);
    if (!choice.isCorrect) {
      await _shakeController.forward();
      _shakeController.reset();
    }
    await progressProvider.recordSession(
      gameId: GameProgress.gameSocialSituations,
      wasCorrect: choice.isCorrect,
    );
    if (!mounted) return;
    await _showFeedbackDialog(choice);
  }

  Future<void> _showFeedbackDialog(ThinkChoice choice) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _FeedbackDialog(
        choice: choice,
        isLastQuestion: _isLastQuestionInLevel,
        onNext: () {
          Navigator.pop(ctx);
          _onNext();
        },
      ),
    );
  }

  void _onNext() {
    if (!_isLastQuestionInLevel) {
      setState(() => _questionInLevel++);
      _startQuestion();
    } else {
      _celebrationController.forward(from: 0);
      setState(() => _phase = _Phase.levelResult);
    }
  }

  void _proceedToNextLevel() {
    if (_currentLevel < _totalLevels) {
      setState(() {
        _currentLevel++;
        _questionInLevel = 0;
        _levelCorrect = 0;
        _phase = _Phase.levelIntro;
      });
      _celebrationController.reset();
    } else {
      _clearResumeState();
      _celebrationController.forward(from: 0);
      setState(() => _phase = _Phase.done);
    }
  }

  void _retryLevel() {
    final previousLevelCorrect = _levelCorrect;
    _buildLevelScenarios(_currentLevel);
    setState(() {
      _questionInLevel = 0;
      _totalCorrect = math.max(0, _totalCorrect - previousLevelCorrect);
      _levelCorrect = 0;
      _phase = _Phase.levelIntro;
    });
    _celebrationController.reset();
  }

  // ── Exit dialog ───────────────────────────────────────────────────────────

  Future<bool> _confirmExit() async {
    final isMidGame = _phase == _Phase.choosing || _phase == _Phase.revealed;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Selesai bermain?',
            style: GoogleFonts.baloo2(
                fontSize: 20, fontWeight: FontWeight.w700, color: _textDark)),
        content: Text(
          isMidGame
              ? 'Permainanmu akan disimpan. Kamu bisa lanjutkan nanti!'
              : 'Progresmu hari ini akan tersimpan!',
          style: GoogleFonts.dmSans(fontSize: 14, color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Lanjut Bermain',
                style: GoogleFonts.dmSans(color: _zoneColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Ya, Keluar',
                style: GoogleFonts.dmSans(
                    color: _errorRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (result == true && isMidGame) {
      await _saveResumeState();
    }
    return result ?? false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _confirmExit();
        if (shouldExit && mounted) {
          // ignore: use_build_context_synchronously
          context.pop();
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _backgroundImagePath,
              fit: BoxFit.cover,
            ),
          ),
          Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: switch (_phase) {
            _Phase.levelIntro => _buildLevelIntro(),
            _Phase.choosing || _Phase.revealed => _buildGame(),
            _Phase.levelResult => _buildLevelResult(),
            _Phase.done => _buildDoneScreen(),
          },
        ),
      ),
        ],
      ),
    );
  }

  // ── Level Intro ───────────────────────────────────────────────────────────

  Widget _buildLevelIntro() {
    final goal = _levelGoals[_currentLevel]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Level path (1 → 2 → 3)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalLevels * 2 - 1, (i) {
              if (i.isOdd) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: _textMuted.withValues(alpha: 0.4)),
                );
              }
              final level = i ~/ 2 + 1;
              final isActive = level == _currentLevel;
              final isDone = level < _currentLevel;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 52 : 44,
                height: isActive ? 52 : 44,
                decoration: BoxDecoration(
                  color: isDone
                      ? _successGreen
                      : isActive
                          ? _zoneColor
                          : _zoneBlackColor.withValues(alpha: 1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                              color: _zoneColor.withValues(alpha: 0.45),
                              offset: const Offset(0, 4),
                              blurRadius: 8)
                        ]
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 22)
                      : Text('$level',
                          style: GoogleFonts.baloo2(
                            fontSize: isActive ? 22 : 18,
                            fontWeight: FontWeight.w800,
                            color:
                                isActive || isDone ? Colors.white : _zoneColor,
                          )),
                ),
              );
            }),
          ),

          const SizedBox(height: 4),
          Text('Level $_currentLevel dari $_totalLevels',
              style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textMuted)),

          const Spacer(),

          // Raccoo bobbing
          AnimatedBuilder(
            animation: _raccooFloat,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _raccooFloat.value),
              child: child,
            ),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9A3C).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/characters/racoo_avatar_brown.png',
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Goal bubble
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: _zoneShadow, offset: Offset(4, 6), blurRadius: 0),
              ],
            ),
            child: Column(
              children: [
                Text('Tujuan belajar kita:',
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textMuted)),
                const SizedBox(height: 8),
                Text(goal,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.baloo2(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                        height: 1.4)),
              ],
            ),
          ),

          const Spacer(),

          _ThinkButton(
            label: 'Mulai Level $_currentLevel',
            color: _zoneColor,
            textColor: Colors.white,
            icon: Icons.play_arrow_rounded,
            onTap: () {
              setState(() {
                _questionInLevel = 0;
                _levelCorrect = 0;
              });
              _startQuestion();
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Game ──────────────────────────────────────────────────────────────────

  Widget _buildGame() {
    final card = _current;
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Situation card
                SlideTransition(
                  position: _cardSlide,
                  child: _SituationCard(scenario: card),
                ),

                const SizedBox(height: 12),

                // Raccoo question
                _QuestionBubble(question: card.question, theme: card.theme),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Pilih jawaban yang paling tepat',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Choice 0 (posisi diacak tiap soal)
                SlideTransition(
                  position: _choiceASlide,
                  child: _ChoiceCard(
                    choice: _orderedChoices[0],
                    imagePath: card.imagePathForChoice(_orderedChoices[0]),
                    optionLabel: 'A',
                    state: _choiceCardState(_orderedChoices[0]),
                    onTap: () => _onChoiceTap(_orderedChoices[0]),
                    shakeAnimation: _orderedChoices[0] == _selectedChoice &&
                            !(_selectedChoice?.isCorrect ?? true)
                        ? _shakeAnimation
                        : null,
                  ),
                ),

                const SizedBox(height: 10),

                // Choice 1
                SlideTransition(
                  position: _choiceBSlide,
                  child: _ChoiceCard(
                    choice: _orderedChoices[1],
                    imagePath: card.imagePathForChoice(_orderedChoices[1]),
                    optionLabel: 'B',
                    state: _choiceCardState(_orderedChoices[1]),
                    onTap: () => _onChoiceTap(_orderedChoices[1]),
                    shakeAnimation: _orderedChoices[1] == _selectedChoice &&
                            !(_selectedChoice?.isCorrect ?? true)
                        ? _shakeAnimation
                        : null,
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final style = _styleOf(_current.theme);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [

          _Button(
            img: 'assets/images/ui/ic_left_feel.png',
            width: 64,
            height: 64,
            onTap: () async {
              final ok = await _confirmExit();
              if (ok && mounted) context.pop();
            },
          ),
          const SizedBox(width: 10),

          // Theme pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: style.accent.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: style.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(_current.theme,
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),

          const Spacer(),

          // Q progress dots
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Row(
                  children: List.generate(_questionsThisLevel, (i) {
                    final isDone = i < _questionInLevel;
                    final isActive = i == _questionInLevel;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isActive ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isDone
                            ? _successGreen
                            : isActive
                                ? _zoneColor
                                : _zoneColor.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text('${_questionInLevel + 1}/$_questionsThisLevel',
                    style: GoogleFonts.baloo2(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Choice state ──────────────────────────────────────────────────────────

  _ChoiceState _choiceCardState(ThinkChoice choice) {
    if (_phase == _Phase.choosing) return _ChoiceState.idle;
    if (_selectedChoice == choice) {
      return choice.isCorrect
          ? _ChoiceState.selectedCorrect
          : _ChoiceState.selectedWrong;
    }
    return _ChoiceState.dimmed;
  }

  // ── Level Result ──────────────────────────────────────────────────────────

  Widget _buildLevelResult() {
    final passed = _levelCorrect >= _passScoreThisLevel;
    final isPerfect = _levelCorrect == _questionsThisLevel;
    final isLastLevel = _currentLevel == _totalLevels;
    final levelStars = _levelCorrect == _questionsThisLevel
        ? 3
        : _levelCorrect >= _passScoreThisLevel
            ? 2
            : _levelCorrect > 0
                ? 1
                : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: passed ? _successGreen : const Color(0xFFFF9A3C),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: (passed ? _zoneShadow : const Color(0xFFC85A00))
                      .withValues(alpha: 0.5),
                  offset: const Offset(3, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Text('Level $_currentLevel Selesai!',
                style: GoogleFonts.baloo2(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),

          const SizedBox(height: 28),

          // Raccoo
          // ScaleTransition(
          //   scale: _celebrationScale,
          //   child: AnimatedBuilder(
          //     animation: _raccooFloat,
          //     builder: (_, child) => Transform.translate(
          //         offset: Offset(0, _raccooFloat.value), child: child),
          //     child: Container(
          //       width: 140,
          //       height: 140,
          //       decoration: BoxDecoration(
          //         color: (passed ? _zoneColor : const Color(0xFFFF9A3C))
          //             .withValues(alpha: 0.12),
          //         shape: BoxShape.circle,
          //       ),
          //       child: Center(
          //         child: Text(passed ? '🦝🎉' : '🦝💪',
          //             style: const TextStyle(fontSize: 64)),
          //       ),
          //     ),
          //   ),
          // ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  passed
                      ? (isPerfect ? 'Sempurna! 🏆' : 'Bagus! 🎉')
                      : 'Hampir! Coba lagi ya! 💪',
                  style: GoogleFonts.baloo2(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      height: 1.1),
                ),
                const SizedBox(height: 8),
                Text(
                  passed
                      ? 'Kamu menjawab $_levelCorrect dari $_questionsThisLevel soal dengan benar!'
                      : 'Kamu menjawab $_levelCorrect dari $_questionsThisLevel soal benar.\nRaccoo percaya kamu pasti bisa!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.baloo2(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _textMuted,
                      height: 1.4),
                ),
                const SizedBox(height: 24),
                // Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final earned = i < levelStars;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400 + i * 150),
                      curve: const Cubic(0.34, 1.56, 0.64, 1),
                      builder: (_, v, __) => Transform.scale(
                        scale: v,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 62,
                                  color: const Color(0xFFB8860B).withValues(
                                      alpha: earned ? 1.0 : 0.22)),
                              Icon(Icons.star_rounded,
                                  size: 56,
                                  color: earned
                                      ? _gold
                                      : _gold.withValues(alpha: 0.22)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

              ],
            ),
          ),

          const Spacer(),

          if (passed) ...[
            if (!isLastLevel)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Selanjutnya: Level ${_currentLevel + 1} 🚀',
                    style: GoogleFonts.dmSans(fontSize: 15, color: _textMuted)),
              ),
            _ThinkButton(
              label: isLastLevel
                  ? 'Lihat Hasil Akhir 🏆'
                  : 'Lanjut ke Level ${_currentLevel + 1}',
              color: _zoneColor,
              textColor: Colors.white,
              icon: isLastLevel
                  ? Icons.emoji_events_rounded
                  : Icons.arrow_forward_rounded,
              onTap: _proceedToNextLevel,
            ),
          ] else ...[
            _ThinkButton(
              label: 'Coba Level $_currentLevel Lagi',
              color: const Color(0xFFFF9A3C),
              textColor: Colors.white,
              icon: Icons.replay_rounded,
              onTap: _retryLevel,
            ),
          ],

          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // ── Done ──────────────────────────────────────────────────────────────────

  Widget _buildDoneScreen() {
    final stars = _totalCorrect >= _totalQuestionsInRun
        ? 3
        : _totalCorrect >= (_totalQuestionsInRun * 2 / 3).ceil()
            ? 2
            : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(stars == 3 ? 'Sempurna! 🏆' : 'Selesai! 🎉',
                    style: GoogleFonts.baloo2(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                        height: 1.1)),

                const SizedBox(height: 8),

                Text(
                    'Kamu sudah menyelesaikan\nsemua $_totalLevels level Raccoo Think!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.baloo2(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textMuted,
                        height: 1.4)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Score card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ScoreStat(
                    label: 'Betul',
                    value: '$_totalCorrect',
                    color: _successGreen,
                    icon: Icons.check_circle_rounded),
                Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
                _ScoreStat(
                    label: 'Total Soal',
                    value: '$_totalQuestionsInRun',
                    color: _zoneColor,
                    icon: Icons.forum_rounded),
                Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
                _ScoreStat(
                    label: 'Bintang',
                    value: '$stars',
                    color: _gold,
                    icon: Icons.star_rounded),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 500 + i * 180),
                curve: const Cubic(0.34, 1.56, 0.64, 1),
                builder: (_, v, __) => Transform.scale(
                  scale: v,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.star_rounded,
                            size: 62,
                            color: const Color(0xFFB8860B).withValues(
                                alpha: i < stars ? 1.0 : 0.22)),
                        Icon(Icons.star_rounded,
                            size: 56,
                            color: i < stars
                                ? _gold
                                : _gold.withValues(alpha: 0.22)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          const Spacer(),

          // if (stars < 3)
          //   Padding(
          //     padding: const EdgeInsets.only(bottom: 12),
          //     child: Text(
          //         'Tidak apa-apa! Setiap latihan membuat kamu makin pintar! 💪',
          //         textAlign: TextAlign.center,
          //         style: GoogleFonts.dmSans(
          //             fontSize: 16, color: _textMuted, height: 1.5)),
          //   ),

          Row(
            children: [
              Expanded(
                child: _ThinkButton(
                  label: 'Main Lagi',
                  color: Colors.white,
                  textColor: _zoneColor,
                  icon: Icons.replay_rounded,
                  onTap: () {
                    _buildLevelScenarios();
                    setState(() {
                      _currentLevel = 1;
                      _questionInLevel = 0;
                      _levelCorrect = 0;
                      _totalCorrect = 0;
                      _phase = _Phase.levelIntro;
                    });
                    _celebrationController.reset();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThinkButton(
                  label: 'Selesai',
                  color: _zoneColor,
                  textColor: Colors.white,
                  icon: Icons.home_rounded,
                  onTap: () => context.pop(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SituationCard extends StatelessWidget {
  final ThinkScenario scenario;
  const _SituationCard({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row(
          //   children: [
          //     Container(
          //       padding:
          //           const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          //       decoration: BoxDecoration(
          //         color: style.bg,
          //         borderRadius: BorderRadius.circular(999),
          //       ),
          //       child: Text(
          //         scenario.theme,
          //         style: GoogleFonts.dmSans(
          //           fontSize: 12,
          //           fontWeight: FontWeight.w700,
          //           color: style.accent,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 12),
          _LandscapeAssetImage(
            assetPath: scenario.effectiveImagePath,
            fallbackEmoji: scenario.emoji,
            fallbackLabel: scenario.situationLabel,
            height: 214,
            borderRadius: 18,
          ),
          const SizedBox(height: 14),
          Text(
            scenario.situationLabel,
            style: GoogleFonts.baloo2(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _textDark,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            scenario.situationNarration,
            style: GoogleFonts.dmSans(
              fontSize: 15.5,
              height: 1.55,
              color: _textMuted,
            ),
          ),
          // const SizedBox(height: 10),
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          //   decoration: BoxDecoration(
          //     color: style.bg.withValues(alpha: 0.72),
          //     borderRadius: BorderRadius.circular(16),
          //   ),
          //   child: Row(
          //     children: [
          //       Text(
          //         scenario.emoji,
          //         style: const TextStyle(fontSize: 20),
          //       ),
          //       const SizedBox(width: 8),
          //       Expanded(
          //         child: Text(
          //           'Perhatikan situasinya baik-baik sebelum memilih jawaban.',
          //           style: GoogleFonts.dmSans(
          //             fontSize: 13,
          //             fontWeight: FontWeight.w500,
          //             color: _textDark,
          //             height: 1.35,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _QuestionBubble extends StatelessWidget {
  final String question;
  final String theme;

  const _QuestionBubble({
    required this.question,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleOf(theme);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: style.bg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/characters/racoo_avatar_brown.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pertanyaan',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: style.accent,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  question,
                  style: GoogleFonts.baloo2(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Choice Card ──────────────────────────────────────────────────────────────

enum _ChoiceState { idle, selectedCorrect, selectedWrong, dimmed }

class _ChoiceCard extends StatelessWidget {
  final ThinkChoice choice;
  final String imagePath;
  final String optionLabel;
  final _ChoiceState state;
  final VoidCallback onTap;
  final Animation<double>? shakeAnimation;

  const _ChoiceCard({
    required this.choice,
    required this.imagePath,
    required this.optionLabel,
    required this.state,
    required this.onTap,
    this.shakeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = state == _ChoiceState.selectedCorrect ||
        state == _ChoiceState.selectedWrong;
    final cardBg = switch (state) {
      _ChoiceState.selectedCorrect => const Color(0xFFF5FBF5),
      _ChoiceState.selectedWrong => const Color(0xFFFFF8F1),
      _ => Colors.white,
    };
    final borderColor = switch (state) {
      _ChoiceState.selectedCorrect => _successGreen.withValues(alpha: 0.18),
      _ChoiceState.selectedWrong =>
        const Color(0xFFFF9A3C).withValues(alpha: 0.22),
      _ => Colors.black.withValues(alpha: 0.06),
    };
    final shadowColor =
        Colors.black.withValues(alpha: isSelected ? 0.05 : 0.07);
    final opacity = state == _ChoiceState.dimmed ? 0.38 : 1.0;
    final isInteractive = state == _ChoiceState.idle;
    final badgeColor = switch (state) {
      _ChoiceState.selectedCorrect => _successGreen.withValues(alpha: 0.12),
      _ChoiceState.selectedWrong =>
        const Color(0xFFFF9A3C).withValues(alpha: 0.12),
      _ => const Color(0xFFF6F1E8),
    };
    final badgeTextColor = switch (state) {
      _ChoiceState.selectedCorrect => _successGreen,
      _ChoiceState.selectedWrong => const Color(0xFFFF9A3C),
      _ => _textDark,
    };

    Widget card = Opacity(
      opacity: opacity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ChoiceAssetPreview(
              assetPath: imagePath,
              fallbackEmoji: choice.emoji,
              fallbackLabel: choice.label,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      optionLabel,
                      style: GoogleFonts.baloo2(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: badgeTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    choice.label,
                    style: GoogleFonts.baloo2(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (shakeAnimation != null) {
      card = AnimatedBuilder(
        animation: shakeAnimation!,
        builder: (_, child) {
          final offset = math.sin(shakeAnimation!.value * math.pi * 4) * 8;
          return Transform.translate(offset: Offset(offset, 0), child: child);
        },
        child: card,
      );
    }

    return GestureDetector(onTap: isInteractive ? onTap : null, child: card);
  }
}

class _ChoiceAssetPreview extends StatefulWidget {
  final String assetPath;
  final String fallbackEmoji;
  final String fallbackLabel;

  const _ChoiceAssetPreview({
    required this.assetPath,
    required this.fallbackEmoji,
    required this.fallbackLabel,
  });

  @override
  State<_ChoiceAssetPreview> createState() => _ChoiceAssetPreviewState();
}

class _ChoiceAssetPreviewState extends State<_ChoiceAssetPreview> {
  late Future<bool> _existsFuture;

  @override
  void initState() {
    super.initState();
    _existsFuture = _assetExists(widget.assetPath);
  }

  @override
  void didUpdateWidget(covariant _ChoiceAssetPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _existsFuture = _assetExists(widget.assetPath);
    }
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _existsFuture,
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _LandscapeAssetImage(
            assetPath: widget.assetPath,
            fallbackEmoji: widget.fallbackEmoji,
            fallbackLabel: widget.fallbackLabel,
            height: 110,
            borderRadius: 16,
          ),
        );
      },
    );
  }
}

class _LandscapeAssetImage extends StatelessWidget {
  final String assetPath;
  final String fallbackEmoji;
  final String fallbackLabel;
  final double height;
  final double borderRadius;

  const _LandscapeAssetImage({
    required this.assetPath,
    required this.fallbackEmoji,
    required this.fallbackLabel,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _LandscapeImageFallback(
            emoji: fallbackEmoji,
            label: fallbackLabel,
          ),
        ),
      ),
    );
  }
}

class _LandscapeImageFallback extends StatelessWidget {
  final String emoji;
  final String label;

  const _LandscapeImageFallback({
    required this.emoji,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _zoneColor.withValues(alpha: 0.16),
            const Color(0xFFFFF3D6),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -22,
            child: Opacity(
              opacity: 0.20,
              child: Text(emoji, style: const TextStyle(fontSize: 96)),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.baloo2(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feedback Dialog ──────────────────────────────────────────────────────────

class _FeedbackDialog extends StatefulWidget {
  final ThinkChoice choice;
  final VoidCallback onNext;
  final bool isLastQuestion;

  const _FeedbackDialog({
    required this.choice,
    required this.onNext,
    required this.isLastQuestion,
  });

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  @override
  Widget build(BuildContext context) {
    final isCorrect = widget.choice.isCorrect;
    final headerEmoji = isCorrect ? '🌟' : '💭';
    final headerText = isCorrect ? 'Betul!' : 'Yuk pikirkan lagi!';
    final accentColor = isCorrect ? _zoneColor : const Color(0xFFFF9A3C);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: _zoneShadow.withValues(alpha: 0.30),
                offset: const Offset(4, 8),
                blurRadius: 0),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child:
                        Text(headerEmoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(headerText,
                    style: GoogleFonts.baloo2(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _textDark)),
              ],
            ),

            const SizedBox(height: 16),

            // GIF
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: double.infinity,
                height: 180,
                child: Image.asset(
                  'assets/images/characters/racoo_walking.gif',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Feedback text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(widget.choice.feedback,
                  style: GoogleFonts.dmSans(
                      fontSize: 16, height: 1.55, color: _textDark)),
            ),

            const SizedBox(height: 20),

            _ThinkButton(
              label: widget.isLastQuestion ? 'Lihat Skor Level' : 'Lanjut',
              color: accentColor,
              textColor: Colors.white,
              icon: widget.isLastQuestion
                  ? Icons.bar_chart_rounded
                  : Icons.arrow_forward_rounded,
              onTap: widget.onNext,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _ScoreStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ScoreStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.baloo2(
                fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: _textMuted)),
      ],
    );
  }
}

class _ThinkButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;
  final VoidCallback onTap;

  const _ThinkButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: color == Colors.white
              ? Border.all(color: _zoneColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: _zoneShadow.withValues(
                  alpha: color == Colors.white ? 0.18 : 0.45),
              offset: const Offset(3, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.baloo2(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
          ],
        ),
      ),
    );
  }
}


class _Button extends StatelessWidget {
  final String img;
  final VoidCallback onTap;
  final double width;
  final double height;

  const _Button({
    required this.img,
    required this.onTap,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        img,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFC85A00),
                  offset: Offset(2, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF3D2B1A),
              size: 28,
            ),
          );
        },
      ),
    );
  }
}

