import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final bool isCorrect; // null = not yet revealed
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
      borderColor =
          isCorrect ? const Color(0xFF4CAF6E) : const Color(0xFFE53935);
    }
    final emotionColor = _emotionToColor(emotion);
    final shadowColor = _emotionShadowColor(emotion);

    return Padding(
      padding: const EdgeInsets.only(right: 5, bottom: 7),
      child: GestureDetector(
        onTap: () {
          context.read<AudioService>().play(_emotionToAudio(emotion));
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: shadowColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Transform.translate(
            offset: const Offset(-5, -7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 4),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: emotionColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _emotionToIcon(emotion),
                      size: 42,
                      color: emotionColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emotion.labelId,
                    style: GoogleFonts.baloo2(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D2B1A),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        return const Color(0xFFFF9A3C);
      case Emotion.sad:
        return const Color(0xFF4BA3C3);
      case Emotion.angry:
        return const Color(0xFFE53935);
      case Emotion.surprised:
        return const Color(0xFFFFC247);
      case Emotion.scared:
        return const Color(0xFF7E57C2);
      case Emotion.neutral:
        return const Color(0xFF8D6E63);
    }
  }

  Color _emotionShadowColor(Emotion e) {
    switch (e) {
      case Emotion.happy:
        return const Color(0xFFC85A00);
      case Emotion.sad:
        return const Color(0xFF1464A0);
      case Emotion.angry:
        return const Color(0xFF9F1E1B);
      case Emotion.surprised:
        return const Color(0xFFC49000);
      case Emotion.scared:
        return const Color(0xFF4D2A80);
      case Emotion.neutral:
        return const Color(0xFF5D4037);
    }
  }
}
