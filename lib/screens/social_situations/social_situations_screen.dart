import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/game_progress.dart';
import '../../providers/progress_provider.dart';
import '../../services/audio_service.dart';

// ─── Zone Design Tokens ───────────────────────────────────────────────────────

const _zoneBg = Color(0xFFF0F9F0);
const _zoneColor = Color(0xFF4CAF6E);
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
  'Berbagi & Giliran':   _ThemeStyle(Color(0xFFFFF8E7), Color(0xFFFF9A3C), Color(0xFFC85A00)),
  'Empati & Kepedulian': _ThemeStyle(Color(0xFFE8F5E9), Color(0xFF4CAF6E), Color(0xFF1A5E36)),
  'Regulasi Emosi':      _ThemeStyle(Color(0xFFF3E5F5), Color(0xFF9C27B0), Color(0xFF4A0072)),
  'Komunikasi Asertif':  _ThemeStyle(Color(0xFFE3F2FD), Color(0xFF1976D2), Color(0xFF0D47A1)),
  'Kontrol Diri':        _ThemeStyle(Color(0xFFE0F2F1), Color(0xFF009688), Color(0xFF004D40)),
  'Resolusi Konflik':    _ThemeStyle(Color(0xFFFFEBEE), Color(0xFFE53935), Color(0xFFB71C1C)),
};

_ThemeStyle _styleOf(String theme) =>
    _themeStyles[theme] ??
    const _ThemeStyle(Color(0xFFF0F9F0), Color(0xFF4CAF6E), Color(0xFF1A5E36));

// ─── Level Data ───────────────────────────────────────────────────────────────

const _levelGoals = {
  1: 'Belajar berbagi\ndan peduli kepada teman 💚',
  2: 'Belajar mengatur perasaan\ndan berbicara dengan baik 💬',
  3: 'Belajar menaati aturan\ndan menyelesaikan masalah 🕊️',
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
}

// ─── Scenario Bank (30 soal) ──────────────────────────────────────────────────

