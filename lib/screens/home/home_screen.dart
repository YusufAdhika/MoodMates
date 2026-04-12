import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/progress_provider.dart';

/// Main menu screen — the first screen children see.
///
/// Design requirements (ages 4–6):
///   • Large touch targets (64dp+)
///   • Character mascot visible on entry
///   • Audio instruction auto-plays on load
///   • No text-only navigation — icons + audio labels
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-play welcome audio on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TODO: play welcome audio when assets are added
      // context.read<AudioService>().play(AudioAsset.instructionHome);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>().progress;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header / Mascot ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Greeting
                  if (progress.childName.isNotEmpty)
                    Text(
                      'Halo, ${progress.childName}! 👋',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5C4033),
                      ),
                    )
                  else
                    const Text(
                      'Halo! 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5C4033),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mau bermain apa hari ini?',
                    style: TextStyle(fontSize: 18, color: Colors.brown),
                  ),
                ],
              ),
            ),

            // ── Game Buttons ──────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: 1,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3.5,
                  children: [
                    _GameMenuButton(
                      icon: Icons.face,
                      label: 'Kenali Emosi',
                      subtitle: 'Tebak perasaan temanmu',
                      color: const Color(0xFFFFB347),
                      onTap: () => context.push('/emotion-recognition'),
                    ),
                    _GameMenuButton(
                      icon: Icons.camera_front,
                      label: 'Tiru Ekspresi',
                      subtitle: 'Tunjukkan ekspresimu!',
                      color: const Color(0xFF87CEEB),
                      onTap: () => context.push('/expression-mirroring'),
                    ),
                    _GameMenuButton(
                      icon: Icons.groups,
                      label: 'Situasi Sosial',
                      subtitle: 'Apa yang harus dilakukan?',
                      color: const Color(0xFF98FB98),
                      onTap: () => context.push('/social-situations'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Parent Mode Button ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: TextButton.icon(
                onPressed: () => context.push('/parent-pin'),
                icon: const Icon(Icons.lock_outline, size: 18),
                label: const Text('Mode Orang Tua'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.brown.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _GameMenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
