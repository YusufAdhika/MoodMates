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
///   context.read<AudioService>().playBg(AudioAsset.bgMain);
///   context.read<AudioService>().stopBg();
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _bgPlayer = AudioPlayer();

  Future<void> init() async {
    // Pre-load commonly used SFX so playback is instant.
    // TODO: uncomment once audio files are added to assets/audio/
    // await _preload(AudioAsset.correct);
    // await _preload(AudioAsset.incorrect);
  }

  /// Play a one-shot SFX asset. Safe when device is muted — just silent.
  /// Silently skips if the asset file has not been added to the bundle yet.
  Future<void> play(AudioAsset asset) async {
    try {
      await rootBundle.load(asset.path);
    } catch (_) {
      return;
    }
    try {
      await _player.stop();
      await _player.setAsset(asset.path);
      await _player.play();
    } catch (e) {
      debugPrint('[AudioService] Failed to play ${asset.path}: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  /// Start looping background music. Silently skips if already playing or file is missing.
  Future<void> playBg(AudioAsset asset) async {
    if (_bgPlayer.playing) return;
    try {
      await rootBundle.load(asset.path);
    } catch (_) {
      debugPrint('[AudioService] BG asset not found: ${asset.path}');
      return;
    }
    try {
      await _bgPlayer.setAsset(asset.path);
      await _bgPlayer.setLoopMode(LoopMode.one);
      await _bgPlayer.setVolume(0.5);
      await _bgPlayer.play();
      debugPrint('[AudioService] BG playing: ${asset.path}');
    } catch (e) {
      debugPrint('[AudioService] Failed to play bg ${asset.path}: $e');
    }
  }

  /// Pause background music (preserves position).
  Future<void> pauseBg() async {
    await _bgPlayer.pause();
  }

  /// Stop and reset background music.
  Future<void> stopBg() async {
    await _bgPlayer.stop();
  }

  void dispose() {
    _player.dispose();
    _bgPlayer.dispose();
  }
}

/// All audio asset paths in one place.
/// Add new entries here as audio files are added to assets/.
enum AudioAsset {
  correct,
  incorrect,
  normalClick,
  // Background music
  bgMain,
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
      case AudioAsset.normalClick:
        return 'assets/audio/sfx/normal_click.mp3';
      case AudioAsset.bgMain:
        return 'assets/audio/background/bg_main.mp3';
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
