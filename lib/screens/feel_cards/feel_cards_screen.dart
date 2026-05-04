import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../models/emotion.dart';
import '../../models/game_progress.dart';
import '../../providers/progress_provider.dart';
import '../../services/audio_service.dart';

// ─── Data model ──────────────────────────────────────────────────────────────

class _EmotionCardData {
  final Emotion emotion;
  final Color cardColor;
  final Color shadowColor;
  final IconData icon;
  final String emoji;
  final String description;
  final String raccooSpeech;
  final String whenExamples;
  final AudioAsset? audioAsset;
  final String? videoPath;

  const _EmotionCardData({
    required this.emotion,
    required this.cardColor,
    required this.shadowColor,
    required this.icon,
    required this.emoji,
    required this.description,
    required this.raccooSpeech,
    required this.whenExamples,
    this.audioAsset,
    this.videoPath,
  });
}

const List<_EmotionCardData> _cards = [
  _EmotionCardData(
    emotion: Emotion.happy,
    cardColor: Color(0xFFFFE082),
    shadowColor: Color(0xFFC85A00),
    icon: Icons.sentiment_very_satisfied_rounded,
    emoji: '😊',
    description: 'Senang itu rasanya mau loncat kegirangan!',
    raccooSpeech:
    'Ini namanya SENANG!\nRasanya hangat di dada dan mau loncat-loncat terus.\nRaccoo suka banget kalau lagi senang!',
    whenExamples: 'Dapat hadiah · Main bareng teman · Makan es krim',
    audioAsset: AudioAsset.emotionHappy,
    videoPath: 'assets/video/raccoo_happy.mp4',
  ),
  _EmotionCardData(
    emotion: Emotion.sad,
    cardColor: Color(0xFFBBDEFB),
    shadowColor: Color(0xFF1464A0),
    icon: Icons.sentiment_very_dissatisfied_rounded,
    emoji: '😢',
    description: 'Sedih itu rasanya dada berat dan pengen nangis.',
    raccooSpeech:
    'Ini namanya SEDIH.\nRasanya dada jadi berat dan mata mau nangis.\nTidak apa-apa lho kalau kamu nangis!',
    whenExamples: 'Balon terbang pergi · Teman pulang duluan · Mainan rusak',
    audioAsset: AudioAsset.emotionSad,
    videoPath: 'assets/video/raccoo_sad.mp4',
  ),
  _EmotionCardData(
    emotion: Emotion.angry,
    cardColor: Color(0xFFFFCDD2),
    shadowColor: Color(0xFF9F1E1B),
    icon: Icons.mood_bad_rounded,
    emoji: '😠',
    description: 'Marah itu rasanya panas di dalam.',
    raccooSpeech:
    'Ini namanya MARAH.\nRasanya panas di dalam dan ingin berteriak.\nRaccoo juga pernah marah kok!',
    whenExamples: 'Mainan diambil · Tidak didengarkan · Antrian diserobot',
    audioAsset: AudioAsset.emotionAngry,
    videoPath: 'assets/video/raccoo_angry.mp4',
  ),
  _EmotionCardData(
    emotion: Emotion.scared,
    cardColor: Color(0xFFE1BEE7),
    shadowColor: Color(0xFF4D2A80),
    icon: Icons.sentiment_very_dissatisfied_rounded,
    emoji: '😨',
    description: 'Takut itu rasanya jantung dag dig dug.',
    raccooSpeech:
    'Ini namanya TAKUT.\nRasanya jantung dag dig dug dan badan gemetar.\nSemua orang pernah takut, termasuk Raccoo!',
    whenExamples: 'Suara petir · Gelap sendiri · Hewan besar yang baru dikenal',
    audioAsset: AudioAsset.emotionScared,
    videoPath: 'assets/video/raccoo_scare.mp4',
  ),
  _EmotionCardData(
    emotion: Emotion.surprised,
    cardColor: Color(0xFFB2EBF2),
    shadowColor: Color(0xFF006064),
    icon: Icons.sentiment_neutral_rounded,
    emoji: '😲',
    description: 'Terkejut itu rasanya tiba-tiba — HAH!',
    raccooSpeech:
    'Ini namanya TERKEJUT.\nRasanya tiba-tiba — HAH! Mata langsung membelalak.\nBisa terkejut yang senang, bisa juga yang kaget!',
    whenExamples:
    'Teman mengagetkan · Dapat kejutan · Lihat sesuatu tak terduga',
    audioAsset: AudioAsset.emotionSurprised,
    videoPath: 'assets/video/raccoo_shock.mp4',
  ),
  _EmotionCardData(
    emotion: Emotion.disgust,
    cardColor: Color(0xFFC8E6C9),
    shadowColor: Color(0xFF33691E),
    icon: Icons.sick_rounded,
    emoji: '🤢',
    description: 'Jijik itu rasanya hidung berkerut — eugh!',
    raccooSpeech:
    'Ini namanya JIJIK.\nRasanya hidung berkerut dan perut tidak enak.\nRaccoo paling jijik sama makanan berjamur, hiii!',
    whenExamples: 'Bau tidak sedap · Makanan busuk · Sesuatu yang kotor',
    audioAsset: AudioAsset.emotionDisgust,
    videoPath: 'assets/video/raccoo_disgust.mp4',
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class FeelCardsScreen extends StatefulWidget {
  const FeelCardsScreen({super.key});

  @override
  State<FeelCardsScreen> createState() => _FeelCardsScreenState();
}

enum _ScreenPhase { intro, cards, done }

class _FeelCardsScreenState extends State<FeelCardsScreen>
    with TickerProviderStateMixin {
  _ScreenPhase _phase = _ScreenPhase.intro;
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isFlipping = false;

  late AudioService _audio;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  late AnimationController _raccooController;
  late Animation<double> _raccooAnimation;

  late AnimationController _entranceController;
  late Animation<Offset> _entranceAnimation;

  late AnimationController _celebrationController;
  late Animation<double> _celebrationAnimation;

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _audio.playBg(AudioAsset.bgPlay);
    });

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _raccooController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _raccooAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _raccooController, curve: Curves.easeInOut),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _entranceAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Cubic(0.34, 1.56, 0.64, 1),
      ),
    );

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _celebrationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Cubic(0.34, 1.56, 0.64, 1),
      ),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _raccooController.dispose();
    _entranceController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _startCards() {
    setState(() {
      _phase = _ScreenPhase.cards;
      _currentIndex = 0;
      _isFlipped = false;
    });
    _flipController.reset();
    _entranceController.forward(from: 0);
  }

  Future<void> _flipCard() async {
    if (_isFlipping || _isFlipped) return;
    setState(() => _isFlipping = true);
    await _flipController.forward();
    setState(() {
      _isFlipped = true;
      _isFlipping = false;
    });
    if (mounted) {
      final audio = _cards[_currentIndex].audioAsset;
      if (audio != null) {
        context.read<AudioService>().play(audio);
      }
    }
  }

  Future<void> _nextCard() async {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
      _flipController.reset();
      _entranceController.forward(from: 0);
    } else {
      await context.read<ProgressProvider>().recordSession(
        gameId: GameProgress.gameFeelCards,
        wasCorrect: true,
      );
      setState(() => _phase = _ScreenPhase.done);
      _celebrationController.forward(from: 0);
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
      });
      _flipController.reset();
      _entranceAnimation = Tween<Offset>(
        begin: const Offset(-1.2, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: const Cubic(0.34, 1.56, 0.64, 1),
        ),
      );
      _entranceController.forward(from: 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _entranceAnimation = Tween<Offset>(
          begin: const Offset(1.2, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Cubic(0.34, 1.56, 0.64, 1),
          ),
        );
      });
    }
  }

  void _replayAudio() {
    final audio = _cards[_currentIndex].audioAsset;
    if (audio != null) {
      context.read<AudioService>().play(audio);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: switch (_phase) {
          _ScreenPhase.intro => _buildIntro(),
          _ScreenPhase.cards => _buildCards(),
          _ScreenPhase.done => _buildDone(),
        },
      ),
    );
  }

  // ── Intro Screen ──────────────────────────────────────────────────────────

  Widget _buildIntro() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/background/bg_racoo_feels.png',
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Row(
                  children: [
                    _Button(
                      img: 'assets/images/ui/ic_left_feel.png',
                      width: 64,
                      height: 64,
                      onTap: () {
                        _audio.play(AudioAsset.normalClick);
                        context.pop();
                      },
                    ),
                    const Spacer(),
                    Text(
                      'Feel Cards',
                      style: GoogleFonts.baloo2(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D2B1A),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              const Spacer(),

              AnimatedBuilder(
                animation: _raccooAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _raccooAnimation.value),
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
                      'assets/images/characters/racoo_avatar_green.png',
                      width: 160,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const _SpeechBubble(
                text:
                'Hei! Yuk kenalan sama\nperasaan-perasaan bareng Raccoo!\nAda 6 teman baru nih!',
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _cards.length,
                      (i) => Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9A3C).withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              _Button(
                width: screenWidth,
                height: 150,
                img: 'assets/images/ui/button_mulai.png',
                onTap: () {
                  _audio.play(AudioAsset.normalClick);
                  _startCards();
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  // ── Cards Screen ──────────────────────────────────────────────────────────

  Widget _buildCards() {
    final card = _cards[_currentIndex];

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            width: 64,
            height: 64,
            'assets/images/background/bg_racoo_feels.png',
            fit: BoxFit.cover,
          ),
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _Button(
                    img: 'assets/images/ui/ic_left_feel.png',
                    width: 64,
                    height: 64,
                    onTap: () {
                      _audio.play(AudioAsset.normalClick);
                      _audio.stop();
                      context.pop();
                    },
                  ),
                  const Spacer(),
                  Text(
                    '${_currentIndex + 1} dari ${_cards.length}',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_cards.length, (i) {
                  final isActive = i == _currentIndex;
                  final isDone = i < _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isActive ? 24 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF57C00E)
                          : isActive
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFFFFFFFF).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: SlideTransition(
                  position: _entranceAnimation,
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity == null) return;
                      if (details.primaryVelocity! < -300 && _isFlipped) {
                        _nextCard();
                      } else if (details.primaryVelocity! > 300) {
                        _prevCard();
                      }
                    },
                    child: _isFlipped
                        ? _CardBack(
                      card: card,
                      onReplayAudio: _replayAudio,
                      flipAnimation: _flipAnimation,
                    )
                        : _CardFront(
                      card: card,
                      onTap: () {
                        _audio.play(AudioAsset.normalClick);
                        _flipCard();
                      },
                      flipAnimation: _flipAnimation,
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    _Button(
                      width: 64,
                      height: 64,
                      img: 'assets/images/ui/ic_left_feel.png',
                      onTap: () {
                        _audio.play(AudioAsset.normalClick);
                        _prevCard();
                      },
                    )
                  else
                    const SizedBox(width: 56),

                  const Spacer(),

                  if (!_isFlipped)
                    Text(
                      'Ketuk kartu untuk membuka!',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        color: const Color(0xFFFFFFFF),
                      ),
                    )
                  else
                    Text(
                      _currentIndex < _cards.length - 1
                          ? 'Geser → untuk lanjut'
                          : 'Kamu sudah lihat semuanya!',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),

                  const Spacer(),

                  if (_isFlipped)
                    _Button(
                      width: 64,
                      height: 64,
                      img: 'assets/images/ui/ic_right_feel.png',
                      onTap: () {
                        _audio.play(AudioAsset.normalClick);
                        _nextCard();
                      },
                    )
                  else
                    const SizedBox(width: 56),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Done Screen ───────────────────────────────────────────────────────────

  Widget _buildDone() {
    return Stack(
      children: [
        // background image
        Positioned.fill(
          child: Image.asset(
            'assets/images/background/bg_success_racoo_feels.png',
            fit: BoxFit.cover,
          ),
        ),

        // konten utama
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                ScaleTransition(
                  scale: _celebrationAnimation,
                  child: AnimatedBuilder(
                    animation: _raccooAnimation,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _raccooAnimation.value),
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
                          'assets/images/characters/racoo_avatar_blue.png',
                          width: 160,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Hore! 🎉',
                  style: GoogleFonts.baloo2(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3D2B1A),
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Kamu sudah kenal semua\nteman perasaan Raccoo!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.baloo2(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D2B1A),
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _cards.map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: c.cardColor,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: c.shadowColor.withValues(alpha: 0.4),
                            offset: const Offset(2, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        '${c.emoji} ${c.emotion.labelId}',
                        style: GoogleFonts.baloo2(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3D2B1A),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                Text(
                  'Kamu luar biasa!',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: const Color(0xFF8D6E63),
                  ),
                ),

                const Spacer(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                        (i) => TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400 + i * 150),
                      curve: const Cubic(0.34, 1.56, 0.64, 1),
                      builder: (context, v, _) => Transform.scale(
                        scale: v,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.star_rounded,
                            size: 48,
                            color: Color(0xFFFFD54F),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: _SecondaryButton(
                        label: 'Lihat Lagi',
                        icon: Icons.replay_rounded,
                        onTap: () {
                          _audio.play(AudioAsset.normalClick);
                          setState(() {
                            _phase = _ScreenPhase.cards;
                            _currentIndex = 0;
                            _isFlipped = false;
                          });
                          _flipController.reset();
                          _entranceController.forward(from: 0);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PrimaryButton(
                        label: 'Selesai',
                        onTap: () {
                          _audio.play(AudioAsset.normalClick);
                          context.pop();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Card Front ───────────────────────────────────────────────────────────────

class _CardFront extends StatelessWidget {
  final _EmotionCardData card;
  final VoidCallback onTap;
  final Animation<double> flipAnimation;

  const _CardFront({
    required this.card,
    required this.onTap,
    required this.flipAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flipAnimation,
      builder: (context, child) {
        final angle = flipAnimation.value * math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: Opacity(
            opacity: (1 - flipAnimation.value * 2).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE0B2),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFC85A00),
                offset: Offset(5, 8),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9A3C).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/characters/racoo_avatar_questioning.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ketuk untuk membuka!',
                style: GoogleFonts.baloo2(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3D2B1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Siapa ya teman perasaan kita hari ini?',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: const Color(0xFF8D6E63),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card Back ────────────────────────────────────────────────────────────────

class _CardBack extends StatefulWidget {
  final _EmotionCardData card;
  final VoidCallback onReplayAudio;
  final Animation<double> flipAnimation;

  const _CardBack({
    required this.card,
    required this.onReplayAudio,
    required this.flipAnimation,
  });

  @override
  State<_CardBack> createState() => _CardBackState();
}

class _CardBackState extends State<_CardBack> {
  VideoPlayerController? _videoController;
  bool _videoReady = false;

  void _onVideoStatusChanged() {
    final vc = _videoController;
    if (vc == null) return;
    final v = vc.value;
    debugPrint(
      '[VideoStatus] ${widget.card.emotion.name} | '
      'playing=${v.isPlaying} | '
      'buffering=${v.isBuffering} | '
      'pos=${v.position.inMilliseconds}ms / ${v.duration.inMilliseconds}ms | '
      'hasError=${v.hasError}'
      '${v.hasError ? " | error=${v.errorDescription}" : ""}',
    );
  }

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(_CardBack oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('[CardBack] didUpdateWidget — old: ${oldWidget.card.videoPath} → new: ${widget.card.videoPath}');
    if (oldWidget.card.videoPath != widget.card.videoPath) {
      debugPrint('[CardBack] videoPath changed, disposing old controller and re-initialising');
      _videoController?.removeListener(_onVideoStatusChanged);
      _videoController?.dispose();
      _videoController = null;
      _videoReady = false;
      _initVideo();
    }
  }

  void _togglePlay() {
    final vc = _videoController;
    if (vc == null) return;
    if (vc.value.isPlaying) {
      debugPrint(
        '[VideoStatus] ${widget.card.emotion.name} | '
            'playing=${vc.value.isPlaying} | ',
      );
      vc.pause();
    } else {
      vc.play();
    }
    setState(() {});
  }

  Future<void> _initVideo() async {
    final path = widget.card.videoPath;
    if (path == null) return;
    debugPrint('[CardBack] _initVideo — loading: $path');
    final controller = VideoPlayerController.asset(
      path,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _videoController = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      controller.addListener(_onVideoStatusChanged);
      await controller.play();
      debugPrint('[CardBack] _initVideo — playing: $path');
      if (mounted) setState(() => _videoReady = true);
    } catch (e) {
      debugPrint('[CardBack] _initVideo — FAILED: $path\n$e');
    }
  }

  @override
  void dispose() {
    debugPrint('[CardBack] dispose — releasing controller for: ${widget.card.videoPath}');
    _videoController?.removeListener(_onVideoStatusChanged);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.flipAnimation,
      builder: (context, child) {
        final angle = (widget.flipAnimation.value - 1) * math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: Opacity(
            opacity: ((widget.flipAnimation.value - 0.5) * 2).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.card.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.card.shadowColor.withValues(alpha: 0.45),
              offset: const Offset(5, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Raccoo video or fallback icon
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: _videoReady && _videoController != null
                    ? GestureDetector(
                  onTap: _togglePlay,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                      ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: _videoController!,
                        builder: (_, value, __) => AnimatedOpacity(
                          opacity: value.isPlaying ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    : Container(
                  width: double.infinity,
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Icon(
                    widget.card.icon,
                    size: 96,
                    color: widget.card.shadowColor,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    // Emotion name
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.card.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.card.emotion.labelId.toUpperCase(),
                            style: GoogleFonts.baloo2(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF3D2B1A),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    // Text(
                    //   widget.card.description,
                    //   textAlign: TextAlign.center,
                    //   style: GoogleFonts.baloo2(
                    //     fontSize: 18,
                    //     fontWeight: FontWeight.w700,
                    //     color: const Color(0xFF3D2B1A),
                    //     height: 1.4,
                    //   ),
                    // ),
                    //
                    // const SizedBox(height: 16),

                    // Raccoo speech bubble
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.sentiment_satisfied_alt_rounded,
                                size: 20,
                                color: Color(0xFFFF9A3C),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Raccoo berkata:',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF8D6E63),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  context.read<AudioService>().play(AudioAsset.normalClick);
                                  widget.onReplayAudio();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9A3C)
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.volume_up_rounded,
                                    size: 20,
                                    color: Color(0xFFFF9A3C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.card.raccooSpeech,
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              height: 1.6,
                              color: const Color(0xFF3D2B1A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    /*
                    // When examples
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.card.whenExamples,
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                color: const Color(0xFF5D4037),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),*/
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Small reusable widgets ───────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  final String text;

  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFC85A00),
            offset: Offset(4, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.baloo2(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF3D2B1A),
          height: 1.4,
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

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color color;

  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color = const Color(0xFFFF9A3C),
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                offset: const Offset(3, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFFF9A3C),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFC85A00),
              offset: Offset(4, 6),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.baloo2(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFC85A00),
              offset: Offset(4, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFF9A3C), size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.baloo2(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D2B1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}