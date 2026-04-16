import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/emotion.dart';
import '../../models/game_progress.dart';
import '../../providers/progress_provider.dart';
import '../../services/audio_service.dart';
import '../../widgets/celebration_widget.dart';
import '../../widgets/emotion_card.dart';

/// Raccoo Feel Cards: interactive flashcards for six basic emotions.
///
/// The child taps the emotion card that matches Raccoo's audio instruction.
/// This introduces six basic emotions inspired by Paul Ekman's universal
/// emotion set: happy, sad, anger, fear, surprise, and disgust.
///
/// Round flow:
///   1. Play Raccoo's instruction audio for the target emotion
///   2. Display the target emotion image
///   2. Show 4 emotion cards (1 correct + 3 distractors)
///   3. Child taps a card (debounced 300ms)
///   4. Reveal correct/incorrect highlight
///   5. If correct → show CelebrationWidget → next round
///   6. If incorrect → show hint → allow retry
class EmotionRecognitionScreen extends StatefulWidget {
  const EmotionRecognitionScreen({super.key});

  @override
  State<EmotionRecognitionScreen> createState() =>
      _EmotionRecognitionScreenState();
}

class _EmotionRecognitionScreenState extends State<EmotionRecognitionScreen> {
  static const int _totalRounds = 5;

  final Random _random = Random();

  int _round = 1;
  late Emotion _targetEmotion;
  late List<Emotion> _choices;
  Emotion? _selectedEmotion;
  bool _revealed = false;
  bool _isTapLocked = false; // debounce guard

  @override
  void initState() {
    super.initState();
    _nextRound();
    // Auto-play feature instruction audio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<AudioService>()
          .play(AudioAsset.instructionEmotionRecognition);
    });
  }

  void _nextRound() {
    setState(() {
      _targetEmotion = allEmotions[_random.nextInt(allEmotions.length)];
      _choices = _buildChoices(_targetEmotion);
      _selectedEmotion = null;
      _revealed = false;
      _isTapLocked = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AudioService>().play(_emotionToAudio(_targetEmotion));
    });
  }

  List<Emotion> _buildChoices(Emotion target) {
    final distractors = allEmotions.where((e) => e != target).toList()
      ..shuffle(_random);
    return ([target, ...distractors.take(3)])..shuffle(_random);
  }

  Future<void> _onCardTap(Emotion tapped) async {
    if (_isTapLocked || _revealed) return;
    _isTapLocked = true;

    final isCorrect = tapped == _targetEmotion;
    // Capture providers before async gaps
    final progressProvider = context.read<ProgressProvider>();
    final audioService = context.read<AudioService>();

    setState(() {
      _selectedEmotion = tapped;
      _revealed = true;
    });

    await progressProvider.recordSession(
      gameId: GameProgress.gameEmotionRecognition,
      wasCorrect: isCorrect,
    );

    audioService.play(isCorrect ? AudioAsset.correct : AudioAsset.incorrect);

    if (isCorrect) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => CelebrationWidget(
          message: 'Benar! 🌟',
          onDismiss: () {
            Navigator.of(context).pop();
            if (_round >= _totalRounds) {
              context.go('/home');
            } else {
              setState(() => _round++);
              _nextRound();
            }
          },
        ),
      );
    } else {
      // Allow retry after 1s
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _revealed = false;
          _selectedEmotion = null;
          _isTapLocked = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesai belajar emosi?'),
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
        if (shouldPop && context.mounted) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF3E0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.brown),
            onPressed: () async {
              if (await _onWillPop() && context.mounted) context.go('/home');
            },
          ),
          title: Text(
            'Ronde $_round / $_totalRounds',
            style: const TextStyle(color: Colors.brown),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ── Instruction ─────────────────────────────────────────────
              const Text(
                'Raccoo Feel Cards',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sentuh kartu emosi yang sesuai dengan instruksi suara Raccoo untuk mengenal 6 emosi dasar.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8D6E63),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── Target emotion display ───────────────────────────────────
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      _targetEmotion.characterAsset,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.face,
                          size: 80,
                          color: Colors.orange,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Choice cards ─────────────────────────────────────────────
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: _choices.map((emotion) {
                    return EmotionCard(
                      emotion: emotion,
                      isSelected: _selectedEmotion == emotion,
                      isCorrect: emotion == _targetEmotion,
                      isRevealed: _revealed,
                      onTap: () => _onCardTap(emotion),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AudioAsset _emotionToAudio(Emotion emotion) {
    switch (emotion) {
      case Emotion.happy:
        return AudioAsset.emotionHappy;
      case Emotion.sad:
        return AudioAsset.emotionSad;
      case Emotion.angry:
        return AudioAsset.emotionAngry;
      case Emotion.scared:
        return AudioAsset.emotionScared;
      case Emotion.surprised:
        return AudioAsset.emotionSurprised;
      case Emotion.disgust:
        return AudioAsset.emotionDisgust;
      case Emotion.neutral:
        return AudioAsset.emotionHappy;
    }
  }
}
