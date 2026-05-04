import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../providers/progress_provider.dart';
import '../../services/audio_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late AudioService _audio;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _audio = context.read<AudioService>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audio.playBg(AudioAsset.bgMain);
      _router = GoRouter.of(context);
      _router!.routerDelegate.addListener(_onRouteChanged);
    });
  }

  void _onRouteChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        _audio.playBg(AudioAsset.bgMain);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _audio.playBg(AudioAsset.bgMain);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _audio.pauseBg();
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    WidgetsBinding.instance.removeObserver(this);
    _audio.stopBg();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double screenW = screen.width;
    final double screenH = screen.height;

    // Tablet when the shorter side is >= 600 logical pixels
    final bool isTablet = screen.shortestSide >= 600;

    // On tablets, content is centred in a capped column so it doesn't
    // stretch awkwardly across a 10-inch display.
    final double contentW = isTablet ? 520.0 : screenW;
    final double contentX = (screenW - contentW) / 2;

    // Scaled element sizes
    final double cardW = contentW * (isTablet ? 0.64 : 0.50);
    final double cardH = isTablet ? 124.0 : 90.0;
    final double titleImgW = contentW * (isTablet ? 0.76 : 0.70);
    final double formImgW = contentW * (isTablet ? 0.92 : 0.90);
    final double sideMargin = contentW * 0.12;

    // Font sizes
    final double nameFontSize = isTablet ? 34.0 : 25.0;
    final double menuFontSize = isTablet ? 20.0 : 14.0;
    final double bottomIconSize = isTablet ? 20.0 : 16.0;
    final double bottomFontSize = isTablet ? 14.0 : 12.0;

    // Vertical position ratios — slightly tighter on tablets which tend to
    // have a squarer aspect ratio than phones.
    final double formTopRatio = isTablet ? 0.22 : 0.25;
    final double greetTopRatio = isTablet ? 0.28 : 0.30;
    final double menuTopRatio = isTablet ? 0.36 : 0.40;

    final progress = context.watch<ProgressProvider>().progress;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ──────────────────────────────────────────────────────
          Image.asset(
            'assets/images/background/bg_main.png',
            fit: BoxFit.cover,
          ),

          SafeArea(
            child: SizedBox(
              height: screenH * 0.92,
              child: Stack(
                children: [
                  // ── Title image ─────────────────────────────────────────────
                  Positioned(
                    top: 0,
                    left: contentX,
                    width: contentW,
                    child: Center(
                      child: Image.asset(
                        'assets/images/ui/title_ui.png',
                        width: titleImgW,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),

                  // ── Form panel ──────────────────────────────────────────────
                  Positioned(
                    top: screenH * formTopRatio,
                    left: contentX,
                    width: contentW,
                    child: Center(
                      child: Image.asset(
                        'assets/images/ui/form_main_ui.png',
                        width: formImgW,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),

                  // ── Greeting text ────────────────────────────────────────────
                  Positioned(
                    top: screenH * greetTopRatio,
                    left: contentX + sideMargin,
                    right: screenW - (contentX + contentW - sideMargin),
                    child: Center(
                      child: Text(
                        progress.childName.isNotEmpty
                            ? 'Halo, ${progress.childName} !'
                            : 'Halo!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ribeye(
                          fontSize: nameFontSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(1, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Menu cards ───────────────────────────────────────────────
                  Positioned(
                    top: screenH * menuTopRatio,
                    left: contentX + sideMargin,
                    right: screenW - (contentX + contentW - sideMargin),
                    child: Column(
                      children: [
                        _MenuCard(
                          label: 'Raccoo Feel Cards',
                          cardW: cardW,
                          cardH: cardH,
                          fontSize: menuFontSize,
                          onTap: () {
                            _audio.play(AudioAsset.normalClick);
                            context.push('/feel-cards');
                          },
                        ),
                        _MenuCard(
                          label: 'Raccoo Mirror',
                          cardW: cardW,
                          cardH: cardH,
                          fontSize: menuFontSize,
                          onTap: () {
                            _audio.play(AudioAsset.normalClick);
                            context.push('/mirror');
                          },
                        ),
                        _MenuCard(
                          label: 'Raccoo Think',
                          cardW: cardW,
                          cardH: cardH,
                          fontSize: menuFontSize,
                          onTap: () {
                            _audio.play(AudioAsset.normalClick);
                            context.push('/think');
                          },
                        ),
                        BottomButtons(
                          audio: _audio,
                          iconSize: bottomIconSize,
                          fontSize: bottomFontSize,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Menu Card ────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final String label;
  final double cardW;
  final double cardH;
  final double fontSize;
  final VoidCallback onTap;

  const _MenuCard({
    required this.label,
    required this.cardW,
    required this.cardH,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/ui/card_ui.png',
            width: cardW,
            height: cardH,
            fit: BoxFit.fill,
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.ribeye(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Buttons ───────────────────────────────────────────────────────────

class BottomButtons extends StatelessWidget {
  final AudioService audio;
  final double iconSize;
  final double fontSize;

  const BottomButtons({
    super.key,
    required this.audio,
    this.iconSize = 16.0,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: () {
              audio.play(AudioAsset.normalClick);
              context.push('/profiles');
            },
            icon: Icon(
              Icons.switch_account_rounded,
              size: iconSize,
              color: const Color(0xFF5D3A1A),
            ),
            label: Text(
              'Ganti Anak',
              style: TextStyle(
                color: const Color(0xFF5D3A1A),
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF5D3A1A),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              audio.play(AudioAsset.normalClick);
              context.push('/parent-pin');
            },
            icon: Icon(
              Icons.lock_outline,
              size: iconSize,
              color: const Color(0xFF5D3A1A),
            ),
            label: Text(
              'Mode Orang Tua',
              style: TextStyle(
                color: const Color(0xFF5D3A1A),
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF5D3A1A),
            ),
          ),
        ],
      ),
    );
  }
}
