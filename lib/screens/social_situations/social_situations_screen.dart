import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/game_progress.dart';
import '../../providers/progress_provider.dart';
import '../../services/audio_service.dart';

// ─── Zone Design Tokens ───────────────────────────────────────────────────────
// Social zone: hijau (#4CAF6E), bg (#F0F9F0), shadow rgba(20,130,70,0.40)

const _zoneColor = Color(0xFF4CAF6E);
const _zoneBg = Color(0xFFF0F9F0);
const _zoneShadow = Color(0xFF1A5E36);
const _textDark = Color(0xFF3D2B1A);
const _textMuted = Color(0xFF8D6E63);
const _successGreen = Color(0xFF388E3C);
const _errorRed = Color(0xFFE53935);
const _gold = Color(0xFFFFD54F);

// ─── Data Model ───────────────────────────────────────────────────────────────

/// Satu pilihan respons dalam skenario sosial.
class ThinkChoice {
  /// Label singkat yang ditampilkan di kartu pilihan.
  final String label;

  /// Ikon placeholder hingga ilustrasi gambar tersedia.
  final IconData icon;

  /// Warna background kartu pilihan.
  final Color cardColor;

  /// true = respons yang tepat secara SEL.
  final bool isCorrect;

  /// Penjelasan edukatif saat pilihan ini dipilih.
  final String feedback;

  const ThinkChoice({
    required this.label,
    required this.icon,
    required this.cardColor,
    required this.isCorrect,
    required this.feedback,
  });
}

/// Satu skenario sosial lengkap untuk "Raccoo Think".
class ThinkScenario {
  /// ID unik untuk tracking dan debugging.
  final String id;

  /// Label singkat situasi — ditampilkan di badge atas ilustrasi.
  final String situationLabel;

  /// Narasi situasi lengkap yang ditampilkan di ilustrasi card.
  final String situationNarration;

  /// Pertanyaan yang diajukan Raccoo ke anak.
  final String question;

  /// Kalimat narasi Raccoo untuk audio (bisa berbeda dari [question]).
  final String raccooSpeech;

  /// Ikon placeholder untuk ilustrasi situasi.
  final IconData illustrationIcon;

  /// Warna tematik kartu ilustrasi situasi.
  final Color illustrationColor;

  /// Selalu tepat 2 pilihan: satu correct, satu incorrect.
  final ThinkChoice choiceA;
  final ThinkChoice choiceB;

  /// Audio narasi — opsional, diputar otomatis saat skenario tampil.
  final AudioAsset? audioAsset;

  const ThinkScenario({
    required this.id,
    required this.situationLabel,
    required this.situationNarration,
    required this.question,
    required this.raccooSpeech,
    required this.illustrationIcon,
    required this.illustrationColor,
    required this.choiceA,
    required this.choiceB,
    this.audioAsset,
  });

  /// Pilihan yang benar.
  ThinkChoice get correctChoice => choiceA.isCorrect ? choiceA : choiceB;
}

// ─── Scenario Data ────────────────────────────────────────────────────────────

