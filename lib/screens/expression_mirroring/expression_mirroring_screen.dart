import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/emotion.dart';
import '../../models/game_progress.dart';
import '../../providers/progress_provider.dart';
import '../../services/audio_service.dart';
import '../../widgets/celebration_widget.dart';
import 'face_detector_service.dart';

/// Mini-game 2: Expression Mirroring
///
/// Shows a target emotion (happy / surprised / scared). Child mimics the
/// expression in front of the front camera. ML Kit detects the expression
/// via smileProbability + eyeOpenProbability.
///
/// Falls back gracefully to self-report mode if:
///   • Camera permission is denied
///   • No front camera on device
///
/// State machine: IDLE → CAMERA_INIT → DETECTING ↔ EVALUATING → CELEBRATING
class ExpressionMirroringScreen extends StatefulWidget {
  const ExpressionMirroringScreen({super.key});

  @override
  State<ExpressionMirroringScreen> createState() =>
      _ExpressionMirroringScreenState();
}

enum _ScreenState { cameraInit, detecting, celebrating, selfReport }

class _ExpressionMirroringScreenState
    extends State<ExpressionMirroringScreen> {
  static const int _totalRounds = 3;
  static const Duration _noFaceTimeout = Duration(seconds: 2);

  CameraController? _cameraController;
  final FaceDetectorService _faceService = FaceDetectorService();
  StreamSubscription<FaceDetectionResult>? _detectionSub;

  _ScreenState _state = _ScreenState.cameraInit;
  int _round = 1;
  late Emotion _targetEmotion;
  bool _faceDetected = false;
  Timer? _noFaceTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _targetEmotion = mirroringEmotions[0];
    _faceService.init();
    _initCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<AudioService>()
          .play(AudioAsset.instructionExpressionMirroring);
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => throw Exception('No front camera'),
      );

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) return;
      _cameraController = controller;
      _faceService.startProcessing(controller);

      _detectionSub = _faceService.results.listen(_onDetectionResult);
      setState(() => _state = _ScreenState.detecting);
      _startNoFaceTimer();
    } catch (e) {
      debugPrint('[ExpressionMirroring] Camera init failed: $e');
      if (mounted) setState(() => _state = _ScreenState.selfReport);
    }
  }

  void _startNoFaceTimer() {
    _noFaceTimer?.cancel();
    _noFaceTimer = Timer(_noFaceTimeout, () {
      if (!_faceDetected && mounted) {
        setState(() {}); // triggers "show face" prompt in UI
      }
    });
  }

  void _onDetectionResult(FaceDetectionResult result) {
    if (!mounted || _state == _ScreenState.celebrating) return;

    setState(() => _faceDetected = result.faceFound);

    if (!result.faceFound) return;
    _noFaceTimer?.cancel();

    // Check if detected emotion matches target
    final matches = _emotionMatches(result.emotion, _targetEmotion);
    if (matches) _onCorrectExpression();
  }

  bool _emotionMatches(DetectedEmotion detected, Emotion target) {
    switch (target) {
      case Emotion.happy:
        return detected == DetectedEmotion.happy;
      case Emotion.surprised:
        return detected == DetectedEmotion.surprised;
      case Emotion.scared:
        return detected == DetectedEmotion.scared;
      default:
        return false;
    }
  }

  Future<void> _onCorrectExpression() async {
    // Guard against re-entry from rapid stream events before the state flip
    // propagates. Set celebrating synchronously before any async gap.
    if (_state == _ScreenState.celebrating) return;
    _state = _ScreenState.celebrating;
    _faceService.stopProcessing();
    setState(() {});

    // Capture providers before async gaps
    final progressProvider = context.read<ProgressProvider>();
    final audioService = context.read<AudioService>();

    await progressProvider.recordSession(
      gameId: GameProgress.gameExpressionMirroring,
      wasCorrect: true,
    );
    audioService.play(AudioAsset.correct);

    if (!mounted) return;
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (_, __, ___) => CelebrationWidget(
        message: 'Bagus sekali! 🎉',
        onDismiss: () {
          Navigator.of(context).pop();
          if (_round >= _totalRounds) {
            context.go('/');
          } else {
            setState(() {
              _round++;
              _targetEmotion =
                  mirroringEmotions[(_round - 1) % mirroringEmotions.length];
              _state = _ScreenState.detecting;
              _faceDetected = false;
            });
            _faceService.startProcessing(_cameraController!);
            _startNoFaceTimer();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _noFaceTimer?.cancel();
    _detectionSub?.cancel();
    _faceService.dispose();
    _cameraController?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesai bermain?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjut'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    return exit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) context.go('/');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE3F2FD),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
            onPressed: () async {
              if (await _onWillPop() && context.mounted) context.go('/');
            },
          ),
          title: Text(
            'Ronde $_round / $_totalRounds',
            style: const TextStyle(color: Colors.blueGrey),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_state == _ScreenState.selfReport) return _buildSelfReportMode();
    if (_state == _ScreenState.cameraInit) {
      return const _CameraLoadingState();
    }
    return _buildCameraMode();
  }

  Widget _buildCameraMode() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Target emotion instruction
          Text(
            'Tunjukkan ekspresi: ${_targetEmotion.labelId}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Target emotion illustration
          // TODO: Image.asset(_targetEmotion.characterAsset)
          const Icon(Icons.face, size: 100, color: Colors.blue),
          const SizedBox(height: 16),

          // Camera preview
          Expanded(
            child: _cameraController != null &&
                    _cameraController!.value.isInitialized
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CameraPreview(_cameraController!),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),

          // No-face prompt
          if (!_faceDetected) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '📷 Tampakkan wajahmu!',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelfReportMode() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Kamera tidak tersedia.\nTunjukkan ekspresimu, lalu tekan tombol!',
            style: TextStyle(fontSize: 18, color: Colors.blueGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            'Ekspresi: ${_targetEmotion.labelId}',
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _onCorrectExpression(),
            icon: const Icon(Icons.check_circle, size: 32),
            label: const Text('Sudah! ✓', style: TextStyle(fontSize: 20)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 64),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraLoadingState extends StatelessWidget {
  const _CameraLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Menyiapkan kamera...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tunggu sebentar ya.',
            style: TextStyle(color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}
