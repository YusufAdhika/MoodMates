import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';

/// A large tappable button that plays an audio label when pressed.
///
/// Satisfies the design requirement that every UI element has both
/// a visual AND audio representation for pre-reader ages 4–6.
///
/// Minimum size: 64×64dp (larger than Material's 48dp for child motor accuracy).
class AudioButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final AudioAsset? audioAsset;
  final Color? color;
  final VoidCallback onTap;
  final double size;

  const AudioButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.audioAsset,
    this.color,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (audioAsset != null) {
          context.read<AudioService>().play(audioAsset!);
        }
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(size / 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: size * 0.45),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
