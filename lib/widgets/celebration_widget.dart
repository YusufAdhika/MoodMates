import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';

/// Full celebration overlay shown after a correct answer or game completion.
///
/// Plays confetti + audio praise. Lottie character animation can be layered
/// on top once .json files are added to assets/.
///
/// Usage:
///   showDialog(
///     context: context,
///     builder: (_) => const CelebrationWidget(onDismiss: ...),
///   );
class CelebrationWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const CelebrationWidget({
    super.key,
    this.message = 'Hebat!',
    required this.onDismiss,
  });

  @override
  State<CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<CelebrationWidget> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _confettiController.play();

    // Play random praise audio
    final praiseAssets = [
      AudioAsset.praiseHebat,
      AudioAsset.praiseKamuPintar,
      AudioAsset.praiseLuarBiasa,
      AudioAsset.praiseBagusSekali,
    ];
    final random = Random();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AudioService>().play(
          praiseAssets[random.nextInt(praiseAssets.length)],
        );
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Semi-transparent background
        GestureDetector(
          onTap: widget.onDismiss,
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
          ),
        ),

        // Confetti
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          colors: const [
            Colors.amber,
            Colors.pink,
            Colors.blue,
            Colors.green,
            Colors.purple,
          ],
        ),

        // Message card
        Center(
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TODO: replace with Lottie.asset('assets/lottie/star.json')
                  // once Lottie files are added
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.message,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tap anywhere to continue hint
                  const Text(
                    'Tap untuk lanjut',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