const List<ThinkScenario> thinkScenarios = [

  // ── Level 1 · Berbagi & Giliran ───────────────────────────────────────────

  ThinkScenario(
    id: 'sharing_1', level: 1, theme: 'Berbagi & Giliran',
    situationLabel: 'Pinjam Mainan',
    situationNarration: 'Kamu sedang bermain dengan mainan kesayanganmu. Teman di sebelahmu ingin meminjamnya sebentar.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🧸',
    choiceA: ThinkChoice(
      label: 'Pinjamkan dan minta dikembalikan setelah selesai',
      emoji: '🤝', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Hebat! Itu pilihan yang baik. Meminjamkan mainan membuat teman merasa dihargai! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Rebut kembali dan berkata tidak mau',
      emoji: '😤', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba pikir lagi ya 🤔 Bagaimana perasaan temanmu kalau tidak dipinjami?',
    ),
  ),

  ThinkScenario(
    id: 'sharing_2', level: 1, theme: 'Berbagi & Giliran',
    situationLabel: 'Krayon Biru',
    situationNarration: 'Kamu dan teman ingin menggunakan krayon biru yang sama untuk mewarnai gambar.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🖍️',
    choiceA: ThinkChoice(
      label: 'Bergantian menggunakannya dengan adil',
      emoji: '🔄', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Bagus sekali! Bergantian adalah cara yang adil dan menyenangkan semua orang! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Rebut krayon agar kamu mewarnai duluan',
      emoji: '😠', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba lihat lagi ya 😊 Apa cara yang lebih adil agar kalian bisa sama-sama mewarnai?',
    ),
  ),

  ThinkScenario(
    id: 'sharing_3', level: 1, theme: 'Berbagi & Giliran',
    situationLabel: 'Ayunan di Taman',
    situationNarration: 'Saat bermain ayunan di taman, ada teman yang sudah menunggu lama ingin giliran naik.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🎠',
    choiceA: ThinkChoice(
      label: 'Turun setelah selesai dan persilakan temanmu naik',
      emoji: '😊', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Keren! Memberikan giliran kepada teman adalah tanda hati yang baik! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Tetap main terus meski teman sudah menunggu',
      emoji: '🙈', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Yuk coba bayangkan 🤔 Kalau kamu yang sudah menunggu lama, apa yang kamu rasakan?',
    ),
  ),

  ThinkScenario(
    id: 'sharing_4', level: 1, theme: 'Berbagi & Giliran',
    situationLabel: 'Kue Tersisa',
    situationNarration: 'Ada sepotong kue tersisa di piring. Kamu ingin memakannya, tapi adikmu juga melihatnya.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🍰',
    choiceA: ThinkChoice(
      label: 'Bagi kue menjadi dua agar bisa makan bersama',
      emoji: '🤝', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Hebat! Berbagi dengan adik adalah tanda kamu penyayang. Adikmu pasti sangat senang! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Langsung makan kue tanpa berbagi',
      emoji: '😋', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba pikir lagi ya 🤔 Bagaimana perasaan adikmu kalau tidak kebagian?',
    ),
  ),

  ThinkScenario(
    id: 'sharing_5', level: 1, theme: 'Berbagi & Giliran',
    situationLabel: 'Buku Bergambar',
    situationNarration: 'Kamu sedang membaca buku bergambar favoritmu. Temanmu datang dan ingin membaca bersama.',
    question: 'Apa yang kamu lakukan?',
    emoji: '📖',
    choiceA: ThinkChoice(
      label: 'Ajak temanmu duduk dan baca bersama-sama',
      emoji: '📚', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Bagus! Membaca bersama teman bisa jadi lebih seru dan menyenangkan! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Sembunyikan buku agar teman tidak ikut membaca',
      emoji: '🙅', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba bayangkan 😊 Enak tidak kalau temanmu tidak mau membagi bukunya denganmu?',
    ),
  ),

  // ── Level 1 · Empati & Kepedulian ─────────────────────────────────────────

  ThinkScenario(
    id: 'empathy_1', level: 1, theme: 'Empati & Kepedulian',
    situationLabel: 'Teman Terjatuh',
    situationNarration: 'Temanmu terjatuh di halaman sekolah dan lututnya terluka. Ia menangis kesakitan.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🤕',
    choiceA: ThinkChoice(
      label: 'Hampiri, tanya kabarnya, dan panggil bu guru',
      emoji: '💚', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Hebat! Itu pilihan yang baik. Membantu teman yang terluka adalah tanda kamu peduli! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Tertawa melihatnya jatuh lalu lanjut bermain',
      emoji: '😂', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba lihat lagi ya 😊 Bagaimana perasaan temanmu kalau ditinggal saat sedang sakit?',
    ),
  ),

  ThinkScenario(
    id: 'empathy_2', level: 1, theme: 'Empati & Kepedulian',
    situationLabel: 'Teman Sedih Sendiri',
    situationNarration: 'Temanmu terlihat sedih sendirian di pojok kelas karena tidak diajak bermain.',
    question: 'Apa yang kamu lakukan?',
    emoji: '😢',
    choiceA: ThinkChoice(
      label: 'Dekati dan ajak bermain bersama',
      emoji: '🫂', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Luar biasa! Mengajak teman yang sedih bermain membuatnya tidak merasa sendirian lagi! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Biarkan saja ia sendiri dan lanjutkan bermain',
      emoji: '🙈', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba bayangkan kamu di posisi temanmu 🤔 Apa yang ingin kamu rasakan dari teman-temanmu?',
    ),
  ),

  ThinkScenario(
    id: 'empathy_3', level: 1, theme: 'Empati & Kepedulian',
    situationLabel: 'Gambar Teman Jatuh',
    situationNarration: 'Kamu tidak sengaja menabrak dan menjatuhkan gambar teman hingga kotor.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🎨',
    choiceA: ThinkChoice(
      label: 'Minta maaf dengan tulus dan bantu membersihkan',
      emoji: '🙏', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Bagus! Meminta maaf dan membantu adalah tanda hati yang baik! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Pura-pura tidak melihat dan langsung pergi',
      emoji: '🏃', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba pikir lagi ya 😊 Apa yang bisa kamu lakukan agar temanmu merasa lebih baik?',
    ),
  ),

  ThinkScenario(
    id: 'empathy_4', level: 1, theme: 'Empati & Kepedulian',
    situationLabel: 'Adik Menangis',
    situationNarration: 'Adikmu menangis karena mainan kesayangannya rusak.',
    question: 'Apa yang kamu lakukan?',
    emoji: '😭',
    choiceA: ThinkChoice(
      label: 'Peluk adik dan temaninya agar tidak sedih sendiri',
      emoji: '🫂', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Wah, kamu kakak yang baik! Menemani adik yang sedih membuatnya merasa lebih nyaman! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Bilang sudah diam, itu cuma mainan',
      emoji: '😑', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba lihat lagi ya 🤔 Bagaimana perasaan adik kalau tidak ditemani saat sedih?',
    ),
  ),

  ThinkScenario(
    id: 'empathy_5', level: 1, theme: 'Empati & Kepedulian',
    situationLabel: 'Teman Baru Bingung',
    situationNarration: 'Temanmu baru pindah sekolah dan terlihat bingung tidak tahu harus ke mana.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🏫',
    choiceA: ThinkChoice(
      label: 'Hampiri dan tawarkan bantuan antar ke kelas',
      emoji: '🤝', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Hebat! Menyambut teman baru membuat ia merasa senang dan tidak kesepian! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Acuhkan karena kamu tidak mengenalnya',
      emoji: '🙄', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, bayangkan kamu jadi teman baru itu 😊 Apa yang ingin kamu rasakan dari teman-teman di sekolah baru?',
    ),
  ),

  // ── Level 2 · Regulasi Emosi ──────────────────────────────────────────────

  ThinkScenario(
    id: 'emoregulation_1', level: 2, theme: 'Regulasi Emosi',
    situationLabel: 'Kalah Balapan',
    situationNarration: 'Kamu kalah dalam permainan balap mobil dan merasa sangat kesal.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🏎️',
    choiceA: ThinkChoice(
      label: 'Tarik napas dan ucapkan selamat kepada temanmu',
      emoji: '😌', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Keren! Itu pilihan yang baik. Menerima kekalahan dengan lapang dada adalah tanda kamu kuat! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Lempar mobil-mobilan ke lantai karena kesal',
      emoji: '😡', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba tarik napas dulu ya 😊 Apa yang bisa kamu lakukan agar perasaan kesalmu berkurang?',
    ),
  ),

  ThinkScenario(
    id: 'emoregulation_2', level: 2, theme: 'Regulasi Emosi',
    situationLabel: 'Menunggu Mainan Robot',
    situationNarration: 'Kamu ingin bermain dengan mainan robot, tapi kakakmu bilang kamu harus menunggu sebentar.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🤖',
    choiceA: ThinkChoice(
      label: 'Bilang iya dan cari kegiatan lain sambil menunggu',
      emoji: '😊', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Bagus! Bersabar dan mencari kegiatan lain saat menunggu adalah tanda kamu bijak! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Menangis keras-keras dan terus merengek',
      emoji: '😭', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba pikir lagi ya 🤔 Kegiatan seru apa yang bisa kamu lakukan sambil menunggu giliran?',
    ),
  ),

  ThinkScenario(
    id: 'emoregulation_3', level: 2, theme: 'Regulasi Emosi',
    situationLabel: 'Gambar Rusak Kena Air',
    situationNarration: 'Teman tidak sengaja menumpahkan air ke gambar yang sudah kamu buat dengan susah payah.',
    question: 'Apa yang kamu lakukan?',
    emoji: '💦',
    choiceA: ThinkChoice(
      label: 'Tarik napas, bilang tidak apa-apa, dan buat ulang bersama',
      emoji: '😌', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Hebat! Memaafkan teman yang tidak sengaja berbuat salah adalah tanda hati yang besar! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Berteriak marah dan mendorong teman',
      emoji: '😡', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba lihat lagi ya 😊 Teman tidak sengaja. Apa cara yang lebih baik untuk mengungkapkan perasaanmu?',
    ),
  ),

  ThinkScenario(
    id: 'emoregulation_4', level: 2, theme: 'Regulasi Emosi',
    situationLabel: 'Tidak Bisa Beli Es Krim',
    situationNarration: 'Kamu sangat ingin membeli es krim, tapi ibu bilang hari ini tidak bisa.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🍦',
    choiceA: ThinkChoice(
      label: 'Terima keputusan ibu dan bilang mungkin lain kali',
      emoji: '😊', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Keren! Menerima keputusan orang tua dengan lapang dada adalah tanda kamu sudah besar! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Ngambek, banting tas, dan tidak mau bicara',
      emoji: '😤', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba tarik napas dulu ya 🤔 Cara apa yang lebih baik untuk menyampaikan kekecewaanmu?',
    ),
  ),

  ThinkScenario(
    id: 'emoregulation_5', level: 2, theme: 'Regulasi Emosi',
    situationLabel: 'Bangunan Balok Roboh',
    situationNarration: 'Saat bermain balok, bangunan yang kamu buat tiba-tiba roboh sendiri.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🧱',
    choiceA: ThinkChoice(
      label: 'Ambil napas, tersenyum, dan mulai membangun kembali',
      emoji: '😄', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Bagus sekali! Mencoba lagi setelah gagal adalah tanda kamu pemberani dan tangguh! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Menendang balok-balok karena frustrasi',
      emoji: '😡', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba tarik napas dulu ya 😊 Apa yang bisa kamu lakukan agar merasa lebih tenang sebelum mencoba lagi?',
    ),
  ),

  // ── Level 2 · Komunikasi Asertif ──────────────────────────────────────────

  ThinkScenario(
    id: 'assertive_1', level: 2, theme: 'Komunikasi Asertif',
    situationLabel: 'Pinjam Pensil Warna',
    situationNarration: 'Kamu ingin meminjam pensil warna milik temanmu untuk menyelesaikan gambarmu.',
    question: 'Apa yang kamu lakukan?',
    emoji: '✏️',
    choiceA: ThinkChoice(
      label: 'Bertanya sopan: "Boleh aku pinjam pensil warnamu?"',
      emoji: '🙏', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Hebat! Bertanya dengan sopan adalah cara yang baik untuk meminta sesuatu! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Langsung ambil tanpa bertanya dulu',
      emoji: '🖐️', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba lihat lagi ya 🤔 Bagaimana perasaan temanmu kalau barangnya diambil tanpa permisi?',
    ),
  ),

  ThinkScenario(
    id: 'assertive_2', level: 2, theme: 'Komunikasi Asertif',
    situationLabel: 'Tidak Mau Main di Luar',
    situationNarration: 'Temanmu mengajak bermain di luar, tapi kamu sedang tidak mau bermain di sana.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🌳',
    choiceA: ThinkChoice(
      label: 'Tolak dengan sopan: "Terima kasih, aku mau di sini saja ya"',
      emoji: '😊', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Bagus! Menolak dengan sopan sambil berterima kasih adalah cara komunikasi yang baik! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Diam saja atau pergi tanpa berkata apa-apa',
      emoji: '🚶', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba pikir lagi ya 😊 Bagaimana cara yang lebih sopan untuk memberitahu temanmu?',
    ),
  ),

  ThinkScenario(
    id: 'assertive_3', level: 2, theme: 'Komunikasi Asertif',
    situationLabel: 'Tidak Mengerti Origami',
    situationNarration: 'Kamu tidak mengerti cara melipat origami yang diajarkan bu guru.',
    question: 'Apa yang kamu lakukan?',
    emoji: '📝',
    choiceA: ThinkChoice(
      label: 'Angkat tangan dan tanya guru dengan sopan',
      emoji: '✋', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Keren! Berani bertanya kepada guru adalah tanda kamu mau belajar dan pintar! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Diam-diam menyalin teman tanpa mau bertanya',
      emoji: '🙈', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba pikir lagi ya 🤔 Apa yang kamu pelajari kalau hanya menyalin tanpa mengerti?',
    ),
  ),

  ThinkScenario(
    id: 'assertive_4', level: 2, theme: 'Komunikasi Asertif',
    situationLabel: 'Barang Terus Disentuh',
    situationNarration: 'Seorang teman terus-terusan menyentuh barang-barangmu meski kamu sudah terlihat tidak nyaman.',
    question: 'Apa yang kamu lakukan?',
    emoji: '😤',
    choiceA: ThinkChoice(
      label: 'Katakan dengan tenang: "Tolong jangan pegang barangku ya"',
      emoji: '💬', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Hebat! Berbicara dengan tenang untuk menyampaikan perasaanmu adalah cara yang tepat! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Langsung dorong tangan temanmu karena kesal',
      emoji: '😠', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba lihat lagi ya 😊 Cara apa yang lebih baik untuk memberitahu temanmu bahwa kamu tidak suka?',
    ),
  ),

  ThinkScenario(
    id: 'assertive_5', level: 2, theme: 'Komunikasi Asertif',
    situationLabel: 'Bantu Ibu Belanja',
    situationNarration: 'Kamu ingin membantu ibu membawakan belanjaan yang berat.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🛍️',
    choiceA: ThinkChoice(
      label: 'Tawarkan bantuan: "Bu, boleh aku bantu bawakan tasnya?"',
      emoji: '🙋', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Wah, kamu anak yang baik! Menawarkan bantuan dengan sopan adalah tanda kamu peduli! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Langsung tarik tas dari tangan ibu tanpa bilang apa-apa',
      emoji: '😬', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba pikir lagi ya 🤔 Bagaimana cara yang lebih sopan untuk menawarkan bantuan?',
    ),
  ),

  // ── Level 3 · Kontrol Diri ────────────────────────────────────────────────

  ThinkScenario(
    id: 'selfcontrol_1', level: 3, theme: 'Kontrol Diri',
    situationLabel: 'Rapikan Mainan',
    situationNarration: 'Bu guru meminta semua anak merapikan mainan sebelum waktu makan siang tiba.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🧹',
    choiceA: ThinkChoice(
      label: 'Langsung rapikan mainanmu dan bantu teman',
      emoji: '✅', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Keren! Itu pilihan yang baik. Mengikuti aturan dan membantu teman adalah hal yang luar biasa! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Terus bermain dan pura-pura tidak dengar',
      emoji: '🙈', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba pikir lagi ya 🤔 Apa yang terjadi kalau semua anak tidak merapikan mainan bersama?',
    ),
  ),

  ThinkScenario(
    id: 'selfcontrol_2', level: 3, theme: 'Kontrol Diri',
    situationLabel: 'Antre Cuci Tangan',
    situationNarration: 'Saat antre mencuci tangan, kamu melihat ada celah di barisan untuk menyalip.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🚰',
    choiceA: ThinkChoice(
      label: 'Tetap di tempat antrian dan sabar menunggu',
      emoji: '🧍', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Bagus! Menunggu dengan sabar di antrian adalah tanda kamu jujur dan adil! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Menyalip ke depan agar lebih cepat',
      emoji: '🏃', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba bayangkan ya 😊 Bagaimana perasaan teman yang sudah lama mengantri kalau kamu menyalip?',
    ),
  ),

  ThinkScenario(
    id: 'selfcontrol_3', level: 3, theme: 'Kontrol Diri',
    situationLabel: 'Guru Sedang Menjelaskan',
    situationNarration: 'Bu guru sedang menjelaskan sesuatu di depan kelas. Temanmu mengajakmu berbicara.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🗣️',
    choiceA: ThinkChoice(
      label: 'Bisikkan "nanti saja ya" dan fokus ke guru',
      emoji: '🤫', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Hebat! Mendengarkan guru dengan fokus adalah tanda kamu menghormati bu guru! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Berbicara keras sampai mengganggu kelas',
      emoji: '📢', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba pikir lagi ya 🤔 Apa yang terjadi dengan pelajaran kalau semua anak berbicara saat guru menjelaskan?',
    ),
  ),

  ThinkScenario(
    id: 'selfcontrol_4', level: 3, theme: 'Kontrol Diri',
    situationLabel: 'Buang Sampah',
    situationNarration: 'Selesai makan, kamu diminta membuang bungkus makananmu ke tempat sampah.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🗑️',
    choiceA: ThinkChoice(
      label: 'Buang bungkus ke tempat sampah dengan rapi',
      emoji: '♻️', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Keren! Membuang sampah pada tempatnya adalah tanggung jawab yang membuat lingkungan bersih! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Tinggalkan di meja karena malas berjalan',
      emoji: '😴', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba bayangkan ya 😊 Bagaimana kalau semua orang meninggalkan sampahnya sembarangan?',
    ),
  ),

  ThinkScenario(
    id: 'selfcontrol_5', level: 3, theme: 'Kontrol Diri',
    situationLabel: 'Tidak Boleh Berlari',
    situationNarration: 'Saat bermain di dalam kelas, ada aturan tidak boleh berlari.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🚶',
    choiceA: ThinkChoice(
      label: 'Berjalan pelan dan ingatkan teman yang berlari',
      emoji: '🚶', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Bagus! Mematuhi aturan dan mengingatkan teman dengan sopan adalah tanda kamu bertanggung jawab! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Berlari-lari karena merasa aturannya tidak penting',
      emoji: '🏃', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba pikir lagi ya 🤔 Kenapa ya aturan tidak boleh berlari di kelas itu ada?',
    ),
  ),

  // ── Level 3 · Resolusi Konflik ────────────────────────────────────────────

  ThinkScenario(
    id: 'conflict_1', level: 3, theme: 'Resolusi Konflik',
    situationLabel: 'Berebut Boneka',
    situationNarration: 'Kamu dan teman menginginkan boneka yang sama untuk dimainkan. Hanya ada satu.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🪆',
    choiceA: ThinkChoice(
      label: 'Usul bergantian: "Kamu dulu 5 menit, lalu aku ya?"',
      emoji: '🤝', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Pintar sekali! Mengusulkan giliran adalah cara yang adil dan damai! 🕊️',
    ),
    choiceB: ThinkChoice(
      label: 'Tarik boneka dari tangan teman',
      emoji: '😤', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba pikir lagi ya 😊 Apa cara yang lebih baik agar kalian bisa sama-sama bermain?',
    ),
  ),

  ThinkScenario(
    id: 'conflict_2', level: 3, theme: 'Resolusi Konflik',
    situationLabel: 'Cat Tumpah ke Baju',
    situationNarration: 'Temanmu tidak sengaja menumpahkan cat ke bajumu saat kalian melukis bersama.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🖌️',
    choiceA: ThinkChoice(
      label: 'Katakan tidak apa-apa dan lanjutkan melukis',
      emoji: '😊', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Hebat! Memaafkan teman yang tidak sengaja adalah tanda kamu punya hati yang besar! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Balas menumpahkan cat ke bajunya',
      emoji: '😠', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba lihat lagi ya 🤔 Teman tidak sengaja melakukannya. Apa yang terjadi kalau kamu membalasnya?',
    ),
  ),

  ThinkScenario(
    id: 'conflict_3', level: 3, theme: 'Resolusi Konflik',
    situationLabel: 'Berebut Jadi Pemimpin',
    situationNarration: 'Kamu dan teman berselisih tentang siapa yang akan menjadi pemimpin dalam permainan.',
    question: 'Apa yang kamu lakukan?',
    emoji: '👑',
    choiceA: ThinkChoice(
      label: 'Usulkan hom-pim-pa atau bergantian setiap ronde',
      emoji: '🤝', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Keren! Mengusulkan cara yang adil agar semua bisa mendapat giliran adalah hal yang bijaksana! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Ngambek dan ancam tidak mau bermain',
      emoji: '😤', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba pikir lagi ya 😊 Cara apa yang bisa membuat semua teman senang dan permainan tetap berlanjut?',
    ),
  ),

  ThinkScenario(
    id: 'conflict_4', level: 3, theme: 'Resolusi Konflik',
    situationLabel: 'Kata-Kata Menyakitkan',
    situationNarration: 'Temanmu berkata kata-kata yang membuatmu tersinggung dan sedih.',
    question: 'Apa yang kamu lakukan?',
    emoji: '😔',
    choiceA: ThinkChoice(
      label: 'Katakan dengan tenang: "Kata-katamu membuatku sedih"',
      emoji: '💬', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Bagus! Mengungkapkan perasaanmu dengan tenang adalah cara yang tepat dan berani! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Balas dengan kata-kata yang lebih menyakitkan',
      emoji: '😈', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba lihat lagi ya 🤔 Kalau kata-kata menyakitkan dibalas, apa yang akan terjadi selanjutnya?',
    ),
  ),

  ThinkScenario(
    id: 'conflict_5', level: 3, theme: 'Resolusi Konflik',
    situationLabel: 'Dituduh Mengambil',
    situationNarration: 'Teman menuduh kamu mengambil penghapusnya, padahal kamu tidak melakukannya.',
    question: 'Apa yang kamu lakukan?',
    emoji: '🔍',
    choiceA: ThinkChoice(
      label: 'Jelaskan dengan tenang dan ajak cari bersama',
      emoji: '🔍', cardColor: Color(0xFFC8E6C9), isCorrect: true,
      feedback: 'Hebat! Menjelaskan dengan tenang dan mengajak mencari bersama adalah cara yang bijak dan jujur! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Balik berteriak marah dan menuduh balik',
      emoji: '😡', cardColor: Color(0xFFFFCDD2), isCorrect: false,
      feedback: 'Hmm, coba tarik napas dulu ya 😊 Cara apa yang lebih tenang untuk membuktikan bahwa kamu tidak mengambilnya?',
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
  late Animation<Offset> _feedbackSlide;
  late Animation<double> _raccooFloat;
  late Animation<double> _shakeAnimation;
  late Animation<double> _celebrationScale;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _buildLevelScenarios();

    _cardSlideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _cardSlide = Tween<Offset>(begin: const Offset(0, -0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardSlideController, curve: const Cubic(0.34, 1.56, 0.64, 1)));

    _choiceEntranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _choiceASlide = Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _choiceEntranceController,
            curve: const Interval(0.0, 0.7, curve: Cubic(0.34, 1.56, 0.64, 1))));
    _choiceBSlide = Tween<Offset>(begin: const Offset(0.5, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _choiceEntranceController,
            curve: const Interval(0.15, 0.85, curve: Cubic(0.34, 1.56, 0.64, 1))));

    _feedbackController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _feedbackSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _feedbackController, curve: const Cubic(0.34, 1.56, 0.64, 1)));

    _raccooController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _raccooFloat = Tween<double>(begin: -6, end: 6)
        .animate(CurvedAnimation(parent: _raccooController, curve: Curves.easeInOut));

    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));

    _celebrationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _celebrationScale = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _celebrationController, curve: const Cubic(0.34, 1.56, 0.64, 1)));

    // Inisialisasi urutan awal (Level Intro belum menampilkan soal, tapi perlu non-empty)
    _orderedChoices = [
      _levelScenarios[1]![0].choiceA,
      _levelScenarios[1]![0].choiceB,
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioService>().play(AudioAsset.instructionSocialSituations);
    });
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
    if (retryLevel != null) {
      final pool = thinkScenarios.where((s) => s.level == retryLevel).toList()..shuffle(rng);
      _levelScenarios[retryLevel] = pool.take(3).toList();
    } else {
      final byLevel = <int, List<ThinkScenario>>{};
      for (final s in thinkScenarios) {
        byLevel.putIfAbsent(s.level, () => []).add(s);
      }
      _levelScenarios = {
        for (int l = 1; l <= 3; l++)
          l: (List.of(byLevel[l]!)..shuffle(rng)).take(3).toList(),
      };
    }
  }

  // ── Game flow ─────────────────────────────────────────────────────────────

  void _startQuestion() {
    final choices = [_current.choiceA, _current.choiceB]..shuffle(math.Random());
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
    audioService.play(choice.isCorrect ? AudioAsset.correct : AudioAsset.incorrect);
    if (!choice.isCorrect) {
      await _shakeController.forward();
      _shakeController.reset();
    }
    await progressProvider.recordSession(
      gameId: GameProgress.gameSocialSituations,
      wasCorrect: choice.isCorrect,
    );
    if (mounted) _feedbackController.forward();
  }

  void _onNext() {
    if (_questionInLevel < 2) {
      setState(() => _questionInLevel++);
      _startQuestion();
    } else {
      _celebrationController.forward(from: 0);
      setState(() => _phase = _Phase.levelResult);
    }
  }

  void _proceedToNextLevel() {
    if (_currentLevel < 3) {
      setState(() {
        _currentLevel++;
        _questionInLevel = 0;
        _levelCorrect = 0;
        _phase = _Phase.levelIntro;
      });
      _celebrationController.reset();
    } else {
      _celebrationController.forward(from: 0);
      setState(() => _phase = _Phase.done);
    }
  }

  void _retryLevel() {
    _buildLevelScenarios(_currentLevel);
    setState(() {
      _questionInLevel = 0;
      _levelCorrect = 0;
      _phase = _Phase.levelIntro;
    });
    _celebrationController.reset();
  }

  // ── Exit dialog ───────────────────────────────────────────────────────────

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Selesai bermain?',
            style: GoogleFonts.baloo2(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark)),
        content: Text('Progresmu hari ini akan tersimpan!',
            style: GoogleFonts.dmSans(fontSize: 14, color: _textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Lanjut Bermain', style: GoogleFonts.dmSans(color: _zoneColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Ya, Keluar',
                style: GoogleFonts.dmSans(color: _errorRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
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
      child: Scaffold(
        backgroundColor: _zoneBg,
        body: SafeArea(
          child: switch (_phase) {
            _Phase.levelIntro   => _buildLevelIntro(),
            _Phase.choosing ||
            _Phase.revealed     => _buildGame(),
            _Phase.levelResult  => _buildLevelResult(),
            _Phase.done         => _buildDoneScreen(),
          },
        ),
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
            children: List.generate(5, (i) {
              if (i.isOdd) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: _textMuted.withValues(alpha: 0.4)),
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
                          : _zoneColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [BoxShadow(color: _zoneColor.withValues(alpha: 0.45), offset: const Offset(0, 4), blurRadius: 8)]
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                      : Text('$level',
                          style: GoogleFonts.baloo2(
                            fontSize: isActive ? 22 : 18,
                            fontWeight: FontWeight.w800,
                            color: isActive || isDone ? Colors.white : _zoneColor,
                          )),
                ),
              );
            }),
          ),

          const SizedBox(height: 4),
          Text('Level $_currentLevel dari 3',
              style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: _textMuted)),

          const Spacer(),

          // Raccoo bobbing
          AnimatedBuilder(
            animation: _raccooFloat,
            builder: (_, child) => Transform.translate(offset: Offset(0, _raccooFloat.value), child: child),
            child: Container(
              width: 148, height: 148,
              decoration: BoxDecoration(
                color: _zoneColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🦝', style: TextStyle(fontSize: 80)),
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
                BoxShadow(color: _zoneShadow, offset: Offset(4, 6), blurRadius: 0),
              ],
            ),
            child: Column(
              children: [
                Text('🎯 Tujuan belajar kita:',
                    style: GoogleFonts.dmSans(
                        fontSize: 14, fontWeight: FontWeight.w600, color: _textMuted)),
                const SizedBox(height: 8),
                Text(goal,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.baloo2(
                        fontSize: 20, fontWeight: FontWeight.w700, color: _textDark, height: 1.4)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Q dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Container(
                width: 10, height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: _zoneColor.withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          const Spacer(),

          _ThinkButton(
            label: 'Mulai Level $_currentLevel!',
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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
                _QuestionBubble(question: card.question),

                const SizedBox(height: 14),

                Text('Pilih jawabanmu:',
                    style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: _textMuted, letterSpacing: 0.4)),

                const SizedBox(height: 8),

                // Choice 0 (posisi diacak tiap soal)
                SlideTransition(
                  position: _choiceASlide,
                  child: _ChoiceCard(
                    choice: _orderedChoices[0],
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
                    state: _choiceCardState(_orderedChoices[1]),
                    onTap: () => _onChoiceTap(_orderedChoices[1]),
                    shakeAnimation: _orderedChoices[1] == _selectedChoice &&
                            !(_selectedChoice?.isCorrect ?? true)
                        ? _shakeAnimation
                        : null,
                  ),
                ),

                // Feedback
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _phase == _Phase.revealed
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SlideTransition(
                            position: _feedbackSlide,
                            child: _FeedbackPanel(
                              choice: _selectedChoice!,
                              onNext: _onNext,
                              isLastQuestion: _questionInLevel >= 2,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
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
          GestureDetector(
            onTap: () async {
              final ok = await _confirmExit();
              if (ok && mounted) context.pop();
            },
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: _zoneShadow, offset: Offset(2, 3), blurRadius: 0)],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: _textDark, size: 26),
            ),
          ),

          const SizedBox(width: 10),

          // Theme pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: style.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: style.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(color: style.accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(_current.theme,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, fontWeight: FontWeight.w700, color: style.accent)),
              ],
            ),
          ),

          const Spacer(),

          // Q progress dots
          Row(
            children: List.generate(3, (i) {
              final isDone = i < _questionInLevel;
              final isActive = i == _questionInLevel;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 22 : 8, height: 8,
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
          Text('${_questionInLevel + 1}/3',
              style: GoogleFonts.baloo2(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _textMuted)),
        ],
      ),
    );
  }

  // ── Choice state ──────────────────────────────────────────────────────────

  _ChoiceState _choiceCardState(ThinkChoice choice) {
    if (_phase == _Phase.choosing) return _ChoiceState.idle;
    if (_selectedChoice == choice) {
      return choice.isCorrect ? _ChoiceState.selectedCorrect : _ChoiceState.selectedWrong;
    }
    return _ChoiceState.dimmed;
  }

  // ── Level Result ──────────────────────────────────────────────────────────

  Widget _buildLevelResult() {
    final passed = _levelCorrect >= 2;
    final isPerfect = _levelCorrect == 3;
    final isLastLevel = _currentLevel == 3;

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
                  color: (passed ? _zoneShadow : const Color(0xFFC85A00)).withValues(alpha: 0.5),
                  offset: const Offset(3, 4), blurRadius: 0,
                ),
              ],
            ),
            child: Text('Level $_currentLevel Selesai!',
                style: GoogleFonts.baloo2(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          ),

          const SizedBox(height: 28),

          // Raccoo
          ScaleTransition(
            scale: _celebrationScale,
            child: AnimatedBuilder(
              animation: _raccooFloat,
              builder: (_, child) =>
                  Transform.translate(offset: Offset(0, _raccooFloat.value), child: child),
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  color: (passed ? _zoneColor : const Color(0xFFFF9A3C)).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(passed ? '🦝🎉' : '🦝💪',
                      style: const TextStyle(fontSize: 64)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            passed
                ? (isPerfect ? 'Sempurna! 🏆' : 'Bagus! 🎉')
                : 'Hampir! Coba lagi ya! 💪',
            style: GoogleFonts.baloo2(
                fontSize: 32, fontWeight: FontWeight.w800, color: _textDark, height: 1.1),
          ),

          const SizedBox(height: 8),

          Text(
            passed
                ? 'Kamu menjawab $_levelCorrect dari 3 soal dengan benar!'
                : 'Kamu menjawab $_levelCorrect dari 3 soal benar.\nRaccoo percaya kamu pasti bisa!',
            textAlign: TextAlign.center,
            style: GoogleFonts.baloo2(
                fontSize: 17, fontWeight: FontWeight.w600, color: _textMuted, height: 1.4),
          ),

          const SizedBox(height: 24),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final earned = i < _levelCorrect;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + i * 150),
                curve: const Cubic(0.34, 1.56, 0.64, 1),
                builder: (_, v, __) => Transform.scale(
                  scale: v,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.star_rounded, size: 56,
                        color: earned ? _gold : _gold.withValues(alpha: 0.22)),
                  ),
                ),
              );
            }),
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
              label: isLastLevel ? 'Lihat Hasil Akhir 🏆' : 'Lanjut ke Level ${_currentLevel + 1} →',
              color: _zoneColor, textColor: Colors.white,
              icon: isLastLevel ? Icons.emoji_events_rounded : Icons.arrow_forward_rounded,
              onTap: _proceedToNextLevel,
            ),
          ] else ...[
            _ThinkButton(
              label: 'Coba Level $_currentLevel Lagi',
              color: const Color(0xFFFF9A3C), textColor: Colors.white,
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
    const total = 9;
    final stars = _totalCorrect >= total ? 3 : _totalCorrect >= 6 ? 2 : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          ScaleTransition(
            scale: _celebrationScale,
            child: AnimatedBuilder(
              animation: _raccooFloat,
              builder: (_, child) =>
                  Transform.translate(offset: Offset(0, _raccooFloat.value), child: child),
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  color: _zoneColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🦝', style: TextStyle(fontSize: 90))),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(stars == 3 ? 'Sempurna! 🏆' : 'Selesai! 🎉',
              style: GoogleFonts.baloo2(
                  fontSize: 36, fontWeight: FontWeight.w800, color: _textDark, height: 1.1)),

          const SizedBox(height: 8),

          Text('Kamu sudah menyelesaikan\nsemua 3 level Raccoo Think!',
              textAlign: TextAlign.center,
              style: GoogleFonts.baloo2(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _textMuted, height: 1.4)),

          const SizedBox(height: 20),

          // Score card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: _zoneShadow, offset: Offset(4, 6), blurRadius: 0)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ScoreStat(label: 'Betul', value: '$_totalCorrect', color: _successGreen, icon: Icons.check_circle_rounded),
                Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
                _ScoreStat(label: 'Total Soal', value: '$total', color: _zoneColor, icon: Icons.forum_rounded),
                Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
                _ScoreStat(label: 'Bintang', value: '$stars', color: _gold, icon: Icons.star_rounded),
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
                    child: Icon(Icons.star_rounded, size: 48,
                        color: i < stars ? _gold : _gold.withValues(alpha: 0.22)),
                  ),
                ),
              );
            }),
          ),

          const Spacer(),

          if (stars < 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Tidak apa-apa! Setiap latihan membuat kamu makin pintar! 💪',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 16, color: _textMuted, height: 1.5)),
            ),

          Row(
            children: [
              Expanded(
                child: _ThinkButton(
                  label: 'Main Lagi',
                  color: Colors.white, textColor: _zoneColor,
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
                  color: _zoneColor, textColor: Colors.white,
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
    final style = _styleOf(scenario.theme);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: style.shadow.withValues(alpha: 0.40), offset: const Offset(4, 7), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        children: [
          // Theme chip
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: style.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: style.accent.withValues(alpha: 0.28)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(color: style.accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(scenario.theme,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, fontWeight: FontWeight.w700, color: style.accent)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Gambar situasi (jika tersedia) atau emoji fallback
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: scenario.imagePath != null
                ? Image.asset(
                    scenario.imagePath!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  )
                : Text(scenario.emoji, style: const TextStyle(fontSize: 72)),
          ),

          const SizedBox(height: 12),

          // Situation label
          Text(scenario.situationLabel,
              style: GoogleFonts.baloo2(
                  fontSize: 18, fontWeight: FontWeight.w700, color: style.accent)),

          const SizedBox(height: 8),

          // Narration
          Text(scenario.situationNarration,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 16, height: 1.55, color: _textDark)),
        ],
      ),
    );
  }
}

