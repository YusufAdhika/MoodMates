import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/progress_provider.dart';

/// Main menu screen — the first screen children see.
///
/// Design: hybrid full-width cards (see DESIGN.md).
///   • Full-width zone-color cards, no horizontal margin
///   • Hard colored offset shadows (DESIGN.md risk #1)
///   • Icon circle on left, Baloo 2 bold title, DM Sans subtitle
///   • 64dp+ touch targets
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress.childName.isNotEmpty
                        ? 'Halo, ${progress.childName}! 👋'
                        : 'Halo! 👋',
                    style: GoogleFonts.baloo2(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3D2B1A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ayo pilih permainan hari ini.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8D6E63),
                    ),
                  ),
                ],
              ),
            ),

            // ── Game Cards ───────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                children: [
                  _GameCard(
                    label: 'Kenali Emosi',
                    subtitle: 'Tebak perasaan dari wajah',
                    zoneColor: const Color(0xFFFF9A3C),
                    shadowColor: const Color(0xFFC85A00),
                    iconData: Icons.face_rounded,
                    onTap: () => context.push('/emotion-recognition'),
                  ),
                  _GameCard(
                    label: 'Tiru Ekspresi',
                    subtitle: 'Tunjukkan ekspresimu!',
                    zoneColor: const Color(0xFF4BA3C3),
                    shadowColor: const Color(0xFF1464A0),
                    iconData: Icons.camera_front_rounded,
                    onTap: () => context.push('/expression-mirroring'),
                  ),
                  _GameCard(
                    label: 'Situasi Sosial',
                    subtitle: 'Pilih perasaan yang cocok',
                    zoneColor: const Color(0xFF4CAF6E),
                    shadowColor: const Color(0xFF14824A),
                    iconData: Icons.groups_rounded,
                    onTap: () => context.push('/social-situations'),
                  ),
                ],
              ),
            ),

            // ── Parent Mode ──────────────────────────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.push('/profiles'),
                      icon: const Icon(Icons.switch_account_rounded, size: 16),
                      label: const Text('Ganti Anak'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8D6E63),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/parent-pin'),
                      icon: const Icon(Icons.lock_outline, size: 16),
                      label: const Text('Mode Orang Tua'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8D6E63),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color zoneColor;
  final Color shadowColor;
  final IconData iconData;
  final VoidCallback onTap;

  const _GameCard({
    required this.label,
    required this.subtitle,
    required this.zoneColor,
    required this.shadowColor,
    required this.iconData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Bottom offset space so the hard shadow doesn't clip
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // Hard colored offset shadow — DESIGN.md risk #1
          decoration: BoxDecoration(
            color: shadowColor,
            borderRadius: BorderRadius.circular(24),
          ),
          // The shadow offset is achieved by translating the card up/left
          // so only the shadow container peeks out on the bottom-right.
          child: Transform.translate(
            offset: const Offset(-5, -7),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: zoneColor,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Icon circle
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, size: 36, color: Colors.white),
                  ),
                  const SizedBox(width: 16),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.baloo2(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
