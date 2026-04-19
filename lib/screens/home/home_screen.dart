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

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color shadowColor;
  final VoidCallback onTap;
  final bool compact;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.shadowColor,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isUltraCompact = constraints.maxHeight < 150;
          final isTightHeight =
              isUltraCompact || compact || constraints.maxHeight < 190;
          final iconBoxSize = isUltraCompact
              ? 48.0
              : isTightHeight
                  ? 68.0
                  : 96.0;
          final iconSize = isUltraCompact
              ? 28.0
              : isTightHeight
                  ? 38.0
                  : 56.0;
          final titleSize = isUltraCompact
              ? 20.0
              : isTightHeight
                  ? 24.0
                  : 30.0;
          final subtitleSize = isUltraCompact
              ? 11.0
              : isTightHeight
                  ? 13.0
                  : 15.0;
          final buttonSize = isUltraCompact
              ? 12.0
              : isTightHeight
                  ? 14.0
                  : 16.0;
          final cardPadding = isUltraCompact
              ? 14.0
              : isTightHeight
                  ? 18.0
                  : 28.0;
          final cardRadius = isTightHeight ? 20.0 : 24.0;
          final iconRadius = isUltraCompact
              ? 14.0
              : isTightHeight
                  ? 18.0
                  : 24.0;
          final spaceLg = isTightHeight ? 12.0 : 20.0;
          final spaceSm = isTightHeight ? 6.0 : 8.0;

          Widget content;
          if (isUltraCompact) {
            content = Row(
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(iconRadius),
                  ),
                  child: Icon(icon, size: iconSize, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.baloo2(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle.replaceAll('\n', ' '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: subtitleSize,
                          height: 1.2,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Main',
                    style: GoogleFonts.baloo2(
                      fontSize: buttonSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          } else {
            content = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Container(
                //   width: iconBoxSize,
                //   height: iconBoxSize,
                //   decoration: BoxDecoration(
                //     color: Colors.white.withValues(alpha: 0.25),
                //     borderRadius: BorderRadius.circular(iconRadius),
                //   ),
                //   child: Icon(icon, size: iconSize, color: Colors.white),
                // ),
                // SizedBox(height: spaceLg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.baloo2(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: spaceSm),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: subtitleSize,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                SizedBox(height: spaceLg),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTightHeight ? 16 : 20,
                    vertical: isTightHeight ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Main Sekarang →',
                    style: GoogleFonts.baloo2(
                      fontSize: buttonSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          }

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(cardRadius),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.7),
                  offset: const Offset(5, 8),
                  blurRadius: 0,
                ),
              ],
            ),
            padding: EdgeInsets.all(cardPadding),
            child: content,
          );
        },
      ),
    );
  }
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
                    'Fitur permainan lama sudah dihapus dan siap dibuat ulang.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8D6E63),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => context.push('/feel-cards-design'),
                    icon: const Icon(Icons.palette_outlined, size: 18),
                    label: const Text('Review design system Feel Cards'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFC85A00),
                      backgroundColor: Colors.white.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Game Menu ────────────────────────────────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  final spacing = availableHeight < 620 ? 12.0 : 16.0;
                  final compactCards = availableHeight < 620;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Column(
                      children: [
                        Expanded(
                          child: _GameCard(
                            title: 'Raccoo Feel Cards',
                            subtitle: 'Kenalan sama 6 perasaan\nbareng Raccoo!',
                            icon: Icons.style_rounded,
                            color: const Color(0xFFFF9A3C),
                            shadowColor: const Color(0xFFC85A00),
                            compact: compactCards,
                            onTap: () => context.push('/feel-cards'),
                          ),
                        ),
                        SizedBox(height: spacing),
                        Expanded(
                          child: _GameCard(
                            title: 'Raccoo Mirror',
                            subtitle:
                                'Tirukan ekspresi wajah\nRaccoo di depan kamera!',
                            icon: Icons.camera_front_rounded,
                            color: const Color(0xFF4BA3C3),
                            shadowColor: const Color(0xFF1464A0),
                            compact: compactCards,
                            onTap: () => context.push('/mirror'),
                          ),
                        ),
                        SizedBox(height: spacing),
                        Expanded(
                          child: _GameCard(
                            title: 'Raccoo Think',
                            subtitle:
                                'Latih respons sosial\ndalam situasi sehari-hari!',
                            icon: Icons.forum_rounded,
                            color: const Color(0xFF4CAF6E),
                            shadowColor: const Color(0xFF1A5E36),
                            compact: compactCards,
                            onTap: () => context.push('/think'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
