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

  bool _bgShouldPlay = false;
  int _sfxGeneration = 0;

  AudioService() {
    // Auto-resume bg music when audio focus is lost (e.g. SFX interrupts it).
    _bgPlayer.playerStateStream.listen((state) {
      if (_bgShouldPlay &&
          !state.playing &&
          state.processingState == ProcessingState.ready) {
        _bgPlayer.play();
      }
    });
  }

  Future<void> init() async {
    // Pre-load commonly used SFX so playback is instant.
    // TODO: uncomment once audio files are added to assets/audio/
    // await _preload(AudioAsset.correct);
    // await _preload(AudioAsset.incorrect);
  }

  /// Play a one-shot SFX asset. Safe when device is muted — just silent.
  /// Silently skips if the asset file has not been added to the bundle yet.
  /// Rapid calls cancel in-flight predecessors — only the latest sound plays.
  Future<void> play(AudioAsset asset) async {
    final generation = ++_sfxGeneration;
    try {
      await rootBundle.load(asset.path);
    } catch (_) {
      return;
    }
    if (generation != _sfxGeneration) return;
    try {
      await _player.stop();
      if (generation != _sfxGeneration) return;
      await _player.setAsset(asset.path);
      if (generation != _sfxGeneration) return;
      await _player.play();
    } catch (e) {
      debugPrint('[AudioService] Failed to play ${asset.path}: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  /// Start looping background music. Stops any currently playing track first.
  Future<void> playBg(AudioAsset asset) async {
    try {
      await rootBundle.load(asset.path);
    } catch (_) {
      debugPrint('[AudioService] BG asset not found: ${asset.path}');
      return;
    }
    try {
      _bgShouldPlay = false;
      if (_bgPlayer.playing) await _bgPlayer.stop();
      await _bgPlayer.setAsset(asset.path);
      await _bgPlayer.setLoopMode(LoopMode.one);
      await _bgPlayer.setVolume(0.5);
      _bgShouldPlay = true;
      await _bgPlayer.play();
      debugPrint('[AudioService] BG playing: ${asset.path}');
    } catch (e) {
      debugPrint('[AudioService] Failed to play bg ${asset.path}: $e');
    }
  }

  /// Pause background music (preserves position).
  Future<void> pauseBg() async {
    _bgShouldPlay = false;
    await _bgPlayer.pause();
  }

  /// Stop and reset background music.
  Future<void> stopBg() async {
    _bgShouldPlay = false;
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
  yeay,
  // Background music
  bgMain,
  bgPlay,
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
      case AudioAsset.yeay:
        return 'assets/audio/sfx/yeay.mp3';
      case AudioAsset.bgMain:
        return 'assets/audio/background/bg_main.mp3';
      case AudioAsset.bgPlay:
        return 'assets/audio/background/bg_play.mp3';
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