class _QuestionBubble extends StatelessWidget {
  final String question;

  const _QuestionBubble({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: _zoneShadow, offset: Offset(3, 5), blurRadius: 0)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _zoneColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🦝', style: TextStyle(fontSize: 24))),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(question,
                style: GoogleFonts.baloo2(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _textDark, height: 1.3)),
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
  final _ChoiceState state;
  final VoidCallback onTap;
  final Animation<double>? shakeAnimation;

  const _ChoiceCard({
    required this.choice,
    required this.state,
    required this.onTap,
    this.shakeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = switch (state) {
      _ChoiceState.selectedCorrect => _successGreen,
      _ChoiceState.selectedWrong   => _errorRed,
      _                            => Colors.transparent,
    };
    final shadowColor = switch (state) {
      _ChoiceState.selectedCorrect => _successGreen.withValues(alpha: 0.45),
      _ChoiceState.selectedWrong   => _errorRed.withValues(alpha: 0.45),
      _                            => Colors.black.withValues(alpha: 0.10),
    };
    final opacity = state == _ChoiceState.dimmed ? 0.38 : 1.0;
    final isInteractive = state == _ChoiceState.idle;

    Widget card = Opacity(
      opacity: opacity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 80),
        decoration: BoxDecoration(
          color: choice.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: borderColor == Colors.transparent ? 0 : 3,
          ),
          boxShadow: [
            BoxShadow(color: shadowColor, offset: const Offset(3, 5), blurRadius: 0),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Gambar jawaban (jika tersedia) atau emoji fallback
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: choice.imagePath != null
                  ? Image.asset(
                      choice.imagePath!,
                      width: 64, height: 64,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(choice.emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
            ),

            const SizedBox(width: 14),

            // Label
            Expanded(
              child: Text(choice.label,
                  style: GoogleFonts.baloo2(
                      fontSize: 17, fontWeight: FontWeight.w700,
                      color: _textDark, height: 1.3)),
            ),

            // Result badge
            if (state == _ChoiceState.selectedCorrect)
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(color: _successGreen, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 20, color: Colors.white),
              ),
            if (state == _ChoiceState.selectedWrong)
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(color: _errorRed, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
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

// ─── Feedback Panel ───────────────────────────────────────────────────────────

class _FeedbackPanel extends StatelessWidget {
  final ThinkChoice choice;
  final VoidCallback onNext;
  final bool isLastQuestion;

  const _FeedbackPanel({
    required this.choice,
    required this.onNext,
    required this.isLastQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = choice.isCorrect;
    final bgColor = isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E7);
    final borderColor = isCorrect ? _successGreen : const Color(0xFFFF9A3C);
    final headerEmoji = isCorrect ? '🌟' : '💭';
    final headerText = isCorrect ? 'Betul!' : 'Yuk pikirkan lagi!';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(color: _zoneShadow.withValues(alpha: 0.25), offset: const Offset(3, 5), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(headerEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(headerText,
                  style: GoogleFonts.baloo2(
                      fontSize: 17, fontWeight: FontWeight.w700,
                      color: isCorrect ? _successGreen : _textDark)),
            ],
          ),

          const SizedBox(height: 8),

          Text(choice.feedback,
              style: GoogleFonts.dmSans(fontSize: 16, height: 1.55, color: _textDark)),

          const SizedBox(height: 14),

          _ThinkButton(
            label: isLastQuestion ? 'Lihat Skor Level →' : 'Lanjut →',
            color: isCorrect ? _zoneColor : const Color(0xFFFF9A3C),
            textColor: Colors.white,
            icon: isLastQuestion ? Icons.bar_chart_rounded : Icons.arrow_forward_rounded,
            onTap: onNext,
          ),
        ],
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
    required this.label, required this.value,
    required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.baloo2(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: GoogleFonts.dmSans(fontSize: 12, color: _textMuted)),
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
    required this.label, required this.color,
    required this.textColor, required this.icon,
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
          border: color == Colors.white ? Border.all(color: _zoneColor, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: _zoneShadow.withValues(alpha: color == Colors.white ? 0.18 : 0.45),
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
                    fontSize: 17, fontWeight: FontWeight.w700, color: textColor)),
          ],
        ),
      ),
    );
  }
}
