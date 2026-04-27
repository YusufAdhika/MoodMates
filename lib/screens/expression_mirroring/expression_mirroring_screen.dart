import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../models/emotion.dart';
import '../../models/game_progress.dart';
import '../../providers/progress_provider.dart';
import '../../services/audio_service.dart';
import 'face_detector_service.dart';

// ─── Zone Design Tokens ───────────────────────────────────────────────────────
// Mirror zone: biru (#4BA3C3), bg (#E8F4FD), shadow rgba(20,100,160,0.40)

const _zoneColor = Color(0xFF4BA3C3);
const _zoneBg = Color(0xFFE8F4FD);
const _zoneShadow = Color(0xFF1464A0);
const _textDark = Color(0xFF3D2B1A);
const _textMuted = Color(0xFF8D6E63);
const _successGreen = Color(0xFF4CAF6E);

// ─── Data Model — Per Emosi ───────────────────────────────────────────────────

/// Data yang dibutuhkan untuk setiap ronde Mirror.
class _MirrorTarget {
  final Emotion emotion;

  /// true → ML Kit bisa deteksi otomatis (happy/surprised/scared).
  /// false → tampilkan kamera + panduan, lalu self-report setelah [selfReportDelay].
  final bool mlKitDetectable;

  /// Instruksi untuk anak, muncul di panel atas.
  final String instruction;

  /// Tip singkat dari Raccoo tentang cara membuat ekspresi ini.
  final String raccooTip;

  /// Feedback saat ekspresi cocok / self-report ditekan.
  final String feedbackMatch;

  /// Feedback sementara saat anak sedang mencoba (ML Kit mode).
  final String feedbackTrying;


  /// Ikon fallback saat video belum siap.
  final IconData icon;

  /// Path video Raccoo untuk mode fallback (tanpa kamera).
  final String? videoPath;

  const _MirrorTarget({
    required this.emotion,
    required this.mlKitDetectable,
    required this.instruction,
    required this.raccooTip,
    required this.feedbackMatch,
    required this.feedbackTrying,
    required this.icon,
    this.videoPath,
  });
}

/// Daftar 6 emosi target — urutan akan diacak saat sesi dimulai.
const List<_MirrorTarget> _allTargets = [
  _MirrorTarget(
    emotion: Emotion.happy,
    mlKitDetectable: true,
    instruction: 'Coba tirukan wajah SENANG!',
    raccooTip: 'Tersenyum lebar dan angkat pipimu ke atas! 😊',
    feedbackMatch: 'Wah, wajah senangnya sudah cocok! Kamu hebat!',
    feedbackTrying: 'Hampir! Coba senyum lebih lebar...',
    icon: Icons.sentiment_very_satisfied_rounded,
    videoPath: 'assets/video/raccoo_happy.mp4',
  ),
  _MirrorTarget(
    emotion: Emotion.sad,
    mlKitDetectable: true,
    instruction: 'Coba tirukan wajah SEDIH!',
    raccooTip: 'Turunkan sudut bibirmu dan coba kelihatan murung. 😢',
    feedbackMatch: 'Keren! Wajah sedihmu bagus sekali! Kamu pintar!',
    feedbackTrying: 'Ayo tunjukkan wajah sedih yang lebih dalam...',
    icon: Icons.sentiment_very_dissatisfied_rounded,
    videoPath: 'assets/video/raccoo_sad.mp4',
  ),
  _MirrorTarget(
    emotion: Emotion.angry,
    mlKitDetectable: true,
    instruction: 'Coba tirukan wajah MARAH!',
    raccooTip: 'Kerutkan alismu ke tengah dan cemberut! 😠',
    feedbackMatch: 'Kamu sudah berhasil! Wajah marahnya keren!',
    feedbackTrying: 'Kerutkan alismu lebih kuat, yuk!',
    icon: Icons.mood_bad_rounded,
    videoPath: 'assets/video/raccoo_angry.mp4.mp4',
  ),
  _MirrorTarget(
    emotion: Emotion.scared,
    mlKitDetectable: true,
    instruction: 'Coba tirukan wajah TAKUT!',
    raccooTip: 'Buka matamu lebar-lebar dan kelihatan kaget! 😨',
    feedbackMatch: 'Bagus banget! Wajah takutnya sudah pas!',
    feedbackTrying: 'Buka matamu lebih lebar lagi...',
    icon: Icons.sentiment_dissatisfied_rounded,
    videoPath: 'assets/video/raccoo_scare.mp4',
  ),
  _MirrorTarget(
    emotion: Emotion.surprised,
    mlKitDetectable: true,
    instruction: 'Coba tirukan wajah TERKEJUT!',
    raccooTip: 'Buka mata dan mulutmu selebar mungkin! 😲',
    feedbackMatch: 'Luar biasa! Wajah terkejutmu sudah cocok!',
    feedbackTrying: 'Buka mulutmu lebih lebar — HAH!',
    icon: Icons.sentiment_neutral_rounded,
    videoPath: 'assets/video/raccoo_shock.mp4',
  ),
  _MirrorTarget(
    emotion: Emotion.disgust,
    mlKitDetectable: true,
    instruction: 'Coba tirukan wajah JIJIK!',
    raccooTip: 'Kerutkan hidungmu dan angkat bibir atasmu — eugh! 🤢',
    feedbackMatch: 'Berhasil! Wajah jijiknya sudah kelihatan!',
    feedbackTrying: 'Kerutkan hidungmu lebih kuat...',
    icon: Icons.sick_rounded,
    videoPath: 'assets/video/raccoo_disgust.mp4',
  ),
];