/// 6 skenario sosial sehari-hari yang familiar untuk anak TK.
/// Masing-masing fokus pada satu keterampilan SEL yang spesifik.
const List<ThinkScenario> thinkScenarios = [
  // ── 1. Empati: Teman Menangis ─────────────────────────────────────────────
  ThinkScenario(
    id: 'friend_crying',
    situationLabel: 'Teman Menangis',
    situationNarration:
        'Temanmu jatuh dan menangis kesakitan. Dia terlihat sangat sedih dan sendirian.',
    question: 'Apa yang kamu lakukan?',
    raccooSpeech:
        'Temanmu jatuh dan menangis. Apa yang akan Raccoo lakukan? Apa yang kamu lakukan?',
    illustrationIcon: Icons.sentiment_very_dissatisfied_rounded,
    illustrationColor: Color(0xFFBBDEFB),
    choiceA: ThinkChoice(
      label: 'Hibur dan tanya\nkabarnya',
      icon: Icons.favorite_rounded,
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Betul! Menghibur teman yang menangis membuatnya merasa tidak sendirian. '
          'Kamu adalah teman yang baik dan peduli! 💚',
    ),
    choiceB: ThinkChoice(
      label: 'Tinggalkan dan\nterus main',
      icon: Icons.directions_run_rounded,
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Hmm... Kalau kita tinggalkan teman yang sedang sedih, dia akan merasa sendirian. '
          'Yuk belajar menghibur teman — itu tanda kamu peduli! 💙',
    ),
  ),

  // ── 2. Berbagi: Berbagi Mainan ────────────────────────────────────────────
  ThinkScenario(
    id: 'sharing_toy',
    situationLabel: 'Berbagi Mainan',
    situationNarration:
        'Temanmu melihat mainanmu dan ingin ikut bermain bersama kamu.',
    question: 'Apa yang kamu lakukan?',
    raccooSpeech:
        'Temanmu ingin bermain dengan mainanmu. Apa yang akan kamu lakukan?',
    illustrationIcon: Icons.toys_rounded,
    illustrationColor: Color(0xFFFFE0B2),
    choiceA: ThinkChoice(
      label: 'Bermain\nbersama-sama',
      icon: Icons.group_rounded,
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Hebat! Berbagi mainan membuat permainan jadi lebih seru dan temanmu jadi senang. '
          'Berbagi adalah tanda hati yang baik! 🌟',
    ),
    choiceB: ThinkChoice(
      label: 'Tidak mau,\nmainanku sendiri',
      icon: Icons.block_rounded,
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Wajar kalau kadang kita ingin mainan kita sendiri. '
          'Tapi coba ingat — berbagi bisa membuat teman senang dan permainan makin seru! 🎮',
    ),
  ),

  // ── 3. Sabar: Menunggu Giliran ────────────────────────────────────────────
  ThinkScenario(
    id: 'waiting_turn',
    situationLabel: 'Menunggu Giliran',
    situationNarration:
        'Di taman ada perosotan seru! Tapi semua anak sedang antri dengan tertib.',
    question: 'Apa yang kamu lakukan?',
    raccooSpeech:
        'Banyak anak antri di perosotan. Giliran kamu masih lama. Apa yang kamu lakukan?',
    illustrationIcon: Icons.sports_gymnastics_rounded,
    illustrationColor: Color(0xFFE1BEE7),
    choiceA: ThinkChoice(
      label: 'Antri dengan\nsabar',
      icon: Icons.people_rounded,
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Keren! Antri dengan sabar adalah hal yang adil. '
          'Semua orang mendapat giliran yang sama kalau kita tertib! ⭐',
    ),
    choiceB: ThinkChoice(
      label: 'Langsung maju\nke depan',
      icon: Icons.fast_forward_rounded,
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Menyerobot antrian bisa membuat teman lain kesal dan sedih. '
          'Menunggu giliran itu adil untuk semua orang — yuk belajar bersabar! ⏳',
    ),
  ),

  // ── 4. Menyambut: Teman Baru ──────────────────────────────────────────────
  ThinkScenario(
    id: 'new_friend',
    situationLabel: 'Teman Baru',
    situationNarration:
        'Ada teman baru di kelasmu. Dia berdiri sendirian di sudut dan kelihatan kesepian.',
    question: 'Apa yang kamu lakukan?',
    raccooSpeech:
        'Ada teman baru yang sendirian dan kelihatan kesepian. Apa yang kamu lakukan?',
    illustrationIcon: Icons.person_add_rounded,
    illustrationColor: Color(0xFFB2EBF2),
    choiceA: ThinkChoice(
      label: 'Sapa dan ajak\nbermain',
      icon: Icons.waving_hand_rounded,
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Luar biasa! Menyapa teman baru membuatnya merasa diterima dan tidak kesepian lagi. '
          'Kamu pasti bisa jadi teman yang menyenangkan! 🤝',
    ),
    choiceB: ThinkChoice(
      label: 'Tidak peduli,\nterus main sendiri',
      icon: Icons.person_rounded,
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Bayangkan kalau kamu yang sendirian di tempat baru — pasti ingin disapa, kan? '
          'Yuk berani menyapa teman baru, kamu bisa bikin dia bahagia! 👋',
    ),
  ),

  // ── 5. Konflik: Berebut Mainan ────────────────────────────────────────────
  ThinkScenario(
    id: 'toy_conflict',
    situationLabel: 'Berebut Mainan',
    situationNarration:
        'Kamu dan temanmu sama-sama mau mainan yang sama persis. Keduanya ingin memakainya sekarang.',
    question: 'Apa yang kamu lakukan?',
    raccooSpeech:
        'Kamu dan temanmu mau mainan yang sama. Apa yang kamu lakukan agar tidak bertengkar?',
    illustrationIcon: Icons.sports_esports_rounded,
    illustrationColor: Color(0xFFFFE0B2),
    choiceA: ThinkChoice(
      label: 'Bicara baik-baik\ndan gantian',
      icon: Icons.handshake_rounded,
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Pintar sekali! Bicara baik-baik dan bergantian adalah cara yang adil dan damai. '
          'Dengan begini, semua orang bisa senang! 🕊️',
    ),
    choiceB: ThinkChoice(
      label: 'Rebut\nmainannya',
      icon: Icons.pan_tool_rounded,
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Merebut mainan bisa menyakiti teman dan membuatnya menangis. '
          'Lebih baik bicara baik-baik agar semua bisa bermain dan tetap berteman! 💬',
    ),
  ),

  // ── 6. Menolong: Teman Kesulitan ─────────────────────────────────────────
  ThinkScenario(
    id: 'helping_friend',
    situationLabel: 'Teman Butuh Bantuan',
    situationNarration:
        'Temanmu kesulitan membawa tumpukan buku yang sangat berat dan hampir jatuh.',
    question: 'Apa yang kamu lakukan?',
    raccooSpeech:
        'Temanmu kesulitan membawa buku yang berat. Apa yang kamu lakukan?',
    illustrationIcon: Icons.menu_book_rounded,
    illustrationColor: Color(0xFFDCEDC8),
    choiceA: ThinkChoice(
      label: 'Tawarkan\nbantuan',
      icon: Icons.volunteer_activism_rounded,
      cardColor: Color(0xFFC8E6C9),
      isCorrect: true,
      feedback:
          'Wah, kamu baik sekali! Menawarkan bantuan membuat teman merasa diperhatikan dan tidak sendirian. '
          'Itu tanda kamu adalah teman sejati! 💪',
    ),
    choiceB: ThinkChoice(
      label: 'Biarkan saja,\nbukan urusanku',
      icon: Icons.do_not_disturb_rounded,
      cardColor: Color(0xFFFFCDD2),
      isCorrect: false,
      feedback:
          'Kalau kita melihat teman kesulitan dan kita bisa bantu, sebaiknya kita bantu. '
          'Membantu teman adalah tanda kita saling peduli! 🌱',
    ),
  ),
];

