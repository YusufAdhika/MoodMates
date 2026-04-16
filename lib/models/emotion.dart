/// Emotion definitions for all three mini-games.
///
/// ML Kit thresholds for Expression Mirroring:
///   happy    → smileProbability > 0.7
///   surprised → leftEyeOpenProbability > 0.8 && smileProbability < 0.4
///   scared   → leftEyeOpenProbability < 0.3 && smileProbability < 0.3
///
/// sad, angry, neutral are used only in Emotion Recognition and Social
/// Situations games (no camera required).
enum Emotion {
  happy,
  sad,
  angry,
  scared,
  surprised,
  disgust,
  neutral,
}

extension EmotionExtension on Emotion {
  /// Indonesian display label shown to children (with audio equivalent).
  String get labelId {
    switch (this) {
      case Emotion.happy:
        return 'Senang';
      case Emotion.sad:
        return 'Sedih';
      case Emotion.angry:
        return 'Marah';
      case Emotion.scared:
        return 'Takut';
      case Emotion.surprised:
        return 'Terkejut';
      case Emotion.disgust:
        return 'Jijik';
      case Emotion.neutral:
        return 'Biasa';
    }
  }

  /// Asset path for the character face illustration.
  /// Place PNG files in assets/images/characters/.
  String get characterAsset {
    return 'assets/images/characters/$name.png';
  }

  /// Audio instruction asset path.
  /// Place MP3 files in assets/audio/instructions/.
  String get audioAsset {
    return 'assets/audio/instructions/emotion_$name.mp3';
  }
}

/// Emotions available in the Expression Mirroring game (limited to what
/// Google ML Kit can reliably detect from smile + eye-open probabilities).
const List<Emotion> mirroringEmotions = [
  Emotion.happy,
  Emotion.surprised,
  Emotion.scared,
];

/// Full emotion set used in Raccoo Feel Cards and Social Situations.
const List<Emotion> allEmotions = [
  Emotion.happy,
  Emotion.sad,
  Emotion.angry,
  Emotion.scared,
  Emotion.surprised,
  Emotion.disgust,
];