// ─── Screen State ─────────────────────────────────────────────────────────────

enum _Phase {
  /// Inisialisasi kamera atau minta izin.
  cameraInit,

  /// Kamera aktif, deteksi berjalan (ML Kit atau self-report timer).
  detecting,

  /// Ekspresi cocok — tampilkan feedback & tombol lanjut.
  matched,

  /// Kamera tidak tersedia — mode panduan animasi + self-report.
  noCamera,

  /// Semua ronde selesai — layar akhir.
  done,
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

/// "Raccoo Mirror" — anak meniru ekspresi wajah sambil melihat kamera depan.
///
/// State machine:  cameraInit → detecting ↔ matched → done
///                           └→ noCamera  ↔ matched → done
///
/// Emosi yang bisa dideteksi otomatis (ML Kit):
///   happy, surprised, scared, sadness, anger, disgust
class ExpressionMirroringScreen extends StatefulWidget {
  const ExpressionMirroringScreen({super.key});

  @override
  State<ExpressionMirroringScreen> createState() =>
      _ExpressionMirroringScreenState();
}

class _ExpressionMirroringScreenState extends State<ExpressionMirroringScreen>
    with TickerProviderStateMixin {
  // ── Config ───────────────────────────────────────────────────────────────

  /// Setelah berapa detik muncul tombol "Sudah Coba!" untuk emosi
  /// yang tidak bisa dideteksi ML Kit (sad, angry, disgust).
  static const Duration _selfReportDelay = Duration(seconds: 4);

  // ── State ────────────────────────────────────────────────────────────────

  _Phase _phase = _Phase.cameraInit;
  late List<_MirrorTarget> _targets;
  int _roundIndex = 0;

  _MirrorTarget get _currentTarget => _targets[_roundIndex];

  bool _faceDetected = false;
  bool _selfReportVisible = false;
  String _feedbackText = '';

  // Require this many consecutive matching frames (~600 ms at 5 fps) before
  // accepting the expression — prevents a single accidental frame from passing.
  static const int _requiredConsecutiveMatches = 3;
  int _consecutiveMatchCount = 0;

  // Camera switching
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isSwitchingCamera = false;

  // ── Services ─────────────────────────────────────────────────────────────

  late AudioService _audio;
  CameraController? _cameraController;
  final FaceDetectorService _faceService = FaceDetectorService();
  StreamSubscription<FaceDetectionResult>? _detectionSub;

  // ── Timers ───────────────────────────────────────────────────────────────

  Timer? _selfReportTimer;
  Timer? _noFaceHintTimer;

  // ── Animations ───────────────────────────────────────────────────────────

  late AnimationController _pulseController;
  late AnimationController _matchController;
  late AnimationController _raccooController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _matchScaleAnimation;
  late Animation<double> _raccooFloatAnimation;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Acak urutan emosi target setiap sesi
    _targets = List<_MirrorTarget>.from(_allTargets)..shuffle(math.Random());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _matchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _matchScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _matchController,
        curve: const Cubic(0.34, 1.56, 0.64, 1),
      ),
    );

    _raccooController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _raccooFloatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _raccooController, curve: Curves.easeInOut),
    );

    _audio = context.read<AudioService>();
    _initCamera();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audio.playBg(AudioAsset.bgMain);
      _audio.play(AudioAsset.instructionExpressionMirroring);
    });
  }

  @override
  void dispose() {
    _audio.stopBg();
    _selfReportTimer?.cancel();
    _noFaceHintTimer?.cancel();
    _detectionSub?.cancel();
    _faceService.dispose();
    _cameraController?.dispose();
    _pulseController.dispose();
    _matchController.dispose();
    _raccooController.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  // ── Camera Init ──────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    // Load TFLite model before opening the camera so inference is ready
    // as soon as the first frames arrive.
    await _faceService.init();

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception('No cameras found');

      final frontIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _cameraIndex = frontIndex >= 0 ? frontIndex : 0;

      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();

      if (!mounted) return;
      _cameraController = controller;
      _faceService.startProcessing(controller);
      _detectionSub = _faceService.results.listen(_onDetectionResult);

      setState(() => _phase = _Phase.detecting);
      _startRound();
    } catch (e) {
      debugPrint('[RaccooMirror] Camera init failed: $e');
      if (mounted) {
        setState(() => _phase = _Phase.noCamera);
        _startRound();
      }
    }
  }

  // ── Camera Switch ────────────────────────────────────────────────────────

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isSwitchingCamera) return;
    setState(() => _isSwitchingCamera = true);

    _faceService.stopProcessing();
    _detectionSub?.cancel();
    _detectionSub = null;

    final old = _cameraController;
    setState(() => _cameraController = null);
    await old?.dispose();

    _cameraIndex = (_cameraIndex + 1) % _cameras.length;

    try {
      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) return;

      _cameraController = controller;
      _faceService.startProcessing(controller);
      _detectionSub = _faceService.results.listen(_onDetectionResult);
      _consecutiveMatchCount = 0;
      setState(() => _isSwitchingCamera = false);
    } catch (e) {
      debugPrint('[RaccooMirror] Camera switch failed: $e');
      if (mounted) setState(() => _isSwitchingCamera = false);
    }
  }

  // ── Round Management ─────────────────────────────────────────────────────

  /// Persiapkan ronde baru: reset flag, mulai timer self-report jika perlu.
  void _startRound() {
    _selfReportTimer?.cancel();
    _noFaceHintTimer?.cancel();

    setState(() {
      _faceDetected = false;
      _selfReportVisible = false;
      _feedbackText = '';
    });
    _consecutiveMatchCount = 0;

    // Untuk emosi yang tidak bisa dideteksi ML Kit, atau di mode noCamera,
    // mulai timer agar tombol "Sudah Coba!" muncul setelah beberapa detik.
    if (!_currentTarget.mlKitDetectable || _phase == _Phase.noCamera) {
      _selfReportTimer = Timer(_selfReportDelay, () {
        if (mounted && _phase == _Phase.detecting ||
            _phase == _Phase.noCamera) {
          setState(() => _selfReportVisible = true);
        }
      });
    }
  }

  /// Dipanggil saat ekspresi cocok (otomatis atau self-report).
  Future<void> _onExpressionMatched() async {
    if (_phase == _Phase.matched || _phase == _Phase.done) return;
    _faceService.stopProcessing();
    _selfReportTimer?.cancel();

    setState(() {
      _phase = _Phase.matched;
      _feedbackText = _currentTarget.feedbackMatch;
    });

    _matchController.forward(from: 0);
    context.read<AudioService>().play(AudioAsset.correct);

    await context.read<ProgressProvider>().recordSession(
          gameId: GameProgress.gameExpressionMirroring,
          wasCorrect: true,
        );
  }

  /// Lanjut ke ronde berikutnya atau ke layar selesai.
  void _nextRound() {
    if (_roundIndex >= _targets.length - 1) {
      setState(() => _phase = _Phase.done);
      _matchController.forward(from: 0);
      return;
    }

    setState(() {
      _roundIndex++;
      _phase = _cameraController != null ? _Phase.detecting : _Phase.noCamera;
    });

    if (_cameraController != null) {
      _faceService.startProcessing(_cameraController!);
    }

    _startRound();
  }

  // ── Face Detection ───────────────────────────────────────────────────────

  void _onDetectionResult(FaceDetectionResult result) {
    if (!mounted || _phase != _Phase.detecting) return;

    setState(() => _faceDetected = result.faceFound);

    if (!result.faceFound) {
      if (_feedbackText.isNotEmpty) setState(() => _feedbackText = '');
      return;
    }

    // Hanya evaluasi emosi yang bisa dideteksi ML Kit.
    if (!_currentTarget.mlKitDetectable) return;

    final matches = _emotionMatches(result.emotion, _currentTarget.emotion);
    if (matches) {
      _consecutiveMatchCount++;
      if (_consecutiveMatchCount >= _requiredConsecutiveMatches) {
        _consecutiveMatchCount = 0;
        _onExpressionMatched();
      }
    } else {
      _consecutiveMatchCount = 0;
      setState(() => _feedbackText = _currentTarget.feedbackTrying);
    }
  }

  bool _emotionMatches(DetectedEmotion detected, Emotion target) {
    switch (target) {
      case Emotion.happy:
        return detected == DetectedEmotion.happy;
      case Emotion.surprised:
        return detected == DetectedEmotion.surprise;
      case Emotion.scared:
        return detected == DetectedEmotion.fear;
      case Emotion.sad:
        return detected == DetectedEmotion.sad;
      case Emotion.angry:
        return detected == DetectedEmotion.angry;
      case Emotion.disgust:
        return detected == DetectedEmotion.disgust;
      default:
        return false;
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
          'Progresmu hari ini akan tersimpan kok!',
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
                color: Colors.red,
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
        if (await _confirmExit() && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: _zoneBg,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/background/bg_racoo_mirror.png',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: switch (_phase) {
                _Phase.cameraInit => _buildInitializing(),
                _Phase.detecting => _buildGameScreen(),
                _Phase.matched => _buildMatchedScreen(),
                _Phase.noCamera => _buildNoCameraScreen(),
                _Phase.done => _buildDoneScreen(),
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Camera Initializing ───────────────────────────────────────────────────

  Widget _buildInitializing() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _raccooFloatAnimation,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _raccooFloatAnimation.value),
              child: child,
            ),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _zoneColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.camera_front_rounded, size: 60, color: _zoneColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Menyiapkan kamera...',
            style: GoogleFonts.baloo2(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tunggu sebentar ya! 📷',
            style: GoogleFonts.dmSans(fontSize: 16, color: _textMuted),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: _zoneColor),
        ],
      ),
    );
  }

  // ── Main Game Screen (Camera Mode) ────────────────────────────────────────

  Widget _buildGameScreen() {
    return Column(
      children: [
        _buildTopBar(),
        _buildTargetPanel(),
        Expanded(child: _buildCameraPanel()),
      ],
    );
  }

  // ── No Camera Screen (Fallback) ───────────────────────────────────────────

  Widget _buildNoCameraScreen() {
    return Column(
      children: [
        _buildTopBar(),
        _buildTargetPanel(),
        Expanded(child: _buildFallbackPanel()),
      ],
    );
  }

  // ── Matched Screen ────────────────────────────────────────────────────────

  Widget _buildMatchedScreen() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ScaleTransition(
                scale: _matchScaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Confetti icon
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: _successGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: _VideoCircle(
                        size: 140,
                        videoPath: _currentTarget.videoPath,
                        fallbackIcon: _currentTarget.icon,
                        fallbackColor: _successGreen,
                        fallbackBg: _successGreen.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '⭐ Berhasil!',
                      style: GoogleFonts.baloo2(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: _zoneShadow,
                            offset: Offset(3, 5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        _feedbackText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.baloo2(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _MirrorButton(
                      label: _roundIndex < _targets.length - 1
                          ? 'Lanjut →'
                          : 'Selesai! 🎉',
                      color: _roundIndex < _targets.length - 1
                          ? _zoneColor
                          : _successGreen,
                      onTap: _nextRound,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Done Screen ───────────────────────────────────────────────────────────

  Widget _buildDoneScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _raccooFloatAnimation,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _raccooFloatAnimation.value),
              child: child,
            ),
            child: _VideoCircle(
              size: 180,
              videoPath: 'assets/video/raccoo_happy.mp4',
              fallbackIcon: Icons.sentiment_very_satisfied_rounded,
              fallbackColor: _zoneColor,
              fallbackBg: _zoneColor.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Kamu Juara! 🏆',
            style: GoogleFonts.baloo2(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: _textDark,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kamu sudah berhasil meniru\n semua ${_targets.length} ekspresi Raccoo!',
            textAlign: TextAlign.center,
            style: GoogleFonts.baloo2(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + i * 180),
                curve: const Cubic(0.34, 1.56, 0.64, 1),
                builder: (context, v, _) => Transform.scale(
                  scale: v,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.star_rounded,
                      size: 52,
                      color: Color(0xFFFFD54F),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Emotion chips recap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _targets.map((t) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _zoneColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _zoneColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon, size: 18, color: _zoneColor),
                    const SizedBox(width: 6),
                    Text(
                      t.emotion.labelId,
                      style: GoogleFonts.baloo2(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          _MirrorButton(
            label: 'Kembali ke Beranda',
            color: _zoneColor,
            onTap: () => context.pop(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Sub-builders ──────────────────────────────────────────────────────────

  /// Top bar: tombol kembali + progress ronde.
  Widget _buildTopBar() {
    final isDone = _phase == _Phase.done;
    final currentRound = isDone ? _targets.length : _roundIndex + 1;
    final totalRounds = _targets.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Tombol kembali
          GestureDetector(
            onTap: () async {
              final shouldExit = await _confirmExit();
              if (shouldExit && mounted) context.pop();
            },
            child: Image.asset(
              'assets/images/ui/ic_left.png',
              width: 64,
              height: 64,
            ),
          ),
          const Spacer(),
          // Progress bar ronde
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Ronde $currentRound / $totalRounds',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 100,
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: currentRound / totalRounds,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_zoneColor),
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

  /// Panel atas: ilustrasi Raccoo + instruksi + tip.
  Widget _buildTargetPanel() {
    final target = _currentTarget;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          // Raccoo illustration + emotion name badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Raccoo animated icon
              AnimatedBuilder(
                animation: _raccooFloatAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _raccooFloatAnimation.value * 0.5),
                  child: child,
                ),
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: _zoneColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _zoneColor.withValues(alpha: 0.4),
                        width: 2.5,
                      ),
                    ),
                    child: _VideoCircle(
                      size: 90,
                      videoPath: target.videoPath,
                      fallbackIcon: target.icon,
                      fallbackColor: _zoneColor,
                      fallbackBg: _zoneColor.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Instruction + tip
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emotion target badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _zoneColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        target.emotion.labelId.toUpperCase(),
                        style: GoogleFonts.baloo2(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      target.instruction,
                      style: GoogleFonts.baloo2(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Raccoo speech bubble tip
          _RaccooTipBubble(tip: target.raccooTip),
        ],
      ),
    );
  }

  /// Panel kamera: preview + overlay deteksi.
  Widget _buildCameraPanel() {
    final controller = _cameraController;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Camera preview
          Expanded(
            child: Stack(
              children: [
                // Camera frame container
                _CameraFrame(
                  controller: controller,
                  faceDetected: _faceDetected,
                ),

                // Switch camera button — top-left, only when 2+ cameras available
                if (_cameras.length >= 2)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: GestureDetector(
                      onTap: _isSwitchingCamera ? null : _switchCamera,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: _isSwitchingCamera
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.cameraswitch_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                  ),

                // "Tampakkan wajahmu!" overlay saat tidak ada wajah
                if (!_faceDetected)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: Center(
                      child: _NoFaceBanner(),
                    ),
                  ),

                // Feedback text saat wajah terdeteksi tapi belum cocok
                if (_faceDetected && _feedbackText.isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _FeedbackOverlay(text: _feedbackText),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Self-report button — muncul setelah _selfReportDelay
          // untuk emosi yang tidak bisa dideteksi ML Kit
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selfReportVisible && !_currentTarget.mlKitDetectable
                ? _MirrorButton(
                    key: const ValueKey('selfReport'),
                    label: 'Sudah Coba! 👍',
                    color: _successGreen,
                    onTap: () {
                      setState(
                          () => _feedbackText = _currentTarget.feedbackMatch);
                      _onExpressionMatched();
                    },
                  )
                : _currentTarget.mlKitDetectable
                    ? Container(
                        key: const ValueKey('hint_ml'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.camera_front_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kamera mendeteksi ekspresimu otomatis!',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        key: const ValueKey('hint_wait'),
                        'Coba tirukan dulu, tombol akan muncul sebentar lagi...',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: _textMuted,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Panel fallback: panduan animasi tanpa kamera.
  Widget _buildFallbackPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Info kamera tidak tersedia
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kamera tidak tersedia — mode panduan aktif',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Mirror simulation frame — tunjukkan emoji guide
          Expanded(
            child: _MirrorSimulation(target: _currentTarget),
          ),

          const SizedBox(height: 16),

          // Self-report button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selfReportVisible
                ? _MirrorButton(
                    key: const ValueKey('selfReport_fb'),
                    label: 'Sudah Mencoba! 👍',
                    color: _successGreen,
                    onTap: () {
                      setState(
                          () => _feedbackText = _currentTarget.feedbackMatch);
                      _onExpressionMatched();
                    },
                  )
                : Text(
                    key: const ValueKey('hint_fb'),
                    'Ikuti panduan di atas, tombol akan muncul sebentar lagi...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: _textMuted,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Bubble tip Raccoo — panel instruksi singkat.
class _RaccooTipBubble extends StatelessWidget {
  final String tip;
  const _RaccooTipBubble({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: _zoneShadow,
            offset: Offset(3, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sentiment_satisfied_alt_rounded,
            size: 18,
            color: _zoneColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: _textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Container kamera dengan border yang berubah warna saat wajah terdeteksi.
class _CameraFrame extends StatelessWidget {
  final CameraController? controller;
  final bool faceDetected;

  const _CameraFrame({
    required this.controller,
    required this.faceDetected,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        faceDetected ? _successGreen : _zoneColor.withValues(alpha: 0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: (faceDetected ? _successGreen : _zoneShadow)
                .withValues(alpha: 0.35),
            offset: const Offset(4, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: controller != null && controller!.value.isInitialized
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller!),
                  // Scan guide overlay (wajah outline)
                  if (!faceDetected) const _ScanGuideOverlay(),
                  // Face detected indicator
                  if (faceDetected)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _successGreen.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.face_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Wajah terdeteksi!',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            : Container(
                color: const Color(0xFF1A1A2E),
                child: const Center(
                  child: CircularProgressIndicator(color: _zoneColor),
                ),
              ),
      ),
    );
  }
}

/// Overlay panduan mengarahkan wajah ke kamera — ditampilkan saat belum ada wajah.
class _ScanGuideOverlay extends StatelessWidget {
  const _ScanGuideOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: const Size(160, 200),
        painter: _FaceOvalPainter(),
      ),
    );
  }
}

/// Gambar oval putus-putus sebagai panduan posisi wajah.
class _FaceOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Dash pattern manual
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height,
    );
    final path = Path()..addOval(rect);

    const dashLength = 12.0;
    const gapLength = 6.0;
    final metrics = path.computeMetrics().first;
    double distance = 0;

    while (distance < metrics.length) {
      final nextDash = distance + dashLength;
      canvas.drawPath(
        metrics.extractPath(distance, nextDash.clamp(0, metrics.length)),
        paint,
      );
      distance = nextDash + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Banner "Tampakkan wajahmu!" saat tidak ada wajah di frame.
class _NoFaceBanner extends StatelessWidget {
  const _NoFaceBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.face_retouching_natural_rounded,
              size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Tampakkan wajahmu ke kamera! 📷',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay feedback di atas kamera saat wajah terdeteksi tapi belum cocok.
class _FeedbackOverlay extends StatelessWidget {
  final String text;
  const _FeedbackOverlay({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _zoneColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Simulasi cermin untuk mode fallback (tanpa kamera).
///
/// Menampilkan:
/// 1. Frame "cermin" dengan guide emoji animasi
/// 2. Langkah-langkah cara membuat ekspresi target
class _MirrorSimulation extends StatefulWidget {
  final _MirrorTarget target;
  const _MirrorSimulation({required this.target});

  @override
  State<_MirrorSimulation> createState() => _MirrorSimulationState();
}

class _MirrorSimulationState extends State<_MirrorSimulation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_MirrorSimulation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target.emotion != widget.target.emotion) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cermin simulasi
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A2035),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _zoneColor.withValues(alpha: 0.5),
                width: 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: _zoneShadow,
                  offset: Offset(4, 6),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Cermin label
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '🪞 Cermin Panduan',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ),

                // Guide video / icon animasi
                Center(
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _VideoCircle(
                          size: 160,
                          videoPath: widget.target.videoPath,
                          fallbackIcon: widget.target.icon,
                          fallbackColor: Colors.white.withValues(alpha: 0.85),
                          fallbackBg: Colors.white.withValues(alpha: 0.12),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            widget.target.emotion.labelId.toUpperCase(),
                            style: GoogleFonts.baloo2(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


                // Oval guide
                Center(
                  child: CustomPaint(
                    size: const Size(140, 180),
                    painter: _FaceOvalPainter(),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Tip cara membuat ekspresi
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: _zoneShadow,
                offset: Offset(3, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: Color(0xFFFFD54F),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.target.raccooTip,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: _textDark,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tombol aksi utama Mirror — warna bisa disesuaikan per konteks.
class _MirrorButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MirrorButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              offset: const Offset(4, 6),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.baloo2(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Circular video player with icon fallback.
/// Manages its own [VideoPlayerController] lifecycle.
class _VideoCircle extends StatefulWidget {
  final double size;
  final String? videoPath;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final Color fallbackBg;

  const _VideoCircle({
    required this.size,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.fallbackBg,
    this.videoPath,
  });

  @override
  State<_VideoCircle> createState() => _VideoCircleState();
}

class _VideoCircleState extends State<_VideoCircle> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(_VideoCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      final old = _controller;
      setState(() => _controller = null);
      old?.dispose();
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final path = widget.videoPath;
    if (path == null) return;
    final controller = VideoPlayerController.asset(path);
    if (mounted) setState(() => _controller = controller);
    try {
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      controller.setLooping(true);
      controller.setVolume(0);
      await controller.play();
    } catch (e) {
      debugPrint('[VideoCircle] init failed: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final ctrl = _controller;
    return ClipOval(
      child: ctrl == null
          ? Container(
              width: s,
              height: s,
              color: widget.fallbackBg,
              child: Icon(
                widget.fallbackIcon,
                size: s * 0.6,
                color: widget.fallbackColor,
              ),
            )
          : ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: ctrl,
              builder: (context, value, _) {
                if (!value.isInitialized) {
                  return Container(
                    width: s,
                    height: s,
                    color: widget.fallbackBg,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white54,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                return SizedBox(
                  width: s,
                  height: s,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: value.size.width,
                      height: value.size.height,
                      child: VideoPlayer(ctrl),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
