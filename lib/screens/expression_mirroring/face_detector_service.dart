import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Detected emotion from ML Kit face analysis.
enum DetectedEmotion {
  happy,     // smileProbability > 0.7
  surprised, // eyeOpen > 0.8 && smile < 0.4
  scared,    // eyeOpen < 0.3 && smile < 0.3
  unknown,   // face found but emotion unclear
}

/// Result from one frame analysis.
class FaceDetectionResult {
  final bool faceFound;
  final double confidence;       // ML Kit face bounding box confidence (0.0–1.0)
  final DetectedEmotion emotion;
  final double smileProbability;
  final double eyeOpenProbability;

  const FaceDetectionResult({
    required this.faceFound,
    required this.confidence,
    required this.emotion,
    required this.smileProbability,
    required this.eyeOpenProbability,
  });

  static const FaceDetectionResult noFace = FaceDetectionResult(
    faceFound: false,
    confidence: 0,
    emotion: DetectedEmotion.unknown,
    smileProbability: 0,
    eyeOpenProbability: 0,
  );
}

/// ML Kit face detection wrapper for the Expression Mirroring game.
///
/// Throttles frame processing to 5fps to stay smooth on low-end
/// Android devices (Snapdragon 450 class), common in Indonesia.
///
/// Usage:
///   final svc = FaceDetectorService();
///   await svc.init();
///   svc.results.listen((result) { ... });
///   svc.startProcessing(cameraController);
///   ...
///   await svc.dispose();
class FaceDetectorService {
  // Minimum face width ratio relative to image width.
  // Faces smaller than this (too far from camera) are treated as not found.
  static const double _minFaceWidthRatio = 0.15;
  static const double _smileThresholdHappy = 0.7;
  static const double _eyeThresholdSurprised = 0.8;
  static const double _eyeThresholdScared = 0.3;
  static const Duration _frameInterval = Duration(milliseconds: 200); // 5fps

  late final FaceDetector _detector;
  Timer? _processingTimer;
  CameraController? _cameraController;
  bool _isProcessing = false;

  final StreamController<FaceDetectionResult> _resultController =
      StreamController<FaceDetectionResult>.broadcast();

  Stream<FaceDetectionResult> get results => _resultController.stream;

  void init() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true, // enables smile + eye open probabilities
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  void startProcessing(CameraController controller) {
    _cameraController = controller;
    _processingTimer = Timer.periodic(_frameInterval, (_) => _processFrame());
  }

  void stopProcessing() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }

  Future<void> _processFrame() async {
    if (_isProcessing) return;
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    _isProcessing = true;
    try {
      final image = await controller.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _detector.processImage(inputImage);

      if (faces.isEmpty) {
        _resultController.add(FaceDetectionResult.noFace);
        return;
      }

      // Use the face with the largest bounding box (closest to camera).
      final face = faces.reduce((a, b) =>
          a.boundingBox.width > b.boundingBox.width ? a : b);

      // Minimum confidence gate — avoids false classifications on partial faces.
      // ML Kit doesn't expose a direct "detection confidence" for face bounds,
      // so we use a heuristic: if the bounding box is very small relative to
      // image dimensions, treat it as low confidence.
      final imageWidth = controller.value.previewSize?.width ?? 640;
      final faceWidthRatio = face.boundingBox.width / imageWidth;
      if (faceWidthRatio < _minFaceWidthRatio) {
        // Face is too small / too far — treat as no face.
        _resultController.add(FaceDetectionResult.noFace);
        return;
      }

      final smile = face.smilingProbability ?? 0.0;
      final eyeOpen =
          ((face.leftEyeOpenProbability ?? 0.0) +
                  (face.rightEyeOpenProbability ?? 0.0)) /
              2.0;

      final emotion = _classifyEmotion(smile, eyeOpen);

      _resultController.add(FaceDetectionResult(
        faceFound: true,
        confidence: faceWidthRatio.clamp(0.0, 1.0),
        emotion: emotion,
        smileProbability: smile,
        eyeOpenProbability: eyeOpen,
      ));
    } catch (e) {
      debugPrint('[FaceDetectorService] Frame error: $e');
      _resultController.add(FaceDetectionResult.noFace);
    } finally {
      _isProcessing = false;
    }
  }

  /// Classifies emotion from ML Kit probabilities.
  ///
  /// Thresholds are intentionally wide (±0.2) because:
  ///   1. Children exaggerate expressions more than adults.
  ///   2. The game should feel responsive, not demanding.
  DetectedEmotion _classifyEmotion(double smile, double eyeOpen) {
    if (smile > _smileThresholdHappy) return DetectedEmotion.happy;
    if (eyeOpen > _eyeThresholdSurprised && smile < 0.4) {
      return DetectedEmotion.surprised;
    }
    if (eyeOpen < _eyeThresholdScared && smile < 0.3) {
      return DetectedEmotion.scared;
    }
    return DetectedEmotion.unknown;
  }

  Future<void> dispose() async {
    stopProcessing();
    await _detector.close();
    await _resultController.close();
  }
}
