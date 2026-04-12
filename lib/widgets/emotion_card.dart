import 'package:flutter/material.dart';
import '../models/emotion.dart';
import '../services/audio_service.dart';
import 'package:provider/provider.dart';

/// A tappable card displaying an emotion face illustration.
///
/// Used in Emotion Recognition (answer choices) and Social Situations
/// (response options). Plays the emotion audio label on tap.
///
/// Touch target is minimum 64×64dp — children ages 4–6 need larger
/// targets than the Material 48dp minimum.
class EmotionCard extends StatelessWidget {
  final Emotion emotion;
  final bool isSelected;
  final bool isCorrect;   // null = not yet revealed
  final bool isRevealed;
  final VoidCallback onTap;

  const EmotionCard({
    super.key,
    required this.emotion,
    required this.onTap,
    this.isSelected = false,
    this.isCorrect = false,
    this.isRevealed = false,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.transparent;
    if (isRevealed && isSelected) {
      borderColor = isCorrect ? Colors.green : Colors.red;
    }

    return GestureDetector(
      onTap: () {
        // Play emotion audio label when tapped
        context.read<AudioService>().play(
          _emotionToAudio(emotion),
        );
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO: replace with Image.asset(emotion.characterAsset)
            // once character illustrations are in assets/images/characters/
            Icon(
              _emotionToIcon(emotion),
              size: 48,
              color: _emotionToColor(emotion),
            ),
            const SizedBox(height: 8),
            Text(
              emotion.labelId,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AudioAsset _emotionToAudio(Emotion e) {
    switch (e) {
      case Emotion.happy:
        return AudioAsset.emotionHappy;
      case Emotion.sad:
        return AudioAsset.emotionSad;
      case Emotion.angry:
        return AudioAsset.emotionAngry;
      case Emotion.surprised:
        return AudioAsset.emotionSurprised;
      case Emotion.scared:
        return AudioAsset.emotionScared;
      case Emotion.neutral:
        return AudioAsset.emotionHappy; // fallback
    }
  }

  IconData _emotionToIcon(Emotion e) {
    switch (e) {
      case Emotion.happy:
        return Icons.sentiment_very_satisfied;
      case Emotion.sad:
        return Icons.sentiment_very_dissatisfied;
      case Emotion.angry:
        return Icons.sentiment_dissatisfied;
      case Emotion.surprised:
        return Icons.sentiment_neutral;
      case Emotion.scared:
        return Icons.sentiment_very_dissatisfied;
      case Emotion.neutral:
        return Icons.sentiment_neutral;
    }
  }

  Color _emotionToColor(Emotion e) {
    switch (e) {
      case Emotion.happy:
        return Colors.amber;
      case Emotion.sad:
        return Colors.blue;
      case Emotion.angry:
        return Colors.red;
      case Emotion.surprised:
        return Colors.purple;
      case Emotion.scared:
        return Colors.deepPurple;
      case Emotion.neutral:
        return Colors.grey;
    }
  }
}
