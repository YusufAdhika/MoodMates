import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// Centralised audio playback.
///
/// All screens route audio through this service so it can be:
///   • No-op'd cleanly in widget tests
///   • Pre-loaded at startup (avoids first-play delay — children notice this)
///
/// Usage:
///   context.read<AudioService>().play(AudioAsset.correct);
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  // Separate player for background music (if added later)
  // final AudioPlayer _bgPlayer = AudioPlayer();

  Future<void> init() async {
    // Pre-load commonly used SFX so playback is instant.
    // TODO: uncomment once audio files are added to assets/audio/
    // await _preload(AudioAsset.correct);
    // await _preload(AudioAsset.incorrect);
  }

  /// Play an audio asset. Safe to call when device is muted — just silent.
  /// Silently skips if the asset file has not been added to the bundle yet.
  Future<void> play(AudioAsset asset) async {
    try {
      // Check the asset exists in the bundle before handing it to just_audio.
      // just_audio throws a FlutterError (not a regular exception) for missing
      // assets, which triggers the debug error overlay even inside try/catch.
      await rootBundle.load(asset.path);
    } catch (_) {
      // Asset not bundled yet — skip silently.
      return;
    }
    try {
      await _player.stop();
      await _player.setAsset(asset.path);
      await _player.play();
    } catch (e) {
      // Audio failure is non-fatal: visual instructions are always shown.
      debugPrint('[AudioService] Failed to play ${asset.path}: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}

/// All audio asset paths in one place.
/// Add new entries here as audio files are added to assets/.
enum AudioAsset {
  correct,
  incorrect,
  // Praise
  praiseHebat,
  praiseKamuPintar,
  praiseLuarBiasa,
  praiseBagusSekali,
  // Game instructions
  instructionEmotionRecognition,
  instructionExpressionMirroring,
  instructionSocialSituations,
  // Emotion names
  emotionHappy,
  emotionSad,
  emotionAngry,
  emotionSurprised,
  emotionScared,
  emotionDisgust,
}

extension AudioAssetPath on AudioAsset {
  String get path {
    switch (this) {
      case AudioAsset.correct:
        return 'assets/audio/sfx/correct.mp3';
      case AudioAsset.incorrect:
        return 'assets/audio/sfx/incorrect.mp3';
      case AudioAsset.praiseHebat:
        return 'assets/audio/praise/hebat.mp3';
      case AudioAsset.praiseKamuPintar:
        return 'assets/audio/praise/kamu_pintar.mp3';
      case AudioAsset.praiseLuarBiasa:
        return 'assets/audio/praise/luar_biasa.mp3';
      case AudioAsset.praiseBagusSekali:
        return 'assets/audio/praise/bagus_sekali.mp3';
      case AudioAsset.instructionEmotionRecognition:
        return 'assets/audio/instructions/game_emotion_recognition.mp3';
      case AudioAsset.instructionExpressionMirroring:
        return 'assets/audio/instructions/game_expression_mirroring.mp3';
      case AudioAsset.instructionSocialSituations:
        return 'assets/audio/instructions/game_social_situations.mp3';
      case AudioAsset.emotionHappy:
        return 'assets/audio/instructions/emotion_happy.mp3';
      case AudioAsset.emotionSad:
        return 'assets/audio/instructions/emotion_sad.mp3';
      case AudioAsset.emotionAngry:
        return 'assets/audio/instructions/emotion_angry.mp3';
      case AudioAsset.emotionSurprised:
        return 'assets/audio/instructions/emotion_surprised.mp3';
      case AudioAsset.emotionScared:
        return 'assets/audio/instructions/emotion_scared.mp3';
      case AudioAsset.emotionDisgust:
        return 'assets/audio/instructions/emotion_disgust.mp3';
    }
  }
}
