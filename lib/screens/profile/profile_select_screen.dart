import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/game_progress.dart';
import '../../providers/progress_provider.dart';
import '../../services/storage_service.dart';

// ─── Green Design Tokens ──────────────────────────────────────────────────────
const _brandGreen  = Color(0xFF4CAF6E);
const _brandShadow = Color(0xFF2A7A48);
const _bg          = Color(0xFFEDFFF3);
const _textColor   = Color(0xFF1A3A2A);
const _mutedText   = Color(0xFF557A65);

/// Profile selection screen — shown when app has multiple registered children
/// or when no active profile is set.
///
/// From here: pick an existing profile to play, or register a new child.
/// Delete requires parent PIN — handled inline via bottom sheet.
class ProfileSelectScreen extends StatelessWidget {
  const ProfileSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Siapa yang bermain?',
                style: GoogleFonts.baloo2(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _textColor,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih profil atau tambah anak baru.',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: _mutedText,
                ),
              ),
              const SizedBox(height: 24),

              // Profile list
              Expanded(
                child: ListView.builder(
                  itemCount: provider.profiles.length,
                  itemBuilder: (context, i) {
                    final profile = provider.profiles[i];
                    return _ProfileCard(
                      profile: profile,
                      isActive: provider.progress.id == profile.id,
                      onTap: () async {
                        await context
                            .read<ProgressProvider>()
                            .switchProfile(profile.id);
                        if (context.mounted) context.go('/home');
                      },
                      onDelete: () => _showDeleteConfirm(context, profile),
                    );
                  },
                ),
              ),

              // Add new child button
              const SizedBox(height: 8),
              _AddButton(onTap: () => _showAddProfile(context)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddProfileSheet(
        onConfirm: (name) async {
          Navigator.pop(ctx);
          await context.read<ProgressProvider>().addProfile(name);
          if (context.mounted) context.go('/home');
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, GameProgress profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DeleteProfileSheet(
        profile: profile,
        onConfirm: () async {
          Navigator.pop(ctx);
          await context.read<ProgressProvider>().deleteProfile(profile.id);
          if (context.mounted) {
            final provider = context.read<ProgressProvider>();
            if (!provider.hasAnyProfile) {
              context.go('/onboarding');
            }
          }
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final GameProgress profile;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final shadowColor =
        isActive ? _brandShadow : const Color(0xFFA5D6B5);
    final cardColor = isActive ? _brandGreen : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: shadowColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Transform.translate(
            offset: const Offset(-4, -5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: isActive
                    ? null
                    : Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Row(
                children: [
                  // Avatar circle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.25)
                          : const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        profile.childName.isNotEmpty
                            ? profile.childName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.baloo2(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isActive ? Colors.white : _brandGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name + stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.childName,
                          style: GoogleFonts.baloo2(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white : _textColor,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${profile.totalSessions} sesi · ${profile.totalStars} ⭐',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: isActive
                                ? Colors.white.withValues(alpha: 0.85)
                                : _mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Delete button
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.7)
                          : _mutedText,
                      size: 22,
                    ),
                    tooltip: 'Hapus profil',
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

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _brandShadow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Transform.translate(
          offset: const Offset(-4, -5),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: _brandGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 8),
                Text(
                  'Tambah Anak Baru',
                  style: GoogleFonts.baloo2(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom Sheets ─────────────────────────────────────────────────────────────

class _AddProfileSheet extends StatefulWidget {
  final Future<void> Function(String name) onConfirm;

  const _AddProfileSheet({required this.onConfirm});

  @override
  State<_AddProfileSheet> createState() => _AddProfileSheetState();
}

class _AddProfileSheetState extends State<_AddProfileSheet> {
  final _controller = TextEditingController();
  String _error = '';
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Masukkan nama anak dulu ya!');
      return;
    }
    if (name.length > 50) {
      setState(() => _error = 'Nama terlalu panjang.');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    await widget.onConfirm(name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFA5D6B5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nama anak baru',
              style: GoogleFonts.baloo2(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Data progress tersimpan terpisah untuk setiap anak.',
              style: GoogleFonts.dmSans(fontSize: 14, color: _mutedText),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: 50,
              style: GoogleFonts.baloo2(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
              decoration: InputDecoration(
                hintText: 'Tulis nama di sini',
                hintStyle: GoogleFonts.dmSans(color: Colors.green.shade200),
                counterText: '',
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _error,
                style: GoogleFonts.dmSans(
                  color: const Color(0xFFE53935),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: _brandShadow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Transform.translate(
                  offset: const Offset(-4, -5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _brandGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              'Tambah',
                              style: GoogleFonts.baloo2(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteProfileSheet extends StatefulWidget {
  final GameProgress profile;
  final Future<void> Function() onConfirm;

  const _DeleteProfileSheet({
    required this.profile,
    required this.onConfirm,
  });

  @override
  State<_DeleteProfileSheet> createState() => _DeleteProfileSheetState();
}

class _DeleteProfileSheetState extends State<_DeleteProfileSheet> {
  String _pin = '';
  String _error = '';
  bool _loading = false;

  void _onDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += d;
      _error = '';
    });
    if (_pin.length == 4) _submit();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    final storage = context.read<StorageService>();
    if (!storage.validatePin(_pin)) {
      setState(() {
        _pin = '';
        _error = 'PIN salah. Coba lagi.';
      });
      return;
    }
    setState(() => _loading = true);
    await widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFA5D6B5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFE53935), size: 40),
          const SizedBox(height: 12),
          Text(
            'Hapus profil "${widget.profile.childName}"?',
            style: GoogleFonts.baloo2(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Semua data progress akan hilang permanen.\nMasukkan PIN orang tua untuk konfirmasi.',
            style: GoogleFonts.dmSans(
                fontSize: 14, color: _mutedText, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length
                      ? const Color(0xFFE53935)
                      : Colors.green.shade100,
                ),
              );
            }),
          ),

          if (_error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _error,
              style: GoogleFonts.dmSans(
                color: const Color(0xFFE53935),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Number pad
          if (!_loading)
            _MiniNumberPad(onDigit: _onDigit, onDelete: _onDelete)
          else
            const CircularProgressIndicator(color: Color(0xFFE53935)),
        ],
      ),
    );
  }
}

class _MiniNumberPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _MiniNumberPad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'del'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((digit) {
                if (digit.isEmpty) return const SizedBox(width: 60);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () => digit == 'del' ? onDelete() : onDigit(digit),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          digit == 'del' ? '⌫' : digit,
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
