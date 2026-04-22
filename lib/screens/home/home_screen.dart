import 'package:flutter/material.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with RouteAware, WidgetsBindingObserver {
  late AudioService _audio;

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _audio.playBg(AudioAsset.bgMain);
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
    WidgetsBinding.instance.removeObserver(this);
    _audio.stopBg();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX 1: use double, not Long
    final double screenW = MediaQuery
        .of(context)
        .size
        .width;
    final double screenH = MediaQuery
        .of(context)
        .size
        .height;

    // ignore: unused_local_variable
    final progress = context
        .watch<ProgressProvider>()
        .progress;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── Layer 1: Background ──
          Image.asset(
            'assets/images/background/bg_main.png',
            fit: BoxFit.cover,
          ),

          // FIX 2: SafeArea only accepts `child`, moved everything inside correctly
          SafeArea(
            child:
            // FIX 3: Stack inside Column must have a bounded height
            SizedBox(
              height: screenH * 0.88,
              child: Stack(
                children: [

                  // Title image
                  Positioned(
                    top: 0,
                    left: 0,
                    width: screenW,
                    child: Center(
                      child: Image.asset(
                        'assets/images/ui/title_ui.png',
                        width: screenW * 0.7,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),

                  // Form panel image
                  Positioned(
                    top: screenH * 0.25,
                    left: 0,
                    width: screenW,
                    child: Center(
                      child: Image.asset(
                        'assets/images/ui/form_main_ui.png',
                        width: screenW * 0.9,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),

                  // ── Menu cards ──
                  Positioned(
                    top: (screenH * 0.4),
                    left: screenW * 0.12,
                    right: screenW * 0.12,
                    child: Column(
                      children: [
                        _MenuCard(
                          label: 'Raccoo Feel Cards',
                          screenW: screenW,
                          onTap: () {
                            _audio.play(AudioAsset.normalClick);
                            context.push('/feel-cards');
                          },
                        ),
                        _MenuCard(
                          label: 'Raccoo Mirror',
                          screenW: screenW,
                          onTap: () {
                            _audio.play(AudioAsset.normalClick);
                            context.push('/mirror');
                          },
                        ),
                        _MenuCard(
                          label: 'Raccoo Think',
                          screenW: screenW,
                          onTap: () {
                            _audio.play(AudioAsset.normalClick);
                            context.push('/think');
                          },
                        ),
                        BottomButtons(audio: _audio),
                      ],
                    ),
                  ),

                  Positioned(
                      top: (screenH * 0.30),
                      left: screenW * 0.12,
                      right: screenW * 0.12,
                      child:
                      Center(
                          child:
                          Text(
                            progress.childName.isNotEmpty
                                ? 'Halo, ${progress.childName} !'
                                : 'Halo!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.ribeye(
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5), // shadow color
                                    blurRadius: 4, // shadow blur
                                    offset: Offset(1, 2), // x, y position
                                  ),
                                ]
                            ),
                          ),
                      )

                  ),

                ],
              ),
            ),

            // ── Bottom buttons ──
            // FIX 4: was misplaced outside SafeArea child with broken braces

          ),

        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String label;
  final double screenW;
  final VoidCallback onTap; // ← add this

  const _MenuCard({
    required this.label,
    required this.screenW,
    required this.onTap, // ← add this
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // ← wrap with this
      child: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/ui/card_ui.png',
              width: screenW * 0.5,
              height: 90,
              fit: BoxFit.fill,
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.ribeye(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5), // shadow color
                      blurRadius: 4, // shadow blur
                      offset: Offset(1, 2), // x, y position
                    ),
                  ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class BottomButtons extends StatelessWidget {
  final AudioService audio;
  const BottomButtons({super.key, required this.audio});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () {
                audio.play(AudioAsset.normalClick);
                context.push('/profiles');
              },
              icon: const Icon(
                Icons.switch_account_rounded,
                size: 16,
                color: Color(0xFF5D3A1A),
              ),
              label: const Text(
                'Ganti Anak',
                style: TextStyle(
                  color: Color(0xFF5D3A1A),
                  fontSize: 12,
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
              icon: const Icon(
                Icons.lock_outline,
                size: 16,
                color: Color(0xFF5D3A1A),
              ),
              label: const Text(
                'Mode Orang Tua',
                style: TextStyle(
                  color: Color(0xFF5D3A1A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5D3A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}