// ─── Screen State ─────────────────────────────────────────────────────────────

enum _Phase {
  /// Menampilkan skenario + 2 pilihan. Anak belum memilih.
  choosing,

  /// Anak sudah memilih — feedback ditampilkan.
  revealed,

  /// Semua skenario selesai.
  done,
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

/// "Raccoo Think" — pembelajaran respons sosial interaktif.
///
/// Alur satu ronde:
///   1. Tampilkan kartu ilustrasi situasi + narasi Raccoo (audio opsional)
///   2. Anak memilih salah satu dari 2 kartu respons
///   3. Feedback langsung muncul (edukatif, suportif)
///   4. Tombol "Lanjut" → ronde berikutnya
///
/// Setelah semua skenario → layar selesai + pencatatan progres.
class SocialSituationsScreen extends StatefulWidget {
  const SocialSituationsScreen({super.key});

  @override
  State<SocialSituationsScreen> createState() => _SocialSituationsScreenState();
}

class _SocialSituationsScreenState extends State<SocialSituationsScreen>
    with TickerProviderStateMixin {
  // ── Session State ────────────────────────────────────────────────────────

  _Phase _phase = _Phase.choosing;
  late List<ThinkScenario> _shuffledScenarios;
  int _scenarioIndex = 0;

  ThinkScenario get _current => _shuffledScenarios[_scenarioIndex];

  /// Pilihan yang ditekan anak. null = belum memilih.
  ThinkChoice? _selectedChoice;

  int _correctCount = 0;

  // ── Animations ───────────────────────────────────────────────────────────

  late AnimationController _illustrationController;
  late AnimationController _choiceEntranceController;
  late AnimationController _feedbackController;
  late AnimationController _raccooController;
  late AnimationController _shakeController;

  late Animation<Offset> _illustrationSlide;
  late Animation<Offset> _choiceASlide;
  late Animation<Offset> _choiceBSlide;
  late Animation<Offset> _feedbackSlide;
  late Animation<double> _raccooFloat;
  late Animation<double> _shakeAnimation;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Acak urutan skenario setiap sesi
    _shuffledScenarios = List<ThinkScenario>.from(thinkScenarios)
      ..shuffle(math.Random());

    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _illustrationSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _illustrationController,
      curve: const Cubic(0.34, 1.56, 0.64, 1),
    ));

    _choiceEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _choiceASlide = Tween<Offset>(
      begin: const Offset(-0.4, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _choiceEntranceController,
      curve: const Interval(0, 0.7, curve: Cubic(0.34, 1.56, 0.64, 1)),
    ));
    _choiceBSlide = Tween<Offset>(
      begin: const Offset(0.4, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _choiceEntranceController,
      curve: const Interval(0.15, 0.85, curve: Cubic(0.34, 1.56, 0.64, 1)),
    ));

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _feedbackSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _feedbackController,
      curve: const Cubic(0.34, 1.56, 0.64, 1),
    ));

    _raccooController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _raccooFloat = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _raccooController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _startRound();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioService>().play(AudioAsset.instructionSocialSituations);
    });
  }

  @override
  void dispose() {
    _illustrationController.dispose();
    _choiceEntranceController.dispose();
    _feedbackController.dispose();
    _raccooController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ── Round Management ─────────────────────────────────────────────────────

  void _startRound() {
    setState(() {
      _phase = _Phase.choosing;
      _selectedChoice = null;
    });
    _illustrationController.forward(from: 0);
    _choiceEntranceController.forward(from: 0);
    _feedbackController.reset();

    // Putar audio narasi skenario jika tersedia
    final audio = _current.audioAsset;
    if (audio != null) {
      context.read<AudioService>().play(audio);
    }
  }

  Future<void> _onChoiceTap(ThinkChoice choice) async {
    if (_phase != _Phase.choosing) return;

    // Capture providers sebelum async gap
    final progressProvider = context.read<ProgressProvider>();
    final audioService = context.read<AudioService>();

    setState(() {
      _selectedChoice = choice;
      _phase = _Phase.revealed;
      if (choice.isCorrect) _correctCount++;
    });

    // Audio feedback
    audioService.play(
      choice.isCorrect ? AudioAsset.correct : AudioAsset.incorrect,
    );

    // Shake animation untuk pilihan salah
    if (!choice.isCorrect) {
      await _shakeController.forward();
      _shakeController.reset();
    }

    // Simpan rekam sesi
    await progressProvider.recordSession(
      gameId: GameProgress.gameSocialSituations,
      wasCorrect: choice.isCorrect,
    );

    // Slide feedback panel ke atas
    if (mounted) _feedbackController.forward();
  }

  void _nextScenario() {
    if (_scenarioIndex >= _shuffledScenarios.length - 1) {
      setState(() => _phase = _Phase.done);
      _illustrationController.forward(from: 0);
    } else {
      setState(() => _scenarioIndex++);
      _startRound();
    }
  }

  // ── Exit Dialog ──────────────────────────────────────────────────────────

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Selesai bermain?',
          style: GoogleFonts.baloo2(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        content: Text(
          'Progresmu hari ini akan tersimpan!',
          style: GoogleFonts.dmSans(fontSize: 14, color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Lanjut Bermain',
              style: GoogleFonts.dmSans(color: _zoneColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Ya, Keluar',
              style: GoogleFonts.dmSans(
                color: _errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
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
          child: _phase == _Phase.done ? _buildDoneScreen() : _buildGame(),
        ),
      ),
    );
  }

  // ── Game Layout ───────────────────────────────────────────────────────────

  Widget _buildGame() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kartu Ilustrasi Situasi
                SlideTransition(
                  position: _illustrationSlide,
                  child: _SituationCard(scenario: _current),
                ),

                const SizedBox(height: 12),

                // Pertanyaan Raccoo
                _QuestionBubble(
                  question: _current.question,
                  onAudioTap: () {
                    final audio = _current.audioAsset;
                    if (audio != null) {
                      context.read<AudioService>().play(audio);
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Label pilihan
                Text(
                  'Pilih responmu:',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // 2 Kartu Pilihan
                Row(
                  children: [
                    Expanded(
                      child: SlideTransition(
                        position: _choiceASlide,
                        child: _ChoiceCard(
                          choice: _current.choiceA,
                          state: _choiceCardState(_current.choiceA),
                          onTap: () => _onChoiceTap(_current.choiceA),
                          shakeAnimation: _current.choiceA ==
                                      _selectedChoice &&
                                  !(_selectedChoice?.isCorrect ?? true)
                              ? _shakeAnimation
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SlideTransition(
                        position: _choiceBSlide,
                        child: _ChoiceCard(
                          choice: _current.choiceB,
                          state: _choiceCardState(_current.choiceB),
                          onTap: () => _onChoiceTap(_current.choiceB),
                          shakeAnimation: _current.choiceB ==
                                      _selectedChoice &&
                                  !(_selectedChoice?.isCorrect ?? true)
                              ? _shakeAnimation
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),

                // Feedback panel — slide muncul setelah memilih
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
                              correctChoice: _current.correctChoice,
                              onNext: _nextScenario,
                              isLastScenario: _scenarioIndex >=
                                  _shuffledScenarios.length - 1,
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

  // ── Top Bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final total = _shuffledScenarios.length;
    final current = _scenarioIndex + 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          // Tombol kembali
          GestureDetector(
            onTap: () async {
              final shouldExit = await _confirmExit();
              if (shouldExit && mounted) context.pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: _zoneShadow,
                    offset: Offset(2, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _textDark,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Title
          Text(
            'Raccoo Think',
            style: GoogleFonts.baloo2(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),

          const Spacer(),

          // Progress dots
          Row(
            children: List.generate(total, (i) {
              final isDone = i < _scenarioIndex;
              final isActive = i == _scenarioIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 20 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isDone
                      ? _successGreen
                      : isActive
                          ? _zoneColor
                          : _zoneColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),

          const SizedBox(width: 8),
          Text(
            '$current/$total',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Choice Card State ────────────────────────────────────────────────────

  _ChoiceState _choiceCardState(ThinkChoice choice) {
    if (_phase == _Phase.choosing) return _ChoiceState.idle;
    if (_selectedChoice == choice) {
      return choice.isCorrect
          ? _ChoiceState.selectedCorrect
          : _ChoiceState.selectedWrong;
    }
    // Pilihan yang tidak dipilih tapi benar — highlight saat jawaban salah
    if (choice.isCorrect && _selectedChoice?.isCorrect == false) {
      return _ChoiceState.revealedCorrect;
    }
    return _ChoiceState.dimmed;
  }

  // ── Done Screen ───────────────────────────────────────────────────────────

  Widget _buildDoneScreen() {
    final total = _shuffledScenarios.length;
    final isPerfect = _correctCount == total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Raccoo celebration
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
                color: _zoneColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sentiment_very_satisfied_rounded,
                size: 110,
                color: _zoneColor,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            isPerfect ? 'Sempurna! 🏆' : 'Selesai! 🎉',
            style: GoogleFonts.baloo2(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: _textDark,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Kamu sudah berlatih $_correctCount dari $total\nrespons sosial dengan benar!',
            textAlign: TextAlign.center,
            style: GoogleFonts.baloo2(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textMuted,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // Score card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: _zoneShadow,
                  offset: Offset(4, 6),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ScoreStat(
                  label: 'Betul',
                  value: '$_correctCount',
                  color: _successGreen,
                  icon: Icons.check_circle_rounded,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFFE0E0E0),
                ),
                _ScoreStat(
                  label: 'Skenario',
                  value: '$total',
                  color: _zoneColor,
                  icon: Icons.forum_rounded,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFFE0E0E0),
                ),
                _ScoreStat(
                  label: 'Bintang',
                  value: _correctCount >= total
                      ? '3'
                      : _correctCount >= (total * 0.5).ceil()
                          ? '2'
                          : '1',
                  color: _gold,
                  icon: Icons.star_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stars animation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final earned = i <
                  (_correctCount >= total
                      ? 3
                      : _correctCount >= (total * 0.5).ceil()
                          ? 2
                          : 1);
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 500 + i * 180),
                curve: const Cubic(0.34, 1.56, 0.64, 1),
                builder: (context, v, _) => Transform.scale(
                  scale: v,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.star_rounded,
                      size: 48,
                      color: earned
                          ? _gold
                          : _gold.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              );
            }),
          ),

          const Spacer(),

          // Motivational message
          if (!isPerfect)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Tidak apa-apa! Setiap latihan membuat kamu makin pintar! 💪',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: _textMuted,
                  height: 1.5,
                ),
              ),
            ),

          // Buttons
          Row(
            children: [
              Expanded(
                child: _ThinkButton(
                  label: 'Main Lagi',
                  color: Colors.white,
                  textColor: _zoneColor,
                  icon: Icons.replay_rounded,
                  onTap: () {
                    setState(() {
                      _shuffledScenarios =
                          List<ThinkScenario>.from(thinkScenarios)
                            ..shuffle(math.Random());
                      _scenarioIndex = 0;
                      _correctCount = 0;
                    });
                    _startRound();
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

/// Kartu besar yang menampilkan ilustrasi + narasi situasi sosial.
class _SituationCard extends StatelessWidget {
  final ThinkScenario scenario;
  const _SituationCard({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scenario.illustrationColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: _zoneShadow,
            offset: Offset(4, 7),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Badge situasi
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                scenario.situationLabel,
                style: GoogleFonts.baloo2(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Ilustrasi placeholder
          // TODO: ganti dengan Image.asset(scenario.imageAsset) saat aset tersedia
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: Icon(
              scenario.illustrationIcon,
              size: 64,
              color: _zoneShadow.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 12),

          // Narasi situasi
          Text(
            scenario.situationNarration,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              height: 1.55,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Speech bubble Raccoo yang memuat pertanyaan + tombol audio.
class _QuestionBubble extends StatelessWidget {
  final String question;
  final VoidCallback onAudioTap;

  const _QuestionBubble({
    required this.question,
    required this.onAudioTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: _zoneShadow,
            offset: Offset(3, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Raccoo icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _zoneColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sentiment_satisfied_alt_rounded,
              size: 26,
              color: _zoneColor,
            ),
          ),

          const SizedBox(width: 12),

          // Question text
          Expanded(
            child: Text(
              question,
              style: GoogleFonts.baloo2(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textDark,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Audio button
          GestureDetector(
            onTap: onAudioTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _zoneColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                size: 22,
                color: _zoneColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Choice Card ──────────────────────────────────────────────────────────────

enum _ChoiceState {
  idle,
  selectedCorrect,
  selectedWrong,
  revealedCorrect, // bukan yang dipilih, tapi ini yang benar
  dimmed,
}

/// Kartu pilihan respons sosial — ukuran besar, mudah disentuh anak.
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
      _ChoiceState.selectedWrong => _errorRed,
      _ChoiceState.revealedCorrect => _successGreen,
      _ => Colors.transparent,
    };

    final shadowColor = switch (state) {
      _ChoiceState.selectedCorrect =>
        _successGreen.withValues(alpha: 0.5),
      _ChoiceState.selectedWrong => _errorRed.withValues(alpha: 0.5),
      _ => _zoneShadow.withValues(alpha: 0.4),
    };

    final opacity = state == _ChoiceState.dimmed ? 0.38 : 1.0;
    final isInteractive = state == _ChoiceState.idle;

    Widget card = Opacity(
      opacity: opacity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          color: choice.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: borderColor == Colors.transparent ? 0 : 3,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(4, 6),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Stack(
          children: [
            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    choice.icon,
                    size: 40,
                    color: _textDark.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  choice.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.baloo2(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    height: 1.3,
                  ),
                ),
              ],
            ),

            // Result badge (✓ atau ✗)
            if (state == _ChoiceState.selectedCorrect ||
                state == _ChoiceState.revealedCorrect)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _successGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            if (state == _ChoiceState.selectedWrong)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _errorRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Shake wrapper untuk pilihan salah
    if (shakeAnimation != null) {
      card = AnimatedBuilder(
        animation: shakeAnimation!,
        builder: (context, child) {
          final offset = math.sin(shakeAnimation!.value * math.pi * 4) * 8;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: card,
      );
    }

    return GestureDetector(
      onTap: isInteractive ? onTap : null,
      child: card,
    );
  }
}

// ─── Feedback Panel ───────────────────────────────────────────────────────────

/// Panel edukatif yang muncul setelah anak memilih jawaban.
///
/// Menampilkan:
/// - Ikon hasil (✓ / 💡)
/// - Penjelasan singkat mengapa pilihan itu tepat/tidak
/// - Tombol "Lanjut"
class _FeedbackPanel extends StatelessWidget {
  final ThinkChoice choice;
  final ThinkChoice correctChoice;
  final VoidCallback onNext;
  final bool isLastScenario;

  const _FeedbackPanel({
    required this.choice,
    required this.correctChoice,
    required this.onNext,
    required this.isLastScenario,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = choice.isCorrect;
    final bgColor =
        isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E7);
    final borderColor = isCorrect ? _successGreen : const Color(0xFFFF9A3C);
    final iconColor = isCorrect ? _successGreen : const Color(0xFFFF9A3C);
    final icon = isCorrect ? Icons.check_circle_rounded : Icons.lightbulb_rounded;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: _zoneShadow.withValues(alpha: 0.3),
            offset: const Offset(3, 5),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Betul! 🌟' : 'Yuk belajar bersama! 💡',
                style: GoogleFonts.baloo2(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isCorrect ? _successGreen : _textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Feedback teks (dari pilihan yang dipilih)
          Text(
            choice.feedback,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.55,
              color: _textDark,
            ),
          ),

          // Jika salah, tunjukkan juga jawaban yang benar
          if (!isCorrect) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _successGreen.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: _successGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Respons yang tepat: "${correctChoice.label.replaceAll('\n', ' ')}"',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _successGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Tombol lanjut
          _ThinkButton(
            label: isLastScenario ? 'Lihat Hasil 🏆' : 'Lanjut →',
            color: _zoneColor,
            textColor: Colors.white,
            icon: isLastScenario
                ? Icons.emoji_events_rounded
                : Icons.arrow_forward_rounded,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

/// Statistik di layar selesai.
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
        Text(
          value,
          style: GoogleFonts.baloo2(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: _textMuted,
          ),
        ),
      ],
    );
  }
}

/// Tombol aksi Think — bisa solid atau outline.
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
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: color == Colors.white
              ? Border.all(color: _zoneColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: _zoneShadow.withValues(alpha: color == Colors.white ? 0.2 : 0.5),
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
            Text(
              label,
              style: GoogleFonts.baloo2(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
