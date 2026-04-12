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

/// A social scenario presented to the child.
class SocialScenario {
  final String descriptionId;   // Indonesian description of the situation
  final String imageAsset;      // Path in assets/images/scenarios/
  final Emotion correctEmotion; // What the child in the scenario should feel

  const SocialScenario({
    required this.descriptionId,
    required this.imageAsset,
    required this.correctEmotion,
  });
}

/// All scenarios used in the Social Situations game.
/// TODO: expand this list and add actual illustration assets.
const List<SocialScenario> scenarios = [
  SocialScenario(
    descriptionId: 'Teman kamu memberikan hadiah ulang tahun. Bagaimana perasaanmu?',
    imageAsset: 'assets/images/scenarios/birthday_gift.png',
    correctEmotion: Emotion.happy,
  ),
  SocialScenario(
    descriptionId: 'Mainan kesayanganmu rusak. Bagaimana perasaanmu?',
    imageAsset: 'assets/images/scenarios/broken_toy.png',
    correctEmotion: Emotion.sad,
  ),
  SocialScenario(
    descriptionId: 'Seseorang mengambil makananmu tanpa izin. Bagaimana perasaanmu?',
    imageAsset: 'assets/images/scenarios/food_taken.png',
    correctEmotion: Emotion.angry,
  ),
  SocialScenario(
    descriptionId: 'Kamu melihat sesuatu yang besar dan tidak kamu kenal. Bagaimana perasaanmu?',
    imageAsset: 'assets/images/scenarios/strange_thing.png',
    correctEmotion: Emotion.scared,
  ),
  SocialScenario(
    descriptionId: 'Temanmu tiba-tiba melompat dari balik pintu. Bagaimana perasaanmu?',
    imageAsset: 'assets/images/scenarios/jump_scare.png',
    correctEmotion: Emotion.surprised,
  ),
];

/// Mini-game 3: Social Situations
///
/// Shows an illustrated social scenario. Child selects the emotion that
/// the character in the scenario should feel.
///
/// Round flow:
///   1. Display scenario illustration + audio description
///   2. Show emotion choice cards
///   3. Child taps a card (debounced 300ms)
///   4. Reveal correct/incorrect
///   5. If correct → celebration → next round
///   6. If incorrect → hint → retry
class SocialSituationsScreen extends StatefulWidget {
  const SocialSituationsScreen({super.key});

  @override
  State<SocialSituationsScreen> createState() => _SocialSituationsScreenState();
}

class _SocialSituationsScreenState extends State<SocialSituationsScreen> {
  static const int _totalRounds = 5;

  final Random _random = Random();

  int _round = 1;
  late SocialScenario _currentScenario;
  late List<Emotion> _choices;
  Emotion? _selectedEmotion;
  bool _revealed = false;
  bool _isTapLocked = false;

  @override
  void initState() {
    super.initState();
    _nextRound();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<AudioService>()
          .play(AudioAsset.instructionSocialSituations);
    });
  }

  void _nextRound() {
    final shuffled = List<SocialScenario>.from(scenarios)..shuffle(_random);
    setState(() {
      _currentScenario = shuffled.first;
      _choices = _buildChoices(_currentScenario.correctEmotion);
      _selectedEmotion = null;
      _revealed = false;
      _isTapLocked = false;
    });
  }

  List<Emotion> _buildChoices(Emotion correct) {
    final distractors = allEmotions.where((e) => e != correct).toList()
      ..shuffle(_random);
    return ([correct, ...distractors.take(3)])..shuffle(_random);
  }

  Future<void> _onCardTap(Emotion tapped) async {
    if (_isTapLocked || _revealed) return;
    _isTapLocked = true;

    final isCorrect = tapped == _currentScenario.correctEmotion;
    // Capture providers before async gaps
    final progressProvider = context.read<ProgressProvider>();
    final audioService = context.read<AudioService>();

    setState(() {
      _selectedEmotion = tapped;
      _revealed = true;
    });

    await progressProvider.recordSession(
      gameId: GameProgress.gameSocialSituations,
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
          message: 'Pintar! 🌟',
          onDismiss: () {
            Navigator.of(context).pop();
            if (_round >= _totalRounds) {
              context.go('/');
            } else {
              setState(() => _round++);
              _nextRound();
            }
          },
        ),
      );
    } else {
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
        backgroundColor: const Color(0xFFF1F8E9),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.green),
            onPressed: () async {
              if (await _onWillPop() && context.mounted) context.go('/');
            },
          ),
          title: Text(
            'Ronde $_round / $_totalRounds',
            style: const TextStyle(color: Colors.green),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ── Scenario illustration ─────────────────────────────────
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  // TODO: Image.asset(_currentScenario.imageAsset)
                  child: Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              // ── Scenario description ──────────────────────────────────
              Text(
                _currentScenario.descriptionId,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── Choice cards ─────────────────────────────────────────
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: _choices.map((emotion) {
                    return EmotionCard(
                      emotion: emotion,
                      isSelected: _selectedEmotion == emotion,
                      isCorrect: emotion == _currentScenario.correctEmotion,
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
}
