import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final buttonColor = color ?? const Color(0xFFFF9A3C);
    final shadowColor = _shadowFor(buttonColor);

    return Padding(
      padding: const EdgeInsets.only(right: 5, bottom: 7),
      child: GestureDetector(
        onTap: () {
          if (audioAsset != null) {
            context.read<AudioService>().play(audioAsset!);
          }
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            color: shadowColor,
            borderRadius: BorderRadius.circular(size / 4),
          ),
          child: Transform.translate(
            offset: const Offset(-5, -7),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(size / 4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: size * 0.45),
                  if (label.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.baloo2(
                        color: Colors.white,
                        fontSize: size * 0.16,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _shadowFor(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness - 0.28).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.1).clamp(0.0, 1.0))
        .toColor();
  }
}
