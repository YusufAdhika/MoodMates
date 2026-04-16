import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/progress_provider.dart';
import '../../services/storage_service.dart';

/// Onboarding screen shown once on first launch.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _onLanjut() async {
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Masukkan nama anak dulu ya!');
      return;
    }
    if (name.length > 50) {
      setState(() => _errorMessage = 'Nama terlalu panjang.');
      return;
    }
    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() => _errorMessage = 'PIN orang tua harus 4 angka.');
      return;
    }
    if (pin != confirmPin) {
      setState(() => _errorMessage = 'Konfirmasi PIN belum cocok.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final progressProvider = context.read<ProgressProvider>();
    final storageService = context.read<StorageService>();

    try {
      await progressProvider.addProfile(name);
      await storageService.setPin(pin);
      if (!mounted) return;
      context.go('/home');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandOrange = Color(0xFFFF9A3C);
    const brandShadow = Color(0xFFC85A00);
    const textColor = Color(0xFF3D2B1A);
    const mutedText = Color(0xFF8D6E63);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Moodmates',
                  style: GoogleFonts.baloo2(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: brandShadow,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Transform.translate(
                    offset: const Offset(-5, -7),
                    child: Container(
                      decoration: BoxDecoration(
                        color: brandOrange,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(
                        Icons.emoji_emotions_rounded,
                        size: 72,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Siapa nama kamu?',
                  style: GoogleFonts.baloo2(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Orang tua siapkan PIN dulu, lalu anak bisa langsung bermain.',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: mutedText,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                _SetupPanel(
                  icon: Icons.child_care_rounded,
                  iconColor: brandOrange,
                  title: 'Untuk Anak',
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 50,
                    style: GoogleFonts.baloo2(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tulis namamu di sini',
                      hintStyle: GoogleFonts.dmSans(
                        color: Colors.brown.shade200,
                      ),
                      counterText: '',
                    ),
                    onSubmitted: (_) => _onLanjut(),
                  ),
                ),
                const SizedBox(height: 16),
                _SetupPanel(
                  icon: Icons.lock_outline_rounded,
                  iconColor: mutedText,
                  title: 'Untuk Orang Tua',
                  subtitle:
                      'PIN ini dipakai untuk membuka dashboard orang tua.',
                  child: Column(
                    children: [
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        obscureText: _obscurePin,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: 'PIN orang tua (4 angka)',
                          hintStyle: GoogleFonts.dmSans(
                            color: Colors.brown.shade200,
                          ),
                          counterText: '',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _obscurePin = !_obscurePin);
                            },
                            icon: Icon(
                              _obscurePin
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPinController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        obscureText: _obscureConfirmPin,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: 'Ulangi PIN orang tua',
                          hintStyle: GoogleFonts.dmSans(
                            color: Colors.brown.shade200,
                          ),
                          counterText: '',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPin = !_obscureConfirmPin;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPin
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _onLanjut(),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFFE53935),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _StartButton(
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _onLanjut,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: mutedText,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Setup ini cuma sekali. Orang tua bisa masuk lewat Mode Orang Tua dengan PIN tadi.',
                          style: GoogleFonts.dmSans(
                            color: mutedText,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
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

class _SetupPanel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget child;

  const _SetupPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: const Color(0xFF3D2B1A),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: GoogleFonts.dmSans(
                color: const Color(0xFF8D6E63),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _StartButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const brandOrange = Color(0xFFFF9A3C);
    const brandShadow = Color(0xFFC85A00);

    return Padding(
      padding: const EdgeInsets.only(right: 5, bottom: 7),
      child: GestureDetector(
        onTap: onPressed,
        child: Opacity(
          opacity: onPressed == null ? 0.6 : 1,
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              color: brandShadow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Transform.translate(
              offset: const Offset(-5, -7),
              child: Container(
                decoration: BoxDecoration(
                  color: brandOrange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          'Mulai Bermain',
                          style: GoogleFonts.baloo2(
                            fontSize: 23,
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
      ),
    );
  }
}
