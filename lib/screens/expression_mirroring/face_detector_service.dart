import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Rect, Size;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Detected emotion — label order matches the FER model's output layer:
///   index 0 → Angry, 1 → Disgust, 2 → Fear,
///   index 3 → Happy, 4 → Sad,    5 → Surprise
enum DetectedEmotion {
  angry,
  disgust,
  fear,
  happy,
  sad,
  surprise,
  unknown,
}

/// Result from one frame analysis.
class FaceDetectionResult {
  final bool faceFound;
  final double confidence;
  final DetectedEmotion emotion;

  /// Raw softmax probabilities [Angry, Disgust, Fear, Happy, Sad, Surprise].
  final List<double> probabilities;

  /// Bounding box in image pixel coordinates (null when no face found).
  final Rect? faceBoundingBox;

  /// Pixel dimensions of the image the bounding box was detected in.
  final Size? imageSize;

  const FaceDetectionResult({
    required this.faceFound,
    required this.confidence,
    required this.emotion,
    required this.probabilities,
    this.faceBoundingBox,
    this.imageSize,
  });

  static const FaceDetectionResult noFace = FaceDetectionResult(
    faceFound: false,
    confidence: 0,
    emotion: DetectedEmotion.unknown,
    probabilities: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  );
}

/// TFLite FER model + ML Kit face-detection wrapper.
///
/// Pipeline per frame (throttled to 5 fps):
///   1. ML Kit detects the face bounding box (fast mode, no classification).
///   2. JPEG from takePicture() is decoded; face region is cropped.
///   3. Crop is resized to 48×48, converted to grayscale, normalised → [0, 1].
///   4. TFLite FER model runs inference on shape [1, 48, 48, 1].
///   5. Argmax of 6-class softmax output maps to DetectedEmotion.
///
/// Usage:
///   final svc = FaceDetectorService();
///   await svc.init();
///   svc.results.listen((r) { ... });
///   svc.startProcessing(cameraController);
///   ...
///   await svc.dispose();
class FaceDetectorService {
  // Faces smaller than this fraction of the frame width are ignored.
  static const double _minFaceWidthRatio = 0.15;

  // Minimum top-1 probability to emit a non-unknown emotion.
  static const double _minEmotionConfidence = 0.40;

  static const Duration _frameInterval = Duration(milliseconds: 100); // 5 fps
  static const int _inputSize = 48;
  static const String _modelAsset = 'assets/model/fer_model.tflite';

  // Must match the FER model's output layer order.
  static const List<DetectedEmotion> _indexToEmotion = [
    DetectedEmotion.angry,   // 0
    DetectedEmotion.disgust, // 1
    DetectedEmotion.fear,    // 2
    DetectedEmotion.happy,   // 3
    DetectedEmotion.sad,     // 4
    DetectedEmotion.surprise, // 5
  ];

  late final FaceDetector _faceDetector;
  Interpreter? _interpreter;

  Timer? _processingTimer;
  CameraController? _cameraController;
  bool _isProcessing = false;

  final StreamController<FaceDetectionResult> _resultController =
      StreamController<FaceDetectionResult>.broadcast();

  Stream<FaceDetectionResult> get results => _resultController.stream;

  Future<void> init() async {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        // Bounding box only — emotion classification is done by TFLite.
        enableClassification: false,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    try {
      _interpreter = await Interpreter.fromAsset(_modelAsset);
    } catch (e) {
      debugPrint('[FaceDetectorService] TFLite load failed: $e');
    }
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
    final interpreter = _interpreter;
    if (interpreter == null) return;

    _isProcessing = true;
    String? tempPath;
    try {
      final xFile = await controller.takePicture();
      tempPath = xFile.path;

      // ── Step 1: detect face bounding box ──────────────────────────────────
      final faces = await _faceDetector
          .processImage(InputImage.fromFilePath(tempPath));

      if (faces.isEmpty) {
        _resultController.add(FaceDetectionResult.noFace);
        return;
      }

      // Largest bounding box = face closest to camera.
      final face = faces.reduce(
          (a, b) => a.boundingBox.width > b.boundingBox.width ? a : b);

      final imageWidth = controller.value.previewSize?.width ?? 640.0;
      final faceWidthRatio = face.boundingBox.width / imageWidth;
      if (faceWidthRatio < _minFaceWidthRatio) {
        _resultController.add(FaceDetectionResult.noFace);
        return;
      }

      // ── Step 2: decode JPEG and crop face ─────────────────────────────────
      final jpegBytes = File(tempPath).readAsBytesSync();
      final decoded = img.decodeJpg(jpegBytes);
      if (decoded == null) {
        _resultController.add(FaceDetectionResult.noFace);
        return;
      }

      final bbox = face.boundingBox;
      final left = bbox.left.toInt().clamp(0, decoded.width - 1);
      final top = bbox.top.toInt().clamp(0, decoded.height - 1);
      final cropW = bbox.width.toInt().clamp(1, decoded.width - left);
      final cropH = bbox.height.toInt().clamp(1, decoded.height - top);

      final faceCrop = img.copyCrop(
        decoded,
        x: left,
        y: top,
        width: cropW,
        height: cropH,
      );

      // ── Step 3: resize to 48×48, normalise grayscale → [0, 1] ────────────
      final resized = img.copyResize(
        faceCrop,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.linear,
      );

      // Build input tensor shape [1][48][48][1].
      final inputTensor = List.generate(
        1,
        (_) => List.generate(
          _inputSize,
          (y) => List.generate(
            _inputSize,
            (x) {
              final pixel = resized.getPixel(x, y);
              final gray = (0.299 * pixel.r.toDouble() +
                      0.587 * pixel.g.toDouble() +
                      0.114 * pixel.b.toDouble()) /
                  255.0;
              return [gray];
            },
          ),
        ),
      );

      // ── Step 4: run TFLite inference ──────────────────────────────────────
      // Output shape [1][6] — 6 softmax probabilities.
      final outputTensor = [List<double>.filled(6, 0.0)];
      interpreter.run(inputTensor, outputTensor);

      final probs = List<double>.from(outputTensor[0]);

      // ── Step 5: argmax + confidence gate ──────────────────────────────────
      int maxIdx = 0;
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > probs[maxIdx]) maxIdx = i;
      }

      final emotion = (probs[maxIdx] >= _minEmotionConfidence &&
              maxIdx < _indexToEmotion.length)
          ? _indexToEmotion[maxIdx]
          : DetectedEmotion.unknown;

      _resultController.add(FaceDetectionResult(
        faceFound: true,
        confidence: faceWidthRatio.clamp(0.0, 1.0),
        emotion: emotion,
        probabilities: probs,
        faceBoundingBox: face.boundingBox,
        imageSize: Size(decoded.width.toDouble(), decoded.height.toDouble()),
      ));
    } catch (e) {
      debugPrint('[FaceDetectorService] Frame error: $e');
      _resultController.add(FaceDetectionResult.noFace);
    } finally {
      // Always delete the temp JPEG to avoid filling device storage.
      if (tempPath != null) {
        try {
          File(tempPath).deleteSync();
        } catch (_) {}
      }
      _isProcessing = false;
    }
  }

  Future<void> dispose() async {
    stopProcessing();
    await _faceDetector.close();
    _interpreter?.close();
    await _resultController.close();
  }
}
